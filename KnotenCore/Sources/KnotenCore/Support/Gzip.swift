import Compression
import Foundation

/// Inflates a gzip stream.
///
/// Foundation has no gzip and `Compression` speaks only raw DEFLATE (RFC 1951),
/// so the wrapper is walked here and the trailer skipped. The one gzip this
/// client meets is a pull round's patch blob, which is gzipped `git
/// format-patch` text.
public enum Gzip {
    /// Nil when the bytes are not gzip, or the payload does not inflate. An
    /// empty payload also reads as nil, which no patch ever is.
    public static func inflate(_ data: Data) -> Data? {
        guard let deflate = payload(of: data) else { return nil }
        return inflateRaw(deflate)
    }

    /// Skips the ten byte header, its optional fields, and the eight byte
    /// trailer, leaving the DEFLATE stream.
    private static func payload(of data: Data) -> Data? {
        guard data.count > 18, data[0] == 0x1f, data[1] == 0x8b, data[2] == 0x08 else {
            return nil
        }

        let flags = data[3]
        var offset = 10

        if flags & 0x04 != 0 {  // FEXTRA: a little endian length, then the field
            guard offset + 2 <= data.count else { return nil }
            let length = Int(data[offset]) | Int(data[offset + 1]) << 8
            offset += 2 + length
        }
        if flags & 0x08 != 0 {  // FNAME, NUL terminated
            offset = endOfNulTerminated(data, from: offset)
        }
        if flags & 0x10 != 0 {  // FCOMMENT, NUL terminated
            offset = endOfNulTerminated(data, from: offset)
        }
        if flags & 0x02 != 0 {  // FHCRC
            offset += 2
        }

        guard offset < data.count - 8 else { return nil }
        return data.subdata(in: offset..<(data.count - 8))
    }

    private static func endOfNulTerminated(_ data: Data, from offset: Int) -> Int {
        var index = offset
        while index < data.count, data[index] != 0 { index += 1 }
        return index + 1
    }

    /// `compression_decode_buffer` needs a destination and reports failure when
    /// it is too small, so the buffer grows until the payload fits.
    private static func inflateRaw(_ deflate: Data) -> Data? {
        var capacity = max(deflate.count * 4, 64 * 1024)

        while capacity <= 64 * 1024 * 1024 {
            var output = Data(count: capacity)
            let written = output.withUnsafeMutableBytes { destination in
                deflate.withUnsafeBytes { source in
                    decode(destination, source, capacity: capacity)
                }
            }
            if written > 0 { return output.prefix(written) }
            capacity *= 4
        }

        return nil
    }

    private static func decode(
        _ destination: UnsafeMutableRawBufferPointer,
        _ source: UnsafeRawBufferPointer,
        capacity: Int
    ) -> Int {
        guard let out = destination.bindMemory(to: UInt8.self).baseAddress,
              let input = source.bindMemory(to: UInt8.self).baseAddress
        else { return 0 }

        return compression_decode_buffer(
            out, capacity, input, source.count, nil, COMPRESSION_ZLIB
        )
    }
}

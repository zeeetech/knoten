import Foundation

enum Random {
    static func bytes(_ count: Int) -> Data {
        var bytes = [UInt8](repeating: 0, count: count)
        for index in bytes.indices {
            bytes[index] = UInt8.random(in: .min ... .max)
        }
        return Data(bytes)
    }
}

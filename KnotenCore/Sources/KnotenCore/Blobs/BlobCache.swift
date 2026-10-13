import CryptoKit
import Foundation

/// Best-effort storage for blob bytes, keyed by the caller.
///
/// A cache is not a feature. A miss and a failure look identical to a caller,
/// so nothing here reports an error: read returns nil, write gives up.
public protocol BlobCache: Sendable {
    func read(_ key: String) async -> Data?
    func write(_ data: Data, key: String) async
    func clear() async
}

/// Bytes on disk, bounded by total size, evicting the least recently used
/// entry first.
///
/// Blob keys are content addressed, so an entry never goes stale and there is
/// nothing to invalidate: a changed avatar is a new CID, which is a new key.
public actor DiskBlobCache: BlobCache {
    private let directory: URL
    private let byteLimit: Int
    private let files = FileManager.default

    public init(directory: URL, byteLimit: Int = 32 * 1024 * 1024) {
        self.directory = directory
        self.byteLimit = byteLimit

        try? files.createDirectory(at: directory, withIntermediateDirectories: true)

        // An image cache has no business in an iCloud backup.
        var target = directory
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        try? target.setResourceValues(values)
    }

    public func read(_ key: String) -> Data? {
        let url = file(for: key)
        guard let data = try? Data(contentsOf: url) else { return nil }
        try? files.setAttributes([.modificationDate: Date()], ofItemAtPath: url.path)
        return data
    }

    public func write(_ data: Data, key: String) {
        try? files.createDirectory(at: directory, withIntermediateDirectories: true)
        try? data.write(to: file(for: key), options: .atomic)
        evict()
    }

    public func clear() {
        for entry in entries() {
            try? files.removeItem(at: entry.url)
        }
    }

    private func file(for key: String) -> URL {
        directory.appending(path: digest(key))
    }

    /// Hashing keeps a DID out of the filename, so a key can never walk the
    /// filesystem.
    private func digest(_ key: String) -> String {
        SHA256.hash(data: Data(key.utf8)).map { String(format: "%02x", $0) }.joined()
    }

    private func entries() -> [(url: URL, size: Int, used: Date)] {
        let keys: [URLResourceKey] = [.contentModificationDateKey, .fileSizeKey]
        guard let listing = try? files.contentsOfDirectory(at: directory, includingPropertiesForKeys: keys) else {
            return []
        }

        return listing.map { url in
            let values = try? url.resourceValues(forKeys: Set(keys))
            return (url, values?.fileSize ?? 0, values?.contentModificationDate ?? .distantPast)
        }
    }

    private func evict() {
        let listing = entries()
        var total = listing.reduce(0) { $0 + $1.size }
        guard total > byteLimit else { return }

        for entry in listing.sorted(by: { $0.used < $1.used }) {
            try? files.removeItem(at: entry.url)
            total -= entry.size
            if total <= byteLimit { return }
        }
    }
}

/// Keeps bytes in memory. For tests and previews, where a filesystem is noise.
public actor MemoryBlobCache: BlobCache {
    private var storage: [String: Data] = [:]

    public init() {}

    public func read(_ key: String) -> Data? {
        storage[key]
    }

    public func write(_ data: Data, key: String) {
        storage[key] = data
    }

    public func clear() {
        storage.removeAll()
    }
}

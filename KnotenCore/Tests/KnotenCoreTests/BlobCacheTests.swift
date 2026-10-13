import Foundation
import Testing

@testable import KnotenCore

private func cacheDirectory() -> URL {
    FileManager.default.temporaryDirectory
        .appending(path: "knoten-blob-tests-\(UUID().uuidString)")
}

@Test func memoryCacheRoundTrips() async {
    let cache = MemoryBlobCache()
    await cache.write(Data("bytes".utf8), key: "did:plc:x/bafy")

    #expect(await cache.read("did:plc:x/bafy") == Data("bytes".utf8))
    #expect(await cache.read("did:plc:x/missing") == nil)
}

@Test func diskCacheRoundTrips() async {
    let cache = DiskBlobCache(directory: cacheDirectory(), byteLimit: 1024)
    await cache.write(Data("bytes".utf8), key: "did:plc:x/bafy")

    #expect(await cache.read("did:plc:x/bafy") == Data("bytes".utf8))
    #expect(await cache.read("did:plc:x/missing") == nil)
}

@Test func diskCacheSurvivesANewInstance() async {
    let directory = cacheDirectory()
    let first = DiskBlobCache(directory: directory, byteLimit: 1024)
    await first.write(Data("bytes".utf8), key: "did:plc:x/bafy")

    let second = DiskBlobCache(directory: directory, byteLimit: 1024)
    #expect(await second.read("did:plc:x/bafy") == Data("bytes".utf8))
}

@Test func diskCacheEvictsTheLeastRecentlyUsed() async throws {
    let cache = DiskBlobCache(directory: cacheDirectory(), byteLimit: 250)

    await cache.write(Data(repeating: 0, count: 100), key: "old")
    try await Task.sleep(for: .milliseconds(10))
    await cache.write(Data(repeating: 0, count: 100), key: "middle")
    try await Task.sleep(for: .milliseconds(10))
    _ = await cache.read("old")
    try await Task.sleep(for: .milliseconds(10))
    await cache.write(Data(repeating: 0, count: 100), key: "new")

    #expect(await cache.read("new") != nil)
    #expect(await cache.read("old") != nil)
    #expect(await cache.read("middle") == nil)
}

@Test func diskCacheClearDropsEverything() async {
    let cache = DiskBlobCache(directory: cacheDirectory(), byteLimit: 1024)
    await cache.write(Data("bytes".utf8), key: "did:plc:x/bafy")

    await cache.clear()
    #expect(await cache.read("did:plc:x/bafy") == nil)
}

@Test func diskCacheStaysOutOfTheBackup() async throws {
    let directory = cacheDirectory()
    _ = DiskBlobCache(directory: directory, byteLimit: 1024)

    let values = try directory.resourceValues(forKeys: [.isExcludedFromBackupKey])
    #expect(values.isExcludedFromBackup == true)
}

@Test func diskCacheKeyNeverReachesTheFilesystem() async throws {
    let directory = cacheDirectory()
    let cache = DiskBlobCache(directory: directory, byteLimit: 1024)
    await cache.write(Data("bytes".utf8), key: "../../etc/passwd")

    let entries = try FileManager.default.contentsOfDirectory(atPath: directory.path)
    #expect(entries.count == 1)
    #expect(entries[0].count == 64)
}

import Foundation
import Testing

@testable import KnotenCore

// The fixture is a real patch blob from sh.tangled.repo.pull, generated rather
// than typed, so the parser is checked against the shape the server sends.

@Test func parsesARealPatchBlob() {
    let patch = Patch.parse(patchFixture)

    #expect(patch.files.count == 2)
    #expect(patch.additions == 12)
    #expect(patch.deletions == 0)
    #expect(patch.files.map(\.path) == [
        "src/lib/app/settings.svelte.ts",
        "src/lib/modals/SettingsAppearanceTab.svelte",
    ])
}

@Test func skipsTheFormatPatchEnvelopeAndTheDiffstat() {
    let patch = Patch.parse(patchFixture)

    // The payload opens with the format-patch envelope and a diffstat listing
    // 33 files; only the files that carry hunks are kept.
    #expect(patch.files.first?.path == "src/lib/app/settings.svelte.ts")
    #expect(patch.files.allSatisfy { !$0.path.contains("locales") })
}

@Test func readsTheHunkOfTheFirstFile() {
    let patch = Patch.parse(patchFixture)
    let file = patch.files.first

    #expect(file?.hunks.count == 1)
    #expect(file?.hunks.first?.header == "@@ -264,6 +264,10 @@")
    #expect(file?.additions == 4)

    let added = file?.hunks.first?.lines.filter { $0.kind == .addition }.map(\.text) ?? []
    #expect(added.first == "\tvisualizerRounding: {")
    #expect(added.count == 4)
}

@Test func inflatesTheGzippedBlobAndParsesIt() throws {
    let gzipped = try #require(Data(base64Encoded: patchFixtureGzippedBase64))
    let inflated = try #require(Gzip.inflate(gzipped))
    let text = try #require(String(data: inflated, encoding: .utf8))

    // Swift drops the newline before the closing delimiter, and a patch payload
    // ends with one, so the literal is the payload minus its last byte.
    #expect(text == patchFixture + "\n")

    let patch = Patch.parse(text)
    #expect(patch.files.count == 2)
    #expect(patch.additions == 12)
}

@Test func rejectsBytesThatAreNotGzip() {
    #expect(Gzip.inflate(Data("not gzip at all, not even close".utf8)) == nil)
    #expect(Gzip.inflate(Data()) == nil)
}

@Test func handlesDeletionsANewFileAndTheNoNewlineMarker() {
    let text = """
    diff --git a/old.txt b/old.txt
    deleted file mode 100644
    index 1111111..0000000
    --- a/old.txt
    +++ /dev/null
    @@ -1,2 +0,0 @@
    -gone
    -too
    diff --git a/new.txt b/new.txt
    new file mode 100644
    index 0000000..2222222
    --- /dev/null
    +++ b/new.txt
    @@ -0,0 +1,2 @@
    +fresh
    +lines
    \\ No newline at end of file
    """

    let patch = Patch.parse(text)

    #expect(patch.files.map(\.path) == ["old.txt", "new.txt"])
    #expect(patch.files[0].deletions == 2)
    #expect(patch.files[0].additions == 0)
    #expect(patch.files[1].additions == 2)
    #expect(patch.files[1].hunks[0].lines.last?.kind == .marker)
}

@Test func stopsAHunkWhenItsLineCountsAreUsedUp() {
    // The `-- ` signature of a format-patch payload follows the last hunk and
    // looks like a deletion, so the counts are what end the hunk.
    let text = """
    diff --git a/a.txt b/a.txt
    --- a/a.txt
    +++ b/a.txt
    @@ -1,1 +1,1 @@
    -old
    +new
    --
    knot
    """

    let patch = Patch.parse(text)

    #expect(patch.files.count == 1)
    #expect(patch.files[0].hunks[0].lines.count == 2)
    #expect(patch.files[0].additions == 1)
    #expect(patch.files[0].deletions == 1)
}

@Test func countsABlankContextLineWrittenWithoutItsLeadingSpace() {
    let text = [
        "diff --git a/a.txt b/a.txt",
        "--- a/a.txt",
        "+++ b/a.txt",
        "@@ -1,3 +1,3 @@",
        " one",
        "-two",
        "+TWO",
        "",
        "",
    ].joined(separator: "\n")

    let patch = Patch.parse(text)
    let lines = patch.files.first?.hunks.first?.lines ?? []

    #expect(lines.count == 4)
    #expect(lines.last?.kind == .context)
    #expect(lines.last?.text == "")
}

@Test func yieldsNothingForTextThatIsNotAPatch() {
    #expect(Patch.parse("").isEmpty)
    #expect(Patch.parse("just some prose\nwith no diff in it").isEmpty)
}

@Test func readsBothTimestampShapes() {
    #expect(Timestamps.date(from: "2026-10-13T04:10:31.151Z") != nil)
    #expect(Timestamps.date(from: "2026-10-13T03:58:14Z") != nil)
    #expect(Timestamps.date(from: "2026-10-13T06:24:36+03:00") != nil)
    #expect(Timestamps.date(from: "not a timestamp") == nil)
}

@Test func keepsTheNumericOffsetWhenReadingATimestamp() throws {
    // A strategy that ignores the offset would read both of these as the same
    // wall clock time, three hours apart.
    let withOffset = try #require(Timestamps.date(from: "2026-10-13T06:24:36+03:00"))
    let inUTC = try #require(Timestamps.date(from: "2026-10-13T03:24:36Z"))

    #expect(withOffset == inUTC)
}

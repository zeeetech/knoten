import Foundation
import Testing

@testable import KnotenCore

@Test func roundTripsArbitraryBytes() {
    let data = Data([0, 1, 2, 253, 254, 255])
    #expect(B64URL.decode(B64URL.encode(data)) == data)
}

@Test func omitsPadding() {
    #expect(!B64URL.encode(Data([1, 2, 3])).contains("="))
}

@Test func usesURLSafeAlphabet() {
    let encoded = B64URL.encode(Data([251, 255, 190]))
    #expect(!encoded.contains("+") && !encoded.contains("/"))
}

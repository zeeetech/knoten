import Foundation
import Testing

@testable import KnotenCore

private let document = """
{
  "id": "did:plc:abc123",
  "alsoKnownAs": ["at://zoey.tngl.sh"],
  "service": [
    {
      "id": "#atproto_pds",
      "type": "AtprotoPersonalDataServer",
      "serviceEndpoint": "https://pds.tngl.sh"
    }
  ]
}
"""

@Test func extractsHandleAndPDS() throws {
    let decoded = try JSONDecoder().decode(DIDDocument.self, from: Data(document.utf8))
    #expect(decoded.handle == "zoey.tngl.sh")
    #expect(decoded.pdsURL?.absoluteString == "https://pds.tngl.sh")
}

@Test func missingPDSYieldsNil() throws {
    let decoded = try JSONDecoder().decode(DIDDocument.self, from: Data(#"{"id":"did:plc:x"}"#.utf8))
    #expect(decoded.pdsURL == nil)
    #expect(decoded.handle == nil)
}

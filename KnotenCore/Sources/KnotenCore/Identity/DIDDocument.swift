import Foundation

public struct DIDDocument: Decodable, Sendable {
    public let id: String
    public let alsoKnownAs: [String]?
    public let service: [Service]?
    public let verificationMethod: [VerificationMethod]?

    public struct Service: Decodable, Sendable {
        public let id: String
        public let type: String
        public let serviceEndpoint: String
    }

    public struct VerificationMethod: Decodable, Sendable {
        public let id: String
        public let type: String
        public let controller: String
        public let publicKeyMultibase: String?
    }

    public var handle: String? {
        alsoKnownAs?
            .first { $0.hasPrefix("at://") }
            .map { String($0.dropFirst("at://".count)) }
    }

    public var pdsURL: URL? {
        service?
            .first { $0.id == "#atproto_pds" || $0.type == "AtprotoPersonalDataServer" }
            .flatMap { URL(string: $0.serviceEndpoint) }
    }
}

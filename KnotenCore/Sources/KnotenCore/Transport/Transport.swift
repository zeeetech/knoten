import Foundation

public struct HTTPResponse: Sendable {
    public let data: Data
    public let response: HTTPURLResponse

    public var status: Int {
        response.statusCode
    }

    public var body: String {
        String(decoding: data, as: UTF8.self)
    }

    public var isSuccess: Bool {
        (200..<300).contains(status)
    }
}

public protocol Transport: Sendable {
    func send(_ request: URLRequest) async -> KnotenResult<HTTPResponse>
}

public struct URLSessionTransport: Transport {
    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func send(_ request: URLRequest) async -> KnotenResult<HTTPResponse> {
        let outcome: (Data, URLResponse)
        do {
            outcome = try await session.data(for: request)
        } catch {
            return .failure(.network(error.localizedDescription))
        }

        guard let http = outcome.1 as? HTTPURLResponse else {
            return .failure(.invalidResponse("not an HTTP response"))
        }
        return .success(HTTPResponse(data: outcome.0, response: http))
    }
}

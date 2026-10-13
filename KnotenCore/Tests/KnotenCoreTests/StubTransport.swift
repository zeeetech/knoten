import Foundation

@testable import KnotenCore

/// A transport that answers from a closure, for tests.
struct StubTransport: Transport {
    let handler: @Sendable (URLRequest) async -> KnotenResult<HTTPResponse>

    func send(_ request: URLRequest) async -> KnotenResult<HTTPResponse> {
        await handler(request)
    }
}

func http(
    _ url: URL?,
    _ status: Int,
    body: String = "",
    headers: [String: String] = [:]
) -> HTTPResponse {
    HTTPResponse(
        data: Data(body.utf8),
        response: HTTPURLResponse(
            url: url ?? URL(string: "https://example.com")!,
            statusCode: status,
            httpVersion: nil,
            headerFields: headers
        )!
    )
}

actor Counter {
    private(set) var value = 0

    func next() -> Int {
        value += 1
        return value
    }
}

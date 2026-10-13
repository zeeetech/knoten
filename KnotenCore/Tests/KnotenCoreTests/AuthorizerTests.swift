import Foundation
import Testing

@testable import KnotenCore

private let didDocument = """
{
  "id": "did:plc:abc",
  "alsoKnownAs": ["at://tester.example"],
  "service": [
    {
      "id": "#atproto_pds",
      "type": "AtprotoPersonalDataServer",
      "serviceEndpoint": "https://pds.example"
    }
  ]
}
"""

private let serverMetadata = """
{
  "issuer": "https://auth.example",
  "authorization_endpoint": "https://auth.example/oauth/authorize",
  "token_endpoint": "https://auth.example/oauth/token",
  "pushed_authorization_request_endpoint": "https://auth.example/oauth/par"
}
"""

/// Serves the documents the flow walks and answers the pushed request with the
/// status a real authorization server uses.
private func authorizationServerTransport(pushedStatus: Int) -> StubTransport {
    StubTransport { request in
        let url = request.url ?? URL(string: "https://example.com")!
        let path = url.host == "plc.directory" ? "/plc" : url.path

        switch (request.httpMethod ?? "GET", path) {
        case ("GET", "/.well-known/atproto-did"):
            return .success(http(url, 200, body: "did:plc:abc"))
        case ("GET", "/plc"):
            return .success(http(url, 200, body: didDocument))
        case ("GET", "/.well-known/oauth-protected-resource"):
            return .success(http(url, 200, body: #"{"authorization_servers":["https://auth.example"]}"#))
        case ("GET", "/.well-known/oauth-authorization-server"):
            return .success(http(url, 200, body: serverMetadata))
        case ("POST", "/oauth/par"):
            return .success(http(
                url,
                pushedStatus,
                body: #"{"request_uri":"urn:ietf:params:oauth:request_uri:abc","expires_in":299}"#
            ))
        default:
            return .failure(.invalidURL(url.absoluteString))
        }
    }
}

private let client = OAuthClient(
    clientID: URL(string: "https://client.example/oauth/client-metadata.json")!,
    redirectURI: URL(string: "example.client:/callback")!
)

@Test func aCreatedPushedRequestIsNotAFailure() async {
    // RFC 9126: the pushed request answers 201 Created.
    let started = await Authorizer(transport: authorizationServerTransport(pushedStatus: 201))
        .start(client: client, identifier: "tester.example")

    #expect(started.value?.did == "did:plc:abc")
    #expect(started.value?.serviceURL.absoluteString == "https://pds.example")
    #expect(started.value?.issuer.absoluteString == "https://auth.example")
}

@Test func theAuthorizeURLNamesTheClientAndThePushedRequest() async {
    let started = await Authorizer(transport: authorizationServerTransport(pushedStatus: 201))
        .start(client: client, identifier: "tester.example")

    let url = started.value?.url.absoluteString ?? ""
    #expect(url.hasPrefix("https://auth.example/oauth/authorize?"))
    #expect(url.contains("client_id=https://client.example/oauth/client-metadata.json"))
    #expect(url.contains("request_uri=urn:ietf:params:oauth:request_uri:abc"))
}

@Test func aRejectedPushedRequestCarriesTheServerReason() async {
    let transport = StubTransport { request in
        let url = request.url ?? URL(string: "https://example.com")!
        let path = url.host == "plc.directory" ? "/plc" : url.path

        switch (request.httpMethod ?? "GET", path) {
        case ("GET", "/.well-known/atproto-did"):
            return .success(http(url, 200, body: "did:plc:abc"))
        case ("GET", "/plc"):
            return .success(http(url, 200, body: didDocument))
        case ("GET", "/.well-known/oauth-protected-resource"):
            return .success(http(url, 200, body: #"{"authorization_servers":["https://auth.example"]}"#))
        case ("GET", "/.well-known/oauth-authorization-server"):
            return .success(http(url, 200, body: serverMetadata))
        default:
            return .success(http(
                url,
                400,
                body: #"{"error":"invalid_redirect_uri","error_description":"Native clients must use HTTP redirect URIs"}"#
            ))
        }
    }

    let started = await Authorizer(transport: transport).start(client: client, identifier: "tester.example")

    #expect(started.error?.localizedDescription == "unexpected HTTP 400")
    if case .http(let status, let body) = started.error {
        #expect(status == 400)
        #expect(body.contains("invalid_redirect_uri"))
    }
}

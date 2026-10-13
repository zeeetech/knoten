import Foundation
import KnotenCore

/// Temporary: runs the real authorization flow against a live authorization
/// server, up to the pushed request, and prints what came back.
@main
struct Smoke {
    static func main() async {
        let identifier = CommandLine.arguments.dropFirst().first ?? "tangled.org"

        let client = OAuthClient(
            clientID: URL(string: "https://knoten.zeetech.io/oauth/client-metadata.json")!,
            redirectURI: URL(string: "io.zeetech.knoten:/callback")!
        )

        print("identifier:", identifier)
        print("client_id :", client.clientID.absoluteString)
        print("redirect  :", client.redirectURI.absoluteString)
        print()

        switch await Authorizer().start(client: client, identifier: identifier) {
        case .success(let authorization):
            print("PAR OK")
            print("  did       :", authorization.did)
            print("  issuer    :", authorization.issuer.absoluteString)
            print("  pds       :", authorization.serviceURL.absoluteString)
            print("  token     :", authorization.tokenEndpoint.absoluteString)
            print("  nonce     :", authorization.nonce ?? "-")
            print("  authorize :", authorization.url.absoluteString)
        case .failure(let error):
            print("PAR FAILED:", error)
            if case .http(let status, let body) = error {
                print("  status:", status)
                print("  body  :", body)
            }
        }
    }
}

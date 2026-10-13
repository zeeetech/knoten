import AuthenticationServices
import KnotenCore
import UIKit

/// Presents the authorization server in a system web session and hands back
/// the redirect URL.
@MainActor
final class AuthenticationSession: NSObject, ASWebAuthenticationPresentationContextProviding {
    // The system does not retain the session while its web view is up, so
    // the model has to.
    private var webSession: ASWebAuthenticationSession?

    func start(url: URL, callbackScheme: String) async -> KnotenResult<URL> {
        let result = await withCheckedContinuation { (continuation: CheckedContinuation<KnotenResult<URL>, Never>) in
            let session = ASWebAuthenticationSession(url: url, callback: .customScheme(callbackScheme)) { callbackURL, error in
                if let callbackURL {
                    continuation.resume(returning: .success(callbackURL))
                } else if (error as? ASWebAuthenticationSessionError)?.code == .canceledLogin {
                    continuation.resume(returning: .failure(.cancelledLogin))
                } else {
                    continuation.resume(returning: .failure(
                        .invalidSession(error?.localizedDescription ?? "the authentication session ended without a callback")
                    ))
                }
            }
            session.presentationContextProvider = self
            webSession = session
            session.start()
        }
        webSession = nil
        return result
    }

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first { $0.isKeyWindow } ?? ASPresentationAnchor()
    }
}

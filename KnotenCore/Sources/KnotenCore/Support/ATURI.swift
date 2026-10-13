import Foundation

/// The parts of an `at://<did>/<collection>/<rkey>` address.
///
/// Only the owner is read in practice: a pull's patch blob lives on the PDS of
/// the account that wrote the pull, and a comment's author is the repository its
/// record sits in, neither of which is in the payload.
public enum ATURI {
    /// The DID that owns a record. Nil when the text is not an at-URI, so a
    /// malformed address degrades one row instead of failing a screen.
    public static func owner(of uri: String) -> String? {
        guard uri.hasPrefix("at://") else { return nil }
        let parts = uri
            .dropFirst("at://".count)
            .split(separator: "/", omittingEmptySubsequences: true)
        guard parts.count >= 3 else { return nil }
        return String(parts[0])
    }
}

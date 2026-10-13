import KnotenCore
import SwiftUI

@MainActor
@Observable
final class PullDetailModel {
    enum DiffState {
        case loading
        /// The pull carries no patch blob, which a pull opened from a branch
        /// without rounds does.
        case empty
        case ready(Patch)
        case failed(KnotenError)
    }

    private(set) var comments: [FeedComment] = []
    private(set) var commentFailure: KnotenError?
    private(set) var diff: DiffState = .loading

    /// The state of the comment box: sending, or the reason it did not.
    private(set) var post: PostState = .idle

    enum PostState: Equatable {
        case idle
        case sending
        case failed(String)
    }

    private var authors: [String: String] = [:]

    private let pull: PullItem
    private let account: SessionModel.Account

    init(pull: PullItem, account: SessionModel.Account) {
        self.pull = pull
        self.account = account
    }

    /// Comments and the patch are independent, so they are fetched together.
    /// The patch is the slow one: it costs a DID resolution, a blob fetch and
    /// an inflate.
    func load() async {
        async let comments: Void = loadComments()
        async let patch: Void = loadPatch()
        _ = await (comments, patch)
    }

    /// The name to show for a comment's author. The feed carries only a DID, so
    /// it is resolved once per author and falls back to the DID itself.
    func label(for author: String?) -> String {
        guard let author else { return "unknown" }
        return authors[author] ?? author
    }

    var isSending: Bool {
        post == .sending
    }

    var postFailure: String? {
        if case .failed(let reason) = post { return reason }
        return nil
    }

    /// Posts a comment, then reads the thread back.
    ///
    /// `createRecord` does not echo the record, so reading the comments again is
    /// how the new row gets its uri and the server's own rendering of it. True
    /// when the comment landed, which is when the box should clear.
    func send(_ body: String) async -> Bool {
        let trimmed = body.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        guard let cid = pull.cid else {
            post = .failed("This pull carries no cid to comment against.")
            return false
        }

        post = .sending
        let subject = CommentSubject(uri: pull.uri, cid: cid)

        switch await account.writer.comment(on: subject, body: trimmed) {
        case .failure(let error):
            post = .failed(error.localizedDescription)
            return false
        case .success:
            await loadComments()
            post = .idle
            return true
        }
    }

    private func loadComments() async {
        switch await account.tangled.listComments(subject: pull.uri, limit: 50) {
        case .failure(let error):
            commentFailure = error
        case .success(let page):
            comments = page.items
            await resolveAuthors(of: page.items)
        }
    }

    private func resolveAuthors(of comments: [FeedComment]) async {
        for did in Set(comments.compactMap(\.author)) where authors[did] == nil {
            switch await account.resolver.resolve(did) {
            case .success(let document):
                authors[did] = document.handle ?? did
            case .failure:
                authors[did] = did
            }
        }
    }

    /// A round's patch lives on the PDS of whoever wrote the pull, gzipped, so
    /// it is resolved, fetched, inflated and parsed here.
    private func loadPatch() async {
        guard let blob = pull.value.rounds.last?.patchBlob else {
            diff = .empty
            return
        }
        guard let author = ATURI.owner(of: pull.uri) else {
            diff = .failed(.invalidURL(pull.uri))
            return
        }

        switch await account.resolver.resolve(author) {
        case .failure(let error):
            diff = .failed(error)
        case .success(let document):
            guard let pds = document.pdsURL else {
                diff = .failed(.invalidResponse("the author's DID document names no PDS"))
                return
            }
            await fetchPatch(blob, from: author, on: pds)
        }
    }

    private func fetchPatch(_ blob: BlobRef, from author: String, on pds: URL) async {
        switch await account.blobs.fetch(blob, did: author, pds: pds) {
        case .failure(let error):
            diff = .failed(error)
        case .success(let data):
            guard let inflated = Gzip.inflate(data),
                  let text = String(data: inflated, encoding: .utf8)
            else {
                diff = .failed(.invalidResponse("the patch blob is not gzipped text"))
                return
            }
            diff = .ready(Patch.parse(text))
        }
    }
}

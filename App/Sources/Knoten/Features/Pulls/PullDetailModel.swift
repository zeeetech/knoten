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

import KnotenCore
import SwiftUI

@MainActor
@Observable
final class InboxModel {
    /// One thing that happened to the account, flattened for a row.
    struct Item: Identifiable, Sendable {
        enum Kind: Sendable {
            case followed
            case work(RepoItem)
        }

        let id: String
        let kind: Kind
        /// The DID of whoever did it. Nothing on the wire here carries a handle.
        let actor: String
        /// The repo it happened in, when it happened in one.
        let repo: String?
        let date: Date?
    }

    enum State {
        case idle
        case loading
        case loaded(Sections)
        case failed(KnotenError)
    }

    /// Two lists rather than one, because they are not the same kind of thing.
    /// A pull or an issue is waiting on a decision; a follower is not.
    struct Sections: Sendable {
        var needsYou: [Item] = []
        /// Capped. An account with thousands of followers would otherwise bury
        /// everything that needs a decision.
        var followers: [Item] = []
    }

    /// Resolving an actor costs a request each, so only the ones a screen can
    /// show are asked about.
    private static let actorCap = 30
    private static let followerCap = 5

    private(set) var state: State = .idle

    private let account: SessionModel.Account
    private let seen: InboxSeenStore
    private var handles: [String: String] = [:]

    init(account: SessionModel.Account, seen: InboxSeenStore = InboxSeenStore()) {
        self.account = account
        self.seen = seen
    }

    var sections: Sections {
        guard case .loaded(let sections) = state else { return Sections() }
        return sections
    }

    var allItems: [Item] {
        sections.needsYou + sections.followers
    }

    var unreadCount: Int {
        allItems.filter { isUnread($0) }.count
    }

    func isUnread(_ item: Item) -> Bool {
        guard let lastSeenAt = seen.lastSeenAt else { return true }
        return (item.date ?? .distantPast) > lastSeenAt
    }

    func clear() {
        seen.markSeen(at: allItems.compactMap(\.date).max() ?? Date())
    }

    func label(for actor: String) -> String {
        handles[actor] ?? actor
    }

    func load() async {
        if case .idle = state {
            state = .loading
        }

        async let followers = account.tangled.listFollows(subject: account.did, limit: 30)
        async let repos = account.tangled.listRepos(subject: account.did, limit: 20)
        let (followerPage, repoPage) = await (followers, repos)

        switch repoPage {
        case .failure(let error):
            state = .failed(error)
            return
        case .success(let page):
            var sections = Sections()
            sections.needsYou = await activity(in: page.items)
            sections.needsYou.sort { ($0.date ?? .distantPast) > ($1.date ?? .distantPast) }
            sections.followers = Array(followItems(from: followerPage).prefix(Self.followerCap))
            state = .loaded(sections)
        }

        await resolveActors()
    }

    private func followItems(from result: KnotenResult<RecordPage<Follow>>) -> [Item] {
        guard case .success(let page) = result else { return [] }

        return page.items.compactMap { record in
            guard let actor = ATURI.owner(of: record.uri) else { return nil }
            return Item(
                id: record.uri,
                kind: .followed,
                actor: actor,
                repo: nil,
                date: Timestamps.date(from: record.value.createdAt)
            )
        }
    }

    /// Pulls and issues opened against the account's repos by other people.
    /// Both queries are scoped to a repo, so this is two rounds per repo.
    private func activity(in repos: [RecordView<Repo>]) async -> [Item] {
        let account = account
        let me = account.did

        return await withTaskGroup(of: [Item].self) { group in
            for repo in repos {
                guard let repoDid = repo.value.repoDid else { continue }
                let name = repo.repoName

                group.addTask {
                    async let pulls = account.tangled.listPulls(subject: repoDid, limit: 20)
                    async let issues = account.tangled.listIssues(subject: repoDid, limit: 20)
                    let (pullPage, issuePage) = await (pulls, issues)

                    var found: [Item] = []

                    if case .success(let page) = pullPage {
                        for item in page.items where ATURI.owner(of: item.uri) != me {
                            found.append(Item(
                                id: item.uri,
                                kind: .work(.pull(item)),
                                actor: ATURI.owner(of: item.uri) ?? me,
                                repo: name,
                                date: Timestamps.date(from: item.value.createdAt)
                            ))
                        }
                    }

                    if case .success(let page) = issuePage {
                        for item in page.items where ATURI.owner(of: item.uri) != me {
                            found.append(Item(
                                id: item.uri,
                                kind: .work(.issue(item)),
                                actor: ATURI.owner(of: item.uri) ?? me,
                                repo: name,
                                date: Timestamps.date(from: item.value.createdAt)
                            ))
                        }
                    }

                    return found
                }
            }

            var all: [Item] = []
            for await found in group {
                all.append(contentsOf: found)
            }
            return all
        }
    }

    /// Nothing in these payloads carries a handle, so each distinct actor is
    /// resolved once, in parallel, and falls back to its DID.
    private func resolveActors() async {
        let account = account
        let pending = Set(allItems.prefix(Self.actorCap).map(\.actor)).filter { handles[$0] == nil }
        guard !pending.isEmpty else { return }

        let resolved = await withTaskGroup(of: (String, String).self) { group in
            for actor in pending {
                group.addTask {
                    switch await account.resolver.resolve(actor) {
                    case .success(let document):
                        return (actor, document.handle ?? actor)
                    case .failure:
                        return (actor, actor)
                    }
                }
            }

            var found: [String: String] = [:]
            for await pair in group {
                found[pair.0] = pair.1
            }
            return found
        }

        handles.merge(resolved) { _, resolved in resolved }
    }
}

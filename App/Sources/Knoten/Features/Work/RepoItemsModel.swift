import KnotenCore
import SwiftUI

@MainActor
@Observable
final class RepoItemsModel {
    /// A repo and the records it holds. Both queries the server offers are
    /// scoped to a repo, so this is the shape of any account-wide list.
    struct Section: Identifiable, Sendable {
        let repo: RecordView<Repo>
        let items: [RepoItem]

        var id: String { repo.uri }
        var name: String { repo.repoName }
    }

    enum State {
        case idle
        case loading
        case loaded([Section])
        case failed(KnotenError)
    }

    let kind: RepoItem.Kind
    private(set) var state: State = .idle

    private let account: SessionModel.Account

    init(kind: RepoItem.Kind, account: SessionModel.Account) {
        self.kind = kind
        self.account = account
    }

    /// Keeps the list on screen while a refresh is in flight, so pull to
    /// refresh does not flash an empty view.
    func load() async {
        if case .idle = state {
            state = .loading
        }

        switch await account.tangled.listRepos(subject: account.did, limit: 50) {
        case .failure(let error):
            state = .failed(error)
        case .success(let page):
            state = .loaded(await sections(of: page.items))
        }
    }

    /// One query per repo, in parallel, because that is the only shape the
    /// server offers. A repo whose record carries no `repoDid` cannot be queried
    /// at all, and is left out rather than shown empty.
    private func sections(of repos: [RecordView<Repo>]) async -> [Section] {
        let account = account
        let kind = kind

        return await withTaskGroup(of: Section?.self) { group in
            for repo in repos {
                guard let repoDid = repo.value.repoDid else { continue }
                group.addTask {
                    let items = await Self.fetch(kind, from: repoDid, with: account.tangled)
                    return items.isEmpty ? nil : Section(repo: repo, items: items)
                }
            }

            var found: [Section] = []
            for await section in group {
                if let section { found.append(section) }
            }
            return found.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        }
    }

    /// A repo that fails to answer contributes nothing rather than failing the
    /// screen: one bad repo should not blank the other nine.
    private static func fetch(
        _ kind: RepoItem.Kind,
        from repoDid: String,
        with client: TangledClient
    ) async -> [RepoItem] {
        switch kind {
        case .pulls:
            guard case .success(let page) = await client.listPulls(subject: repoDid, limit: 20) else {
                return []
            }
            return page.items.map(RepoItem.pull)

        case .issues:
            guard case .success(let page) = await client.listIssues(subject: repoDid, limit: 20) else {
                return []
            }
            return page.items.map(RepoItem.issue)
        }
    }
}

import KnotenCore
import SwiftUI

@MainActor
@Observable
final class PullsModel {
    /// The pulls of one repo. `listPulls` is scoped to a repo, so an account's
    /// pulls only exist as one answer per repo, never as one list.
    struct RepoPulls: Identifiable, Sendable {
        let repo: RecordView<Repo>
        let pulls: [PullItem]

        var id: String { repo.uri }

        var name: String { repo.repoName }
    }

    enum State {
        case idle
        case loading
        case loaded([RepoPulls])
        case failed(KnotenError)
    }

    private(set) var state: State = .idle

    private let account: SessionModel.Account

    init(account: SessionModel.Account) {
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
    /// server offers. A repo whose record carries no `repoDid` cannot be
    /// queried at all, and is left out rather than shown empty.
    private func sections(of repos: [RecordView<Repo>]) async -> [RepoPulls] {
        let account = account

        return await withTaskGroup(of: RepoPulls?.self) { group in
            for repo in repos {
                guard let repoDid = repo.value.repoDid else { continue }
                group.addTask {
                    switch await account.tangled.listPulls(subject: repoDid, limit: 20) {
                    case .success(let page) where !page.items.isEmpty:
                        return RepoPulls(repo: repo, pulls: page.items)
                    default:
                        return nil
                    }
                }
            }

            var found: [RepoPulls] = []
            for await section in group {
                if let section { found.append(section) }
            }
            return found.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        }
    }
}

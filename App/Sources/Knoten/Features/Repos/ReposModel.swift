import KnotenCore
import SwiftUI

@MainActor
@Observable
final class ReposModel {
    enum State {
        case idle
        case loading
        case loaded([RecordView<Repo>])
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
        case .success(let page):
            state = .loaded(page.items)
        case .failure(let error):
            state = .failed(error)
        }
    }
}

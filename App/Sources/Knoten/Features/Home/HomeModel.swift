import KnotenCore
import SwiftUI

@MainActor
@Observable
final class HomeModel {
    enum State {
        case idle
        case loading
        case loaded([TimelineItem])
        case failed(KnotenError)
    }

    private(set) var state: State = .idle

    private let account: SessionModel.Account

    init(account: SessionModel.Account) {
        self.account = account
    }

    /// Keeps the feed on screen while a refresh is in flight, so pull to
    /// refresh does not flash an empty view.
    func load() async {
        if case .idle = state {
            state = .loading
        }

        switch await account.tangled.getTimeline(limit: 30) {
        case .success(let page):
            state = .loaded(page.feed)
        case .failure(let error):
            state = .failed(error)
        }
    }
}

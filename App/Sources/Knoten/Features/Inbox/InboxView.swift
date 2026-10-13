import KnotenCore
import SwiftUI

struct InboxView: View {
    @Environment(SessionModel.self) private var session
    @State private var model: InboxModel?

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Inbox")
                .toolbar {
                    if let model, model.unreadCount > 0 {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Clear") { model.clear() }
                        }
                    }
                }
        }
        .task(id: session.account?.did) { await prepare() }
    }

    private func prepare() async {
        guard let account = session.account else {
            model = nil
            return
        }
        if model == nil {
            model = InboxModel(account: account)
            // Asked here rather than at launch: this is the screen the badge
            // would announce, so it is where the ask makes sense.
            await BackgroundRefresh.requestBadgeAuthorization()
        }
        await model?.load()
    }

    @ViewBuilder
    private var content: some View {
        if let model {
            switch model.state {
            case .idle, .loading:
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .failed(let error):
                ContentUnavailableView(
                    "Could not load",
                    systemImage: "exclamationmark.triangle",
                    description: Text(error.localizedDescription)
                )
            case .loaded(let sections) where sections.needsYou.isEmpty && sections.followers.isEmpty:
                ContentUnavailableView(
                    "Nothing new",
                    systemImage: "bell",
                    description: Text("Pulls, issues and followers show up here.")
                )
            case .loaded(let sections):
                List {
                    if !sections.needsYou.isEmpty {
                        Section("Needs you") {
                            ForEach(sections.needsYou) { item in
                                row(for: item, model: model)
                            }
                        }
                    }
                    if !sections.followers.isEmpty {
                        Section("New followers") {
                            ForEach(sections.followers) { item in
                                row(for: item, model: model)
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .refreshable { await model.load() }
            }
        } else {
            ContentUnavailableView(
                "Not signed in",
                systemImage: "person.crop.circle.badge.questionmark",
                description: Text("Sign in from Settings to see what needs you.")
            )
        }
    }

    /// Anything that happened in a repo has a screen to open.
    @ViewBuilder
    private func row(for item: InboxModel.Item, model: InboxModel) -> some View {
        if case .work(let work) = item.kind {
            NavigationLink {
                RepoItemDetailView(item: work)
            } label: {
                InboxRow(item: item, actor: model.label(for: item.actor), unread: model.isUnread(item))
            }
        } else {
            InboxRow(item: item, actor: model.label(for: item.actor), unread: model.isUnread(item))
        }
    }
}

private struct InboxRow: View {
    let item: InboxModel.Item
    let actor: String
    let unread: Bool

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: Theme.Space.md) {
            Image(systemName: symbol)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 16)

            VStack(alignment: .leading, spacing: Theme.Space.xs) {
                headline
                    .font(.subheadline)

                if let detail {
                    Text(detail)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                if let date = item.date {
                    Text(RelativeTime.label(for: date))
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer(minLength: Theme.Space.sm)

            if unread {
                Circle()
                    .fill(Theme.Palette.ide)
                    .frame(width: 8, height: 8)
            }
        }
        .padding(.vertical, Theme.Space.xs)
    }

    /// The actor is bold and the repo is monospaced, so the eye can pick out who
    /// and where without reading the line.
    private var headline: Text {
        switch item.kind {
        case .followed:
            return Text(actor).bold() + Text(" followed you")

        case .work(let work):
            return Text(actor).bold()
                + Text(" opened a \(work.kind.singular) in ")
                + Text(item.repo ?? "a repo").font(.identifier(.subheadline))
        }
    }

    private var detail: String? {
        switch item.kind {
        case .followed:
            return nil
        case .work(let work):
            return work.title
        }
    }

    private var symbol: String {
        switch item.kind {
        case .followed: return "person.badge.plus"
        case .work(let work): return work.kind.symbol
        }
    }
}

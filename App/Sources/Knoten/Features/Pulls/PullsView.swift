import KnotenCore
import SwiftUI

struct PullsView: View {
    @Environment(SessionModel.self) private var session
    @State private var model: PullsModel?

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Pulls")
        }
        .task(id: session.account?.did) { await prepare() }
    }

    private func prepare() async {
        guard let account = session.account else {
            model = nil
            return
        }
        if model == nil {
            model = PullsModel(account: account)
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
            case .loaded(let sections) where sections.isEmpty:
                ContentUnavailableView(
                    "No pull requests",
                    systemImage: "arrow.triangle.pull",
                    description: Text("Pulls opened against your repositories show up here.")
                )
            case .loaded(let sections):
                List {
                    ForEach(sections) { section in
                        Section(section.name) {
                            ForEach(section.pulls, id: \.uri) { pull in
                                NavigationLink {
                                    PullDetailView(pull: pull)
                                } label: {
                                    PullRow(pull: pull)
                                }
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
                description: Text("Sign in from Settings to see your pull requests.")
            )
        }
    }
}

private struct PullRow: View {
    let pull: PullItem

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Space.xs) {
            Text(pull.value.title)
                .font(.subheadline.weight(.semibold))
                .lineLimit(2)

            HStack(spacing: Theme.Space.sm) {
                PullStateBadge(state: pull.state)

                Text(pull.branchLabel)
                    .font(.identifier(.caption))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            if let comments {
                Text(comments)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, Theme.Space.xs)
    }

    private var comments: String? {
        switch pull.commentCount {
        case 0: return nil
        case 1: return "1 comment"
        default: return "\(pull.commentCount) comments"
        }
    }
}

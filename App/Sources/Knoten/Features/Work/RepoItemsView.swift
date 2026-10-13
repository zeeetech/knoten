import KnotenCore
import SwiftUI

struct RepoItemsView: View {
    @Environment(SessionModel.self) private var session
    @State private var kind: RepoItem.Kind
    @State private var model: RepoItemsModel?

    init(kind: RepoItem.Kind) {
        _kind = State(initialValue: kind)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                picker
                content
            }
            .navigationTitle("Work")
        }
        .task(id: taskKey) { await prepare() }
    }

    /// Reloads when either the account or the kind changes, which is the pair
    /// the list depends on.
    private var taskKey: String {
        "\(session.account?.did ?? "-")|\(kind.rawValue)"
    }

    private var picker: some View {
        Picker("Kind", selection: $kind) {
            ForEach(RepoItem.Kind.allCases, id: \.self) { kind in
                Text(kind.rawValue).tag(kind)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, Theme.Space.lg)
        .padding(.bottom, Theme.Space.sm)
    }

    private func prepare() async {
        guard let account = session.account else {
            model = nil
            return
        }
        if model?.kind != kind {
            model = RepoItemsModel(kind: kind, account: account)
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
                    "No \(kind.plural)",
                    systemImage: kind.symbol,
                    description: Text("\(kind.rawValue) opened against your repositories show up here.")
                )
            case .loaded(let sections):
                List {
                    ForEach(sections) { section in
                        Section(section.name) {
                            ForEach(section.items) { item in
                                NavigationLink {
                                    RepoItemDetailView(item: item)
                                } label: {
                                    RepoItemRow(item: item)
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
                description: Text("Sign in from Settings to see your \(kind.plural).")
            )
        }
    }
}

private struct RepoItemRow: View {
    let item: RepoItem

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Space.xs) {
            Text(item.title)
                .font(.subheadline.weight(.semibold))
                .lineLimit(2)

            HStack(spacing: Theme.Space.sm) {
                RepoStateBadge(state: item.state)

                if let branches = item.branchLabel {
                    Text(branches)
                        .font(.identifier(.caption))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
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
        switch item.commentCount {
        case 0: return nil
        case 1: return "1 comment"
        default: return "\(item.commentCount) comments"
        }
    }
}

import KnotenCore
import SwiftUI

struct ReposView: View {
    @Environment(SessionModel.self) private var session
    @State private var model: ReposModel?

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Repos")
        }
        .task(id: session.account?.did) { await prepare() }
    }

    private func prepare() async {
        guard let account = session.account else {
            model = nil
            return
        }
        if model == nil {
            model = ReposModel(account: account)
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
            case .loaded(let repos) where repos.isEmpty:
                ContentUnavailableView(
                    "No repositories",
                    systemImage: "shippingbox",
                    description: Text("Repositories you host on a knot show up here.")
                )
            case .loaded(let repos):
                List(repos, id: \.uri) { record in
                    RepoRow(record: record)
                }
                .listStyle(.insetGrouped)
                .refreshable { await model.load() }
            }
        } else {
            ContentUnavailableView(
                "Not signed in",
                systemImage: "person.crop.circle.badge.questionmark",
                description: Text("Sign in from Settings to see your repositories.")
            )
        }
    }
}

private struct RepoRow: View {
    let record: RecordView<Repo>

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Space.xs) {
            Text(name)
                .font(.identifier(.subheadline).weight(.semibold))

            if let description = record.value.description, !description.isEmpty {
                Text(description)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            HStack(spacing: Theme.Space.xs) {
                Image(systemName: "server.rack")
                    .font(.caption2)
                Text(record.value.knot)
                    .font(.identifier(.caption))
            }
            .foregroundStyle(.tertiary)
        }
        .padding(.vertical, Theme.Space.xs)
    }

    /// A repo record may carry no name, so fall back to the record key, which
    /// is the slug in the URL.
    private var name: String {
        if let name = record.value.name, !name.isEmpty {
            return name
        }
        return record.uri.split(separator: "/").last.map(String.init) ?? record.uri
    }
}

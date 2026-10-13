import KnotenCore
import SwiftUI

struct PullDetailView: View {
    let pull: PullItem

    @Environment(SessionModel.self) private var session
    @State private var model: PullDetailModel?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Space.lg) {
                header
                diffBlock
                commentsBlock
            }
            .padding(Theme.Space.lg)
        }
        .background(Theme.Palette.canvas)
        .navigationTitle(pull.value.title)
        .navigationBarTitleDisplayMode(.inline)
        // Keyed on the account, not the pull: the screen is built per pull, and
        // the session can arrive after it does, in which case the load has to
        // run again.
        .task(id: session.account?.did) { await prepare() }
    }

    private func prepare() async {
        guard let account = session.account else { return }
        if model == nil {
            model = PullDetailModel(pull: pull, account: account)
        }
        await model?.load()
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: Theme.Space.sm) {
            Text(pull.value.title)
                .font(.title3.weight(.semibold))

            HStack(spacing: Theme.Space.sm) {
                PullStateBadge(state: pull.state)
                Text(pull.branchLabel)
                    .font(.identifier(.caption))
                    .foregroundStyle(.secondary)
            }

            // The body is markdown that may point at blobs; it is shown as it
            // arrives rather than rendered.
            if let body = pull.value.body, !body.isEmpty {
                Text(body)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Theme.Space.md)
        .background(Theme.Palette.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.card))
    }

    @ViewBuilder
    private var diffBlock: some View {
        if let state = model?.diff {
            switch state {
            case .loading:
                loading("Loading the diff")
            case .empty:
                note("This pull carries no patch.")
            case .failed(let error):
                note("Could not load the diff: \(error.localizedDescription)")
            case .ready(let patch) where patch.isEmpty:
                note("The patch has no changes to show.")
            case .ready(let patch):
                PullDiffView(patch: patch)
            }
        } else {
            loading("Loading the diff")
        }
    }

    @ViewBuilder
    private var commentsBlock: some View {
        if let model {
            VStack(alignment: .leading, spacing: Theme.Space.md) {
                Text(title(for: model.comments.count))
                    .font(.headline)

                if let failure = model.commentFailure {
                    note(failure.localizedDescription)
                } else if model.comments.isEmpty {
                    note("No comments yet.")
                } else {
                    ForEach(model.comments, id: \.uri) { comment in
                        CommentCard(comment: comment, author: model.label(for: comment.author))
                    }
                }
            }
        }
    }

    private func title(for count: Int) -> String {
        count == 1 ? "1 comment" : "\(count) comments"
    }

    private func loading(_ text: String) -> some View {
        HStack(spacing: Theme.Space.sm) {
            ProgressView()
            Text(text)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private func note(_ text: String) -> some View {
        Text(text)
            .font(.footnote)
            .foregroundStyle(.secondary)
    }
}

private struct CommentCard: View {
    let comment: FeedComment
    let author: String

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Space.sm) {
            HStack(spacing: Theme.Space.sm) {
                Text(author)
                    .font(.identifier(.caption).weight(.semibold))
                    .lineLimit(1)

                Spacer(minLength: Theme.Space.sm)

                if let date = Timestamps.date(from: comment.createdAt) {
                    Text(RelativeTime.label(for: date))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }

            Text(comment.body.plain)
                .font(.subheadline)
                .textSelection(.enabled)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Theme.Space.md)
        .background(Theme.Palette.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.card))
    }
}

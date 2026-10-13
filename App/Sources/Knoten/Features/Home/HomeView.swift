import KnotenCore
import SwiftUI

struct HomeView: View {
    @Environment(SessionModel.self) private var session
    @State private var model: HomeModel?

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Home")
        }
        .task(id: session.account?.did) { await prepare() }
    }

    private func prepare() async {
        guard let account = session.account else {
            model = nil
            return
        }
        if model == nil {
            model = HomeModel(account: account)
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
            case .loaded(let items) where items.isEmpty:
                ContentUnavailableView(
                    "Nothing yet",
                    systemImage: "house",
                    description: Text("Activity across Tangled shows up here.")
                )
            case .loaded(let items):
                List(items, id: \.id) { item in
                    TimelineRow(item: item)
                }
                .listStyle(.insetGrouped)
                .refreshable { await model.load() }
            }
        } else {
            ContentUnavailableView(
                "Not signed in",
                systemImage: "person.crop.circle.badge.questionmark",
                description: Text("Sign in from Settings to see what is happening on Tangled.")
            )
        }
    }
}

private struct TimelineRow: View {
    let item: TimelineItem

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

                if let date = EventTime.date(from: item.eventAt) {
                    Text(EventTime.label(for: date))
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(.vertical, Theme.Space.xs)
    }

    /// Names are bold and repos are monospaced, so the eye can pick out who and
    /// what without reading the whole line.
    private var headline: Text {
        switch item.event {
        case .follow(let actor, let subject, _, _):
            Text(actor.label).bold() + Text(" followed ") + Text(subject.label).bold()
        case .repo(let repo, _, _):
            Text(repo.owner.label).bold() + Text(" created ") + Text(repo.name).font(.identifier(.subheadline))
        case .star(let actor, let repo, _, _):
            Text(actor.label).bold() + Text(" starred ") + Text(repo.name).font(.identifier(.subheadline))
        case .unknown(let type, _):
            Text("Activity ") + Text(variant(of: type)).font(.identifier(.subheadline))
        }
    }

    private var detail: String? {
        switch item.event {
        case .follow:
            return nil
        case .repo(let repo, _, _), .star(_, let repo, _, _):
            guard let description = repo.description, !description.isEmpty else { return nil }
            return description
        case .unknown:
            return nil
        }
    }

    private var symbol: String {
        switch item.event {
        case .follow: return "person.badge.plus"
        case .repo: return "shippingbox"
        case .star: return "star"
        case .unknown: return "questionmark.circle"
        }
    }

    /// The union sends `sh.tangled.feed.getTimeline#forkEvent`; the fragment is
    /// the part worth showing.
    private func variant(of type: String) -> String {
        type.split(separator: "#").last.map(String.init) ?? type
    }
}

/// Tangled timestamps arrive both with and without fractional seconds, so the
/// precise form is tried first.
@MainActor
private enum EventTime {
    private static let precise: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private static let plain = ISO8601DateFormatter()

    static func date(from timestamp: String) -> Date? {
        precise.date(from: timestamp) ?? plain.date(from: timestamp)
    }

    /// Short enough to scan in a feed. The automatic relative style counts
    /// seconds, which is noise in a list.
    static func label(for date: Date, now: Date = Date()) -> String {
        let seconds = now.timeIntervalSince(date)
        switch seconds {
        case ..<60:
            return "now"
        case ..<3_600:
            return "\(Int(seconds / 60))m"
        case ..<86_400:
            return "\(Int(seconds / 3_600))h"
        case ..<604_800:
            return "\(Int(seconds / 86_400))d"
        default:
            return date.formatted(.dateTime.month(.abbreviated).day())
        }
    }
}

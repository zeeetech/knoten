import Foundation

/// Typed Tangled reads over the session-bound XRPC caller. No networking of
/// its own; every call is one XRPC query. Parameter names match the lexicons.
///
/// Every query goes to `api`, the Tangled API host (bobbin), not to the
/// account's PDS. Reads are public, so the session is only there to sign the
/// request, not to authorize it.
public struct TangledClient: Sendable {
    private let client: XRPCClient
    private let api: URL

    public init(client: XRPCClient, api: URL) {
        self.client = client
        self.api = api
    }

    /// sh.tangled.repo.listRepos: repo records owned by a DID.
    public func listRepos(
        subject: String,
        cursor: String? = nil,
        limit: Int? = nil,
        order: String? = nil
    ) async -> KnotenResult<RecordPage<Repo>> {
        await client.publicGet(
            Tangled.repoListRepos,
            params: [
                "subject": subject,
                "cursor": cursor,
                "limit": limit.map(String.init),
                "order": order,
            ].compactMapValues { $0 },
            on: api
        )
    }

    /// sh.tangled.repo.getRepo: one repo record by AT-URI.
    public func getRepo(repo: String) async -> KnotenResult<RecordView<Repo>> {
        await client.publicGet(Tangled.repoGetRepo, params: ["repo": repo], on: api)
    }

    /// sh.tangled.repo.getRepoByRepoDid: one repo record by repo DID.
    public func getRepoByRepoDid(repoDid: String) async -> KnotenResult<RecordView<Repo>> {
        await client.publicGet(Tangled.repoGetRepoByRepoDid, params: ["repoDid": repoDid], on: api)
    }

    /// sh.tangled.repo.listPulls: pulls for a repo DID, with derived state.
    public func listPulls(
        subject: String,
        author: String? = nil,
        status: String? = nil,
        cursor: String? = nil,
        limit: Int? = nil,
        order: String? = nil
    ) async -> KnotenResult<PullPage> {
        await client.publicGet(
            Tangled.repoListPulls,
            params: [
                "subject": subject,
                "author": author,
                "status": status,
                "cursor": cursor,
                "limit": limit.map(String.init),
                "order": order,
            ].compactMapValues { $0 },
            on: api
        )
    }

    /// sh.tangled.repo.getPull: one pull record by AT-URI.
    public func getPull(pull: String) async -> KnotenResult<RecordView<Pull>> {
        await client.publicGet(Tangled.repoGetPull, params: ["pull": pull], on: api)
    }

    /// sh.tangled.repo.listIssues: issues for a repo DID, with derived state.
    public func listIssues(
        subject: String,
        author: String? = nil,
        state: String? = nil,
        cursor: String? = nil,
        limit: Int? = nil,
        order: String? = nil
    ) async -> KnotenResult<IssuePage> {
        await client.publicGet(
            Tangled.repoListIssues,
            params: [
                "subject": subject,
                "author": author,
                "state": state,
                "cursor": cursor,
                "limit": limit.map(String.init),
                "order": order,
            ].compactMapValues { $0 },
            on: api
        )
    }

    /// sh.tangled.repo.getIssue: one issue record by AT-URI.
    public func getIssue(issue: String) async -> KnotenResult<RecordView<Issue>> {
        await client.publicGet(Tangled.repoGetIssue, params: ["issue": issue], on: api)
    }

    /// sh.tangled.ci.queryPipelines: pipelines a spindle ran for a repo DID.
    public func queryPipelines(
        repo: String,
        limit: Int? = nil,
        cursor: String? = nil
    ) async -> KnotenResult<PipelinePage> {
        await client.publicGet(
            Tangled.ciQueryPipelines,
            params: [
                "repo": repo,
                "limit": limit.map(String.init),
                "cursor": cursor,
            ].compactMapValues { $0 },
            on: api
        )
    }

    /// sh.tangled.actor.getProfile: one profile record by AT-URI, of the form
    /// `at://<did>/sh.tangled.actor.profile/self`.
    public func getProfile(actor: String) async -> KnotenResult<RecordView<Profile>> {
        await client.publicGet(Tangled.actorGetProfile, params: ["actor": actor], on: api)
    }

    /// sh.tangled.knot.listKnots: knot records owned by a DID.
    public func listKnots(
        subject: String,
        cursor: String? = nil,
        limit: Int? = nil,
        order: String? = nil
    ) async -> KnotenResult<RecordPage<Knot>> {
        await client.publicGet(
            Tangled.knotListKnots,
            params: [
                "subject": subject,
                "cursor": cursor,
                "limit": limit.map(String.init),
                "order": order,
            ].compactMapValues { $0 },
            on: api
        )
    }

    /// sh.tangled.feed.getTimeline: recent activity across Tangled. There is no
    /// per-account variant; the server ignores any actor filter, so this is the
    /// whole network rather than the accounts a user follows.
    public func getTimeline(
        cursor: String? = nil,
        limit: Int? = nil
    ) async -> KnotenResult<TimelinePage> {
        await client.publicGet(
            Tangled.feedGetTimeline,
            params: [
                "cursor": cursor,
                "limit": limit.map(String.init),
            ].compactMapValues { $0 },
            on: api
        )
    }
}

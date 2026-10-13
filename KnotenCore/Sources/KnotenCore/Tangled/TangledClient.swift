/// Typed Tangled reads over the session-bound XRPC caller. No networking of
/// its own; every call is one XRPC query. Parameter names match the lexicons.
public struct TangledClient: Sendable {
    private let client: XRPCClient

    public init(client: XRPCClient) {
        self.client = client
    }

    /// sh.tangled.repo.listRepos: repo records owned by a DID.
    public func listRepos(
        subject: String,
        cursor: String? = nil,
        limit: Int? = nil,
        order: String? = nil
    ) async -> KnotenResult<RecordPage<Repo>> {
        await client.get(
            Tangled.repoListRepos,
            params: [
                "subject": subject,
                "cursor": cursor,
                "limit": limit.map(String.init),
                "order": order,
            ].compactMapValues { $0 }
        )
    }

    /// sh.tangled.repo.getRepo: one repo record by AT-URI.
    public func getRepo(repo: String) async -> KnotenResult<RecordView<Repo>> {
        await client.get(Tangled.repoGetRepo, params: ["repo": repo])
    }

    /// sh.tangled.repo.getRepoByRepoDid: one repo record by repo DID.
    public func getRepoByRepoDid(repoDid: String) async -> KnotenResult<RecordView<Repo>> {
        await client.get(Tangled.repoGetRepoByRepoDid, params: ["repoDid": repoDid])
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
        await client.get(
            Tangled.repoListPulls,
            params: [
                "subject": subject,
                "author": author,
                "status": status,
                "cursor": cursor,
                "limit": limit.map(String.init),
                "order": order,
            ].compactMapValues { $0 }
        )
    }

    /// sh.tangled.repo.getPull: one pull record by AT-URI.
    public func getPull(pull: String) async -> KnotenResult<RecordView<Pull>> {
        await client.get(Tangled.repoGetPull, params: ["pull": pull])
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
        await client.get(
            Tangled.repoListIssues,
            params: [
                "subject": subject,
                "author": author,
                "state": state,
                "cursor": cursor,
                "limit": limit.map(String.init),
                "order": order,
            ].compactMapValues { $0 }
        )
    }

    /// sh.tangled.repo.getIssue: one issue record by AT-URI.
    public func getIssue(issue: String) async -> KnotenResult<RecordView<Issue>> {
        await client.get(Tangled.repoGetIssue, params: ["issue": issue])
    }

    /// sh.tangled.ci.queryPipelines: pipelines a spindle ran for a repo DID.
    public func queryPipelines(
        repo: String,
        limit: Int? = nil,
        cursor: String? = nil
    ) async -> KnotenResult<PipelinePage> {
        await client.get(
            Tangled.ciQueryPipelines,
            params: [
                "repo": repo,
                "limit": limit.map(String.init),
                "cursor": cursor,
            ].compactMapValues { $0 }
        )
    }

    /// sh.tangled.actor.getProfile: one profile record by AT-URI.
    public func getProfile(actor: String) async -> KnotenResult<RecordView<Profile>> {
        await client.get(Tangled.actorGetProfile, params: ["actor": actor])
    }

    /// sh.tangled.knot.listKnots: knot records owned by a DID.
    public func listKnots(
        subject: String,
        cursor: String? = nil,
        limit: Int? = nil,
        order: String? = nil
    ) async -> KnotenResult<RecordPage<Knot>> {
        await client.get(
            Tangled.knotListKnots,
            params: [
                "subject": subject,
                "cursor": cursor,
                "limit": limit.map(String.init),
                "order": order,
            ].compactMapValues { $0 }
        )
    }
}

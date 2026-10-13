/// NSIDs for the Tangled read paths 0.1.0 uses, as defined by the lexicons in
/// tangled.org/core (sh.tangled.*). Names mirror the lexicon IDs.
public enum Tangled {
    /// Tangled queries are served by bobbin, the API service, on its own host.
    /// The web appview (tangled.org) only renders HTML and does not answer XRPC.
    public static let defaultAPI = "https://api.tangled.org"

    public static let repoListRepos = "sh.tangled.repo.listRepos"
    public static let repoGetRepo = "sh.tangled.repo.getRepo"
    public static let repoGetRepoByRepoDid = "sh.tangled.repo.getRepoByRepoDid"
    public static let repoListPulls = "sh.tangled.repo.listPulls"
    public static let repoGetPull = "sh.tangled.repo.getPull"
    public static let repoListIssues = "sh.tangled.repo.listIssues"
    public static let repoGetIssue = "sh.tangled.repo.getIssue"
    public static let ciQueryPipelines = "sh.tangled.ci.queryPipelines"
    public static let actorGetProfile = "sh.tangled.actor.getProfile"
    public static let knotListKnots = "sh.tangled.knot.listKnots"
}

# Knoten design

A native iOS client for Tangled, the social coding platform built on the AT
Protocol. Knoten is an independent app view: it talks to any PDS and any knot,
it does not depend on Tangled's own client, and it does not use their brand.

This document is the source of truth for the visual system, the screen
inventory, the freemium gate and the 0.1.0 scope. Everything here is a
decision, not a proposal, unless it sits under "Open risks".

## Decisions

- **OAuth from day one.** No app passwords. Full atproto OAuth with PAR, PKCE
  and DPoP, the same profile implemented in `proto_rune`. The reference for
  this code is `proto_rune/lib/atproto/oauth/*`.
- **No push in 0.1.0.** Real-time notifications need a relay we host. Until
  that relay exists, the app polls and uses background refresh. Push may
  become a subscription later; the one-time Pro purchase does not fund an
  always-on server.
- **iOS only until it pays for itself.** No Kotlin, no Compose Multiplatform,
  no shared core in another language. `KnotenCore` stays free of SwiftUI and
  UIKit so a future port has a spec to follow instead of a rewrite to guess at.
- **A new app view, not a Tangled reskin.** Same protocol, our own surface.

## Architecture

Three layers, same shape as the other SDKs in the stack: transport, then
lexicon types, then the app models the UI reads.

```
KnotenCore/            pure Swift package, no UI
  Support/             base64url, JWT, errors, randomness
  Crypto/              DPoPKey (ES256), PKCE
  Transport/           Transport protocol, DPoP executor with nonce retry
  OAuth/               client, session, authorizer, session store
  Identity/            handle and DID resolution, DID documents
  XRPC/                XRPC caller bound to a session

App/Sources/Knoten/    SwiftUI, generated into an Xcode project by XcodeGen
  DesignSystem/        tokens and small components
  Purchases/           StoreKit 2 entitlement state
  Features/            ServerSettings, Paywall, Tips, Settings
```

`Transport` is the only seam that touches the network. Everything above it
takes a `Transport`, so tests drive the whole OAuth flow with a stub and no
sockets.

Sessions live in a `SessionStore` actor. Access tokens are short lived and
refresh tokens are single use, so a rotation has to be visible to every caller
at once. One actor, not a lock and not a singleton.

## Design system

Dark first, with a light palette defined. The app follows the system
appearance; the dark values are the ones designed first.

| Token | Dark | Light | Use |
| --- | --- | --- | --- |
| `canvas` | `systemGroupedBackground` | same | screen background |
| `surface` | `secondarySystemGroupedBackground` | same | rows and cards |
| `surfaceHigh` | `tertiarySystemGroupedBackground` | same | chips, code |
| `separator` | `separator` | same | dividers, borders |
| `ide` | `#3B9EFF` | `#007ACC` | links, actions, focus |
| `trust` | `#30D158` | `#0B7A4B` | ok, verified, connected |
| `pro` | gradient `ide` to `trust` | same | PRO badge, mark |

Type is San Francisco throughout. Anything the eye scans rather than reads
(hostnames, handles, DIDs, SHAs, versions) is set in SF Mono via
`Font.identifier(_:)`. Counters use monospaced digits.

Radii: cards `12`, inner elements `8`, pills `999`, sheets `28`. Spacing scale:
`4 / 8 / 12 / 16 / 20 / 32`. Rows are at least `44` tall.

Motion: `.snappy` for state toggles, `.bouncy` for the unlock, `.smooth` for
copy that changes, `.numericText()` for counters. Haptics on purchase and on
unlock.

## Screens

### Home feed

The global activity feed, `List(.insetGrouped)` under `NavigationStack`, pull to
refresh. One row per event: a small glyph, then a line that reads as a sentence.

Names are bold and repo names are monospaced, so who and what can be picked out
without reading the whole line. A repo description follows on one or two
secondary lines when there is one.

The timestamp is compact (`18m`, `4h`, `2d`), not the automatic relative style,
which counts seconds and turns a feed into noise. Past a week it becomes a date.

### Pulls

Two screens. The list groups pulls by repo, because that is the only shape the
server offers, and each row carries the state capsule, the branches in SF Mono
(`fix -> main`) and the comment count.

The detail stacks the pull's own description, then the diff, then the comments.
Diff lines never wrap: a diff is read by column, so each file scrolls sideways.
Additions take the trust green and deletions the system red. A file past 300
lines names what it left out instead of laying it out, because a large patch is
cheap to fetch and expensive to render.

### Inbox

Two sections. "Needs you" holds pulls and issues opened against your repos by
other people, newest first; only a pull opens, since there is no issue screen
yet. "New followers" holds at most five.

The actor is bold and the repo is monospaced, so who and where can be picked out
without reading the line. An unread row carries a dot in the IDE blue; clearing
marks everything on screen as read.

### Server settings (the freemium gate)

`List(.insetGrouped)` under `NavigationStack`. Three sections: the instance in
use, custom knots, custom PDS.

The instance section shows AppView, handle and a connection status, all
read only, all in SF Mono.

The custom sections are the paywall. On the free plan the rows render a
realistic preview of what would be configured (`https://pds.zoey.dev`, a knot
hostname) and then get `blur(radius: 3)`, `saturation(0.5)`, `opacity(0.55)`,
with hit testing off. Each row carries a trailing `lock.fill`. The section
header carries a `PRO` capsule. The whole section is a tap target that opens
the paywall.

On purchase the section animates open: blur to zero, saturation to one, the
PRO badges scale away, `.bouncy(0.45)`, success haptic.

### Paywall

A large sheet, `presentationCornerRadius(28)`, drag indicator visible. A short
hero with the mark and the title, then four benefit rows (`server.rack`,
`personalhotspot`, `bell.badge`, `app.badge`), then the tip jar, then a pinned
purchase bar.

The purchase bar holds a StoreKit 2 `ProductView` for `knoten.pro.lifetime`.
The price is whatever StoreKit returns, localized, never hardcoded. Below it, a
restore button and one line of fine print. The whole app has exactly one
non-consumable.

### Tip jar

A horizontal row of `ProductView(style: .compact)` cards, one per consumable,
each with a coffee glyph. Present in Settings and at the base of the paywall.

Above the cards sits a line that reacts to Focus Mode. When the app has not
cleared anything it stays plain: "Knoten is a one-person project." After the
user clears their inbox it changes to what actually happened: "You cleared 47
PRs in 4 min." The tip jar shows up after the app has done something, not
before.

## OAuth

The flow is the atproto profile, in order:

1. Resolve the handle to a DID, then check the DID document claims the handle
   back. Both directions, always.
2. Read the DID document, take the PDS service endpoint.
3. Fetch `/.well-known/oauth-protected-resource` for the authorization server.
4. Fetch `/.well-known/oauth-authorization-server` for the endpoints.
5. Generate a DPoP key, a PKCE verifier and a state token.
6. POST the pushed authorization request, DPoP signed, with `login_hint`.
7. Open the authorization URL in `ASWebAuthenticationSession`.
8. Exchange the code, verifying that `sub` matches the DID we resolved.
9. Store the session and the raw DPoP key in the Keychain.

DPoP nonces are mandatory and rotate. The executor retries once on a `400`
carrying `use_dpop_nonce`, using the nonce from the response header.

Client identity is published at `web/oauth/client-metadata.json`, served from
the `client_id` URL. The redirect is a native scheme in reverse-domain order,
`io.zeetech.knoten:/callback`, one slash after the colon, as the spec requires.

That redirect is verified, not assumed. Both `tngl.sh` and `bsky.social`
answered a pushed request for it with a `request_uri`, so custom schemes are
accepted and the in-app loopback listener that bluesky-social/atproto#2814
suggested as a fallback is not needed. The pushed request answers `201
Created`, per RFC 9126, which is not a failure.

## Services

Three hosts, and the difference matters:

| Host | Serves | Auth |
| --- | --- | --- |
| the account's PDS | `com.atproto.*`, blobs | DPoP signed session token |
| `api.tangled.org` | `sh.tangled.*` queries (bobbin) | none, reads are public |
| `tangled.org` | the web appview, HTML only | n/a, links only |

The PDS is per account and comes from the DID document. The API host is the
instance, fixed to `api.tangled.org` for tangled.org. The web appview answers
no XRPC: a `sh.tangled.*` query there returns the 404 page, not JSON.

A session token is bound to the account's PDS. It must not travel to the API
host or to another account's PDS, so those reads go through `publicGet` and
`publicData`, which send no credential. Writes against another service will
need a service auth token minted for that service
(`com.atproto.server.getServiceAuth`), not the session token.

### Rate limit

The PDS answers `ratelimit-policy: 3000;w=300`: 3000 requests per five minutes,
shared across every call to that host. The API host does not advertise one.
`com.atproto.sync.getBlob` sends `cache-control: private` and
`vary: Authorization`, and no `ETag`.

`vary: Authorization` is why `URLCache` is not the answer. It would key entries
on the auth header, which rotates on every refresh and differs per account, so
a multi-account app would never reuse a hit. Cache blobs ourselves instead.

### Feed

`sh.tangled.feed.getTimeline` is the activity feed, and it is global. `limit`
and `cursor` work; an actor filter does not. The server accepts `did`, `actor`
or `subject` and ignores all three, returning the same network-wide feed, so
there is no follows feed in 0.1.0 and none to promise.

The response is `{feed: [{event, eventAt}], cursor}`, and `event` is a union
discriminated by the fragment of `$type`:

| Variant | Carries |
| --- | --- |
| `#followEvent` | `actor`, `subject` |
| `#repoEvent` | `repo` |
| `#starEvent` | `actor`, `repo` |

`repo` here is not the `sh.tangled.repo` record. It is a derived summary with
`owner`, `slug`, `did` and counters, and no `knot`. The record and the summary
are two types, not one. An unrecognized variant is kept rather than dropped, so
a new event type on the server does not empty the feed.

The feed is public, but the app only builds it while signed in, because every
read signs a DPoP proof and the client is built from the session. Showing it to
a signed out user means a session-less client with an ephemeral key, which
0.1.0 does not do.

### Pulls

`sh.tangled.repo.listPulls` requires a `subject`, the repo DID. There is no
cross-repo and no global pull list: the global feed carries follow, repo and
star events only. So the app asks each of the account's repos in turn, and a
repo whose record carries no `repoDid` cannot be asked at all.

A pull's diff is not an endpoint. Each round of the pull carries a `patchBlob`,
gzipped `git format-patch` text, and the blob lives on the PDS of whoever wrote
the pull, not on the repo owner's. Reading a diff is therefore: read the pull,
take the newest round, read the author's DID out of the pull's AT-URI, resolve
that DID to a PDS, `com.atproto.sync.getBlob`, inflate, parse. Four network hops
for one screen, and the reason `Gzip` and `Patch` exist in the core.

Comments are `sh.tangled.feed.comment` records, read with
`sh.tangled.feed.listComments?subject=<AT-URI>`, which serves a pull and an
issue alike. Two things about the shape: the body is a markup union
(`original` plus rendered `text`), not a string, and the payload carries no
handle, so the author is a DID that has to be resolved before it can be shown.

Pull state is not on the pull record. It is a separate
`sh.tangled.repo.pull.status` record, written into the repo owner's repository,
and bobbin folds it into the `state` and `commentCount` that `listPulls`
returns.

None of these NSIDs are guessable: `repo.pull.listComments` and every other
plausible name answers 404. They were found by reading the `collections` out of
`com.atproto.repo.describeRepo`, which is the only authoritative list of what a
repo holds.

### Inbox

There is no notifications endpoint. Every plausible NSID answers 404, so the
inbox is composed from what does exist:

| Source | Query | Cost |
| --- | --- | --- |
| new followers | `graph.listFollows?subject=<did>` | one round |
| pulls opened on your repos | `repo.listPulls?subject=<repoDid>` | one round per repo |
| issues opened on your repos | `repo.listIssues?subject=<repoDid>` | one round per repo |

`graph.listFollows` reads the followers, not the accounts followed: every record
it answers with names the account as its subject, so the follower is the
repository the record lives in.

`feed.listStars?subject=<repoDid>` exists too, and is left out on purpose. A
popular repo carries over a thousand stars, which is noise in a list that is
meant to hold decisions.

Nothing in any of these payloads carries a handle, so every actor is a DID that
has to be resolved before it can be shown. The resolutions are capped and run in
parallel, and an unresolved actor falls back to its DID.

Followers get their own section, capped at five, because an account with
thousands of them would otherwise bury every pull and issue under a wall of
follows.

### Background refresh

The badge is the only thing a background run produces, so a run rebuilds the
inbox far enough to count it and throws the rest away. There is no push in
0.1.0, and the system decides when a run happens.

`BGTaskScheduler` is unavailable in the iOS simulator: submitting a request
there fails with `BGTaskSchedulerErrorDomain` code 1. The wiring is therefore
only verified as far as the identifier being accepted without an exception, and
the wake itself has to be checked on a device.

Badges need `.badge` authorization, which is asked for the first time the inbox
appears rather than at launch.

## Brand surfaces

The app and the landing page are two different surfaces and do not share a
theme.

The landing at `knoten.zeetech.io` follows the Zeetech brand directive in
full, because it is Zeetech's front door. The app keeps its own developer-tool
design (system surfaces, SF Pro and SF Mono, IDE blue and trust green), because
the directive's type system cannot be applied on iOS (MonoLisa is paid and not
embeddable), a purple accent fights the system tint, and a fully branded app
would read as a vendor product rather than the independent, open source client
it is.

The brand touches the app in exactly two places: the app icon, on the Zeetech
near-black, and an attribution line in Settings. Knoten has no mark of its own
yet; the landing carries the Zeetech symbol alone until it does.

## Blobs

`com.atproto.sync.getBlob` returns the original bytes with no resizing, and an
avatar can be two megapixels. Two layers:

- `DiskBlobCache` keeps the bytes, bounded by total size, evicting the least
  recently used first. The key is `did/cid`, hashed before it becomes a
  filename, and the directory is excluded from backup. Blobs are content
  addressed, so an entry never goes stale and there is nothing to invalidate:
  a new avatar is a new CID, which is a new key.
- `AvatarImageCache` keeps the decoded, downscaled `UIImage`, so a list does
  not re-decode the same JPEG on every scroll.

`BlobCache` reports no errors on purpose. A cache is not a feature: a miss and
a failure are the same thing to a caller, so a read returns nil and a write
gives up.

## 0.1.0

In:

- OAuth login, one account.
- Home feed of activity, read only.
- Repos list and file reading, read only.
- Pull request list, unified diff, and the comments on a pull, all read only.
  Writing a comment would be the first write to the PDS and is still open.
- Inbox, plus background refresh, no push. The refresh is on appear, on pull to
  refresh, and on the system's own schedule; there is no foreground timer.
- Server settings with the freemium gate.
- Paywall, one non-consumable.
- Tip jar, three consumables.

Out, on purpose: push, widgets, multi-account, OAuth account switching, any
write to a knot.

## Open risks

- **Lexicon churn.** `sh.tangled.*` is alpha and being restructured. Pin a
  version, expect breakage, keep the wire types in one place.
- **Rate limit on the PDS.** 3000 requests per five minutes, shared with every
  other call to that host, and `getBlob` carries no `ETag`. The blob cache
  exists partly because of this. The feed is not affected, since it is served by
  the API host, but backoff still has to land before the app leans on the PDS at
  volume.
- **Widgets are not real time.** WidgetKit refreshes on a budget. A CI widget
  answers "is main green", not "watch this run".
- **App Store review.** A thin client to a website can trip guideline 4.2. The
  native value has to be visible: widgets, notifications, share sheet,
  Shortcuts. Selling features with IAP is fine; do not use Tangled's name or
  logo as if the app were official.

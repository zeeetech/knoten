# knoten

[English](README.md) | [Português (BR)](README.pt-BR.md)

![iOS](https://img.shields.io/badge/iOS-18%2B-black.svg)
![Swift](https://img.shields.io/badge/swift-6-orange.svg)
![License](https://img.shields.io/badge/license-MPL--2.0-blue.svg)

A native iOS client for [Tangled](https://tangled.org), the social coding
platform built on the AT Protocol.

Knoten is its own app view. It talks to any PDS and any knot, it does not
depend on Tangled's client, and it does not use their brand. Same idea as the
alternate clients for Bluesky: the protocol is the platform, the app is one way
into it.

Login is atproto OAuth: PAR, PKCE and DPoP, no app passwords. The session is
DPoP bound, so requests carry a signed proof instead of a bearer token, and the
nonce rotation is handled for you. Everything returns tagged errors, nothing
throws across a boundary it should not.

## Build it

Needs Xcode 27 (Swift 6.4, iOS 27 SDK) and XcodeGen.

```bash
brew install xcodegen

cd KnotenCore && swift test        # protocol core, no UI
cd ../App && xcodegen generate     # writes Knoten.xcodeproj
open Knoten.xcodeproj
```

The Xcode project is generated, not committed. `project.yml` is the source of
truth. StoreKit products live in `App/StoreKit/Knoten.storekit`, so the
purchase flow works in the simulator without App Store Connect.

`KnotenCore` also carries a live smoke check. It walks the authorization flow
against a real authorization server, up to the pushed request, and prints what
came back. That is the quickest way to tell a server problem from a client one:

```bash
cd KnotenCore && swift run knoten-smoke your.handle.example
```

## Layout

```
KnotenCore/    protocol core: DPoP, PKCE, OAuth, identity, XRPC
App/           SwiftUI app, one target
web/           client metadata published for OAuth
docs/          design notes
```

`KnotenCore` has no UI dependency on purpose. It builds and tests on its own,
which is what makes a future port a port and not a rewrite.

## Status

0.1.0 is in progress. Read only: feed, repos, pull requests, inbox, plus the
Pro purchase and the tip jar. Push, widgets and multi-account come after the
notification relay exists. See [docs/DESIGN.md](docs/DESIGN.md) for the full
scope and the open risks.

## Contributing

Fork, branch, write tests, `swift test`, open a PR. Keep `KnotenCore` free of
UI imports and keep the wire types in one place.

## License

[MPL-2.0](LICENSE). Use it, fork it, ship it. Changes to the files we wrote
come back under the same license; whatever you build next to it is yours.

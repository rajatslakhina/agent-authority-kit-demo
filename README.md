# AgentAuthority Demo

**A household-ledger app with three agents calling into it — Siri, an on-device budget model, and a remote MCP client — where none of them borrows your session. Grant one a payment scope and you get a consent sheet bound to that exact agent, scope and device key. Start a task, revoke the agent halfway, and watch it stop at the next step.**

[![CI](https://github.com/rajatslakhina/agent-authority-kit-demo/actions/workflows/ci.yml/badge.svg)](https://github.com/rajatslakhina/agent-authority-kit-demo/actions/workflows/ci.yml)

This is the runnable companion to **[agent-authority-kit](https://github.com/rajatslakhina/agent-authority-kit)**, which holds all of the logic and its tests. This repo is only the app: one `Demo.xcodeproj`, one Swift file, and the package pulled from GitHub as a remote dependency on any released 1.x (`upToNextMajorVersion` from `1.0.0` — never a branch, never a local path).

## Why this matters

An app that lets agents act for the user has to answer four questions that "the agent uses the user's session" cannot: *which* agent did this, *what* was it allowed to do, *for how long*, and *how do I stop it right now, mid-task*. This app makes each answer visible on one screen:

| You do | You see |
|---|---|
| **Grant read** to an agent that holds nothing sensitive | A token is issued immediately — the scope is below the consent floor. (Grants accumulate: an agent already holding pay is re-issued one token carrying both, which asks for consent again because it is a fresh mint of a sensitive scope.) |
| **Grant pay** to Siri or the model | A consent sheet naming the agent and the scope. Allow → the agent's token is re-issued carrying its old scopes *plus* pay. Deny → nothing is minted and the old token stays. |
| **Grant pay** to the Desktop MCP client | Refused by policy: a remote client may only read. No prompt is shown. |
| **Grant read** on the on-device budget model, **Start 8-step task**, then **Revoke model** | The task stops at the next step with `revoked: agent budget-model` — revocation reaches work already in flight. (Started with no grant, it stops at step 1 with `no token`.) |
| **Kill switch** | Every outstanding token dies, every agent row that holds a token shows it struck through and marked revoked (the agent still *holds* it; the broker refuses it), and the revocation generation on screen increments. The next grant starts from a clean slate. |
| **Run adversarial suite** | 20 scenarios — 18 attacks (stolen token, stolen token re-delegated, proof replay, scope escalation, delegation widening, revocation during consent, …) each stopped for its *expected* reason, plus 2 baselines that must be allowed. The footer reads “20 of 20 scenarios behaved as expected”. |
| **Tamper with a copy** (after any grant — the log starts empty) | One audit entry of a copy is edited; the keyed hash chain reports exactly where it broke. |

## What the app owns

`Demo/DemoApp.swift` holds the app's compiled-in `DemoPolicy` — which agent kind may hold which scope, for how long, and how deep it may delegate — plus the broker limits (`hardMaxLifetime = 600`, `proofWindow = 30`). That table is the product decision; the package enforces it and enforces its own floor underneath it (consent for every sensitive scope, a hard lifetime ceiling, a hard delegation-depth ceiling) even if the table is wrong.

## Screenshots

**There are none, and none are mocked up.** This release was never launched on a Simulator (see *Verification*), so there is nothing real to show. The table above describes what the code does, traced through `AuthorityConsoleView` and `AuthorityConsoleModel`, not what was observed on a screen.

## How to run it

1. `git clone https://github.com/rajatslakhina/agent-authority-kit-demo.git`
2. Open `Demo.xcodeproj` in Xcode 16 or later. Xcode resolves `agent-authority-kit` from GitHub (`upToNextMajorVersion` from `1.0.0`).
3. Select the **Demo** scheme and any iOS 17+ Simulator.
4. Build & Run (⌘R).

On the Simulator the console shows **“Proof keys: software P-256 (no Secure Enclave here)”**: the Simulator has no Secure Enclave, so `ProofKeyFactory` falls back to a software key. On a device with a Secure Enclave, the same code binds every token to an enclave-resident key.

## Project layout

```
Demo.xcodeproj/
  project.pbxproj                    XCRemoteSwiftPackageReference → agent-authority-kit, upToNextMajorVersion 1.0.0
  xcshareddata/xcschemes/Demo.xcscheme
Demo/
  DemoApp.swift                      @main app + DemoPolicy (the app-owned authority table)
.github/workflows/ci.yml             resolve the remote package + build for the iOS Simulator
```

## Verification

What was actually run, and what was not:

- **CI** ([Actions](https://github.com/rajatslakhina/agent-authority-kit-demo/actions/workflows/ci.yml)), on `macos-15` with Xcode 16.4: `xcodebuild -resolvePackageDependencies` fetched the package from GitHub and resolved **`agent-authority-kit @ 1.0.0`** (plus `swift-crypto` and `swift-asn1`, which the package declares for its Linux build). Then `xcodebuild build -scheme Demo -destination 'generic/platform=iOS Simulator'` reported **BUILD SUCCEEDED**. This proves the remote package resolves and the app compiles against it. It does not prove the app runs.
- **The library's own tests** (69, in the [library repo](https://github.com/rajatslakhina/agent-authority-kit)) cover the console's view model, `AuthorityConsoleModel`: consent approve, decline and dismiss; grants accumulating; mid-task revocation stopping a job; cancellation; the bounded activity log; and the tamper demonstration. The SwiftUI views themselves have no tests.
- **Not done: a Simulator run.** Computer-use access to Xcode and Simulator was granted, but the Mac's screen was locked, and macOS blocks every click while it is. All three attempts were refused the same way. **The app has been compiled for the iOS Simulator but never launched on one, and no screenshots exist.**

## License

MIT

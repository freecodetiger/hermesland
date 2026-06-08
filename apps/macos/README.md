# Hermes Island macOS Shell Source

This directory contains source-only scaffolding for the future Hermes Island macOS app shell. It intentionally does not include an Xcode project, Swift package manifest, or app target wiring.

## Current Source

- `Sources/AppShell/AppConnectionState.swift` defines the high-level connection lifecycle: offline, connecting, idle online, running, waiting for approval, and error.
- `Sources/AppShell/AppRoute.swift` defines app destinations and menu commands.
- `Sources/AppShell/AppShellModel.swift` provides an `ObservableObject`-compatible model for SwiftUI or AppKit-hosted SwiftUI views.

## Future App Wiring

A later macOS target can import these files into an app module and hold one shared `AppShellModel` instance at the shell boundary.

For a SwiftUI menu bar app, `MenuBarExtra` can read `connectionState` to choose status copy, enable approval actions, and expose commands such as open chat, open tasks, connect, disconnect, and quit. Window entry points can send `.open(...)` commands before presenting a destination window.

For an AppKit status item app, `NSStatusItem` and `NSMenuItem` actions can call `AppShellModel.send(_:)`. AppKit windows can observe the same model directly or host SwiftUI views that observe it.

No build integration exists yet. These files are designed to be added later to an Xcode macOS app target without changing this source shape.

## SwiftPM Companion

This directory now also includes a Swift Package executable target for a runnable local MVP shell:

```bash
cd apps/macos
swift run hermes-island-companion demo
swift test
```

With the mock Gateway running, the companion can also exercise the live HTTP flow:

```bash
npm --workspace @hermesland/gateway run dev
cd apps/macos
swift run hermes-island-companion live
```

## Hermes Agent Live Flow

Start the SSH tunnel to the deployed Hermes Agent API server:

```bash
SSHPASS='706nb' sshpass -e ssh -N \
  -L 8650:172.17.0.1:8650 \
  -o StrictHostKeyChecking=no \
  -o UserKnownHostsFile=/tmp/hermesland_known_hosts \
  -o ExitOnForwardFailure=yes \
  nb706@1.95.80.155
```

In a separate shell, load the API key into shell state without printing it:

```bash
export HERMES_AGENT_API_KEY="$(
  SSHPASS='706nb' sshpass -e ssh \
    -o StrictHostKeyChecking=no \
    -o UserKnownHostsFile=/tmp/hermesland_known_hosts \
    nb706@1.95.80.155 \
    'bash -lc '"'"'source /home/nb706/zpc/.hermes/.env; printf %s "$API_SERVER_KEY"'"'"''
)"
export HERMES_AGENT_GATEWAY_URL="http://127.0.0.1:8650"
export HERMES_AGENT_MODEL="hermes-zpc"
export HERMES_AGENT_SESSION_ID="hermes-island-dev"
```

Run the companion live flow through npm:

```bash
npm run run:macos-agent-live -- "Reply with a short connectivity check."
```

The executable is not a packaged `.app` yet. It verifies the app shell, Swift SDK, Gateway HTTP flow, and UI state reducer can run together without requiring an Xcode project, which keeps the MVP testable while full Xcode is unavailable in the current environment.

## SwiftPM Menu Bar AppKit Target

There is also a minimal AppKit status item target:

```bash
cd apps/macos
swift build --product hermes-island-menubar
swift run hermes-island-menubar
```

This is a real macOS process with an `NSStatusItem`, but it is still not a signed `.app` bundle. It exists as the current runnable desktop MVP while the project does not have a full Xcode app target.

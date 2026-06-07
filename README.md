# Hermes Island

Hermes Island is a macOS-native Agent notification and task control center. It brings Hermes Agent task execution, streaming chat, scheduled task notifications, and approval requests into a lightweight menu bar companion app.

## MVP Scope

The first runnable MVP focuses on:

- Event protocol with `event_id`, `seq`, `type`, `created_at`, and `payload`.
- Mock Hermes Gateway with REST and WebSocket-compatible event streaming.
- macOS menu bar shell.
- Realtime client logic for reconnect, event replay, dedupe, and ACK.
- Island UI for task status and user approval.

Post-MVP items include APNs, plugin marketplace, team permission system, RAG, multi-model management, and complex workflow orchestration.

## Repository Layout

```text
apps/macos/                  macOS SwiftUI/AppKit client
packages/hermes-protocol/    Shared event protocol and contract tests
server/gateway/              Hermes Gateway mock and future service
scripts/                     Smoke and development scripts
docs/                        Architecture, protocol, security, Agent Team docs
```

## Current Development Model

Development uses git worktrees and task-specific Agent ownership. See:

- [Agent Team Plan](docs/agent-team/README.md)
- [Worktree Playbook](docs/agent-team/worktree-playbook.md)
- [Task Packets](docs/agent-team/task-packets.md)

## Local Commands

Install dependencies:

```bash
npm install
```

Run all available tests:

```bash
npm test
```

Run protocol tests:

```bash
npm run test:protocol
```

Run Gateway tests:

```bash
npm run test:gateway
```

Run smoke tests:

```bash
npm run smoke
```

## macOS Build Note

Full macOS App build verification requires Xcode. If `xcodebuild` reports that the active developer directory is Command Line Tools, switch to a full Xcode installation before running macOS build verification.


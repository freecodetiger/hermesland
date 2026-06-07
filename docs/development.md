# Development

## Local Setup

Install dependencies from the repository root:

```bash
npm install
```

Run the default verification suite:

```bash
npm test
```

Run the Gateway smoke check:

```bash
npm run smoke
```

The smoke runner targets `http://127.0.0.1:8787` by default. Override it when
the mock Gateway is running elsewhere:

```bash
HERMES_GATEWAY_URL=http://127.0.0.1:8787 npm run smoke
```

If no Gateway HTTP server is listening, `npm run smoke` skips the Gateway smoke
checks so CI can run without a background service. To require a live Gateway,
enable strict mode:

```bash
HERMES_SMOKE_STRICT=1 npm run smoke
```

Once the mock Gateway exists and is running, the same command checks:

- `GET /healthz`
- `POST /v1/auth/device/start`
- `POST /v1/messages`
- `GET /v1/events?after_seq=0`
- message event order: `message.accepted` before `message.delta` before
  `message.completed`

## Worktrees

Use task-specific worktrees for parallel Agent work:

```bash
git worktree add .worktrees/<agent-task> -b <type>/<short-name> main
cd .worktrees/<agent-task>
npm install
npm test
```

Before starting work inside a worktree, confirm the branch and local status:

```bash
git branch --show-current
git status --short
```

Keep edits within the task's assigned file ownership. Commit from inside the
worktree after verification:

```bash
git add <changed-files>
git commit -m "<type>: <summary>"
```

## Verification Commands

Run these before handing off a branch:

```bash
npm test
npm run smoke
git status --short
```

When the Gateway server is not running, default smoke may skip live checks.
Use `HERMES_SMOKE_STRICT=1 npm run smoke` for release and local end-to-end
verification. Treat test failures from `npm test` as release blockers unless
the task packet explicitly documents a different expectation.

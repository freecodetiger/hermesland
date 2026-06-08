# Hermes Agent Gateway Integration

This document records the verified connection path for the deployed Hermes Agent server and the integration implications for Hermes Island.

Implementation plan: `docs/superpowers/plans/2026-06-08-hermes-agent-api-server-adapter.md`

## Verified Server

- SSH: `nb706@1.95.80.155`
- OS: Ubuntu 22.04 LTS
- Hermes Agent process:
  - Working directory: `/home/nb706/zpc/hermes-agent`
  - Command: `/home/nb706/zpc/hermes-agent/venv/bin/python -m hermes_cli.main gateway run --replace`
- Runtime Hermes home:
  - `/home/nb706/zpc/.hermes`

## Verified Gateway Endpoint

The running gateway is Hermes Agent's Python `api_server` adapter, not the Hermes Island MVP mock Gateway.

It listens on the server-only Docker bridge address:

```text
172.17.0.1:8650
```

It is not listening on the server's public interface and not on `127.0.0.1:8650`.

Verified routes:

- `GET /health`
- `GET /health/detailed`
- `GET /v1/health`
- `GET /v1/models`
- `GET /v1/capabilities`
- `POST /v1/chat/completions`
- `POST /v1/responses`
- `POST /v1/runs`
- `GET /v1/runs/{run_id}`
- `GET /v1/runs/{run_id}/events`
- `POST /v1/runs/{run_id}/stop`

`GET /` and `GET /healthz` are not valid routes for this server. A `not_found` or `404: Not Found` response on those paths does not mean the gateway is down.

## Authentication

The API server requires Bearer authentication for `/v1/*` endpoints.

The server-side key is configured in:

```text
/home/nb706/zpc/.hermes/.env
```

Do not commit this key to the repository. Load it only into local shell state when testing:

```bash
export HERMES_AGENT_API_KEY="$(
  SSHPASS='706nb' sshpass -e ssh \
    -o StrictHostKeyChecking=no \
    -o UserKnownHostsFile=/tmp/hermesland_known_hosts \
    nb706@1.95.80.155 \
    'bash -lc '"'"'source /home/nb706/zpc/.hermes/.env; printf %s "$API_SERVER_KEY"'"'"''
)"
```

## Local Development Connection

Use an SSH tunnel for development:

```bash
SSHPASS='706nb' sshpass -e ssh -N \
  -L 8650:172.17.0.1:8650 \
  -o StrictHostKeyChecking=no \
  -o UserKnownHostsFile=/tmp/hermesland_known_hosts \
  -o ExitOnForwardFailure=yes \
  nb706@1.95.80.155
```

Then test from the local machine:

```bash
curl -sS -i http://127.0.0.1:8650/health

curl -sS -i \
  -H "Authorization: Bearer ${HERMES_AGENT_API_KEY}" \
  http://127.0.0.1:8650/v1/models

curl -sS -i \
  -H "Authorization: Bearer ${HERMES_AGENT_API_KEY}" \
  http://127.0.0.1:8650/v1/capabilities
```

Expected model ID from the verified deployment:

```text
hermes-zpc
```

## Hermes Island Integration Implication

The current Hermes Island MVP client and smoke tests target the local mock Gateway contract:

- `GET /healthz`
- `POST /v1/auth/device/start`
- `POST /v1/messages`
- `GET /v1/events`
- `POST /v1/tasks/run`
- `POST /v1/approvals/{id}/approve`

The deployed Hermes Agent server exposes an OpenAI-compatible API server contract instead:

- `GET /health`
- `POST /v1/chat/completions`
- `POST /v1/runs`
- `GET /v1/runs/{run_id}/events`

Therefore, Hermes Island should not point the existing MVP client directly at `http://127.0.0.1:8650` and expect it to work. The next implementation step should add a real Hermes Agent adapter layer that maps:

- health: `/health`
- outbound prompt: `/v1/runs` or `/v1/chat/completions`
- streaming lifecycle: `/v1/runs/{run_id}/events`
- stop: `/v1/runs/{run_id}/stop`

The Swift UI should consume the same internal `HermesUIEvent` model after adapter normalization, so the UI does not depend on whether the upstream is the mock Gateway or the real Hermes Agent API server.

## Production Exposure Option

For production, prefer a TLS reverse proxy route through Caddy instead of exposing port `8650` directly.

Required constraints:

- Keep Bearer auth enabled.
- Do not expose the API server without a strong `API_SERVER_KEY`.
- Restrict CORS unless a browser client needs it.
- Consider IP allowlisting or VPN access for administrative clients.

The development SSH tunnel remains the safest default until Hermes Island has a stable authenticated client.

import http from "node:http";
import { fileURLToPath } from "node:url";
import { EVENT_TYPES, validateEventEnvelope } from "@hermesland/hermes-protocol";

export function health() {
  return { status: "ok" };
}

export class EventStore {
  #events = [];
  #cursors = new Map();
  #nextSeq = 1;

  append({ type, payload }) {
    const seq = this.#nextSeq++;
    const storedEvent = {
      event_id: `evt_${String(seq).padStart(6, "0")}`,
      seq,
      type,
      created_at: new Date().toISOString(),
      payload,
    };
    const validation = validateEventEnvelope(storedEvent);

    if (!validation.ok) {
      throw new Error(validation.error);
    }

    this.#events.push(storedEvent);
    return storedEvent;
  }

  listAfter(afterSeq = 0) {
    return this.#events.filter((event) => event.seq > afterSeq);
  }

  ack(deviceId, lastSeq) {
    this.#cursors.set(deviceId, lastSeq);
  }

  getCursor(deviceId) {
    return this.#cursors.get(deviceId) ?? 0;
  }
}

export function createMockMessageStream({ conversation_id, client_msg_id, content }) {
  const message_id = `msg_${client_msg_id}`;

  return [
    {
      type: EVENT_TYPES.messageAccepted,
      payload: {
        conversation_id,
        message_id,
        client_msg_id,
      },
    },
    {
      type: EVENT_TYPES.messageDelta,
      payload: {
        conversation_id,
        message_id,
        client_msg_id,
        delta: "Mock response part 1",
      },
    },
    {
      type: EVENT_TYPES.messageDelta,
      payload: {
        conversation_id,
        message_id,
        client_msg_id,
        delta: content ? `Echo: ${content}` : "Mock response part 2",
      },
    },
    {
      type: EVENT_TYPES.messageDelta,
      payload: {
        conversation_id,
        message_id,
        client_msg_id,
        delta: "Mock response part 3",
      },
    },
    {
      type: EVENT_TYPES.messageCompleted,
      payload: {
        conversation_id,
        message_id,
        client_msg_id,
      },
    },
  ];
}

export function createServer({ store = new EventStore() } = {}) {
  return http.createServer(async (request, response) => {
    try {
      const url = new URL(request.url ?? "/", "http://localhost");

      if (request.method === "GET" && url.pathname === "/healthz") {
        sendJson(response, 200, health());
        return;
      }

      if (request.method === "POST" && url.pathname === "/v1/auth/device/start") {
        sendJson(response, 200, {
          device_code: "mock-device-code",
          token: "mock-token",
        });
        return;
      }

      if (request.method === "GET" && url.pathname === "/v1/events") {
        const afterSeq = parseSeq(url.searchParams.get("after_seq"));
        sendJson(response, 200, { events: store.listAfter(afterSeq) });
        return;
      }

      if (request.method === "POST" && url.pathname === "/v1/events/ack") {
        const body = await readJson(request);
        store.ack(body.device_id, body.last_seq);
        sendJson(response, 200, {
          device_id: body.device_id,
          last_seq: body.last_seq,
        });
        return;
      }

      if (request.method === "POST" && url.pathname === "/v1/messages") {
        const body = await readJson(request);
        const events = createMockMessageStream(body).map((event) => store.append(event));

        sendJson(response, 202, {
          accepted: true,
          events,
        });
        return;
      }

      if (request.method === "GET" && url.pathname === "/v1/realtime") {
        const afterSeq = parseSeq(url.searchParams.get("after_seq"));
        sendSse(response, store.listAfter(afterSeq));
        return;
      }

      sendJson(response, 404, { error: "not_found" });
    } catch (error) {
      sendJson(response, 400, { error: "bad_request", message: error.message });
    }
  });
}

function parseSeq(value) {
  if (value === null || value === "") {
    return 0;
  }

  const parsed = Number(value);
  if (!Number.isInteger(parsed) || parsed < 0) {
    throw new Error("after_seq must be a non-negative integer");
  }

  return parsed;
}

async function readJson(request) {
  let rawBody = "";

  for await (const chunk of request) {
    rawBody += chunk;
  }

  if (rawBody === "") {
    return {};
  }

  return JSON.parse(rawBody);
}

function sendJson(response, statusCode, body) {
  response.writeHead(statusCode, {
    "content-type": "application/json",
  });
  response.end(JSON.stringify(body));
}

function sendSse(response, events) {
  response.writeHead(200, {
    "cache-control": "no-cache",
    connection: "keep-alive",
    "content-type": "text/event-stream",
  });

  for (const event of events) {
    response.write(`event: ${event.type}\n`);
    response.write(`data: ${JSON.stringify(event)}\n\n`);
  }

  response.end();
}

if (process.argv[1] === fileURLToPath(import.meta.url)) {
  const port = Number(process.env.PORT ?? 3000);
  createServer().listen(port, () => {
    console.log(`gateway listening on http://127.0.0.1:${port}`);
  });
}

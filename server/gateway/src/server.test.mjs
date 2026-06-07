import { test } from "node:test";
import assert from "node:assert/strict";
import { EVENT_TYPES, validateEventEnvelope } from "@hermesland/hermes-protocol";
import {
  EventStore,
  createMockMessageStream,
  createServer,
  health,
} from "./server.mjs";

test("health returns ok", () => {
  assert.deepEqual(health(), { status: "ok" });
});

test("EventStore appends events with increasing seq and stable event_id", () => {
  const store = new EventStore();

  const first = store.append({
    type: EVENT_TYPES.messageAccepted,
    payload: { client_msg_id: "msg-1" },
  });
  const second = store.append({
    type: EVENT_TYPES.messageCompleted,
    payload: { client_msg_id: "msg-1" },
  });

  assert.equal(first.seq, 1);
  assert.equal(second.seq, 2);
  assert.match(first.event_id, /^evt_000001$/);
  assert.match(first.created_at, /^\d{4}-\d{2}-\d{2}T/);
  assert.deepEqual(first.payload, { client_msg_id: "msg-1" });
  assert.deepEqual(validateEventEnvelope(first), { ok: true });
  assert.deepEqual(validateEventEnvelope(second), { ok: true });
  assert.equal(store.listAfter(0)[0].event_id, first.event_id);
  assert.deepEqual(store.listAfter(1), [second]);
});

test("EventStore rejects events that do not validate as EventEnvelope", () => {
  const store = new EventStore();

  assert.throws(
    () => store.append({ type: "message.unknown", payload: {} }),
    /EventEnvelope.type must be a known event type/,
  );
});

test("EventStore stores ACK cursors per device", () => {
  const store = new EventStore();

  assert.equal(store.getCursor("device-a"), 0);
  store.ack("device-a", 12);
  store.ack("device-b", 3);

  assert.equal(store.getCursor("device-a"), 12);
  assert.equal(store.getCursor("device-b"), 3);
});

test("mock message stream emits accepted, deltas, and completed in order", () => {
  const events = createMockMessageStream({
    conversation_id: "conv-1",
    client_msg_id: "msg-1",
    content: "hello",
  });

  assert.equal(events[0].type, EVENT_TYPES.messageAccepted);
  assert.equal(events.at(-1).type, EVENT_TYPES.messageCompleted);
  assert.equal(events.filter((event) => event.type === EVENT_TYPES.messageDelta).length, 3);
  assert.deepEqual(
    events.map((event) => event.payload.client_msg_id),
    ["msg-1", "msg-1", "msg-1", "msg-1", "msg-1"],
  );
  assert.deepEqual(events[1].payload, {
    conversation_id: "conv-1",
    message_id: "msg_msg-1",
    client_msg_id: "msg-1",
    delta: "Mock response part 1",
  });
});

test("HTTP endpoints expose mock auth, event replay, ACKs, messages, and SSE replay", async (t) => {
  const store = new EventStore();
  const server = createServer({ store });

  await new Promise((resolve) => server.listen(0, resolve));
  t.after(() => server.close());

  const baseUrl = `http://127.0.0.1:${server.address().port}`;

  const healthResponse = await fetch(`${baseUrl}/healthz`);
  assert.equal(healthResponse.status, 200);
  assert.deepEqual(await healthResponse.json(), { status: "ok" });

  const authResponse = await fetch(`${baseUrl}/v1/auth/device/start`, {
    method: "POST",
  });
  assert.equal(authResponse.status, 200);
  assert.deepEqual(await authResponse.json(), {
    device_code: "mock-device-code",
    token: "mock-token",
  });

  const messageResponse = await fetch(`${baseUrl}/v1/messages`, {
    method: "POST",
    headers: { "content-type": "application/json" },
    body: JSON.stringify({
      conversation_id: "conv-1",
      client_msg_id: "msg-1",
      content: "hello",
    }),
  });
  assert.equal(messageResponse.status, 202);
  const messageBody = await messageResponse.json();
  assert.equal(messageBody.accepted, true);
  assert.equal(messageBody.events.length, 5);
  assert.deepEqual(
    messageBody.events.map((event) => event.seq),
    [1, 2, 3, 4, 5],
  );
  assert.deepEqual(messageBody.events.map(validateEventEnvelope), [
    { ok: true },
    { ok: true },
    { ok: true },
    { ok: true },
    { ok: true },
  ]);
  assert.deepEqual(messageBody.events[1], {
    event_id: "evt_000002",
    seq: 2,
    type: EVENT_TYPES.messageDelta,
    created_at: messageBody.events[1].created_at,
    payload: {
      conversation_id: "conv-1",
      message_id: "msg_msg-1",
      client_msg_id: "msg-1",
      delta: "Mock response part 1",
    },
  });

  const replayResponse = await fetch(`${baseUrl}/v1/events?after_seq=2`);
  assert.equal(replayResponse.status, 200);
  const replayBody = await replayResponse.json();
  assert.deepEqual(
    replayBody.events.map((event) => event.seq),
    [3, 4, 5],
  );
  assert.deepEqual(replayBody.events.map(validateEventEnvelope), [
    { ok: true },
    { ok: true },
    { ok: true },
  ]);

  const ackResponse = await fetch(`${baseUrl}/v1/events/ack`, {
    method: "POST",
    headers: { "content-type": "application/json" },
    body: JSON.stringify({ device_id: "device-a", last_seq: 5 }),
  });
  assert.equal(ackResponse.status, 200);
  assert.deepEqual(await ackResponse.json(), { device_id: "device-a", last_seq: 5 });
  assert.equal(store.getCursor("device-a"), 5);

  const sseResponse = await fetch(`${baseUrl}/v1/realtime?after_seq=3`);
  assert.equal(sseResponse.status, 200);
  assert.equal(sseResponse.headers.get("content-type"), "text/event-stream");
  const sseBody = await sseResponse.text();
  assert.match(sseBody, /event: message\.delta/);
  assert.match(sseBody, /event: message\.completed/);
  assert.match(sseBody, /"seq":4/);
  assert.match(sseBody, /"seq":5/);
  assert.match(sseBody, /"payload":\{"conversation_id":"conv-1","message_id":"msg_msg-1","client_msg_id":"msg-1","delta":"Mock response part 3"\}/);
});

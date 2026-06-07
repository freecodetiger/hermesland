import { test } from "node:test";
import assert from "node:assert/strict";
import { protocolVersion as packageProtocolVersion } from "@hermesland/hermes-protocol";
import {
  CLIENT_COMMAND_TYPES,
  EVENT_TYPES,
  commandExamples,
  eventExamples,
  protocolVersion,
  validateClientCommand,
  validateEventEnvelope,
} from "./index.mjs";

test("exposes protocol version", () => {
  assert.equal(protocolVersion, "0.1.0");
  assert.equal(packageProtocolVersion, protocolVersion);
});

test("exports the MVP event type contract", () => {
  assert.deepEqual(Object.values(EVENT_TYPES), [
    "message.accepted",
    "message.delta",
    "message.completed",
    "message.failed",
    "task.started",
    "task.progress",
    "task.completed",
    "task.failed",
    "task.cancelled",
    "task.requires_approval",
    "notification.created",
    "agent.online",
    "agent.offline",
    "system.error",
  ]);
});

test("exports the client command type contract", () => {
  assert.deepEqual(Object.values(CLIENT_COMMAND_TYPES), [
    "message.send",
    "events.ack",
  ]);
});

test("validates EventEnvelope required fields", () => {
  const envelope = eventExamples.messageAccepted;

  assert.deepEqual(validateEventEnvelope(envelope), { ok: true });

  for (const field of ["event_id", "seq", "type", "created_at", "payload"]) {
    const invalid = { ...envelope };
    delete invalid[field];

    assert.deepEqual(validateEventEnvelope(invalid), {
      ok: false,
      error: `EventEnvelope.${field} is required`,
    });
  }
});

test("rejects invalid EventEnvelope seq values", () => {
  for (const seq of [-1, 1.5, Number.MAX_SAFE_INTEGER + 1, Number.NaN]) {
    assert.deepEqual(validateEventEnvelope({ ...eventExamples.messageAccepted, seq }), {
      ok: false,
      error: "EventEnvelope.seq must be a non-negative safe integer",
    });
  }
});

test("validates every exported event example", () => {
  assert.deepEqual(Object.keys(eventExamples), [
    "messageAccepted",
    "messageDelta",
    "messageCompleted",
    "messageFailed",
    "taskStarted",
    "taskProgress",
    "taskCompleted",
    "taskFailed",
    "taskCancelled",
    "taskRequiresApproval",
    "notificationCreated",
    "agentOnline",
    "agentOffline",
    "systemError",
  ]);

  for (const [name, example] of Object.entries(eventExamples)) {
    assert.deepEqual(validateEventEnvelope(example), { ok: true }, name);
  }
});

test("validates client command required fields", () => {
  assert.deepEqual(validateClientCommand(commandExamples.messageSend), { ok: true });
  assert.deepEqual(validateClientCommand(commandExamples.eventsAck), { ok: true });

  assert.deepEqual(validateClientCommand({ payload: {} }), {
    ok: false,
    error: "ClientCommand.type is required",
  });

  assert.deepEqual(
    validateClientCommand({
      type: CLIENT_COMMAND_TYPES.messageSend,
      payload: { text: "missing id" },
    }),
    {
      ok: false,
      error: "ClientCommand.message.send.payload.client_msg_id is required",
    },
  );
});

import { test } from "node:test";
import assert from "node:assert/strict";
import { assertEventOrder } from "./smoke.mjs";

test("assertEventOrder accepts expected event types in order", () => {
  const events = [
    { type: "session.started" },
    { type: "message.accepted" },
    { type: "message.delta" },
    { type: "message.completed" },
  ];

  assert.doesNotThrow(() => {
    assertEventOrder(events, [
      "message.accepted",
      "message.delta",
      "message.completed",
    ]);
  });
});

test("assertEventOrder rejects missing expected event types", () => {
  assert.throws(
    () => {
      assertEventOrder(
        [{ type: "message.accepted" }, { type: "message.completed" }],
        ["message.accepted", "message.delta", "message.completed"],
      );
    },
    /missing message.delta/,
  );
});

test("assertEventOrder rejects expected event types out of order", () => {
  assert.throws(
    () => {
      assertEventOrder(
        [
          { type: "message.delta" },
          { type: "message.accepted" },
          { type: "message.completed" },
        ],
        ["message.accepted", "message.delta", "message.completed"],
      );
    },
    /missing message.delta after message.accepted/,
  );
});

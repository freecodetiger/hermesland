import { test } from "node:test";
import assert from "node:assert/strict";
import { health } from "./server.mjs";

test("health returns ok", () => {
  assert.deepEqual(health(), { status: "ok" });
});

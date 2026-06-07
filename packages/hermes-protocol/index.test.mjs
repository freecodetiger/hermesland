import { test } from "node:test";
import assert from "node:assert/strict";
import { protocolVersion } from "./index.mjs";

test("exposes protocol version", () => {
  assert.equal(protocolVersion, "0.1.0");
});

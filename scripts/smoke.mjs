#!/usr/bin/env node

import { inspect } from "node:util";
import { fileURLToPath } from "node:url";

const DEFAULT_GATEWAY_URL = "http://127.0.0.1:8787";
const STRICT_ENV = "HERMES_SMOKE_STRICT";
const MESSAGE_EVENT_ORDER = [
  "message.accepted",
  "message.delta",
  "message.completed",
];

class SmokeError extends Error {
  constructor(message, options = {}) {
    super(message, options);
    this.name = "SmokeError";
  }
}

export function assertEventOrder(events, expectedTypes) {
  let searchFrom = 0;
  let previousType = null;

  for (const expectedType of expectedTypes) {
    const foundIndex = events.findIndex((event, index) => {
      return index >= searchFrom && event?.type === expectedType;
    });

    if (foundIndex === -1) {
      const suffix = previousType === null ? "" : ` after ${previousType}`;
      throw new SmokeError(`missing ${expectedType}${suffix}`);
    }

    searchFrom = foundIndex + 1;
    previousType = expectedType;
  }
}

function gatewayBaseUrl() {
  return process.env.HERMES_GATEWAY_URL || DEFAULT_GATEWAY_URL;
}

async function requestJson(baseUrl, method, path, body, options = {}) {
  const url = new URL(path, baseUrl);
  const headers = { accept: "application/json" };
  const init = { method, headers };

  if (body !== undefined) {
    headers["content-type"] = "application/json";
    init.body = JSON.stringify(body);
  }

  let response;
  try {
    response = await fetch(url, init);
  } catch (error) {
    if (options.allowUnreachable) {
      return null;
    }
    throw new SmokeError(
      `${method} ${url.href} failed: Gateway is unreachable (${error.message})`,
      { cause: error },
    );
  }

  const text = await response.text();
  const parsedBody = parseResponseBody(text);

  if (!response.ok) {
    throw new SmokeError(
      `${method} ${url.href} returned HTTP ${response.status}: ${formatBody(parsedBody)}`,
    );
  }

  return parsedBody;
}

function isStrict() {
  return process.env[STRICT_ENV] === "1" || process.env[STRICT_ENV] === "true";
}

function parseResponseBody(text) {
  if (text.length === 0) {
    return null;
  }

  try {
    return JSON.parse(text);
  } catch {
    return text;
  }
}

function formatBody(body) {
  if (typeof body === "string") {
    return body;
  }

  return inspect(body, { depth: 5, colors: false });
}

function extractEvents(body) {
  if (Array.isArray(body)) {
    return body;
  }

  if (Array.isArray(body?.events)) {
    return body.events;
  }

  throw new SmokeError(
    `GET /v1/events?after_seq=0 returned no event array: ${formatBody(body)}`,
  );
}

async function runSmoke() {
  const baseUrl = gatewayBaseUrl();
  console.log(`Smoke target: ${baseUrl}`);

  const health = await requestJson(baseUrl, "GET", "/healthz", undefined, {
    allowUnreachable: !isStrict(),
  });
  if (health === null) {
    console.log(`skip Gateway smoke: target unreachable; set ${STRICT_ENV}=1 to fail instead`);
    return;
  }
  console.log("ok GET /healthz");

  const clientId = `smoke-${Date.now()}`;
  await requestJson(baseUrl, "POST", "/v1/auth/device/start", {
    device_name: "smoke-runner",
    client_id: clientId,
  });
  console.log("ok POST /v1/auth/device/start");

  await requestJson(baseUrl, "POST", "/v1/messages", {
    conversation_id: "conv-smoke",
    client_msg_id: clientId,
    content: "Hermes smoke test message",
  });
  console.log("ok POST /v1/messages");

  const eventsBody = await requestJson(baseUrl, "GET", "/v1/events?after_seq=0");
  const events = extractEvents(eventsBody);
  assertEventOrder(events, MESSAGE_EVENT_ORDER);
  console.log(`ok GET /v1/events?after_seq=0 includes ${MESSAGE_EVENT_ORDER.join(" -> ")}`);
}

const isCli = fileURLToPath(import.meta.url) === process.argv[1];

if (isCli) {
  runSmoke().catch((error) => {
    const message = error instanceof SmokeError ? error.message : error.stack;
    console.error(`Smoke failed: ${message}`);
    process.exitCode = 1;
  });
}

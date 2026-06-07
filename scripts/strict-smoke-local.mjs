#!/usr/bin/env node

import { spawn } from "node:child_process";

const gateway = spawn("npm", ["--workspace", "@hermesland/gateway", "run", "dev"], {
  stdio: ["ignore", "pipe", "pipe"],
  env: { ...process.env, PORT: "8787" },
});

let settled = false;

gateway.stdout.on("data", async (chunk) => {
  process.stdout.write(chunk);
  if (settled || !chunk.toString().includes("gateway listening")) {
    return;
  }

  settled = true;
  const smoke = spawn("npm", ["run", "smoke"], {
    stdio: "inherit",
    env: { ...process.env, HERMES_SMOKE_STRICT: "1" },
  });

  smoke.on("exit", (code) => {
    gateway.kill("SIGINT");
    process.exitCode = code ?? 1;
  });
});

gateway.stderr.on("data", (chunk) => {
  process.stderr.write(chunk);
});

gateway.on("exit", (code) => {
  if (!settled) {
    process.exitCode = code ?? 1;
  }
});

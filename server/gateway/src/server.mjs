import http from "node:http";
import { fileURLToPath } from "node:url";
import { EVENT_TYPES, validateEventEnvelope } from "@hermesland/hermes-protocol";

export function health() {
  return { status: "ok" };
}

export function defaultPort() {
  return 8787;
}

export class EventStore {
  #events = [];
  #cursors = new Map();
  #tasks = [];
  #approvals = [];
  #nextSeq = 1;
  #nextTaskSeq = 1;
  #nextApprovalSeq = 1;

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

  runTask({ mode = "success" } = {}) {
    if (!["success", "failure", "approval"].includes(mode)) {
      throw new Error("mode must be one of: success, failure, approval");
    }

    const task = {
      task_id: `task_${String(this.#nextTaskSeq++).padStart(6, "0")}`,
      mode,
      status: "running",
      title: `Mock ${mode} task`,
    };
    this.#tasks.push(task);

    const events = [
      this.append({
        type: EVENT_TYPES.taskStarted,
        payload: {
          task_id: task.task_id,
          title: task.title,
        },
      }),
    ];

    if (mode === "failure") {
      task.status = "failed";
      events.push(
        this.append({
          type: EVENT_TYPES.taskFailed,
          payload: {
            task_id: task.task_id,
            error: {
              code: "MOCK_TASK_FAILED",
              message: "Mock task failed safely.",
            },
          },
        }),
      );
      return { task: copyRecord(task), events };
    }

    if (mode === "approval") {
      const approval = {
        approval_id: `approval_${String(this.#nextApprovalSeq++).padStart(6, "0")}`,
        task_id: task.task_id,
        status: "pending",
        prompt: "Approve mock task?",
        actions: ["approve", "reject"],
      };
      this.#approvals.push(approval);
      task.status = "requires_approval";
      events.push(
        this.append({
          type: EVENT_TYPES.taskRequiresApproval,
          payload: {
            task_id: task.task_id,
            approval_id: approval.approval_id,
            prompt: approval.prompt,
            actions: approval.actions,
          },
        }),
      );
      return { task: copyRecord(task), approval: copyRecord(approval), events };
    }

    task.status = "completed";
    events.push(
      this.append({
        type: EVENT_TYPES.taskProgress,
        payload: {
          task_id: task.task_id,
          progress: 0.5,
          message: "Mock task running.",
        },
      }),
      this.append({
        type: EVENT_TYPES.taskCompleted,
        payload: {
          task_id: task.task_id,
          result: "Mock task completed.",
        },
      }),
    );

    return { task: copyRecord(task), events };
  }

  listTasks() {
    return this.#tasks.map(copyRecord);
  }

  resolveApproval(approvalId, decision) {
    const approval = this.#approvals.find((candidate) => candidate.approval_id === approvalId);

    if (!approval) {
      return {
        ok: false,
        statusCode: 404,
        body: { error: "approval_not_found", approval_id: approvalId },
      };
    }

    if (approval.status !== "pending") {
      return {
        ok: false,
        statusCode: 409,
        body: {
          error: "approval_already_resolved",
          approval_id: approval.approval_id,
          status: approval.status,
        },
      };
    }

    const task = this.#tasks.find((candidate) => candidate.task_id === approval.task_id);
    const events = [];

    if (decision === "approve") {
      approval.status = "approved";
      task.status = "completed";
      events.push(
        this.append({
          type: EVENT_TYPES.taskProgress,
          payload: {
            task_id: task.task_id,
            progress: 1,
            message: "Approval granted.",
          },
        }),
        this.append({
          type: EVENT_TYPES.taskCompleted,
          payload: {
            task_id: task.task_id,
            result: "Mock task approved and completed.",
          },
        }),
      );
    } else {
      approval.status = "rejected";
      task.status = "cancelled";
      events.push(
        this.append({
          type: EVENT_TYPES.taskCancelled,
          payload: {
            task_id: task.task_id,
            reason: "Approval rejected.",
          },
        }),
      );
    }

    return {
      ok: true,
      body: {
        approval: copyRecord(approval),
        task: copyRecord(task),
        events,
      },
    };
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

      if (request.method === "POST" && url.pathname === "/v1/tasks/run") {
        const body = await readJson(request);
        const taskRun = store.runTask(body);
        sendJson(response, 202, taskRun);
        return;
      }

      if (request.method === "GET" && url.pathname === "/v1/tasks") {
        sendJson(response, 200, { tasks: store.listTasks() });
        return;
      }

      const approvalMatch = url.pathname.match(/^\/v1\/approvals\/([^/]+)\/(approve|reject)$/);
      if (request.method === "POST" && approvalMatch) {
        const result = store.resolveApproval(approvalMatch[1], approvalMatch[2]);
        sendJson(response, result.statusCode ?? 200, result.body);
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

function copyRecord(record) {
  return { ...record };
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
  const port = Number(process.env.PORT ?? defaultPort());
  createServer().listen(port, () => {
    console.log(`gateway listening on http://127.0.0.1:${port}`);
  });
}

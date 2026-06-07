export const protocolVersion = "0.1.0";

export const EVENT_TYPES = Object.freeze({
  messageAccepted: "message.accepted",
  messageDelta: "message.delta",
  messageCompleted: "message.completed",
  messageFailed: "message.failed",
  taskStarted: "task.started",
  taskProgress: "task.progress",
  taskCompleted: "task.completed",
  taskFailed: "task.failed",
  taskCancelled: "task.cancelled",
  taskRequiresApproval: "task.requires_approval",
  notificationCreated: "notification.created",
  agentOnline: "agent.online",
  agentOffline: "agent.offline",
  systemError: "system.error",
});

export const CLIENT_COMMAND_TYPES = Object.freeze({
  messageSend: "message.send",
  eventsAck: "events.ack",
});

const eventTypeValues = new Set(Object.values(EVENT_TYPES));
const clientCommandTypeValues = new Set(Object.values(CLIENT_COMMAND_TYPES));

export function validateEventEnvelope(value) {
  if (!isRecord(value)) {
    return invalid("EventEnvelope must be an object");
  }

  for (const field of ["event_id", "seq", "type", "created_at", "payload"]) {
    if (!(field in value)) {
      return invalid(`EventEnvelope.${field} is required`);
    }
  }

  if (!Number.isSafeInteger(value.seq) || value.seq < 0) {
    return invalid("EventEnvelope.seq must be a non-negative safe integer");
  }

  if (!eventTypeValues.has(value.type)) {
    return invalid("EventEnvelope.type must be a known event type");
  }

  return { ok: true };
}

export function validateClientCommand(value) {
  if (!isRecord(value)) {
    return invalid("ClientCommand must be an object");
  }

  if (!("type" in value)) {
    return invalid("ClientCommand.type is required");
  }

  if (!clientCommandTypeValues.has(value.type)) {
    return invalid("ClientCommand.type must be a known command type");
  }

  if (!("payload" in value)) {
    return invalid("ClientCommand.payload is required");
  }

  if (value.type === CLIENT_COMMAND_TYPES.messageSend) {
    if (!isRecord(value.payload) || !("client_msg_id" in value.payload)) {
      return invalid("ClientCommand.message.send.payload.client_msg_id is required");
    }
  }

  return { ok: true };
}

export const eventExamples = Object.freeze({
  messageAccepted: envelope(1, EVENT_TYPES.messageAccepted, {
    message_id: "msg_001",
    client_msg_id: "client_msg_001",
  }),
  messageDelta: envelope(2, EVENT_TYPES.messageDelta, {
    message_id: "msg_001",
    delta: "Hello",
  }),
  messageCompleted: envelope(3, EVENT_TYPES.messageCompleted, {
    message_id: "msg_001",
    text: "Hello from Hermes Island.",
  }),
  messageFailed: envelope(4, EVENT_TYPES.messageFailed, {
    message_id: "msg_002",
    error: {
      code: "MODEL_ERROR",
      message: "Model stream failed.",
    },
  }),
  taskStarted: envelope(5, EVENT_TYPES.taskStarted, {
    task_id: "task_001",
    title: "Run smoke test",
  }),
  taskProgress: envelope(6, EVENT_TYPES.taskProgress, {
    task_id: "task_001",
    progress: 0.5,
    message: "Gateway stream connected.",
  }),
  taskCompleted: envelope(7, EVENT_TYPES.taskCompleted, {
    task_id: "task_001",
    result: "Smoke test passed.",
  }),
  taskFailed: envelope(8, EVENT_TYPES.taskFailed, {
    task_id: "task_002",
    error: {
      code: "COMMAND_FAILED",
      message: "npm test exited non-zero.",
    },
  }),
  taskCancelled: envelope(9, EVENT_TYPES.taskCancelled, {
    task_id: "task_003",
    reason: "User cancelled from Island.",
  }),
  taskRequiresApproval: envelope(10, EVENT_TYPES.taskRequiresApproval, {
    task_id: "task_004",
    approval_id: "approval_001",
    prompt: "Allow file write?",
    actions: ["approve", "deny"],
  }),
  notificationCreated: envelope(11, EVENT_TYPES.notificationCreated, {
    notification_id: "notif_001",
    title: "Task completed",
    body: "Smoke test passed.",
  }),
  agentOnline: envelope(12, EVENT_TYPES.agentOnline, {
    agent_id: "agent_001",
    name: "Gateway Agent",
  }),
  agentOffline: envelope(13, EVENT_TYPES.agentOffline, {
    agent_id: "agent_001",
    reason: "WebSocket closed.",
  }),
  systemError: envelope(14, EVENT_TYPES.systemError, {
    error: {
      code: "UNHANDLED_ERROR",
      message: "Unexpected gateway error.",
    },
  }),
});

export const commandExamples = Object.freeze({
  messageSend: Object.freeze({
    type: CLIENT_COMMAND_TYPES.messageSend,
    payload: {
      client_msg_id: "client_msg_001",
      text: "Start the smoke test.",
    },
  }),
  eventsAck: Object.freeze({
    type: CLIENT_COMMAND_TYPES.eventsAck,
    payload: {
      event_ids: ["evt_001", "evt_002"],
      through_seq: 2,
    },
  }),
});

function envelope(seq, type, payload) {
  return Object.freeze({
    event_id: `evt_${String(seq).padStart(3, "0")}`,
    seq,
    type,
    created_at: "2026-01-01T00:00:00.000Z",
    payload,
  });
}

function isRecord(value) {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

function invalid(error) {
  return { ok: false, error };
}

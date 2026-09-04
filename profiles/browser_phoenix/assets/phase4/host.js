import { BrowserRuntimeLoader, DiagnosticCollector, detectBrowserPrerequisites, mayActivate } from "./js/index.js";
import { FixtureDOMRenderer } from "./dom/fixture-dom-renderer.js";

const status = document.querySelector("[data-bh01-status]");
const detail = document.querySelector("[data-bh01-detail]");
const events = [];
const fixtureEffects = [];
const domTraces = [];
const timingObservations = [];
const runtimeResources = { memory_pages: null, workers: null };
const pendingServerRequests = new Set();
const serverSession = { csrf: null, identity_id: null };
const diagnostics = new DiagnosticCollector({ source: "browser-host", clockId: "performance" });
let renderer = null;
let fixtureQueue = Promise.resolve();
const record = (event) => {
  if (events.length < 256) events.push(event);
  if (event?.code) recordDiagnostic(event);
  if (globalThis.__blazexBH01) {
    globalThis.__blazexBH01.events = events;
    globalThis.__blazexBH01.diagnostics = diagnostics.summary();
  }
  if (event?.type === "runtime-ready") runtimeResources.memory_pages = event.memory_pages;
  if (event?.type === "runtime-event" && event.name === "bh01_fixture_effect") applyFixtureEffect(event.payload);
};
const show = (state, message) => {
  status.dataset.state = state;
  status.textContent = message;
};

const prerequisites = detectBrowserPrerequisites();
globalThis.__blazexBH01 = { prerequisites, events, state: "checked" };
detail.textContent = prerequisites.message;
const loader = mayActivate(prerequisites) ? new BrowserRuntimeLoader({ onEvent: record }) : null;

if (!mayActivate(prerequisites)) {
  show("fallback", prerequisites.decision === "unsupported" ? "Experimental runtime unavailable" : "Server-rendered fallback active");
  globalThis.__blazexBH01.state = "fallback";
} else {
  await start();
}

async function start() {
  show("starting", "Starting experimental Elixir WebAssembly runtime…");
  Object.assign(globalThis.__blazexBH01, { loader, state: "starting" });
  try {
    const activation = await loader.start({
      manifestUrl: "./runtime-manifest.json",
      frameUrl: "./runtime-frame.html",
      timeoutMs: 15_000,
    });
    const echo = await activation.bridge.request("runtime.echo", { message: "bh01-browser-roundtrip", generation: activation.generation });
    renderer = new FixtureDOMRenderer({
      target: document.querySelector("[data-bh01-fixture-host]"),
      documentImpl: document,
      generation: activation.generation,
      onEvent: (event) => enqueueFixtureEvent(event),
      onTrace: (trace) => { if (domTraces.length < 256) domTraces.push(trace); },
    });
    const fixture = fixtureApi(activation);
    globalThis.blazexBh01Fixture = fixture;
    await fixture.command("mount");
    show("ready", "Experimental Elixir WebAssembly runtime ready");
    detail.textContent = `Activation generation ${activation.generation}; verified Elixir bridge round trip: ${echo.message}.`;
    Object.assign(globalThis.__blazexBH01, { state: "ready", activation, echo, fixture_effects: fixtureEffects, dom_traces: domTraces, timing_observations: timingObservations });
  } catch (error) {
    record({ type: "activation-failed", code: error?.code ?? "unexpected-host-error" });
    loader.stop("activation-error");
    show("failed", "Experimental runtime failed safely");
    detail.textContent = error instanceof Error ? error.message : "The runtime failed without a diagnostic.";
    Object.assign(globalThis.__blazexBH01, { state: "failed", error: { code: error?.code ?? "unexpected", message: detail.textContent } });
  }
}

globalThis.blazexBh01Start = start;
globalThis.blazexBh01Stop = async () => {
  const state = globalThis.__blazexBH01;
  const completedActivation = state?.activation;
  try {
    if (globalThis.blazexBh01Fixture) await globalThis.blazexBh01Fixture.dispose();
    if (state?.activation?.bridge) await state.activation.bridge.request("runtime.shutdown", {}, { timeoutMs: 2_000 });
  } finally {
    state?.loader?.stop("explicit-browser-stop");
    renderer?.dispose("browser-stop");
    renderer = null;
    globalThis.blazexBh01Fixture = null;
    if (state) {
      globalThis.__blazexBH01.state = "stopped";
      globalThis.__blazexBH01.final_resources = hostResources(completedActivation);
      globalThis.__blazexBH01.activation = null;
    }
    show("stopped", "Experimental runtime stopped");
  }
};

function applyFixtureEffect(effect) {
  if (!renderer) return;
  const startedAt = performance.now();
  try {
    const observation = renderer.apply(effect);
    rememberTiming({ kind: "effect-to-dom", generation: effect.generation, sequence: effect.sequence, duration_ms: performance.now() - startedAt });
    if (fixtureEffects.length < 256) fixtureEffects.push({ effect, observation });
    if (globalThis.__blazexBH01) globalThis.__blazexBH01.fixture_effects = fixtureEffects;
  } catch (error) {
    record({ protocol: "blazex.bh01.fixture-host/0.1", type: "fixture-effect-failed", code: error?.code ?? "fixture-effect-failed" });
  }
}

function enqueueFixtureEvent(event) {
  const fixture = globalThis.blazexBh01Fixture;
  if (!fixture) return;
  fixtureQueue = fixtureQueue.then(() => fixture.event(event)).catch((error) => {
    record({ protocol: "blazex.bh01.fixture-host/0.1", type: "fixture-event-failed", code: error?.code ?? "fixture-event-failed" });
  });
}

function fixtureApi(activation) {
  let disposed = false;

  const command = async (commandName, payload = {}) => {
    return observeRequest(activation, "command", commandName, () => activation.bridge.request("fixture.command", { command: commandName, ...payload }));
  };

  const completeServerCommand = async (intent, options = {}) => {
    const result = await sendServerCommand(intent, options);
    if (disposed) return { intent, result, delivered: false };
    const rendered = await command("server.result", { result });
    return { intent, result, rendered, delivered: true };
  };

  return Object.freeze({
    command,
    event: async (event) => {
      const observed = await observeRequest(activation, "event", event.event, () => activation.bridge.request("fixture.event", event));
      const intent = observed?.ack?.result?.command;
      return intent ? { ...observed, server: await completeServerCommand(intent) } : observed;
    },
    establishSession: async (identityId = "operator") => {
      const response = await fetch("/bh01/test/session", {
        method: "POST",
        credentials: "same-origin",
        headers: { "content-type": "application/json", "x-bh01-test-control": "enabled" },
        body: JSON.stringify({ identity_id: identityId }),
      });
      const body = await response.json();
      if (!response.ok || typeof body.csrf_token !== "string") throw new Error("BH-01 test session was rejected");
      serverSession.csrf = body.csrf_token;
      serverSession.identity_id = body.identity_id;
      record({ protocol: "blazex.bh01.server-trace/0.1", stage: "session-established", identity_id: body.identity_id });
      return Object.freeze({ identity_id: body.identity_id, expires_at_ms: body.expires_at_ms });
    },
    expireSession: async () => {
      const response = await fetch("/bh01/test/expire", {
        method: "POST",
        credentials: "same-origin",
        headers: { "x-bh01-test-control": "enabled" },
      });
      return Object.freeze({ status: response.status, expired: response.ok });
    },
    serverCommand: async (options = {}) => {
      const prepared = await command("server.prepare", {
        ...(options.correlationId ? { correlation_id: options.correlationId } : {}),
        ...(options.idempotencyKey ? { idempotency_key: options.idempotencyKey } : {}),
        ...(Number.isSafeInteger(options.expectedVersion) ? { expected_version: options.expectedVersion } : {}),
      });
      return completeServerCommand(prepared.ack.result.command, options);
    },
    snapshot: async () => ({ runtime: await activation.bridge.request("fixture.snapshot", {}), dom: renderer.snapshot(), host: hostResources(activation) }),
    settle: async () => {
      await fixtureQueue;
      return { runtime: await activation.bridge.request("fixture.snapshot", {}), dom: renderer.snapshot(), host: hostResources(activation) };
    },
    dispose: async () => {
      disposed = true;
      for (const controller of pendingServerRequests) controller.abort("fixture-dispose");
      serverSession.csrf = null;
      serverSession.identity_id = null;
      try { return await activation.bridge.request("fixture.command", { command: "dispose" }); }
      finally { renderer?.dispose("fixture-dispose"); }
    },
  });
}

async function sendServerCommand(intent, options = {}) {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort("server-timeout"), 1_500);
  pendingServerRequests.add(controller);
  try {
    const headers = {
      "content-type": "application/json",
      "x-bh01-csrf": serverSession.csrf ?? "",
    };
    if (options.failureMode) {
      headers["x-bh01-test-control"] = "enabled";
      headers["x-bh01-failure-mode"] = options.failureMode;
    }
    const response = await fetch("/bh01/commands/counter-increment", {
      method: "POST",
      credentials: "same-origin",
      headers,
      body: JSON.stringify(intent),
      signal: controller.signal,
    });
    const text = await response.text();
    if (new TextEncoder().encode(text).byteLength > 2_048) throw new Error("server-result-oversized");
    const result = JSON.parse(text);
    record({
      protocol: "blazex.bh01.server-trace/0.1",
      stage: "transport-result",
      correlation_id: intent.correlation_id,
      http_status: response.status,
      outcome: result?.status ?? "invalid",
      code: result?.error?.code ?? null,
    });
    return result;
  } catch (error) {
    const timedOut = controller.signal.aborted && controller.signal.reason === "server-timeout";
    const code = timedOut ? "transport-timeout" : "transport-unavailable";
    record({ protocol: "blazex.bh01.server-trace/0.1", stage: "transport-failed", correlation_id: intent.correlation_id, code });
    return {
      protocol: "blazex.bh01.server-result/0.1",
      status: "error",
      correlation_id: intent.correlation_id,
      error: { code, retryable: true },
    };
  } finally {
    clearTimeout(timeout);
    pendingServerRequests.delete(controller);
  }
}

async function observeRequest(activation, kind, name, request) {
  const startedAt = performance.now();
  const ack = await request();
  const runtime = await activation.bridge.request("fixture.snapshot", {});
  const transitionedAt = performance.now();
  await new Promise((resolve) => requestAnimationFrame(() => resolve()));
  const paintedAt = performance.now();
  const timing = {
    kind,
    name,
    generation: activation.generation,
    request_to_snapshot_ms: transitionedAt - startedAt,
    snapshot_to_paint_ms: paintedAt - transitionedAt,
    request_to_paint_ms: paintedAt - startedAt,
  };
  rememberTiming(timing);
  return { ack, runtime, dom: renderer.snapshot(), host: hostResources(activation), timing };
}

function rememberTiming(observation) {
  if (timingObservations.length < 256) timingObservations.push(Object.freeze(observation));
}

function recordDiagnostic(event) {
  const transport = event.stage?.startsWith("transport");
  const render = event.type === "fixture-effect-failed";
  diagnostics.record({
    scenarioId: "bh01-browser-profile",
    generation: event.generation ?? globalThis.__blazexBH01?.activation?.generation ?? 1,
    correlationId: event.correlation_id ?? `event-${events.length}`,
    layer: transport ? "server-transport" : render ? "standalone-dom" : "browser-runtime",
    category: transport ? "transport" : render ? "render" : "bridge",
    severity: "error",
    owner: render ? "standalone-dom-owner" : "browser-host-owner",
    code: event.code,
    userMessage: transport ? "The operation could not reach the server." : render ? "The interface could not be updated." : "The runtime operation failed.",
    internal: { stage: event.stage ?? null, type: event.type ?? null, http_status: event.http_status ?? null, outcome: event.outcome ?? null },
  });
}

function hostResources(activation) {
  const dom = renderer?.snapshot();
  const domResources = dom ? { roots: dom.root_count, listeners: dom.listener_count, nodes: dom.node_count } : { roots: 0, listeners: 0, nodes: 0 };
  return Object.freeze({
    memory_pages: runtimeResources.memory_pages,
    workers: runtimeResources.workers,
    worker_observation: "not exposed at the parent-frame boundary",
    bridge: activation?.bridge?.metrics?.() ?? null,
    lifecycle: loader?.lifecycle?.() ?? null,
    server: { pending: pendingServerRequests.size, session_configured: serverSession.csrf !== null },
    browser: {
      workers: runtimeResources.workers,
      listeners: domResources.listeners,
      observers: 0,
      fetches: pendingServerRequests.size,
      requests: (activation?.bridge?.metrics?.().pending ?? 0) + pendingServerRequests.size,
      dom_roots: domResources.roots,
      references: renderer ? 1 : 0,
    },
    adapter: { active_generations: 0 },
    dom: domResources,
  });
}

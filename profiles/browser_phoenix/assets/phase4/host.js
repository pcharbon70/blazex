import { BrowserRuntimeLoader, detectBrowserPrerequisites, mayActivate } from "./js/index.js";
import { FixtureDOMRenderer } from "./dom/fixture-dom-renderer.js";

const status = document.querySelector("[data-bh01-status]");
const detail = document.querySelector("[data-bh01-detail]");
const events = [];
const fixtureEffects = [];
const domTraces = [];
const timingObservations = [];
const runtimeResources = { memory_pages: null, workers: null };
let renderer = null;
let fixtureQueue = Promise.resolve();
const record = (event) => {
  if (events.length < 256) events.push(event);
  if (globalThis.__blazexBH01) globalThis.__blazexBH01.events = events;
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
  return Object.freeze({
    command: async (command, payload = {}) => {
      return observeRequest(activation, "command", command, () => activation.bridge.request("fixture.command", { command, ...payload }));
    },
    event: async (event) => {
      return observeRequest(activation, "event", event.event, () => activation.bridge.request("fixture.event", event));
    },
    snapshot: async () => ({ runtime: await activation.bridge.request("fixture.snapshot", {}), dom: renderer.snapshot(), host: hostResources(activation) }),
    settle: async () => {
      await fixtureQueue;
      return { runtime: await activation.bridge.request("fixture.snapshot", {}), dom: renderer.snapshot(), host: hostResources(activation) };
    },
    dispose: async () => {
      try { return await activation.bridge.request("fixture.command", { command: "dispose" }); }
      finally { renderer?.dispose("fixture-dispose"); }
    },
  });
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

function hostResources(activation) {
  const dom = renderer?.snapshot();
  return Object.freeze({
    memory_pages: runtimeResources.memory_pages,
    workers: runtimeResources.workers,
    worker_observation: "not exposed at the parent-frame boundary",
    bridge: activation?.bridge?.metrics?.() ?? null,
    lifecycle: loader?.lifecycle?.() ?? null,
    dom: dom ? { roots: dom.root_count, listeners: dom.listener_count, nodes: dom.node_count } : { roots: 0, listeners: 0, nodes: 0 },
  });
}

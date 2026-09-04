import { BrowserRuntimeLoader, detectBrowserPrerequisites, mayActivate } from "./js/index.js";
import { FixtureDOMRenderer } from "./dom/fixture-dom-renderer.js";

const status = document.querySelector("[data-bh01-status]");
const detail = document.querySelector("[data-bh01-detail]");
const events = [];
const fixtureEffects = [];
const domTraces = [];
let renderer = null;
let fixtureQueue = Promise.resolve();
const record = (event) => {
  if (events.length < 256) events.push(event);
  if (globalThis.__blazexBH01) globalThis.__blazexBH01.events = events;
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
    Object.assign(globalThis.__blazexBH01, { state: "ready", activation, echo, fixture_effects: fixtureEffects, dom_traces: domTraces });
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
      globalThis.__blazexBH01.activation = null;
    }
    show("stopped", "Experimental runtime stopped");
  }
};

function applyFixtureEffect(effect) {
  if (!renderer) return;
  try {
    const observation = renderer.apply(effect);
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
      const ack = await activation.bridge.request("fixture.command", { command, ...payload });
      await Promise.resolve();
      return { ack, runtime: await activation.bridge.request("fixture.snapshot", {}), dom: renderer.snapshot() };
    },
    event: async (event) => {
      const ack = await activation.bridge.request("fixture.event", event);
      await Promise.resolve();
      return { ack, runtime: await activation.bridge.request("fixture.snapshot", {}), dom: renderer.snapshot() };
    },
    snapshot: async () => ({ runtime: await activation.bridge.request("fixture.snapshot", {}), dom: renderer.snapshot() }),
    dispose: async () => {
      try { return await activation.bridge.request("fixture.command", { command: "dispose" }); }
      finally { renderer?.dispose("fixture-dispose"); }
    },
  });
}

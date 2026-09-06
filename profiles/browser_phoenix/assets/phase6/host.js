import {
  BlazeXHostError,
  BrowserRuntimeStartup,
  SharedRuntimeRegistry,
  inspectHostManifest,
} from "./js/index.js";

const status = document.querySelector("[data-bh03-status]");
const snapshotElement = document.querySelector("[data-bh03-snapshot]");
const stopButton = document.querySelector("[data-bh03-stop]");
const restartButton = document.querySelector("[data-bh03-restart]");
const events = [];
const checks = [];
const runtimeAcknowledgements = [];
let runtimeStarts = 0;
let registry = null;
let scope = null;

const state = globalThis.__blazexBH03 = {
  protocol: "blazex.bh03.browser-profile/1",
  state: "checking",
  support_state: "unsupported",
  events,
  checks,
  runtime_acknowledgements: runtimeAcknowledgements,
};

stopButton.addEventListener("click", () => stop());
restartButton.addEventListener("click", () => location.reload());

await start();

async function start() {
  show("starting", "Starting one verified AtomVM/Elixir runtime…");
  try {
    const gate = await inspectHostManifest({ manifestUrl: "./runtime-manifest.json", timeoutMs: 15_000 });
    state.gate = gate;
    if (gate.decision === "rejected") {
      throw new BlazeXHostError("unsupported-prerequisite", gate.prerequisites.message, {
        reason: "active-profile-prerequisite-missing",
        missing: gate.prerequisites.missing,
      });
    }
    pass("exact-manifest-and-prerequisites");

    registry = new SharedRuntimeRegistry({
      startRuntime: async (options) => {
        runtimeStarts += 1;
        return new BrowserRuntimeStartup({ onEvent: record }).start(options);
      },
      onEvent: record,
    });

    const open = {
      scopeId: "page-runtime",
      compatibility: gate.manifest.compatibility,
      startupOptions: {
        gate,
        frameUrl: "./runtime-frame.html",
        timeoutMs: 30_000,
      },
    };
    const [first, second] = await Promise.all([registry.open(open), registry.open(open)]);
    if (first !== second || runtimeStarts !== 1) throw new Error("Compatible opens did not coalesce");
    scope = first;
    pass("one-shared-runtime");

    const roots = scope.roots();
    const [primary, secondary] = await Promise.all([
      roots.register("primary-root"),
      roots.register("secondary-root"),
    ]);
    pass("two-independent-root-registrations");

    await primary.mount({ targetId: "primary-slot", tree: tree("Primary mounted", 1) });
    renderRoot("primary-root", "primary-slot", "Primary mounted", 1);
    await secondary.mount({ targetId: "secondary-slot", tree: tree("Secondary mounted", 1) });
    renderRoot("secondary-root", "secondary-slot", "Secondary mounted", 1);
    pass("independent-mount");

    await primary.update(tree("Primary updated", 2));
    renderRoot("primary-root", "primary-slot", "Primary updated", 2);
    await secondary.move("alternate-slot");
    renderRoot("secondary-root", "alternate-slot", "Secondary moved", 1);
    pass("update-and-move-isolation");

    await primary.dispose();
    document.querySelector('[data-root="primary-root"]').hidden = true;
    if (secondary.snapshot().state !== "ready") throw new Error("Disposing one root mutated its sibling");
    await primary.mount({ targetId: "primary-slot", tree: tree("Primary remounted", 3) });
    renderRoot("primary-root", "primary-slot", "Primary remounted", 3);
    pass("dispose-and-remount-isolation");

    const mismatch = { ...gate.manifest.compatibility, renderer: "blazex.renderer/999" };
    let mismatchError;
    try { await registry.open({ ...open, compatibility: mismatch }); }
    catch (error) { mismatchError = error; }
    const mismatchFallback = registry.fallbackFor({ scopeId: "page-runtime", error: mismatchError, runtimeGeneration: scope.snapshot().runtime_generation });
    const prerequisiteFallback = registry.fallbackFor({
      scopeId: "unsupported-profile",
      runtimeGeneration: 0,
      error: new BlazeXHostError("unsupported-prerequisite", "A required browser capability is unavailable", { reason: "fixture-prerequisite" }),
    });
    if (mismatchFallback.action !== "deployment-action" || prerequisiteFallback.action !== "static-content") {
      throw new Error("Fallback classification drifted");
    }
    state.fallbacks = [mismatchFallback, prerequisiteFallback];
    pass("intentional-fallback-decisions");

    if (runtimeAcknowledgements.length < 8 || runtimeAcknowledgements.some((item) => item !== "bh03-profile")) {
      throw new Error("Root operations were not acknowledged by the Elixir runtime fixture");
    }
    pass("elixir-runtime-root-acknowledgements");

    state.state = "ready";
    state.scope = scope;
    state.registry = registry;
    stopButton.disabled = false;
    show("ready", "Shared AtomVM/Elixir runtime ready; two root lifecycles passed");
    publish();
  } catch (error) {
    const fallbackRegistry = registry ?? new SharedRuntimeRegistry();
    const fallback = fallbackRegistry.fallbackFor({ scopeId: "page-runtime", error, runtimeGeneration: scope?.snapshot().runtime_generation ?? 0 });
    Object.assign(state, {
      state: fallback ? "fallback" : "failed",
      error: boundedError(error),
      fallback: fallback ?? null,
    });
    show(state.state, fallback ? "Experimental runtime fell back safely" : "Experimental runtime failed safely");
    publish();
  }
}

async function stop() {
  if (!registry || state.state === "stopped") return state.shutdown;
  stopButton.disabled = true;
  try {
    const shutdown = await registry.close("page-runtime", { reason: "profile-owner-stop", timeoutMs: 5_000 });
    state.shutdown = shutdown;
    state.state = "stopped";
    pass("registry-owned-shutdown");
    show("stopped", "Shared runtime stopped and both roots released");
    publish();
    return shutdown;
  } catch (error) {
    state.state = "failed";
    state.error = boundedError(error);
    show("failed", "Shared runtime shutdown failed safely");
    publish();
    throw error;
  }
}

globalThis.blazexBh03Stop = stop;

function record(event) {
  if (events.length < 256) events.push(event);
  const marker = event?.protocol === "blazex.bridge.trace/1" && event.kind === "response"
    ? event.value?.result?.runtime_fixture
    : null;
  if (marker && runtimeAcknowledgements.length < 64) runtimeAcknowledgements.push(marker);
}

function tree(text, revision) {
  return { kind: "status", text, revision };
}

function renderRoot(rootId, targetId, text, revision) {
  const root = document.querySelector(`[data-root="${rootId}"]`);
  document.getElementById(targetId).append(root);
  root.hidden = false;
  root.textContent = `${text} · runtime revision ${revision}`;
  root.dataset.revision = String(revision);
}

function pass(name) {
  if (!checks.includes(name)) checks.push(name);
}

function show(next, message) {
  status.dataset.state = next;
  status.textContent = message;
}

function publish() {
  state.snapshot = {
    protocol: state.protocol,
    state: state.state,
    support_state: state.support_state,
    runtime_starts: runtimeStarts,
    checks: [...checks],
    registry: registry?.snapshot() ?? null,
    scope: scope?.snapshot() ?? null,
    roots: scope?.rootsSnapshot() ?? null,
    fallbacks: state.fallbacks ?? [],
    shutdown: state.shutdown ?? null,
    error: state.error ?? null,
    runtime_acknowledgement_count: runtimeAcknowledgements.length,
  };
  snapshotElement.textContent = JSON.stringify(state.snapshot, null, 2);
}

function boundedError(error) {
  return {
    name: String(error?.name ?? "Error").slice(0, 64),
    code: String(error?.code ?? "unexpected-profile-error").slice(0, 96),
    message: String(error?.message ?? "The profile failed").slice(0, 256),
  };
}

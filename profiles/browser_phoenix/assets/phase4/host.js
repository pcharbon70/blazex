import { BrowserRuntimeLoader, detectBrowserPrerequisites, mayActivate } from "./js/index.js";

const status = document.querySelector("[data-bh01-status]");
const detail = document.querySelector("[data-bh01-detail]");
const events = [];
const record = (event) => {
  if (events.length < 256) events.push(event);
  globalThis.__blazexBH01 = { ...(globalThis.__blazexBH01 ?? {}), events };
};
const show = (state, message) => {
  status.dataset.state = state;
  status.textContent = message;
};

const prerequisites = detectBrowserPrerequisites();
globalThis.__blazexBH01 = { prerequisites, events, state: "checked" };
detail.textContent = prerequisites.message;

if (!mayActivate(prerequisites)) {
  show("fallback", prerequisites.decision === "unsupported" ? "Experimental runtime unavailable" : "Server-rendered fallback active");
  globalThis.__blazexBH01.state = "fallback";
} else {
  show("starting", "Starting experimental Elixir WebAssembly runtime…");
  const loader = new BrowserRuntimeLoader({ onEvent: record });
  globalThis.__blazexBH01.loader = loader;
  try {
    const activation = await loader.start({
      manifestUrl: "./runtime-manifest.json",
      frameUrl: "./runtime-frame.html",
      timeoutMs: 15_000,
    });
    const echo = await activation.bridge.request("runtime.echo", { message: "bh01-browser-roundtrip", generation: activation.generation });
    show("ready", "Experimental Elixir WebAssembly runtime ready");
    detail.textContent = `Activation generation ${activation.generation}; verified Elixir bridge round trip: ${echo.message}.`;
    Object.assign(globalThis.__blazexBH01, { state: "ready", activation, echo });
  } catch (error) {
    loader.stop("activation-error");
    show("failed", "Experimental runtime failed safely");
    detail.textContent = error instanceof Error ? error.message : "The runtime failed without a diagnostic.";
    Object.assign(globalThis.__blazexBH01, { state: "failed", error: { code: error?.code ?? "unexpected", message: detail.textContent } });
  }
}

globalThis.blazexBh01Stop = async () => {
  const state = globalThis.__blazexBH01;
  try {
    if (state?.activation?.bridge) await state.activation.bridge.request("runtime.shutdown", {}, { timeoutMs: 2_000 });
  } finally {
    state?.loader?.stop("explicit-browser-stop");
    if (state) state.state = "stopped";
    show("stopped", "Experimental runtime stopped");
  }
};

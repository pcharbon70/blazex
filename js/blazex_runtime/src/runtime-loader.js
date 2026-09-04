import { acquireDeclaredArtifacts, fetchRuntimeManifest } from "./manifest-loader.js";
import { BrowserHostBridge } from "./host-bridge.js";
import { BrowserRuntimeLifecycle } from "./lifecycle.js";
import { BrowserRuntimeFrame } from "./runtime-frame-port.js";
import { errorRecord } from "./internal/errors.js";

export class BrowserRuntimeLoader {
  #controller = null;
  #bridge = null;
  #frame = null;
  #generation = 0;
  #eventTarget;
  #lifecycle;
  #onEvent;
  #ready = null;

  constructor({ onEvent = () => {}, frameFactory = (options) => new BrowserRuntimeFrame(options), lifecycle, eventTarget = globalThis } = {}) {
    this.#onEvent = onEvent;
    this.frameFactory = frameFactory;
    this.#eventTarget = eventTarget;
    this.#lifecycle = lifecycle ?? new BrowserRuntimeLifecycle({ onTransition: onEvent });
  }

  async start({ manifestUrl, frameUrl, timeoutMs = 15_000, fetchImpl, cryptoImpl }) {
    if (this.#controller) throw new Error("BrowserRuntimeLoader already owns an activation");
    this.#generation = this.#lifecycle.begin({ manifest_url: manifestUrl });
    this.#controller = new AbortController();
    this.#lifecycle.own("abort-controller", () => this.#controller?.abort("lifecycle-stop"));
    const pagehide = () => this.stop("pagehide");
    this.#eventTarget.addEventListener?.("pagehide", pagehide, { once: true });
    this.#lifecycle.own("pagehide-listener", () => this.#eventTarget.removeEventListener?.("pagehide", pagehide));
    const emit = (stage, details = {}) => this.#onEvent(Object.freeze({ protocol: "blazex.lifecycle/1", generation: this.#generation, stage, ...details }));
    try {
      this.#lifecycle.transition("fetching");
      emit("manifest-fetching");
      const manifest = await fetchRuntimeManifest(manifestUrl, { signal: this.#controller.signal, timeoutMs, fetchImpl });
      emit("manifest-verified", { manifest_id: manifest.manifest_id, manifest_generation: manifest.generation });
      const artifacts = await acquireDeclaredArtifacts(manifest, { signal: this.#controller.signal, timeoutMs, fetchImpl, cryptoImpl });
      emit("artifacts-verified", { artifact_ids: Object.values(artifacts).map((item) => item.declaration.id), manifest_generation: manifest.generation });
      this.#lifecycle.transition("instantiating", { manifest_generation: manifest.generation });
      this.#frame = this.frameFactory({ frameUrl, onEvent: (event) => this.#handleFrameEvent(event) });
      this.#lifecycle.own("runtime-frame", () => this.#frame?.stop("lifecycle-stop"));
      await this.#frame.attach(this.#controller.signal);
      this.#lifecycle.transition("loading");
      emit("frame-attached", { manifest_generation: manifest.generation });
      this.#ready = deferred();
      this.#frame.start({ manifest, artifacts, generation: this.#generation });
      this.#lifecycle.transition("starting");
      await boundedReady(this.#ready.promise, timeoutMs, this.#controller.signal);
      this.#bridge = new BrowserHostBridge({ transport: this.#frame, generation: this.#generation, scenarioId: `browser-host-${this.#generation}`, onTrace: this.#onEvent });
      this.#lifecycle.own("host-bridge", () => this.#bridge?.stop("lifecycle-stop"));
      return Object.freeze({ manifest_id: manifest.manifest_id, manifest_generation: manifest.generation, generation: this.#generation, bridge: this.#bridge });
    } catch (error) {
      this.#lifecycle.fail(error);
      emit("loader-failed", { error: errorRecord(error) });
      this.stop("activation-failed");
      throw error;
    }
  }

  stop(reason = "requested") {
    this.#lifecycle.stop(reason);
    this.#controller = null;
    this.#bridge = null;
    this.#frame = null;
    this.#ready = null;
  }

  lifecycle() {
    return this.#lifecycle.snapshot();
  }

  #handleFrameEvent(event) {
    if (!this.#lifecycle.acceptGeneration(event.generation)) return;
    this.#onEvent(event);
    if (event.type === "application-ready") {
      if (this.#lifecycle.snapshot().state !== "starting") {
        const error = new Error("Duplicate or out-of-order application readiness");
        error.code = "readiness-protocol-mismatch";
        this.#lifecycle.fail(error);
        this.#ready?.reject(error);
        queueMicrotask(() => this.stop("readiness-protocol-mismatch"));
        return;
      }
      this.#lifecycle.transition("ready", { readiness_event: event.name });
      this.#onEvent(Object.freeze({ protocol: "blazex.lifecycle/1", generation: this.#generation, stage: "root-ready" }));
      this.#ready?.resolve(event);
    } else if (event.type === "runtime-failed" || (event.type === "runtime-exited" && event.status !== 0)) {
      const error = new Error(event.reason ?? "The browser runtime failed");
      error.code = event.code ?? event.type;
      this.#lifecycle.fail(error);
      this.#ready?.reject(error);
      queueMicrotask(() => this.stop("runtime-failed"));
    }
  }
}

function deferred() {
  let resolve;
  let reject;
  const promise = new Promise((resolvePromise, rejectPromise) => { resolve = resolvePromise; reject = rejectPromise; });
  return { promise, resolve, reject };
}

function boundedReady(promise, timeoutMs, signal) {
  return new Promise((resolve, reject) => {
    let completed = false;
    const finish = (callback, value) => {
      if (completed) return;
      completed = true;
      clearTimeout(timer);
      signal.removeEventListener("abort", cancelled);
      callback(value);
    };
    const cancelled = () => finish(reject, Object.assign(new Error("Application startup was cancelled"), { code: "startup-cancelled" }));
    const timer = setTimeout(() => finish(reject, Object.assign(new Error("Application readiness timed out"), { code: "startup-timeout" })), timeoutMs);
    signal.addEventListener("abort", cancelled, { once: true });
    promise.then((value) => finish(resolve, value), (error) => finish(reject, error));
  });
}

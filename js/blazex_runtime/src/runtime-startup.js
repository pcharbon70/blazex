import { acquireHostArtifacts } from "./artifact-acquisition.js";
import { BlazeXHostError, errorRecord } from "./internal/errors.js";
import { BrowserRuntimeFrame } from "./runtime-frame-port.js";

export const BH03_RUNTIME_STARTUP = deepFreeze({
  protocol: "blazex.runtime-startup/1",
  adapter_identity: "blazex.popcorn-runtime-adapter/1",
  engine: "fissionvm-popcorn",
  transport_protocol: "blazex.runtime.frame/1",
  memory_pages: 256,
  bundle_virtual_path: "/bundle.avm",
  entrypoint: "Elixir.BlazeX.BH01.BrowserHost.Boot",
  readiness_event: "popcorn_app_ready",
  required_features: ["shared-memory", "threads"],
});

export class BrowserRuntimeStartup {
  #attempt = 0;
  #controller = null;
  #externalAbort = null;
  #externalSignal = null;
  #failure = null;
  #frame = null;
  #manifestGeneration = null;
  #onEvent;
  #ready = null;
  #readinessObserved = false;
  #runtimeMemoryPages = null;
  #state = "inactive";
  #lossSignal = null;

  constructor({ frameFactory = (options) => new BrowserRuntimeFrame(options), onEvent = () => {} } = {}) {
    this.frameFactory = frameFactory;
    this.#onEvent = onEvent;
  }

  async start({ gate, frameUrl, timeoutMs = 15_000, fetchImpl, cryptoImpl, webAssemblyImpl, signal } = {}) {
    if (this.#controller) startupFailure("already-active", "A runtime startup attempt is already active");
    validateTimeout(timeoutMs);
    this.#attempt += 1;
    const attempt = this.#attempt;
    this.#failure = null;
    this.#readinessObserved = false;
    this.#runtimeMemoryPages = null;
    const lossSignal = this.#lossSignal = { failure: null, listeners: new Set(), closed: false };
    this.#controller = new AbortController();
    this.#externalSignal = signal ?? null;
    this.#externalAbort = () => this.#controller?.abort(signal?.reason ?? new DOMException("Cancelled", "AbortError"));
    signal?.addEventListener("abort", this.#externalAbort, { once: true });
    if (signal?.aborted) this.#externalAbort();
    try {
      this.#transition("acquiring", { attempt_generation: attempt });
      const acquired = await acquireHostArtifacts(gate, {
        cryptoImpl,
        fetchImpl,
        signal: this.#controller.signal,
        timeoutMs,
        webAssemblyImpl,
      });
      this.#manifestGeneration = acquired.manifest_generation;
      this.#transition("starting", { acquired_bytes: acquired.total_bytes, manifest_generation: acquired.manifest_generation });
      this.#ready = deferred();
      try {
        this.#frame = this.frameFactory({ frameUrl, onEvent: (event) => this.#handleFrameEvent(event) });
        await this.#frame.attach(this.#controller.signal);
      } catch (error) {
        startupFailure("transport-attach", "The isolated runtime transport could not be attached", { cause: error instanceof Error ? error.name : String(error) });
      }
      if (this.#controller.signal.aborted) startupFailure("startup-cancelled", "Runtime startup was cancelled");
      const runtimeManifest = Object.freeze({ ...gate.manifest, startup: BH03_RUNTIME_STARTUP });
      try {
        this.#frame.start({ manifest: runtimeManifest, artifacts: acquired.artifacts, generation: attempt });
      } catch (error) {
        startupFailure("transport-start", "The isolated runtime transport rejected startup", { cause: error instanceof Error ? error.name : String(error) });
      }
      const readiness = await boundedReadiness(this.#ready.promise, timeoutMs, this.#controller.signal);
      this.#transition("ready", { manifest_generation: acquired.manifest_generation, readiness_event: readiness.name });
      return Object.freeze({
        protocol: "blazex.runtime-ready/1",
        state: "ready",
        attempt_generation: attempt,
        manifest_id: acquired.manifest_id,
        manifest_generation: acquired.manifest_generation,
        acquired_bytes: acquired.total_bytes,
        runtime_memory_pages: this.#runtimeMemoryPages,
        startup: BH03_RUNTIME_STARTUP,
        transport: this.#frame,
        subscribeLoss: (listener) => {
          if (typeof listener !== "function") throw new TypeError("A runtime loss listener is required");
          if (lossSignal.failure) listener(lossSignal.failure);
          else if (!lossSignal.closed) lossSignal.listeners.add(listener);
          return () => lossSignal.listeners.delete(listener);
        },
        release: (reason = "owner-release") => this.release(reason),
      });
    } catch (error) {
      this.#failure = errorRecord(error);
      this.#state = "failed";
      this.#emit("failed", { failure: this.#failure });
      this.#releaseOwned("startup-failed");
      throw error;
    }
  }

  release(reason = "owner-release") {
    if (!this.#controller && this.#state === "stopped") return this.snapshot();
    this.#state = "stopped";
    if (this.#lossSignal) {
      this.#lossSignal.closed = true;
      this.#lossSignal.listeners.clear();
    }
    this.#releaseOwned(reason);
    this.#emit("stopped", { reason });
    return this.snapshot();
  }

  snapshot() {
    return Object.freeze({
      protocol: "blazex.runtime-startup-state/1",
      state: this.#state,
      attempt_generation: this.#attempt,
      manifest_generation: this.#manifestGeneration,
      runtime_memory_pages: this.#runtimeMemoryPages,
      failure: this.#failure,
      owns_transport: this.#frame !== null,
    });
  }

  #handleFrameEvent(event) {
    if (!["starting", "ready"].includes(this.#state)) return;
    if (event?.protocol !== BH03_RUNTIME_STARTUP.transport_protocol) return;
    if (event.generation !== this.#attempt || event.manifest_generation !== this.#manifestGeneration) {
      this.#emit("stale-event-rejected", { event_type: event.type });
      return;
    }
    if (event.type === "runtime-memory") {
      if (!Number.isSafeInteger(event.memory_pages) || event.memory_pages !== BH03_RUNTIME_STARTUP.memory_pages) {
        this.#reject(startupError("protocol-mismatch", "Runtime memory observation is missing or incompatible"));
        return;
      }
      this.#runtimeMemoryPages = event.memory_pages;
    }
    this.#emit("transport-event", {
      event_type: event.type,
      ...(event.type === "runtime-memory" || event.type === "runtime-ready" ? { memory_pages: event.memory_pages } : {}),
    });
    if (event.type === "application-ready") {
      if (event.name !== BH03_RUNTIME_STARTUP.readiness_event || this.#state !== "starting" || this.#readinessObserved) {
        this.#reject(startupError("protocol-mismatch", "Runtime readiness was duplicate, out of order, or incompatible"));
        return;
      }
      this.#readinessObserved = true;
      queueMicrotask(() => {
        if (this.#state === "starting" && this.#readinessObserved) this.#ready?.resolve(event);
      });
      return;
    }
    if (event.type === "runtime-failed") {
      const error = event.code === "bundle-load-failed"
        ? new BlazeXHostError("bundle-load", "The application bundle could not be loaded", { class: "bundle-load", phase: "starting", reason: "bundle-load-failed" })
        : startupError("runtime-failed", "The isolated runtime failed before application readiness", { transport_code: event.code });
      this.#reject(error);
      return;
    }
    if (event.type === "runtime-exited") {
      this.#reject(startupError("runtime-exited", "The isolated runtime exited before application readiness", { status: event.status }));
    }
  }

  #reject(error) {
    if (this.#state === "ready") {
      this.#failure = errorRecord(error);
      this.#state = "failed";
      const signal = this.#lossSignal;
      signal.failure = this.#failure;
      signal.closed = true;
      const listeners = [...signal.listeners];
      signal.listeners.clear();
      this.#releaseOwned("post-readiness-protocol-failure");
      // Notify ownership before diagnostics; observers must never leave a known-dead scope ready.
      for (const listener of listeners) {
        try { listener(signal.failure); } catch { /* One observer cannot suppress another. */ }
      }
      this.#emit("failed", { failure: this.#failure });
      return;
    }
    this.#ready?.reject(error);
  }

  #releaseOwned(reason) {
    this.#controller?.abort(reason);
    try {
      this.#frame?.stop(reason);
    } catch (error) {
      this.#emit("cleanup-failed", { failure: errorRecord(error) });
    }
    this.#externalSignal?.removeEventListener("abort", this.#externalAbort);
    this.#controller = null;
    this.#externalAbort = null;
    this.#externalSignal = null;
    this.#frame = null;
    this.#ready = null;
    this.#readinessObserved = false;
    this.#runtimeMemoryPages = null;
  }

  #transition(state, details) {
    this.#state = state;
    this.#emit(state, details);
  }

  #emit(stage, details = {}) {
    this.#onEvent(Object.freeze({
      protocol: "blazex.runtime-startup/1",
      stage,
      attempt_generation: this.#attempt,
      manifest_generation: this.#manifestGeneration,
      details: Object.freeze({ ...details }),
    }));
  }
}

function boundedReadiness(promise, timeoutMs, signal) {
  return new Promise((resolve, reject) => {
    let complete = false;
    const finish = (callback, value) => {
      if (complete) return;
      complete = true;
      clearTimeout(timer);
      signal.removeEventListener("abort", cancelled);
      callback(value);
    };
    const cancelled = () => finish(reject, startupError("startup-cancelled", "Runtime startup was cancelled"));
    const timer = setTimeout(
      () => finish(reject, new BlazeXHostError("readiness-timeout", "Application readiness timed out", { class: "readiness-timeout", phase: "starting", reason: "readiness-timeout", timeout_ms: timeoutMs })),
      timeoutMs,
    );
    signal.addEventListener("abort", cancelled, { once: true });
    if (signal.aborted) cancelled();
    promise.then((value) => finish(resolve, value), (error) => finish(reject, error));
  });
}

function deferred() {
  let resolve;
  let reject;
  const promise = new Promise((resolvePromise, rejectPromise) => {
    resolve = resolvePromise;
    reject = rejectPromise;
  });
  return { promise, resolve, reject };
}

function validateTimeout(value) {
  if (!Number.isSafeInteger(value) || value < 1 || value > 60_000) {
    startupFailure("timeout-invalid", "Runtime startup timeout must be between 1 and 60000 milliseconds");
  }
}

function startupError(reason, message, details = {}) {
  return new BlazeXHostError("runtime-startup", message, { class: "runtime-startup", phase: "starting", reason, ...details });
}

function startupFailure(reason, message, details = {}) {
  throw startupError(reason, message, details);
}

function deepFreeze(value) {
  for (const item of Object.values(value)) {
    if (item && typeof item === "object") deepFreeze(item);
  }
  return Object.freeze(value);
}

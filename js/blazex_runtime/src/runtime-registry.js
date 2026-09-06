import { BrowserHostBridge } from "./host-bridge.js";
import { negotiateCompatibility } from "./compatibility.js";
import { BlazeXHostError, errorRecord } from "./internal/errors.js";
import { BH03_ROOT_LIMITS, BrowserRootRegistry } from "./root-lifecycle.js";
import { BrowserRuntimeStartup } from "./runtime-startup.js";

export const BH03_RUNTIME_REGISTRY_LIMITS = Object.freeze({
  max_scopes: 16,
  max_roots_per_scope: BH03_ROOT_LIMITS.max_roots_per_scope,
  default_shutdown_timeout_ms: 5_000,
  max_shutdown_timeout_ms: 10_000,
});

const ID = /^[a-z][a-z0-9-]{0,63}$/;
const RUNTIME_SCOPE_OWNERS = new WeakMap();

export class SharedRuntimeRegistry {
  #entries = new Map();
  #generation = 0;
  #metrics = { starts: 0, shares: 0, failures: 0, mismatches: 0, shutdowns: 0, shutdown_failures: 0 };
  #onEvent;
  #startRuntime;

  constructor({ startRuntime = (options) => new BrowserRuntimeStartup().start(options), onEvent = () => {} } = {}) {
    if (typeof startRuntime !== "function") throw new TypeError("A runtime startup function is required");
    this.#startRuntime = startRuntime;
    this.#onEvent = onEvent;
  }

  async open({ scopeId, compatibility, startupOptions = {} } = {}) {
    validateId(scopeId, "scope-id-invalid");
    let negotiated;
    try {
      negotiated = negotiateCompatibility(compatibility);
    } catch (error) {
      this.#metrics.mismatches += 1;
      throw error;
    }
    const signature = compatibilitySignature(negotiated.identities);
    const existing = this.#entries.get(scopeId);
    if (existing) {
      if (existing.compatibility !== signature) {
        this.#metrics.mismatches += 1;
        throw new BlazeXHostError("identity-mismatch", "The host scope already belongs to a different compatibility identity", { reason: "incompatible-scope-reuse", scope_id: scopeId });
      }
      if (existing.state === "failed") {
        this.#metrics.shares += 1;
        this.#emit("scope-shared", existing);
        throw failureFromRecord(existing.failure);
      }
      if (["stopping", "stopped"].includes(existing.state)) {
        throw new BlazeXHostError("runtime-shutdown", "The runtime scope is closing or stopped", { reason: "scope-not-open", scope_id: scopeId });
      }
      this.#metrics.shares += 1;
      this.#emit("scope-shared", existing);
      return existing.promise;
    }
    if (this.#entries.size >= BH03_RUNTIME_REGISTRY_LIMITS.max_scopes) {
      throw new BlazeXHostError("identity-mismatch", "The bounded runtime scope registry is full", { reason: "scope-limit", max_scopes: BH03_RUNTIME_REGISTRY_LIMITS.max_scopes });
    }

    const entry = {
      compatibility: signature,
      closePromise: null,
      failure: null,
      generation: ++this.#generation,
      promise: null,
      ready: null,
      scope: null,
      scopeId,
      state: "starting",
    };
    this.#entries.set(scopeId, entry);
    this.#metrics.starts += 1;
    this.#emit("scope-starting", entry);
    entry.promise = Promise.resolve()
      .then(() => this.#startRuntime(startupOptions))
      .then((ready) => {
        validateReadyHandle(ready);
        entry.ready = ready;
        entry.scope = new BrowserRuntimeScope({ entry, ready, onEvent: this.#onEvent });
        entry.state = "ready";
        this.#emit("scope-ready", entry);
        return entry.scope;
      })
      .catch((error) => {
        const normalized = normalizeStartupFailure(error);
        entry.failure = errorRecord(normalized);
        entry.state = "failed";
        this.#metrics.failures += 1;
        this.#emit("scope-failed", entry);
        throw normalized;
      });
    return entry.promise;
  }

  close(scopeId, { reason = "owner-close", timeoutMs = BH03_RUNTIME_REGISTRY_LIMITS.default_shutdown_timeout_ms } = {}) {
    validateId(scopeId, "scope-id-invalid");
    validateShutdownTimeout(timeoutMs);
    const entry = this.#entries.get(scopeId);
    if (!entry) {
      return Promise.reject(new BlazeXHostError("runtime-shutdown", "The runtime scope does not exist", { reason: "scope-unknown", scope_id: scopeId }));
    }
    if (entry.state === "stopped") return Promise.resolve(entry.shutdown);
    if (entry.closePromise) return entry.closePromise;
    entry.closePromise = this.#closeEntry(entry, { reason: boundedReason(reason), timeoutMs });
    return entry.closePromise;
  }

  snapshot() {
    const scopes = [...this.#entries.values()]
      .sort((left, right) => left.scopeId.localeCompare(right.scopeId))
      .map((entry) => Object.freeze({
        scope_id: entry.scopeId,
        generation: entry.generation,
        state: entry.state,
        failure: entry.failure,
      }));
    return Object.freeze({
      protocol: "blazex.runtime-registry/1",
      scopes: Object.freeze(scopes),
      metrics: Object.freeze({ ...this.#metrics, scope_count: scopes.length }),
    });
  }

  #emit(stage, entry) {
    this.#onEvent(Object.freeze({
      protocol: "blazex.runtime-registry/1",
      stage,
      scope_id: entry.scopeId,
      generation: entry.generation,
      state: entry.state,
      metrics: this.snapshot().metrics,
    }));
  }

  async #closeEntry(entry, options) {
    if (entry.state === "starting") {
      try {
        await entry.promise;
      } catch (_error) {
        // Startup owns failure cleanup. Closing retains a stopped tombstone.
      }
    }
    if (!entry.scope) {
      entry.state = "stopped";
      entry.shutdown = shutdownSnapshot(entry, { acknowledged: false, root_failures: 0 });
      this.#metrics.shutdowns += 1;
      this.#emit("scope-stopped", entry);
      return entry.shutdown;
    }

    entry.state = "stopping";
    this.#emit("scope-stopping", entry);
    try {
      const result = await RUNTIME_SCOPE_OWNERS.get(entry.scope).shutdown(options);
      entry.state = "stopped";
      entry.shutdown = shutdownSnapshot(entry, result);
      this.#metrics.shutdowns += 1;
      this.#emit("scope-stopped", entry);
      return entry.shutdown;
    } catch (error) {
      const normalized = normalizeShutdownFailure(error);
      entry.failure = errorRecord(normalized);
      entry.state = "stopped";
      const roots = entry.scope.rootsSnapshot()?.roots ?? [];
      entry.shutdown = shutdownSnapshot(entry, { acknowledged: false, root_failures: roots.filter((root) => root.state === "failed").length });
      this.#metrics.shutdown_failures += 1;
      this.#emit("scope-stop-failed", entry);
      throw normalized;
    }
  }
}

export class BrowserRuntimeScope {
  #entry;
  #onEvent;
  #ready;
  #released = false;
  #roots;

  constructor({ entry, ready, onEvent }) {
    this.#entry = entry;
    this.#ready = ready;
    this.#onEvent = onEvent;
    RUNTIME_SCOPE_OWNERS.set(this, Object.freeze({
      shutdown: (options) => this.#shutdown(options),
    }));
  }

  snapshot() {
    return Object.freeze({
      protocol: "blazex.runtime-scope/1",
      scope_id: this.#entry.scopeId,
      runtime_generation: this.#entry.generation,
      attempt_generation: this.#ready.attempt_generation,
      manifest_id: this.#ready.manifest_id,
      manifest_generation: this.#ready.manifest_generation,
      state: this.#entry.state,
      owns_runtime_release: false,
    });
  }

  roots() {
    if (this.#entry.state !== "ready") {
      throw new BlazeXHostError("root-lifecycle", "The runtime scope is not accepting roots", { reason: "scope-not-ready", state: this.#entry.state });
    }
    if (!this.#roots) {
      this.#roots = new BrowserRootRegistry({
        createBridge: (rootId) => new BrowserHostBridge({
          transport: this.#ready.transport,
          generation: this.#ready.attempt_generation,
          scenarioId: `root:${this.#entry.scopeId}:${rootId}`,
          onTrace: this.#onEvent,
        }),
        onEvent: this.#onEvent,
        scopeId: this.#entry.scopeId,
      });
    }
    return this.#roots;
  }

  rootsSnapshot() {
    return this.#roots?.snapshot() ?? null;
  }

  async #shutdown({ reason, timeoutMs }) {
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort("shutdown-timeout"), timeoutMs);
    let control = null;
    try {
      const rootSummary = this.#roots
        ? await this.#roots.shutdown({ reason, signal: controller.signal, timeoutMs })
        : Object.freeze({ root_count: 0, failures: 0 });
      if (controller.signal.aborted) throw shutdownTimeout(timeoutMs);
      control = new BrowserHostBridge({
        transport: this.#ready.transport,
        generation: this.#ready.attempt_generation,
        scenarioId: `runtime:${this.#entry.scopeId}`,
        onTrace: this.#onEvent,
      });
      const acknowledgement = await control.request("runtime.shutdown", {
        scope_id: this.#entry.scopeId,
        runtime_generation: this.#entry.generation,
        root_failures: rootSummary.failures,
      }, { signal: controller.signal, timeoutMs });
      validateShutdownAcknowledgement(acknowledgement, this.#entry);
      return Object.freeze({ acknowledged: true, root_failures: rootSummary.failures });
    } catch (error) {
      if (controller.signal.aborted) throw shutdownTimeout(timeoutMs);
      throw error;
    } finally {
      clearTimeout(timer);
      control?.stop(reason);
      this.#roots?.forceStop(reason);
      this.#release(reason);
    }
  }

  #release(reason) {
    if (this.#released) return;
    this.#released = true;
    this.#ready.release(reason);
  }
}

function validateReadyHandle(ready) {
  if (
    ready?.protocol !== "blazex.runtime-ready/1" ||
    ready.state !== "ready" ||
    !Number.isSafeInteger(ready.attempt_generation) ||
    ready.attempt_generation < 1 ||
    typeof ready.transport?.request !== "function" ||
    typeof ready.transport?.cancel !== "function" ||
    typeof ready.release !== "function"
  ) {
    throw new BlazeXHostError("runtime-startup", "Runtime startup did not return a valid ready handle", { reason: "ready-handle-invalid" });
  }
}

function normalizeStartupFailure(error) {
  if (error instanceof BlazeXHostError) return error;
  return new BlazeXHostError("runtime-startup", "The shared runtime failed to start", { reason: "startup-failed", cause: error instanceof Error ? error.name : String(error) });
}

function failureFromRecord(record) {
  return new BlazeXHostError(record?.code ?? "runtime-startup", record?.message ?? "The shared runtime scope is failed", record?.details ?? { reason: "sticky-failure" });
}

function validateId(value, reason) {
  if (typeof value !== "string" || !ID.test(value)) {
    throw new BlazeXHostError("identity-mismatch", "Runtime scope identity is invalid", { reason });
  }
}

function compatibilitySignature(identities) {
  return JSON.stringify(Object.entries(identities).sort(([left], [right]) => left.localeCompare(right)));
}

function validateShutdownTimeout(value) {
  if (!Number.isSafeInteger(value) || value < 1 || value > BH03_RUNTIME_REGISTRY_LIMITS.max_shutdown_timeout_ms) {
    throw new BlazeXHostError("runtime-shutdown", "Runtime shutdown timeout is outside the governed range", { reason: "timeout-invalid" });
  }
}

function validateShutdownAcknowledgement(result, entry) {
  if (!isPlainObject(result) || result.scope_id !== entry.scopeId) {
    throw new BlazeXHostError("ownership-violation", "The runtime acknowledged a foreign scope", { reason: "foreign-shutdown-acknowledgement", scope_id: entry.scopeId });
  }
  if (result.runtime_generation !== entry.generation) {
    throw new BlazeXHostError("stale-generation", "The runtime acknowledged a stale shutdown generation", { reason: "stale-shutdown-acknowledgement", expected: entry.generation, observed: result.runtime_generation });
  }
}

function normalizeShutdownFailure(error) {
  if (error instanceof BlazeXHostError) return error;
  return new BlazeXHostError("runtime-shutdown", "Runtime shutdown failed", { reason: "shutdown-failed", cause: error instanceof Error ? error.name : String(error) });
}

function shutdownTimeout(timeoutMs) {
  return new BlazeXHostError("shutdown-timeout", "Runtime shutdown exceeded its bounded timeout", { reason: "root-drain-or-runtime-ack-timeout", timeout_ms: timeoutMs });
}

function shutdownSnapshot(entry, result) {
  return Object.freeze({
    protocol: "blazex.runtime-shutdown/1",
    scope_id: entry.scopeId,
    runtime_generation: entry.generation,
    state: "stopped",
    acknowledged: result.acknowledged,
    root_failures: result.root_failures,
    released: true,
  });
}

function boundedReason(reason) {
  return String(reason ?? "owner-close").slice(0, 96);
}

function isPlainObject(value) {
  return value !== null && typeof value === "object" && !Array.isArray(value) && Object.getPrototypeOf(value) === Object.prototype;
}

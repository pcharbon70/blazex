import { BrowserHostBridge } from "./host-bridge.js";
import { negotiateCompatibility } from "./compatibility.js";
import { BlazeXHostError, errorRecord } from "./internal/errors.js";
import { BH03_ROOT_LIMITS, BrowserRootRegistry } from "./root-lifecycle.js";
import { BrowserRuntimeStartup } from "./runtime-startup.js";

export const BH03_RUNTIME_REGISTRY_LIMITS = Object.freeze({
  max_scopes: 16,
  max_roots_per_scope: BH03_ROOT_LIMITS.max_roots_per_scope,
});

const ID = /^[a-z][a-z0-9-]{0,63}$/;

export class SharedRuntimeRegistry {
  #entries = new Map();
  #generation = 0;
  #metrics = { starts: 0, shares: 0, failures: 0, mismatches: 0 };
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
      this.#metrics.shares += 1;
      this.#emit("scope-shared", existing);
      if (existing.state === "failed") throw failureFromRecord(existing.failure);
      return existing.promise;
    }
    if (this.#entries.size >= BH03_RUNTIME_REGISTRY_LIMITS.max_scopes) {
      throw new BlazeXHostError("identity-mismatch", "The bounded runtime scope registry is full", { reason: "scope-limit", max_scopes: BH03_RUNTIME_REGISTRY_LIMITS.max_scopes });
    }

    const entry = {
      compatibility: signature,
      failure: null,
      generation: ++this.#generation,
      promise: null,
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
}

export class BrowserRuntimeScope {
  #entry;
  #onEvent;
  #ready;
  #roots;

  constructor({ entry, ready, onEvent }) {
    this.#entry = entry;
    this.#ready = ready;
    this.#onEvent = onEvent;
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
}

function validateReadyHandle(ready) {
  if (
    ready?.protocol !== "blazex.runtime-ready/1" ||
    ready.state !== "ready" ||
    !Number.isSafeInteger(ready.attempt_generation) ||
    ready.attempt_generation < 1 ||
    typeof ready.transport?.request !== "function" ||
    typeof ready.transport?.cancel !== "function"
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

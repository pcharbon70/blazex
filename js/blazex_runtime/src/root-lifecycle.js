import { assertBoundedValue } from "./bridge-protocol.js";
import { BlazeXHostError, errorRecord } from "./internal/errors.js";

const ID = /^[a-z][a-z0-9-]{0,63}$/;
const PROTOCOL = "blazex.root-lifecycle/1";
export const BH03_ROOT_LIMITS = Object.freeze({ max_roots_per_scope: 64 });

export class BrowserRootRegistry {
  #createBridge;
  #accepting = true;
  #onEvent;
  #roots = new Map();
  #scopeId;

  constructor({ createBridge, onEvent = () => {}, scopeId }) {
    if (typeof createBridge !== "function") throw new TypeError("A root bridge factory is required");
    validateId(scopeId, "invalid-root-or-target-id");
    this.#createBridge = createBridge;
    this.#onEvent = onEvent;
    this.#scopeId = scopeId;
  }

  register(rootId) {
    validateId(rootId, "invalid-root-or-target-id");
    if (!this.#accepting) {
      return Promise.reject(new BlazeXHostError("root-lifecycle", "The root registry is not accepting registrations", { reason: "scope-not-ready", scope_id: this.#scopeId }));
    }
    if (this.#roots.has(rootId)) {
      return Promise.reject(new BlazeXHostError("duplicate-root", "The root identity is already registered or reserved", { reason: "existing-or-reserved-root-id", root_id: rootId }));
    }
    if (this.#roots.size >= BH03_ROOT_LIMITS.max_roots_per_scope) {
      return Promise.reject(new BlazeXHostError("root-lifecycle", "The bounded root registry is full", { reason: "root-limit", max_roots: BH03_ROOT_LIMITS.max_roots_per_scope }));
    }

    const handle = new BrowserRootHandle({ bridge: this.#createBridge(rootId), onEvent: this.#onEvent, rootId, scopeId: this.#scopeId });
    this.#roots.set(rootId, handle);
    return handle.register().then(
      () => handle,
      (error) => {
        if (this.#roots.get(rootId) === handle) this.#roots.delete(rootId);
        throw error;
      },
    );
  }

  snapshot() {
    const roots = [...this.#roots.values()]
      .map((root) => root.snapshot())
      .sort((left, right) => left.root_id.localeCompare(right.root_id));
    const states = Object.fromEntries(roots.map((root) => [root.root_id, root.state]));
    return Object.freeze({
      protocol: PROTOCOL,
      scope_id: this.#scopeId,
      root_count: roots.length,
      max_roots: BH03_ROOT_LIMITS.max_roots_per_scope,
      roots: Object.freeze(roots),
      states: Object.freeze(states),
      owns_runtime: false,
      owns_runtime_release: false,
      accepting: this.#accepting,
    });
  }

  async shutdown({ reason = "runtime-shutdown", signal, timeoutMs = 5_000 } = {}) {
    this.#accepting = false;
    const results = await Promise.allSettled(
      [...this.#roots.values()].map((root) => root.dispose({ signal, timeoutMs })),
    );
    for (const root of this.#roots.values()) root.stop(reason);
    return Object.freeze({
      root_count: results.length,
      failures: results.filter((result) => result.status === "rejected").length,
    });
  }

  forceStop(reason = "runtime-stopped") {
    this.#accepting = false;
    for (const root of this.#roots.values()) root.stop(reason);
  }
}

export class BrowserRootHandle {
  #bridge;
  #failure = null;
  #generation = 0;
  #onEvent;
  #pending = 0;
  #rootId;
  #scopeId;
  #state = "unregistered";
  #tail = Promise.resolve();
  #terminal = false;

  constructor({ bridge, onEvent = () => {}, rootId, scopeId }) {
    if (!bridge?.request || !bridge?.metrics) throw new TypeError("A bounded root bridge is required");
    validateId(rootId, "invalid-root-or-target-id");
    validateId(scopeId, "invalid-root-or-target-id");
    this.#bridge = bridge;
    this.#onEvent = onEvent;
    this.#rootId = rootId;
    this.#scopeId = scopeId;
  }

  register() {
    return this.#enqueue("root.register", ["unregistered"], "registered", () => ({}));
  }

  mount({ targetId, tree }) {
    validateId(targetId, "invalid-root-or-target-id");
    assertBoundedValue(tree);
    return this.#enqueue("root.mount", ["registered", "disposed"], "ready", () => ({ target_id: targetId, tree }), "mounting");
  }

  update(tree) {
    assertBoundedValue(tree);
    return this.#enqueue("root.update", ["ready"], "ready", () => ({ tree }));
  }

  move(targetId) {
    validateId(targetId, "invalid-root-or-target-id");
    return this.#enqueue("root.move", ["ready"], "ready", () => ({ target_id: targetId }), "moving");
  }

  dispose(options = {}) {
    return this.#enqueue("root.dispose", ["registered", "ready", "failed"], "disposed", () => ({}), "disposing", true, options);
  }

  stop(reason = "runtime-stopped") {
    if (this.#terminal) return;
    this.#terminal = true;
    this.#bridge.stop(reason);
    if (this.#state !== "disposed") {
      this.#failure = errorRecord(new BlazeXHostError("runtime-shutdown", "The owning runtime stopped", { reason: "scope-stopped" }));
      this.#transition("failed", "runtime.stop");
    }
  }

  snapshot() {
    return Object.freeze({
      protocol: PROTOCOL,
      scope_id: this.#scopeId,
      root_id: this.#rootId,
      root_generation: this.#generation,
      state: this.#state,
      pending: this.#pending,
      failure: this.#failure,
      owns_runtime: false,
      owns_runtime_release: false,
    });
  }

  #enqueue(operation, allowed, successState, payload, transientState = null, idempotentDisposed = false, bridgeOptions = {}) {
    this.#pending += 1;
    const task = this.#tail.then(async () => {
      if (idempotentDisposed && this.#state === "disposed") return this.snapshot();
      if (this.#terminal) {
        throw new BlazeXHostError("root-lifecycle", "The owning runtime is stopped", { reason: "scope-stopped", root_id: this.#rootId });
      }
      if (!allowed.includes(this.#state)) {
        throw new BlazeXHostError("root-lifecycle", "The root operation is not valid in its current state", {
          reason: "illegal-transition",
          operation,
          root_id: this.#rootId,
          state: this.#state,
        });
      }

      const generation = this.#generation + 1;
      const requestPayload = { root_id: this.#rootId, root_generation: generation, ...payload() };
      assertBoundedValue(requestPayload);
      this.#generation = generation;
      this.#failure = null;
      if (transientState) this.#transition(transientState, operation);

      try {
        const result = await this.#bridge.request(operation, requestPayload, bridgeOptions);
        validateAcknowledgement(result, this.#rootId, generation);
        this.#transition(successState, operation);
        return this.snapshot();
      } catch (error) {
        const normalized = normalizeRootFailure(error);
        this.#failure = errorRecord(normalized);
        this.#transition("failed", operation);
        throw normalized;
      }
    });
    this.#tail = task.catch(() => {});
    return task.finally(() => { this.#pending -= 1; });
  }

  #transition(state, operation) {
    this.#state = state;
    this.#onEvent(Object.freeze({
      protocol: PROTOCOL,
      operation,
      scope_id: this.#scopeId,
      root_id: this.#rootId,
      root_generation: this.#generation,
      state,
    }));
  }
}

function validateAcknowledgement(result, rootId, generation) {
  if (!isPlainObject(result) || result.root_id !== rootId) {
    throw new BlazeXHostError("ownership-violation", "The runtime acknowledged a foreign root", { reason: "foreign-root-acknowledgement", root_id: rootId });
  }
  if (result.root_generation !== generation) {
    throw new BlazeXHostError("stale-generation", "The runtime acknowledged the wrong root generation", { reason: "wrong-root-generation", expected: generation, observed: result.root_generation });
  }
}

function normalizeRootFailure(error) {
  if (error instanceof BlazeXHostError) return error;
  return new BlazeXHostError("root-lifecycle", "The root operation failed", { reason: "operation-failed", cause: error instanceof Error ? error.name : String(error) });
}

function validateId(value, reason) {
  if (typeof value !== "string" || !ID.test(value)) {
    throw new BlazeXHostError("root-lifecycle", "The root or target identity is invalid", { reason });
  }
}

function isPlainObject(value) {
  return value !== null && typeof value === "object" && !Array.isArray(value) && Object.getPrototypeOf(value) === Object.prototype;
}

import { BlazeXHostError, errorRecord } from "./internal/errors.js";

export const LIFECYCLE_STATES = Object.freeze([
  "not-started",
  "checking",
  "fetching",
  "instantiating",
  "loading",
  "starting",
  "ready",
  "failed",
  "stopping",
  "stopped",
]);

const TRANSITIONS = Object.freeze({
  "not-started": ["checking", "stopping"],
  checking: ["fetching", "failed", "stopping"],
  fetching: ["instantiating", "failed", "stopping"],
  instantiating: ["loading", "failed", "stopping"],
  loading: ["starting", "failed", "stopping"],
  starting: ["ready", "failed", "stopping"],
  ready: ["failed", "stopping"],
  failed: ["stopping"],
  stopping: ["stopped"],
  stopped: ["checking"],
});

const NON_RETRYABLE = new Set([
  "artifact-integrity-mismatch",
  "artifact-url-forbidden",
  "manifest-schema-unsupported",
  "manifest-startup-invalid",
  "wasm-import-contract-mismatch",
  "wasm-export-contract-mismatch",
  "prerequisite-missing",
]);

export class BrowserRuntimeLifecycle {
  #attempt = 0;
  #failure = null;
  #generation = 0;
  #metrics = { transitions: 0, failures: 0, stale_drops: 0, cleanup_failures: 0, cleanup_ms: 0 };
  #resources = [];
  #state = "not-started";
  #trace;

  constructor({ onTransition = () => {}, clock = () => performance.now() } = {}) {
    this.#trace = onTransition;
    this.clock = clock;
  }

  begin(details = {}) {
    if (!TRANSITIONS[this.#state].includes("checking")) throw new BlazeXHostError("lifecycle-start-forbidden", "The current lifecycle state cannot start", { state: this.#state });
    if (this.#state === "stopped" && this.#failure === null) this.#attempt = 0;
    this.#generation += 1;
    this.#attempt += 1;
    this.#failure = null;
    this.transition("checking", details);
    return this.#generation;
  }

  transition(next, details = {}) {
    if (!LIFECYCLE_STATES.includes(next) || !TRANSITIONS[this.#state].includes(next)) {
      throw new BlazeXHostError("lifecycle-transition-illegal", "The lifecycle transition is illegal", { from: this.#state, to: next });
    }
    const previous = this.#state;
    this.#state = next;
    this.#metrics.transitions += 1;
    this.#emit(previous, next, details);
    return this.snapshot();
  }

  fail(error, details = {}) {
    if (["failed", "stopping", "stopped"].includes(this.#state)) return this.snapshot();
    this.#failure = classifyLifecycleFailure(error, this.#attempt);
    this.#metrics.failures += 1;
    return this.transition("failed", { ...details, failure: this.#failure });
  }

  own(kind, cleanup) {
    if (typeof cleanup !== "function" || ["failed", "stopping", "stopped"].includes(this.#state)) {
      throw new BlazeXHostError("lifecycle-resource-owner-invalid", "A live lifecycle and cleanup function are required");
    }
    const resource = { kind, cleanup, released: false };
    this.#resources.push(resource);
    return () => this.#release(resource);
  }

  stop(reason = "requested") {
    if (this.#state === "stopped") return this.snapshot();
    if (this.#state !== "stopping") this.transition("stopping", { reason });
    const startedAt = this.clock();
    for (const resource of [...this.#resources].reverse()) this.#release(resource);
    this.#resources = [];
    this.#metrics.cleanup_ms = Math.max(0, this.clock() - startedAt);
    this.transition("stopped", { reason, converged: this.#metrics.cleanup_failures === 0 });
    return this.snapshot();
  }

  acceptGeneration(generation) {
    if (generation === this.#generation && !["stopping", "stopped"].includes(this.#state)) return true;
    this.#metrics.stale_drops += 1;
    return false;
  }

  canRetry(maxAttempts = 2) {
    return ["failed", "stopped"].includes(this.#state) && this.#failure?.retryable === true && this.#attempt < maxAttempts;
  }

  retryDelayMs(maxAttempts = 2) {
    if (!this.canRetry(maxAttempts)) return null;
    return Math.min(250 * (2 ** Math.max(0, this.#attempt - 1)), 1_000);
  }

  snapshot() {
    const resource_counts = Object.fromEntries(
      [...new Set(this.#resources.filter((item) => !item.released).map((item) => item.kind))]
        .sort()
        .map((kind) => [kind, this.#resources.filter((item) => !item.released && item.kind === kind).length]),
    );
    return Object.freeze({
      protocol: "blazex.lifecycle/1",
      state: this.#state,
      generation: this.#generation,
      attempt: this.#attempt,
      failure: this.#failure,
      resources: Object.freeze(resource_counts),
      metrics: Object.freeze({ ...this.#metrics }),
    });
  }

  #release(resource) {
    if (resource.released) return;
    resource.released = true;
    try {
      resource.cleanup();
    } catch (error) {
      this.#metrics.cleanup_failures += 1;
      this.#emit(this.#state, this.#state, { cleanup_error: errorRecord(error), resource: resource.kind });
    }
  }

  #emit(from, to, details) {
    this.#trace(Object.freeze({
      protocol: "blazex.lifecycle.transition/1",
      generation: this.#generation,
      attempt: this.#attempt,
      sequence: this.#metrics.transitions,
      at_ms: this.clock(),
      from,
      to,
      details: Object.freeze({ ...details }),
      resources: this.snapshot().resources,
    }));
  }
}

export function classifyLifecycleFailure(error, attempt = 1) {
  const record = errorRecord(error);
  const retryable = !NON_RETRYABLE.has(record.code) && attempt < 2;
  return Object.freeze({ ...record, retryable, action: retryable ? "reset-and-backoff" : "user-or-deployment-action" });
}

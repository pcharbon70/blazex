import { BlazeXHostError, errorRecord } from "./internal/errors.js";

export const RECOVERY_TERMINAL_STATES = Object.freeze([
  "stable", "failed", "fallback", "user-action", "stopped", "exhausted", "stale-dropped",
]);

export class BrowserRecoveryCoordinator {
  #attempts = new Map();
  #generation;
  #inflight = new Map();
  #maxAttempts;
  #scenarioId;
  #state = "stable";
  #stopped = false;
  #trace;

  constructor({ scenarioId, generation, maxAttempts = 2, onTrace = () => {} }) {
    if (!identifier(scenarioId) || !Number.isSafeInteger(generation) || generation < 1) {
      throw new TypeError("A bounded scenario identity and positive generation are required");
    }
    if (!Number.isSafeInteger(maxAttempts) || maxAttempts < 1 || maxAttempts > 3) {
      throw new TypeError("Recovery attempts must be between one and three");
    }
    this.#scenarioId = scenarioId;
    this.#generation = generation;
    this.#maxAttempts = maxAttempts;
    this.#trace = onTrace;
  }

  async run({ failureId, correlationId, generation = this.#generation, retryable, authorityBearing = false, requester = "browser-recovery-coordinator", operation }) {
    if (this.#stopped) throw new BlazeXHostError("recovery-stopped", "Recovery is stopped");
    if (![failureId, correlationId].every(identifier) || typeof operation !== "function") {
      throw new BlazeXHostError("recovery-request-invalid", "Recovery request is invalid");
    }
    if (generation !== this.#generation) {
      this.#emit("stale-dropped", { failure_id: failureId, correlation_id: correlationId, generation });
      return Object.freeze({ state: "stale-dropped", attempted: false, attempt: 0, delay_ms: null });
    }
    if (authorityBearing && requester !== "browser-recovery-coordinator") {
      throw new BlazeXHostError("recovery-owner-forbidden", "Authority-bearing retries require the browser coordinator");
    }
    if (!retryable) {
      this.#state = "failed";
      this.#emit("failed", { failure_id: failureId, correlation_id: correlationId, retryable: false });
      return Object.freeze({ state: "failed", attempted: false, attempt: 0, delay_ms: null });
    }
    if (this.#inflight.has(correlationId)) {
      throw new BlazeXHostError("recovery-duplicate", "One recovery is already active for this correlation");
    }

    const key = `${failureId}:${correlationId}`;
    const attempt = (this.#attempts.get(key) ?? 0) + 1;
    if (attempt > this.#maxAttempts) {
      this.#state = "exhausted";
      this.#emit("exhausted", { failure_id: failureId, correlation_id: correlationId, attempt: attempt - 1 });
      return Object.freeze({ state: "exhausted", attempted: false, attempt: attempt - 1, delay_ms: null });
    }

    this.#attempts.set(key, attempt);
    const controller = new AbortController();
    this.#inflight.set(correlationId, controller);
    this.#state = "recovering";
    const delayMs = [100, 250][attempt - 1] ?? 250;
    this.#emit("attempt", { failure_id: failureId, correlation_id: correlationId, attempt, delay_ms: delayMs, authority_bearing: authorityBearing });
    try {
      const value = await operation({ attempt, delayMs, signal: controller.signal });
      if (generation !== this.#generation || this.#stopped) {
        this.#emit("stale-dropped", { failure_id: failureId, correlation_id: correlationId, generation });
        return Object.freeze({ state: "stale-dropped", attempted: true, attempt, delay_ms: delayMs });
      }
      this.#state = "stable";
      this.#emit("stable", { failure_id: failureId, correlation_id: correlationId, attempt });
      return Object.freeze({ state: "stable", attempted: true, attempt, delay_ms: delayMs, value });
    } catch (error) {
      const state = attempt >= this.#maxAttempts ? "exhausted" : "failed";
      this.#state = state;
      this.#emit(state, { failure_id: failureId, correlation_id: correlationId, attempt, error: errorRecord(error) });
      return Object.freeze({ state, attempted: true, attempt, delay_ms: delayMs, error: errorRecord(error) });
    } finally {
      this.#inflight.delete(correlationId);
    }
  }

  replaceGeneration(generation) {
    if (!Number.isSafeInteger(generation) || generation <= this.#generation) {
      throw new BlazeXHostError("recovery-generation-invalid", "Replacement generation must increase");
    }
    for (const controller of this.#inflight.values()) controller.abort("generation-replaced");
    this.#inflight.clear();
    this.#generation = generation;
    this.#state = "stable";
    this.#emit("generation-replaced", { generation });
  }

  stop(reason = "requested") {
    if (this.#stopped) return this.snapshot();
    this.#stopped = true;
    for (const controller of this.#inflight.values()) controller.abort(reason);
    this.#inflight.clear();
    this.#state = "stopped";
    this.#emit("stopped", { reason });
    return this.snapshot();
  }

  snapshot() {
    return Object.freeze({
      protocol: "blazex.bh01.recovery/0.1",
      scenario_id: this.#scenarioId,
      generation: this.#generation,
      state: this.#state,
      pending: this.#inflight.size,
      attempts: Object.freeze(Object.fromEntries([...this.#attempts.entries()].sort())),
      stopped: this.#stopped,
    });
  }

  #emit(kind, details) {
    this.#trace(Object.freeze({ protocol: "blazex.bh01.recovery-trace/0.1", scenario_id: this.#scenarioId, generation: this.#generation, kind, details: Object.freeze(details) }));
  }
}

function identifier(value) {
  return typeof value === "string" && /^[A-Za-z0-9][A-Za-z0-9._:-]{0,63}$/.test(value);
}

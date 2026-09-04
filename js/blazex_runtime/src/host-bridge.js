import { BRIDGE_LIMITS, createBridgeCancel, createBridgeRequest, validateBridgeResponse } from "./bridge-protocol.js";
import { BlazeXHostError } from "./internal/errors.js";

export class BrowserHostBridge {
  #generation;
  #metrics = { requests: 0, responses: 0, failures: 0, cancellations: 0, timeouts: 0, stale_drops: 0, bytes_sent: 0, bytes_received: 0 };
  #pending = new Map();
  #scenarioId;
  #sequence = 0;
  #stopped = false;
  #trace;
  #transport;

  constructor({ transport, generation, scenarioId, onTrace = () => {} }) {
    if (!transport?.request || !transport?.cancel) throw new TypeError("A request/cancel bridge transport is required");
    this.#transport = transport;
    this.#generation = generation;
    this.#scenarioId = scenarioId;
    this.#trace = onTrace;
  }

  request(operation, payload, { timeoutMs = 5_000, signal } = {}) {
    if (this.#stopped) return Promise.reject(new BlazeXHostError("bridge-stopped", "The bridge is stopped"));
    if (this.#pending.size >= BRIDGE_LIMITS.max_concurrency) return Promise.reject(new BlazeXHostError("bridge-backpressure", "The bridge concurrency limit is reached"));
    const correlationId = randomId();
    let request;
    try {
      request = createBridgeRequest({ scenarioId: this.#scenarioId, generation: this.#generation, correlationId, sequence: ++this.#sequence, operation, payload, timeoutMs });
    } catch (error) {
      return Promise.reject(error);
    }
    this.#metrics.requests += 1;
    this.#metrics.bytes_sent += encodedBytes(request);
    this.#emit("request", request);

    return new Promise((resolve, reject) => {
      let completed = false;
      const finish = (callback, value) => {
        if (completed) {
          this.#metrics.stale_drops += 1;
          return;
        }
        completed = true;
        clearTimeout(timer);
        signal?.removeEventListener("abort", cancelFromSignal);
        this.#pending.delete(correlationId);
        callback(value);
      };
      const cancel = (reason, code) => {
        if (completed) return;
        this.#metrics.cancellations += 1;
        if (code === "bridge-timeout") this.#metrics.timeouts += 1;
        const envelope = createBridgeCancel(request, reason);
        this.#transport.cancel(envelope);
        this.#emit("cancel", envelope);
        finish(reject, new BlazeXHostError(code, code === "bridge-timeout" ? "Bridge request timed out" : "Bridge request was cancelled"));
      };
      const cancelFromSignal = () => cancel(signal?.reason, "bridge-cancelled");
      const timer = setTimeout(() => cancel("timeout", "bridge-timeout"), timeoutMs);
      this.#pending.set(correlationId, { cancel, request });
      signal?.addEventListener("abort", cancelFromSignal, { once: true });
      if (signal?.aborted) return cancelFromSignal();

      Promise.resolve(this.#transport.request(request)).then(
        (rawResponse) => {
          if (completed || this.#stopped || request.generation !== this.#generation) {
            this.#metrics.stale_drops += 1;
            return;
          }
          try {
            const response = validateBridgeResponse(rawResponse, request);
            this.#metrics.responses += 1;
            this.#metrics.bytes_received += encodedBytes(response);
            this.#emit("response", response);
            if (response.status === "ok") finish(resolve, response.result);
            else {
              this.#metrics.failures += 1;
              finish(reject, new BlazeXHostError(response.error?.code ?? "bridge-remote-error", response.error?.message ?? "The runtime rejected the request"));
            }
          } catch (error) {
            this.#metrics.failures += 1;
            finish(reject, error);
          }
        },
        (error) => {
          if (completed) {
            this.#metrics.stale_drops += 1;
            return;
          }
          this.#metrics.failures += 1;
          finish(reject, error instanceof Error ? error : new BlazeXHostError("bridge-transport-failed", "The bridge transport failed"));
        },
      );
    });
  }

  stop(reason = "requested") {
    if (this.#stopped) return;
    this.#stopped = true;
    for (const { cancel } of [...this.#pending.values()]) cancel(reason, "bridge-stopped");
    this.#generation += 1;
    this.#emit("stopped", { reason });
  }

  metrics() {
    return Object.freeze({
      ...this.#metrics,
      pending: this.#pending.size,
      generation: this.#generation,
      stopped: this.#stopped,
      timers: this.#pending.size,
      retries: 0,
    });
  }

  #emit(kind, value) {
    this.#trace(Object.freeze({ protocol: "blazex.bridge.trace/1", kind, value, metrics: this.metrics() }));
  }
}

function randomId() {
  const values = new Uint32Array(3);
  globalThis.crypto.getRandomValues(values);
  return `bx-${[...values].map((value) => value.toString(16).padStart(8, "0")).join("")}`;
}

function encodedBytes(value) {
  return new TextEncoder().encode(JSON.stringify(value)).byteLength;
}

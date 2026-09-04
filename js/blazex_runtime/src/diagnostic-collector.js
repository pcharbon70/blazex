import { BlazeXHostError, redactDiagnostic } from "./internal/errors.js";

const CATEGORIES = new Set(["supply-chain", "integrity", "transport", "compatibility", "activation", "runtime-contract", "runtime", "bridge", "render", "identity", "authority", "concurrency", "server", "resource-lifecycle"]);
const SEVERITIES = new Set(["debug", "info", "warning", "error", "blocker"]);
const ID = /^[A-Za-z0-9][A-Za-z0-9._:-]{0,95}$/;

export class DiagnosticCollector {
  #clock;
  #clockId;
  #duplicateDrops = 0;
  #events = [];
  #seen = new Set();
  #source;

  constructor({ source, clockId, clock = () => performance.now() }) {
    if (![source, clockId].every((value) => typeof value === "string" && ID.test(value))) throw new TypeError("Bounded diagnostic source and clock identities are required");
    this.#source = source;
    this.#clockId = clockId;
    this.#clock = clock;
  }

  record({ scenarioId, generation, correlationId, layer, category, severity, owner, code, userMessage, internal = {} }) {
    if (![scenarioId, correlationId, layer, owner, code].every((value) => typeof value === "string" && ID.test(value)) || !Number.isSafeInteger(generation) || generation < 1 || !CATEGORIES.has(category) || !SEVERITIES.has(severity)) {
      throw new BlazeXHostError("diagnostic-record-invalid", "Diagnostic identity or classification is invalid");
    }
    if (typeof userMessage !== "string" || userMessage.length < 1 || userMessage.length > 256) throw new BlazeXHostError("diagnostic-message-invalid", "Diagnostic user message is invalid");
    const safeInternal = redactDiagnostic(internal);
    const signature = JSON.stringify({ scenarioId, generation, correlationId, layer, category, severity, owner, code, safeInternal });
    if (this.#seen.has(signature)) {
      this.#duplicateDrops += 1;
      return null;
    }
    if (this.#events.length >= 256) throw new BlazeXHostError("diagnostic-retention-limit", "Diagnostic retention limit reached");
    this.#seen.add(signature);
    const event = Object.freeze({
      protocol: "blazex.bh01.diagnostic/0.1",
      sequence: this.#events.length + 1,
      scenario_id: scenarioId,
      generation,
      correlation_id: correlationId,
      source: this.#source,
      clock_id: this.#clockId,
      at_tick: Math.max(0, Number(this.#clock())),
      layer,
      category,
      severity,
      owner,
      code,
      user_message: redactDiagnostic(userMessage),
      internal: Object.freeze(safeInternal),
    });
    this.#events.push(event);
    return event;
  }

  summary() {
    return Object.freeze({
      protocol: "blazex.bh01.diagnostic-summary/0.1",
      count: this.#events.length,
      duplicate_drops: this.#duplicateDrops,
      developer: Object.freeze(this.#events.map(({ sequence, layer, category, severity, owner, code, correlation_id, internal }) => Object.freeze({ sequence, layer, category, severity, owner, code, correlation_id, internal }))),
      user: Object.freeze(this.#events.map(({ severity, code, user_message: message, correlation_id }) => Object.freeze({ severity, code, message, correlation_id }))),
    });
  }
}

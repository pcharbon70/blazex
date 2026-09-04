import { BlazeXHostError } from "./internal/errors.js";

const MAX_SAMPLES = 256;

export class ResourceLedger {
  #generation;
  #samples = [];
  #scenarioId;
  #unknown = new Map();
  #zeroAtDisposal;

  constructor({ scenarioId, generation, zeroAtDisposal = [] }) {
    if (!boundedIdentifier(scenarioId) || !Number.isSafeInteger(generation) || generation < 1) throw new TypeError("A bounded scenario identity and positive generation are required");
    this.#scenarioId = scenarioId;
    this.#generation = generation;
    this.#zeroAtDisposal = new Set(zeroAtDisposal);
  }

  observe(label, resources, { generation = this.#generation } = {}) {
    if (!boundedIdentifier(label) || generation !== this.#generation || !plainObject(resources)) throw new BlazeXHostError("resource-sample-invalid", "Resource sample identity or shape is invalid");
    const flat = flatten(resources);
    for (const [path, value] of Object.entries(flat)) {
      if (value === null) {
        if (!this.#unknown.has(path)) throw new BlazeXHostError("resource-unknown-unexplained", "Unknown resource observations require an explanation", { path });
      } else if (!Number.isSafeInteger(value) || value < 0) {
        throw new BlazeXHostError("resource-value-invalid", "Resource counts must be non-negative safe integers or explained unknowns", { path });
      }
    }
    if (this.#samples.length >= MAX_SAMPLES) throw new BlazeXHostError("resource-sample-limit", "Resource sample limit reached");
    const sample = Object.freeze({ label, generation, sequence: this.#samples.length + 1, resources: Object.freeze(flat) });
    this.#samples.push(sample);
    return sample;
  }

  explainUnknown(path, reason) {
    if (!boundedPath(path) || typeof reason !== "string" || reason.length < 8 || reason.length > 256) throw new BlazeXHostError("resource-unknown-explanation-invalid", "Unknown resource explanation is invalid");
    this.#unknown.set(path, reason);
  }

  report() {
    const baseline = this.#samples[0] ?? null;
    const disposed = [...this.#samples].reverse().find((sample) => sample.label === "disposed") ?? null;
    const paths = new Set(this.#samples.flatMap((sample) => Object.keys(sample.resources)));
    const peak = Object.fromEntries([...paths].sort().map((path) => [path, numericPeak(this.#samples, path)]));
    const leaks = disposed ? [...this.#zeroAtDisposal].filter((path) => disposed.resources[path] !== 0) : [...this.#zeroAtDisposal];
    return Object.freeze({
      protocol: "blazex.bh01.resource-report/0.1",
      scenario_id: this.#scenarioId,
      generation: this.#generation,
      sample_count: this.#samples.length,
      baseline,
      peak: Object.freeze(peak),
      stable: this.#samples.at(-1) ?? null,
      disposed,
      leaks: Object.freeze(leaks.sort()),
      unknown: Object.freeze(Object.fromEntries([...this.#unknown.entries()].sort())),
      converged: disposed !== null && leaks.length === 0,
    });
  }
}

function flatten(value, prefix = "", result = {}) {
  for (const [key, child] of Object.entries(value)) {
    const path = prefix ? `${prefix}.${key}` : key;
    if (plainObject(child)) flatten(child, path, result);
    else result[path] = child;
  }
  return result;
}

function numericPeak(samples, path) {
  const values = samples.map((sample) => sample.resources[path]).filter((value) => Number.isSafeInteger(value));
  return values.length ? Math.max(...values) : null;
}

function boundedIdentifier(value) { return typeof value === "string" && /^[A-Za-z0-9][A-Za-z0-9._:-]{0,63}$/.test(value); }
function boundedPath(value) { return typeof value === "string" && /^[a-z][a-z0-9_.-]{0,127}$/.test(value); }
function plainObject(value) { return value !== null && typeof value === "object" && !Array.isArray(value) && Object.getPrototypeOf(value) === Object.prototype; }

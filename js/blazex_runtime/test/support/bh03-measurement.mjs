export const BH03_MEASUREMENT_PROTOCOL = "blazex.bh03.measurement/1";

export const BH03_MEASUREMENT_LIMITS = Object.freeze({
  max_samples: 32,
  max_duration_ms: 60_000,
  runtime_memory_pages: 256,
  profile_roots: 2,
  additional_roots: 8,
  runtime_acknowledgements_after_shutdown: 43,
});

const SAMPLE_KEYS = Object.freeze([
  "iteration",
  "startup_to_ready_ms",
  "measurement_root_cycle_ms",
  "shutdown_ms",
  "runtime_memory_pages",
  "root_count_before_shutdown",
  "disposed_root_count_after_shutdown",
  "runtime_iframes_after_shutdown",
  "runtime_acknowledgements",
  "memory",
]);

export function describeSamples(values, { expectedCount } = {}) {
  if (!Array.isArray(values) || values.length < 1 || values.length > BH03_MEASUREMENT_LIMITS.max_samples) {
    throw new TypeError("Measurement samples must be a non-empty bounded array");
  }
  return describe(values.map(finiteDuration), expectedCount);
}

export function describeByteSamples(values, { expectedCount } = {}) {
  if (!Array.isArray(values) || values.length < 1 || values.length > BH03_MEASUREMENT_LIMITS.max_samples) {
    throw new TypeError("Memory samples must be a non-empty bounded array");
  }
  return describe(values.map(finiteBytes), expectedCount);
}

function describe(values, expectedCount) {
  if (expectedCount !== undefined && values.length !== expectedCount) {
    throw new TypeError(`Expected ${expectedCount} measurement samples`);
  }
  const sorted = [...values].sort((left, right) => left - right);
  const middle = Math.floor(sorted.length / 2);
  const median = sorted.length % 2 === 0
    ? (sorted[middle - 1] + sorted[middle]) / 2
    : sorted[middle];
  return Object.freeze({
    count: sorted.length,
    minimum: rounded(sorted[0]),
    median: rounded(median),
    maximum: rounded(sorted.at(-1)),
    mean: rounded(sorted.reduce((sum, value) => sum + value, 0) / sorted.length),
  });
}

export function normalizeMemoryObservation(value) {
  if (!isPlainObject(value)) throw new TypeError("Memory observation must be an object");
  if (value.available === false) {
    exactKeys(value, ["available", "reason"]);
    if (value.reason !== "browser-memory-api-unavailable") throw new TypeError("Unavailable memory observations require the governed reason");
    return Object.freeze({ available: false, api: null, reason: value.reason });
  }
  exactKeys(value, ["available", "api", "ready_bytes", "after_root_cycle_bytes", "after_shutdown_bytes"]);
  if (value.available !== true || value.api !== "performance.memory.usedJSHeapSize") {
    throw new TypeError("Available memory observations require the governed browser API");
  }
  const ready = finiteBytes(value.ready_bytes);
  const afterRoots = finiteBytes(value.after_root_cycle_bytes);
  const afterShutdown = finiteBytes(value.after_shutdown_bytes);
  return Object.freeze({
    available: true,
    api: value.api,
    ready_bytes: ready,
    after_root_cycle_bytes: afterRoots,
    after_shutdown_bytes: afterShutdown,
    observed_peak_growth_bytes: Math.max(ready, afterRoots, afterShutdown) - ready,
    ready_to_shutdown_delta_bytes: afterShutdown - ready,
  });
}

export function summarizeLifecycleSamples(samples, { expectedCount = 5 } = {}) {
  if (!Array.isArray(samples) || samples.length !== expectedCount || expectedCount < 1 || expectedCount > BH03_MEASUREMENT_LIMITS.max_samples) {
    throw new TypeError(`Expected ${expectedCount} retained lifecycle samples`);
  }
  const normalized = samples.map((sample, index) => normalizeLifecycleSample(sample, index + 1));
  const memoryAvailable = normalized.filter((sample) => sample.memory.available).length;
  return Object.freeze({
    protocol: BH03_MEASUREMENT_PROTOCOL,
    sample_count: normalized.length,
    timing_ms: Object.freeze({
      startup_to_ready: describeSamples(normalized.map((sample) => sample.startup_to_ready_ms), { expectedCount }),
      measurement_root_cycle: describeSamples(normalized.map((sample) => sample.measurement_root_cycle_ms), { expectedCount }),
      shutdown: describeSamples(normalized.map((sample) => sample.shutdown_ms), { expectedCount }),
    }),
    memory_capability: Object.freeze({ available_samples: memoryAvailable, unavailable_samples: normalized.length - memoryAvailable }),
    lifecycle: Object.freeze({
      roots_per_sample: BH03_MEASUREMENT_LIMITS.profile_roots + BH03_MEASUREMENT_LIMITS.additional_roots,
      disposed_roots_per_sample: BH03_MEASUREMENT_LIMITS.profile_roots + BH03_MEASUREMENT_LIMITS.additional_roots,
      runtime_iframes_after_shutdown: 0,
      runtime_memory_pages: BH03_MEASUREMENT_LIMITS.runtime_memory_pages,
      runtime_acknowledgements_after_shutdown: BH03_MEASUREMENT_LIMITS.runtime_acknowledgements_after_shutdown,
    }),
    release_budget: null,
    support_state: "unsupported",
  });
}

function normalizeLifecycleSample(value, expectedIteration) {
  if (!isPlainObject(value)) throw new TypeError("Lifecycle sample must be an object");
  exactKeys(value, SAMPLE_KEYS);
  if (value.iteration !== expectedIteration) throw new TypeError("Lifecycle sample iteration is not contiguous");
  const expectedRoots = BH03_MEASUREMENT_LIMITS.profile_roots + BH03_MEASUREMENT_LIMITS.additional_roots;
  if (value.runtime_memory_pages !== BH03_MEASUREMENT_LIMITS.runtime_memory_pages) throw new TypeError("Runtime memory pages diverged");
  if (value.root_count_before_shutdown !== expectedRoots || value.disposed_root_count_after_shutdown !== expectedRoots) throw new TypeError("Root cleanup counts diverged");
  if (value.runtime_iframes_after_shutdown !== 0) throw new TypeError("Runtime frame leaked after shutdown");
  if (value.runtime_acknowledgements !== BH03_MEASUREMENT_LIMITS.runtime_acknowledgements_after_shutdown) throw new TypeError("Runtime acknowledgement count diverged");
  return Object.freeze({
    ...value,
    startup_to_ready_ms: finiteDuration(value.startup_to_ready_ms),
    measurement_root_cycle_ms: finiteDuration(value.measurement_root_cycle_ms),
    shutdown_ms: finiteDuration(value.shutdown_ms),
    memory: normalizeMemoryObservation(value.memory),
  });
}

function finiteDuration(value) {
  if (!Number.isFinite(value) || value < 0 || value > BH03_MEASUREMENT_LIMITS.max_duration_ms) {
    throw new TypeError("Measurement duration is outside the governed range");
  }
  return value;
}

function finiteBytes(value) {
  if (!Number.isSafeInteger(value) || value < 0) throw new TypeError("Memory byte count must be a non-negative safe integer");
  return value;
}

function rounded(value) {
  return Math.round(value * 1_000) / 1_000;
}

function exactKeys(value, expected) {
  const actual = Object.keys(value).sort();
  const wanted = [...expected].sort();
  if (actual.length !== wanted.length || actual.some((key, index) => key !== wanted[index])) {
    throw new TypeError("Measurement observation fields diverged");
  }
}

function isPlainObject(value) {
  return value !== null && typeof value === "object" && !Array.isArray(value) && Object.getPrototypeOf(value) === Object.prototype;
}

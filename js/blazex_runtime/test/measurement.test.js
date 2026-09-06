import assert from "node:assert/strict";
import test from "node:test";

import {
  BH03_MEASUREMENT_PROTOCOL,
  describeByteSamples,
  describeSamples,
  normalizeMemoryObservation,
  summarizeLifecycleSamples,
} from "./support/bh03-measurement.mjs";

test("describes bounded timing samples deterministically", () => {
  assert.deepEqual(describeSamples([9.9999, 2, 4, 8, 6], { expectedCount: 5 }), {
    count: 5,
    minimum: 2,
    median: 6,
    maximum: 10,
    mean: 6,
  });
  assert.deepEqual(describeSamples([4, 2]), { count: 2, minimum: 2, median: 3, maximum: 4, mean: 3 });
});

test("describes byte samples without applying duration ceilings", () => {
  assert.deepEqual(describeByteSamples([120_000, 80_000], { expectedCount: 2 }), {
    count: 2,
    minimum: 80_000,
    median: 100_000,
    maximum: 120_000,
    mean: 100_000,
  });
  assert.throws(() => describeByteSamples([-1]), /non-negative safe integer/);
});

test("normalizes available and unavailable memory without inventing values", () => {
  assert.deepEqual(normalizeMemoryObservation({
    available: true,
    api: "performance.memory.usedJSHeapSize",
    ready_bytes: 100,
    after_root_cycle_bytes: 160,
    after_shutdown_bytes: 120,
  }), {
    available: true,
    api: "performance.memory.usedJSHeapSize",
    ready_bytes: 100,
    after_root_cycle_bytes: 160,
    after_shutdown_bytes: 120,
    observed_peak_growth_bytes: 60,
    ready_to_shutdown_delta_bytes: 20,
  });
  assert.deepEqual(normalizeMemoryObservation({ available: false, reason: "browser-memory-api-unavailable" }), {
    available: false,
    api: null,
    reason: "browser-memory-api-unavailable",
  });
  assert.equal(normalizeMemoryObservation({
    available: true,
    api: "performance.memory.usedJSHeapSize",
    ready_bytes: 200,
    after_root_cycle_bytes: 150,
    after_shutdown_bytes: 100,
  }).observed_peak_growth_bytes, 0);
});

test("summarizes lifecycle observations while keeping budgets and support absent", () => {
  const samples = Array.from({ length: 5 }, (_, index) => ({
    iteration: index + 1,
    startup_to_ready_ms: 100 + index,
    measurement_root_cycle_ms: 20 + index,
    shutdown_ms: 10 + index,
    runtime_memory_pages: 256,
    root_count_before_shutdown: 10,
    disposed_root_count_after_shutdown: 10,
    runtime_iframes_after_shutdown: 0,
    runtime_acknowledgements: 43,
    memory: { available: false, reason: "browser-memory-api-unavailable" },
  }));
  const summary = summarizeLifecycleSamples(samples);
  assert.equal(summary.protocol, BH03_MEASUREMENT_PROTOCOL);
  assert.equal(summary.sample_count, 5);
  assert.equal(summary.timing_ms.startup_to_ready.median, 102);
  assert.deepEqual(summary.memory_capability, { available_samples: 0, unavailable_samples: 5 });
  assert.equal(summary.lifecycle.roots_per_sample, 10);
  assert.equal(summary.release_budget, null);
  assert.equal(summary.support_state, "unsupported");
});

test("rejects malformed, unbounded, leaked, and extended observations", () => {
  assert.throws(() => describeSamples([], { expectedCount: 5 }), /non-empty bounded/);
  assert.throws(() => describeSamples([60_001]), /outside the governed range/);
  assert.throws(() => normalizeMemoryObservation({ available: false, reason: "unknown", bytes: 1 }), /fields diverged/);
  const sample = {
    iteration: 1,
    startup_to_ready_ms: 1,
    measurement_root_cycle_ms: 1,
    shutdown_ms: 1,
    runtime_memory_pages: 256,
    root_count_before_shutdown: 10,
    disposed_root_count_after_shutdown: 10,
    runtime_iframes_after_shutdown: 1,
    runtime_acknowledgements: 43,
    memory: { available: false, reason: "browser-memory-api-unavailable" },
  };
  assert.throws(() => summarizeLifecycleSamples([sample], { expectedCount: 1 }), /frame leaked/);
  assert.throws(() => summarizeLifecycleSamples([{ ...sample, runtime_iframes_after_shutdown: 0, budget_ms: 20 }], { expectedCount: 1 }), /fields diverged/);
});

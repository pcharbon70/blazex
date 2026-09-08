// Run once, before measurements. The resulting frozen record is never regenerated.
import fs from "node:fs";
import crypto from "node:crypto";
import { execFileSync } from "node:child_process";
const base = "23176db2ff608084e9f779943eadcd0eed1926af";
const target = "docs/research/assets/bh-04-baseline/blazex-bh-04-phase-10-authorization-v0.1.0.json";
if (fs.existsSync(target)) throw Error("Authorization already frozen");
if (execFileSync("git", ["rev-parse", "HEAD"], { encoding: "utf8" }).trim() !== base) throw Error("Unexpected base");
const files = execFileSync("git", ["ls-files"], { encoding: "utf8" }).trim().split("\n").filter(p =>
  p.startsWith("docs/research/assets/bh-04-baseline/") && p.endsWith(".json") ||
  p.startsWith("docs/research/assets/quality-acceptance/") && p.endsWith(".json") ||
  p.startsWith("docs/research/20-notes/architecture-decisions/") && p.endsWith(".md") ||
  /(?:mix\.lock|package-lock\.json|dependency.*\.json)$/.test(p) ||
  ["docs/research/20-notes/browser-host-implementation-milestones.md", "docs/research/60-planning/liveview-integration-deferral.md", "docs/research/60-planning/development-environment-and-deferred-qualification-policy.md"].includes(p));
const hash = p => crypto.createHash("sha256").update(fs.readFileSync(p)).digest("hex");
const record = { schema_version: "1.0.0", phase: 10, base_revision: base,
  branch: "codex/bh04-phase10-acceptance", authority: "Repository owner explicitly requested BH-04 Phase 10 implementation, one commit per section, one PR, merge, synchronize main, then delete feature branch on 2026-09-08.",
  active_predecessors: [1,2,3,4,5,6,7,9], deferred_phase: 8,
  source_bindings: Object.fromEntries(files.sort().map(p => [p, hash(p)])),
  metrics: { keyed: { scenario: "keyed-reorder", samples_per_browser: 100, retained_setup_samples: 1, threshold_ms_p95: 50 },
    queue: { runs_per_browser: 20, offered_per_run: 65, maximum: 64, coalescing: 0 },
    stale: { renderer_per_browser: 1000, effects_per_browser: 1000, seed: 731, rejection_percent: 100 },
    failure: { observation_ms: 1000, corpus: "Phase 7 effect failures plus Phase 4 malformed/apply/disposal cases, freshly executed" } },
  method: { clock: "performance.now monotonic browser clock; host elapsed clocks never combined", receipt: "immediately before submit", queue_wait: "receipt through scheduled pump start", preflight: "pump start through accepted acknowledgement (includes pure planning and first DOM preflight)", apply: "first before-operation fault hook through committed acknowledgement, includes final projection verification", paint: "second requestAnimationFrame after commit: conservative frame-opportunity proxy, NOT a compositor/physical paint measurement", statistics: "nearest-rank median/p95/p99, min/max, population SD/mean CV; retain every measured failure and the explicitly excluded setup sample", variance: "CV > 10 percent requires documented investigation; no filtering or averaging away instability", regression: "no like-for-like prior BH-04 measurement baseline; do not manufacture a regression percentage" },
  review_lenses: ["architecture", "implementation", "renderer/conformance", "security", "accessibility", "performance/reliability", "packaging/dependency", "provenance"],
  review_owner: "bh-04-owner", independence: "Single implementing agent is not an independent reviewer. Separate reviewer authorization requested; absent independent review blocks acceptance.",
  rules: { accept: "All five conditions, active suites, source freshness and independent reviews pass; no open blocker", bounded: "Only explicitly owned external qualification or independent clean-environment repeat conditions; no correctness or budget waiver", revise: "Available correctness, budget, measurement-method or review defect requires correction and affected reruns", block: "Missing active evidence, independent review or authority blocks acceptance", bh05: "Eligible only after acceptance; separately authorized, never implemented here", excluded: ["LiveView", "LocalLiveView", "BH-05 implementation", "support promotion", "public API stability", "threshold reduction", "scenario removal", "script relocation"] }
};
fs.writeFileSync(target, JSON.stringify(record, null, 2) + "\n");
console.log(target, hash(target));

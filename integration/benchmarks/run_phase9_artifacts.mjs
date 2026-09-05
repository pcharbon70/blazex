#!/usr/bin/env node

import { constants, brotliCompressSync } from "node:zlib";
import { createHash } from "node:crypto";
import { mkdir, readFile, writeFile } from "node:fs/promises";
import { dirname, resolve } from "node:path";
import { parseArgs } from "node:util";

const { values } = parseArgs({
  options: {
    profile: { type: "string" },
    revision: { type: "string" },
    "environment-id": { type: "string" },
    output: { type: "string" },
    samples: { type: "string", default: "3" },
  },
});
if (!values.profile || !values.output || !/^[0-9a-f]{40}$/.test(values.revision ?? "")) throw new Error("--profile, --output, and an exact --revision are required");
if (!/^BX-BH01-ENV-[A-Z0-9.-]+$/.test(values["environment-id"] ?? "")) throw new Error("--environment-id is required");
const repetitions = Number(values.samples);
if (!Number.isSafeInteger(repetitions) || repetitions < 3) throw new Error("--samples must be at least three");

const profile = resolve(values.profile);
const manifestBytes = await readFile(resolve(profile, "profile-assets-manifest.json"));
const manifest = JSON.parse(manifestBytes);
const rows = [];
for (const declaration of manifest.artifacts) {
  const bytes = await readFile(resolve(profile, declaration.path));
  const compressed = [];
  for (let iteration = 1; iteration <= repetitions; iteration += 1) {
    compressed.push(brotliCompressSync(bytes, { params: { [constants.BROTLI_PARAM_QUALITY]: 11 } }).byteLength);
  }
  if (new Set(compressed).size !== 1) throw new Error(`Brotli output changed across repetitions: ${declaration.path}`);
  rows.push({
    artifact_id: declaration.path,
    owner_class: ownerClass(declaration.path),
    reachability_root: "profile-assets-manifest.json",
    cache_class: declaration.cache,
    mime: declaration.mime,
    source_sha256: declaration.sha256,
    decoded_bytes: bytes.byteLength,
    brotli_quality: 11,
    brotli_bytes: compressed[0],
    repetitions,
    request_count: 1,
    profile: "PROFILE-BROWSER-PHOENIX",
    mode: "standalone-dom-feasibility",
    build_mode: "release-candidate-artifacts"
  });
}
rows.sort((left, right) => left.artifact_id.localeCompare(right.artifact_id));

const totals = {};
for (const row of rows) {
  const current = totals[row.owner_class] ?? { decoded_bytes: 0, brotli_bytes: 0, request_count: 0 };
  current.decoded_bytes += row.decoded_bytes;
  current.brotli_bytes += row.brotli_bytes;
  current.request_count += row.request_count;
  totals[row.owner_class] = current;
}
totals.total = rows.reduce((value, row) => ({
  decoded_bytes: value.decoded_bytes + row.decoded_bytes,
  brotli_bytes: value.brotli_bytes + row.brotli_bytes,
  request_count: value.request_count + row.request_count,
}), { decoded_bytes: 0, brotli_bytes: 0, request_count: 0 });

const report = {
  schema_version: "1.0.0",
  run_id: "BX-BH01-PHASE9-RUN-ARTIFACTS-LINUX-0.1",
  status: "observed",
  captured_at: new Date().toISOString(),
  source_revision: values.revision,
  environment_id: values["environment-id"],
  profile_manifest: {
    id: manifest.manifest_id,
    sha256: createHash("sha256").update(manifestBytes).digest("hex"),
    governed_files: manifest.artifacts.length
  },
  compression: { algorithm: "brotli", quality: 11, repetitions },
  artifacts: rows,
  totals,
  source_maps: manifest.source_maps,
  limitations: [
    "The application AVM currently contains reachable runtime and library modules and is not a pure authored-application payload.",
    "Brotli output is measured locally and is not evidence that the current Phoenix asset endpoint negotiates Brotli transfer.",
    "No optional component, data, chart, font, or icon package is activated in BH-01."
  ]
};
await mkdir(dirname(resolve(values.output)), { recursive: true });
await writeFile(resolve(values.output), `${JSON.stringify(report, null, 2)}\n`, "utf8");
console.log(`BH-01 Phase 9 artifact accounting: OBSERVED (${rows.length} files; ${totals.total.brotli_bytes} Brotli bytes)`);

function ownerClass(path) {
  if (path === "artifacts/AtomVM.mjs" || path === "artifacts/AtomVM.wasm") return "runtime";
  if (path === "artifacts/bundle.avm") return "application-bundle-unpruned";
  if (path.startsWith("dom/")) return "shared-ui-fixture";
  if (path.startsWith("js/") || ["host.js", "runtime-frame.js", "runtime-frame.html", "runtime-manifest.json", "index.html", "deployment-contract.json"].includes(path)) return "loader-bootstrap";
  return "other-profile-asset";
}

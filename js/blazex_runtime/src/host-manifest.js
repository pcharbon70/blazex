import { REQUIRED_COMPATIBILITY, negotiateCompatibility } from "./compatibility.js";
import { discoverHostManifest, resolveHostUrl } from "./discovery.js";
import {
  BH03_BROWSER_REQUIRED,
  BH03_DEPLOYMENT_REQUIRED,
  BH03_OPTIONAL,
  evaluateHostPrerequisites,
  mayProceedToAcquisition,
} from "./prerequisites.js";
import { BlazeXHostError } from "./internal/errors.js";

const SCHEMA_VERSION = "1.0.0";
const MAX_MANIFEST_BYTES = 65_536;
const TOP_LEVEL_FIELDS = Object.freeze(["schema_version", "manifest_id", "generation", "profile_id", "compatibility", "prerequisites", "artifacts"]);
const PREREQUISITE_FIELDS = Object.freeze(["browser_required", "deployment_required", "optional"]);
const ARTIFACT_FIELDS = Object.freeze(["id", "role", "path", "mime", "bytes", "sha256"]);
const REQUIRED_ROLES = Object.freeze(["runtime-module", "runtime-wasm", "application-bundle"]);
const ROLE_MIME = Object.freeze({
  "runtime-module": ["text/javascript", "application/javascript"],
  "runtime-wasm": ["application/wasm"],
  "application-bundle": ["application/vnd.atomvm.avm", "application/octet-stream"],
});
const ID = /^[a-z][a-z0-9-]*$/;
const MANIFEST_ID = /^BX-BH03-[A-Z0-9-]+$/;
const SHA256 = /^[0-9a-f]{64}$/;

export function validateHostManifest(value, manifestUrl) {
  if (!isPlainObject(value)) invalid("shape", {});
  exactFields(value, TOP_LEVEL_FIELDS, "top-level-fields");
  if (value.schema_version !== SCHEMA_VERSION) invalid("schema-version", { observed: value.schema_version, supported: SCHEMA_VERSION });
  if (typeof value.manifest_id !== "string" || !MANIFEST_ID.test(value.manifest_id)) invalid("manifest-id", {});
  if (!Number.isSafeInteger(value.generation) || value.generation < 1) invalid("generation", {});
  if (typeof value.profile_id !== "string" || !ID.test(value.profile_id)) invalid("profile-id", {});

  const normalizedManifestUrl = resolveHostUrl(manifestUrl, manifestUrl);
  const compatibility = negotiateCompatibility(value.compatibility);
  const prerequisites = normalizePrerequisites(value.prerequisites);
  const artifacts = normalizeArtifacts(value.artifacts, normalizedManifestUrl);

  return Object.freeze({
    schema_version: value.schema_version,
    manifest_id: value.manifest_id,
    generation: value.generation,
    profile_id: value.profile_id,
    manifest_url: normalizedManifestUrl,
    compatibility: compatibility.identities,
    prerequisites,
    artifacts,
  });
}

export async function fetchHostManifest(manifestUrl, options = {}) {
  const fetchImpl = options.fetchImpl ?? globalThis.fetch;
  if (typeof fetchImpl !== "function") invalid("fetch-unavailable", {});
  const url = resolveHostUrl(manifestUrl, options.baseUrl ?? globalThis.location?.href ?? manifestUrl);
  const controller = new AbortController();
  const abort = () => controller.abort(options.signal?.reason ?? new DOMException("Cancelled", "AbortError"));
  options.signal?.addEventListener("abort", abort, { once: true });
  const timer = setTimeout(() => controller.abort(new DOMException("Timed out", "TimeoutError")), options.timeoutMs ?? 10_000);
  try {
    if (options.signal?.aborted) abort();
    const response = await fetchImpl(new URL(url), {
      cache: "no-store",
      credentials: "same-origin",
      redirect: "error",
      signal: controller.signal,
    });
    if (controller.signal.aborted) throw controller.signal.reason;
    validateManifestResponse(response, url);
    const text = await readBoundedText(response);
    let value;
    try {
      value = JSON.parse(text);
    } catch {
      invalid("json", {});
    }
    return validateHostManifest(value, url);
  } catch (error) {
    if (error instanceof BlazeXHostError) throw error;
    invalid(options.signal?.aborted ? "fetch-cancelled" : controller.signal.aborted ? "fetch-timeout" : "fetch-failed", {
      cause: error instanceof Error ? error.name : String(error),
    });
  } finally {
    clearTimeout(timer);
    options.signal?.removeEventListener("abort", abort);
  }
}

export async function inspectHostManifest(options = {}) {
  const discovery = discoverHostManifest(options);
  const manifest = await fetchHostManifest(discovery.url, { ...options, baseUrl: options.baseUrl ?? globalThis.location?.href ?? discovery.url });
  const prerequisites = evaluateHostPrerequisites(manifest.prerequisites, options.environment ?? globalThis, { sameOriginArtifacts: true });
  return Object.freeze({
    protocol: "blazex.pre-acquisition-gate/1",
    decision: mayProceedToAcquisition(prerequisites) ? "eligible-for-artifact-acquisition" : "rejected",
    discovery,
    manifest,
    prerequisites,
    artifacts_acquired: 0,
  });
}

function normalizePrerequisites(value) {
  if (!isPlainObject(value)) invalid("prerequisites-shape", {});
  exactFields(value, PREREQUISITE_FIELDS, "prerequisite-fields");
  for (const field of PREREQUISITE_FIELDS) {
    if (!uniqueStrings(value[field])) invalid("prerequisite-list", { field });
  }
  if (
    !arraysEqual(value.browser_required, BH03_BROWSER_REQUIRED) ||
    !arraysEqual(value.deployment_required, BH03_DEPLOYMENT_REQUIRED) ||
    !arraysEqual(value.optional, BH03_OPTIONAL)
  ) {
    invalid("prerequisite-contract", {});
  }
  return Object.freeze(Object.fromEntries(PREREQUISITE_FIELDS.map((field) => [field, Object.freeze([...value[field]])])));
}

function normalizeArtifacts(value, manifestUrl) {
  if (!Array.isArray(value) || value.length !== REQUIRED_ROLES.length) invalid("artifact-count", {});
  const ids = new Set();
  const roles = new Set();
  const urls = new Set();
  const artifacts = value.map((artifact) => {
    if (!isPlainObject(artifact)) invalid("artifact-shape", {});
    exactFields(artifact, ARTIFACT_FIELDS, "artifact-fields");
    if (typeof artifact.id !== "string" || !ID.test(artifact.id) || ids.has(artifact.id)) invalid("artifact-id", { id: artifact.id });
    ids.add(artifact.id);
    if (!REQUIRED_ROLES.includes(artifact.role) || roles.has(artifact.role)) invalid("artifact-role", { role: artifact.role });
    roles.add(artifact.role);
    if (typeof artifact.path !== "string" || artifact.path.length === 0) invalid("artifact-path", { id: artifact.id });
    const url = resolveHostUrl(artifact.path, manifestUrl);
    if (urls.has(url)) invalid("artifact-url-duplicate", { id: artifact.id });
    urls.add(url);
    if (!ROLE_MIME[artifact.role].includes(artifact.mime)) invalid("artifact-mime", { id: artifact.id });
    if (!Number.isSafeInteger(artifact.bytes) || artifact.bytes < 1 || !SHA256.test(artifact.sha256)) invalid("artifact-integrity-declaration", { id: artifact.id });
    return Object.freeze({ ...artifact, url });
  });
  if (REQUIRED_ROLES.some((role) => !roles.has(role))) invalid("artifact-role-missing", {});
  return Object.freeze(artifacts);
}

function validateManifestResponse(response, expectedUrl) {
  if (!response?.ok) invalid("fetch-status", { status: response?.status });
  let observed;
  try {
    observed = new URL(response.url || expectedUrl);
  } catch {
    invalid("response-url", {});
  }
  if (response.redirected || observed.href !== expectedUrl) invalid("fetch-redirect", {});
  const mime = String(response.headers?.get("content-type") ?? "").split(";", 1)[0].trim().toLowerCase();
  if (mime !== "application/json") invalid("response-mime", { mime });
  const length = Number(response.headers?.get("content-length"));
  if (Number.isFinite(length) && length > MAX_MANIFEST_BYTES) invalid("response-too-large", {});
}

async function readBoundedText(response) {
  if (typeof response.body?.getReader !== "function") {
    const text = await response.text();
    if (new TextEncoder().encode(text).byteLength > MAX_MANIFEST_BYTES) invalid("response-too-large", {});
    return text;
  }
  const reader = response.body.getReader();
  const chunks = [];
  let length = 0;
  while (true) {
    const { done, value } = await reader.read();
    if (done) break;
    length += value.byteLength;
    if (length > MAX_MANIFEST_BYTES) {
      await reader.cancel();
      invalid("response-too-large", {});
    }
    chunks.push(value);
  }
  const bytes = new Uint8Array(length);
  let offset = 0;
  for (const chunk of chunks) {
    bytes.set(chunk, offset);
    offset += chunk.byteLength;
  }
  return new TextDecoder().decode(bytes);
}

function exactFields(value, expected, reason) {
  const observed = Object.keys(value).sort();
  const wanted = [...expected].sort();
  if (observed.length !== wanted.length || observed.some((item, index) => item !== wanted[index])) {
    invalid(reason, { expected: wanted, observed });
  }
}

function uniqueStrings(value) {
  return Array.isArray(value) && value.every((item) => typeof item === "string" && item.length > 0) && new Set(value).size === value.length;
}

function arraysEqual(left, right) {
  return left.length === right.length && left.every((item, index) => item === right[index]);
}

function isPlainObject(value) {
  return value !== null && typeof value === "object" && !Array.isArray(value) && Object.getPrototypeOf(value) === Object.prototype;
}

function invalid(reason, details) {
  throw new BlazeXHostError("manifest-invalid", "Browser profile manifest validation failed", {
    reason,
    phase: "before-artifact-acquisition",
    ...details,
  });
}

import { BlazeXHostError } from "./internal/errors.js";

const SCHEMA_VERSION = "1.0.0";
const REQUIRED_ROLES = Object.freeze(["runtime-module", "runtime-wasm", "application-bundle"]);
const ROLE_MIME = Object.freeze({
  "runtime-module": ["text/javascript", "application/javascript"],
  "runtime-wasm": ["application/wasm"],
  "application-bundle": ["application/vnd.atomvm.avm", "application/octet-stream"],
});
const SHA256 = /^[0-9a-f]{64}$/;

export async function fetchRuntimeManifest(manifestUrl, options = {}) {
  const fetchImpl = options.fetchImpl ?? globalThis.fetch;
  if (typeof fetchImpl !== "function") {
    throw new BlazeXHostError("fetch-unavailable", "The host does not provide fetch");
  }
  const resolvedUrl = new URL(manifestUrl, options.baseUrl ?? globalThis.location?.href);
  const response = await boundedFetch(resolvedUrl, {
    fetchImpl,
    timeoutMs: options.timeoutMs,
    signal: options.signal,
    cache: "no-store",
  });
  validateResponse(response, resolvedUrl, ["application/json"], null);
  let value;
  try {
    value = JSON.parse(await response.text());
  } catch (error) {
    throw new BlazeXHostError("manifest-json-invalid", "The runtime manifest is not valid JSON", {
      cause: error instanceof Error ? error.message : String(error),
    });
  }
  return validateRuntimeManifest(value, response.url || resolvedUrl.href);
}

export function validateRuntimeManifest(value, manifestUrl) {
  if (!isPlainObject(value)) {
    throw new BlazeXHostError("manifest-shape-invalid", "The runtime manifest must be an object");
  }
  if (value.schema_version !== SCHEMA_VERSION) {
    throw new BlazeXHostError("manifest-schema-unsupported", "Unsupported runtime manifest schema", {
      observed: value.schema_version,
      supported: SCHEMA_VERSION,
    });
  }
  if (typeof value.manifest_id !== "string" || !value.manifest_id.startsWith("BX-BH01-")) {
    throw new BlazeXHostError("manifest-id-invalid", "The runtime manifest identity is missing or unknown");
  }
  if (!Number.isSafeInteger(value.generation) || value.generation < 1) {
    throw new BlazeXHostError("manifest-generation-invalid", "The manifest generation must be a positive integer");
  }
  if (!Array.isArray(value.artifacts) || value.artifacts.length !== REQUIRED_ROLES.length) {
    throw new BlazeXHostError("manifest-artifacts-invalid", "The manifest must declare exactly the Phase 4 runtime artifacts");
  }

  const ids = new Set();
  const roles = new Set();
  const base = new URL(".", manifestUrl);
  const artifacts = value.artifacts.map((artifact) => {
    if (!isPlainObject(artifact)) {
      throw new BlazeXHostError("artifact-declaration-invalid", "Artifact declarations must be objects");
    }
    if (typeof artifact.id !== "string" || ids.has(artifact.id)) {
      throw new BlazeXHostError("artifact-id-duplicate", "Artifact IDs must be non-empty and unique", { id: artifact.id });
    }
    ids.add(artifact.id);
    if (!REQUIRED_ROLES.includes(artifact.role) || roles.has(artifact.role)) {
      throw new BlazeXHostError("artifact-role-invalid", "Artifact roles must be known and unique", { role: artifact.role });
    }
    roles.add(artifact.role);
    if (!Number.isSafeInteger(artifact.bytes) || artifact.bytes < 1 || !SHA256.test(artifact.sha256)) {
      throw new BlazeXHostError("artifact-integrity-declaration-invalid", "Artifact size or digest is invalid", { id: artifact.id });
    }
    if (!ROLE_MIME[artifact.role].includes(artifact.mime)) {
      throw new BlazeXHostError("artifact-mime-declaration-invalid", "Artifact MIME is not valid for its role", { id: artifact.id });
    }
    const url = new URL(artifact.path, base);
    if (url.origin !== base.origin || url.username || url.password || url.hash) {
      throw new BlazeXHostError("artifact-url-forbidden", "Artifact URLs must be same-origin values without credentials or fragments", { id: artifact.id });
    }
    return Object.freeze({ ...artifact, url: url.href });
  });

  if (REQUIRED_ROLES.some((role) => !roles.has(role))) {
    throw new BlazeXHostError("artifact-role-missing", "A required runtime artifact role is missing");
  }
  const startup = value.startup;
  if (
    !isPlainObject(startup) ||
    startup.memory_pages !== 256 ||
    startup.entrypoint !== "Elixir.BlazeX.BH01.BrowserHost.Boot" ||
    startup.readiness_event !== "popcorn_app_ready" ||
    !isUniqueStringArray(startup.allowed_import_modules) ||
    !isUniqueStringArray(startup.required_exports) ||
    !isUniqueStringArray(startup.required_features)
  ) {
    throw new BlazeXHostError("manifest-startup-invalid", "The Phase 4 startup contract is missing or unsupported");
  }
  return Object.freeze({
    ...value,
    manifest_url: new URL(manifestUrl).href,
    artifacts: Object.freeze(artifacts),
    startup: Object.freeze({ ...startup }),
  });
}

export async function fetchDeclaredArtifact(manifest, role, options = {}) {
  const artifact = manifest.artifacts.find((candidate) => candidate.role === role);
  if (!artifact) throw new BlazeXHostError("artifact-role-missing", `Missing artifact role: ${role}`);
  const response = await boundedFetch(new URL(artifact.url), {
    fetchImpl: options.fetchImpl ?? globalThis.fetch,
    timeoutMs: options.timeoutMs,
    signal: options.signal,
    cache: "no-store",
  });
  validateResponse(response, new URL(artifact.url), ROLE_MIME[role], artifact.bytes);
  const bytes = new Uint8Array(await response.arrayBuffer());
  if (bytes.byteLength !== artifact.bytes) {
    throw new BlazeXHostError("artifact-size-mismatch", "Fetched artifact size does not match its declaration", {
      id: artifact.id,
      expected: artifact.bytes,
      observed: bytes.byteLength,
    });
  }
  const observed = await digestHex(bytes, options.cryptoImpl ?? globalThis.crypto);
  if (observed !== artifact.sha256) {
    throw new BlazeXHostError("artifact-integrity-mismatch", "Fetched artifact digest does not match its declaration", {
      id: artifact.id,
      expected: artifact.sha256,
      observed,
    });
  }
  let wasmContract;
  if (role === "runtime-wasm") {
    wasmContract = inspectWasmContract(bytes, manifest.startup, artifact.id);
  }
  return Object.freeze({ declaration: artifact, bytes, ...(wasmContract ? { wasmContract } : {}) });
}

export async function acquireDeclaredArtifacts(manifest, options = {}) {
  const acquired = await Promise.all(REQUIRED_ROLES.map((role) => fetchDeclaredArtifact(manifest, role, options)));
  return Object.freeze(Object.fromEntries(acquired.map((item) => [item.declaration.role, item])));
}

async function boundedFetch(url, { fetchImpl, timeoutMs = 15_000, signal, cache }) {
  const controller = new AbortController();
  const abort = () => controller.abort(signal?.reason ?? new DOMException("Cancelled", "AbortError"));
  signal?.addEventListener("abort", abort, { once: true });
  const timer = setTimeout(() => controller.abort(new DOMException("Timed out", "TimeoutError")), timeoutMs);
  try {
    if (signal?.aborted) abort();
    const response = await fetchImpl(url, { cache, credentials: "same-origin", redirect: "error", signal: controller.signal });
    if (controller.signal.aborted) throw controller.signal.reason;
    return response;
  } catch (error) {
    const cancelled = signal?.aborted;
    const timedOut = !cancelled && controller.signal.aborted;
    const code = cancelled ? "fetch-cancelled" : timedOut ? "fetch-timeout" : "fetch-failed";
    const message = cancelled ? "Artifact fetch was cancelled" : timedOut ? "Artifact fetch timed out" : "Artifact fetch failed";
    throw new BlazeXHostError(code, message, {
      url: url.href,
      cause: error instanceof Error ? error.name : String(error),
    });
  } finally {
    clearTimeout(timer);
    signal?.removeEventListener("abort", abort);
  }
}

function validateResponse(response, expectedUrl, acceptedMime, expectedBytes) {
  if (!response?.ok) throw new BlazeXHostError("fetch-status-invalid", "Artifact fetch returned an unsuccessful status", { status: response?.status });
  const observedUrl = new URL(response.url || expectedUrl.href);
  if (response.redirected || observedUrl.href !== expectedUrl.href) {
    throw new BlazeXHostError("fetch-redirect-forbidden", "Artifact redirects and URL substitution are forbidden");
  }
  const mime = String(response.headers?.get("content-type") ?? "").split(";", 1)[0].trim().toLowerCase();
  if (!acceptedMime.includes(mime)) throw new BlazeXHostError("fetch-mime-invalid", "Artifact response MIME does not match its declaration", { mime });
  const length = response.headers?.get("content-length");
  if (expectedBytes !== null && length !== null && Number(length) !== expectedBytes) {
    throw new BlazeXHostError("fetch-length-invalid", "Artifact response length does not match its declaration");
  }
}

async function digestHex(bytes, cryptoImpl) {
  if (!cryptoImpl?.subtle) throw new BlazeXHostError("crypto-unavailable", "SubtleCrypto is required for artifact integrity");
  const digest = new Uint8Array(await cryptoImpl.subtle.digest("SHA-256", bytes));
  return [...digest].map((value) => value.toString(16).padStart(2, "0")).join("");
}

function inspectWasmContract(bytes, startup, artifactId) {
  let module;
  try {
    module = new WebAssembly.Module(bytes);
  } catch (error) {
    throw new BlazeXHostError("wasm-invalid", "The declared runtime is not valid or uses unsupported WebAssembly features", {
      id: artifactId,
      cause: error instanceof Error ? error.message : String(error),
    });
  }
  const imports = WebAssembly.Module.imports(module);
  const importModules = [...new Set(imports.map((item) => item.module))].sort();
  const allowed = [...startup.allowed_import_modules].sort();
  if (!arraysEqual(importModules, allowed)) {
    throw new BlazeXHostError("wasm-import-contract-mismatch", "WebAssembly imports do not match the declared module allowlist", {
      id: artifactId,
      expected: allowed,
      observed: importModules,
    });
  }
  const exports = WebAssembly.Module.exports(module).map((item) => item.name).sort();
  const missingExports = startup.required_exports.filter((name) => !exports.includes(name));
  if (missingExports.length > 0) {
    throw new BlazeXHostError("wasm-export-contract-mismatch", "WebAssembly is missing required exports", {
      id: artifactId,
      missing: missingExports,
    });
  }
  return Object.freeze({
    import_modules: Object.freeze(importModules),
    required_exports: Object.freeze([...startup.required_exports]),
    required_features: Object.freeze([...startup.required_features]),
    memory_imports: imports.filter((item) => item.kind === "memory").length,
  });
}

function isUniqueStringArray(value) {
  return Array.isArray(value) && value.every((item) => typeof item === "string" && item.length > 0) && new Set(value).size === value.length;
}

function arraysEqual(left, right) {
  return left.length === right.length && left.every((item, index) => item === right[index]);
}

function isPlainObject(value) {
  return value !== null && typeof value === "object" && !Array.isArray(value) && Object.getPrototypeOf(value) === Object.prototype;
}

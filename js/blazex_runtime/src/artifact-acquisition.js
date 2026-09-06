import { BlazeXHostError } from "./internal/errors.js";

export const BH03_ARTIFACT_ROLES = Object.freeze([
  "runtime-module",
  "runtime-wasm",
  "application-bundle",
]);

export const BH03_ARTIFACT_LIMITS = Object.freeze({
  "runtime-module": 2_097_152,
  "runtime-wasm": 16_777_216,
  "application-bundle": 33_554_432,
  aggregate: 52_428_800,
});

const ROLE_MIME = Object.freeze({
  "runtime-module": Object.freeze(["text/javascript", "application/javascript"]),
  "runtime-wasm": Object.freeze(["application/wasm"]),
  "application-bundle": Object.freeze(["application/vnd.atomvm.avm", "application/octet-stream"]),
});
const SHA256 = /^[0-9a-f]{64}$/;

export async function acquireHostArtifacts(gate, options = {}) {
  const manifest = validateGate(gate);
  const timeoutMs = validateTimeout(options.timeoutMs ?? 15_000);
  validateDeclarations(manifest);
  const acquired = [];
  try {
    for (const role of BH03_ARTIFACT_ROLES) {
      const declaration = manifest.artifacts.find((artifact) => artifact.role === role);
      acquired.push(await fetchArtifact(declaration, {
        cryptoImpl: options.cryptoImpl ?? globalThis.crypto,
        fetchImpl: options.fetchImpl ?? globalThis.fetch,
        signal: options.signal,
        timeoutMs,
        webAssemblyImpl: options.webAssemblyImpl ?? globalThis.WebAssembly,
      }));
    }
  } catch (error) {
    acquired.length = 0;
    throw error;
  }
  return Object.freeze({
    protocol: "blazex.artifact-acquisition/1",
    manifest_id: manifest.manifest_id,
    manifest_generation: manifest.generation,
    total_bytes: acquired.reduce((total, artifact) => total + artifact.bytes.byteLength, 0),
    artifacts: Object.freeze(Object.fromEntries(acquired.map((artifact) => [artifact.declaration.role, artifact]))),
  });
}

function validateGate(gate) {
  if (
    !isPlainObject(gate) ||
    gate.protocol !== "blazex.pre-acquisition-gate/1" ||
    gate.decision !== "eligible-for-artifact-acquisition" ||
    !isPlainObject(gate.manifest)
  ) {
    unavailable("pre-acquisition-gate", "Artifact acquisition requires a successful Phase 2 gate");
  }
  return gate.manifest;
}

function validateDeclarations(manifest) {
  if (!Array.isArray(manifest.artifacts) || manifest.artifacts.length !== BH03_ARTIFACT_ROLES.length) {
    integrity("declaration-count", "The accepted manifest must declare exactly three artifacts");
  }
  const observedRoles = manifest.artifacts.map((artifact) => artifact?.role);
  if (observedRoles.some((role, index) => role !== BH03_ARTIFACT_ROLES[index])) {
    integrity("declaration-order", "Artifact declarations are not in the required role order");
  }
  let total = 0;
  for (const artifact of manifest.artifacts) {
    if (
      typeof artifact.id !== "string" ||
      typeof artifact.url !== "string" ||
      !ROLE_MIME[artifact.role]?.includes(artifact.mime) ||
      !Number.isSafeInteger(artifact.bytes) ||
      artifact.bytes < 1 ||
      artifact.bytes > BH03_ARTIFACT_LIMITS[artifact.role] ||
      !SHA256.test(artifact.sha256)
    ) {
      integrity("declaration-limit", "An artifact declaration exceeds or violates the Phase 3 contract", { id: artifact?.id, role: artifact?.role });
    }
    let url;
    let manifestUrl;
    try {
      url = new URL(artifact.url);
      manifestUrl = new URL(manifest.manifest_url);
    } catch {
      integrity("declaration-url", "An artifact declaration has an invalid resolved URL", { id: artifact.id });
    }
    if (url.origin !== manifestUrl.origin || url.username || url.password || url.hash) {
      integrity("declaration-url", "An artifact declaration no longer satisfies the same-origin URL policy", { id: artifact.id });
    }
    total += artifact.bytes;
  }
  if (total > BH03_ARTIFACT_LIMITS.aggregate) {
    integrity("declaration-aggregate-limit", "Declared artifact bytes exceed the aggregate Phase 3 limit", { declared_bytes: total });
  }
}

async function fetchArtifact(declaration, options) {
  if (typeof options.fetchImpl !== "function") unavailable("fetch-unavailable", "The host does not provide fetch", { id: declaration.id });
  const controller = new AbortController();
  const cancel = () => controller.abort(options.signal?.reason ?? new DOMException("Cancelled", "AbortError"));
  options.signal?.addEventListener("abort", cancel, { once: true });
  const timer = setTimeout(() => controller.abort(new DOMException("Timed out", "TimeoutError")), options.timeoutMs);
  try {
    if (options.signal?.aborted) cancel();
    const expectedUrl = new URL(declaration.url);
    let response;
    try {
      response = await options.fetchImpl(expectedUrl, {
        cache: "no-store",
        credentials: "same-origin",
        redirect: "error",
        signal: controller.signal,
      });
    } catch (error) {
      const reason = options.signal?.aborted ? "fetch-cancelled" : controller.signal.aborted ? "fetch-timeout" : "fetch-network";
      unavailable(reason, "A declared runtime artifact could not be fetched", { id: declaration.id, cause: error instanceof Error ? error.name : String(error) });
    }
    if (options.signal?.aborted) unavailable("fetch-cancelled", "Artifact acquisition was cancelled", { id: declaration.id });
    if (controller.signal.aborted) unavailable("fetch-timeout", "Artifact acquisition timed out", { id: declaration.id });
    validateResponse(response, expectedUrl, declaration);
    const bytes = await readExactBytes(response, declaration, controller.signal);
    const digest = await digestHex(bytes, options.cryptoImpl, declaration.id);
    if (digest !== declaration.sha256) {
      integrity("digest", "Artifact SHA-256 does not match its accepted declaration", { id: declaration.id, expected: declaration.sha256, observed: digest });
    }
    let wasm;
    if (declaration.role === "runtime-wasm") wasm = inspectWebAssembly(bytes, options.webAssemblyImpl, declaration.id);
    return Object.freeze({
      declaration,
      bytes,
      sha256: digest,
      ...(wasm ? { webassembly: wasm } : {}),
    });
  } finally {
    clearTimeout(timer);
    options.signal?.removeEventListener("abort", cancel);
  }
}

function validateResponse(response, expectedUrl, declaration) {
  if (!response?.ok) unavailable("fetch-status", "Artifact fetch returned an unsuccessful status", { id: declaration.id, status: response?.status });
  let observedUrl;
  try {
    observedUrl = new URL(response.url || expectedUrl.href);
  } catch {
    integrity("response-url", "Artifact response URL is invalid", { id: declaration.id });
  }
  if (response.redirected || observedUrl.href !== expectedUrl.href) {
    integrity("response-redirect", "Artifact redirects or URL substitution are forbidden", { id: declaration.id });
  }
  const mime = String(response.headers?.get("content-type") ?? "").split(";", 1)[0].trim().toLowerCase();
  if (!ROLE_MIME[declaration.role].includes(mime) || mime !== declaration.mime) {
    integrity("response-mime", "Artifact response MIME does not match its declaration", { id: declaration.id, observed: mime });
  }
  const encoding = String(response.headers?.get("content-encoding") ?? "").trim().toLowerCase();
  if (encoding && encoding !== "identity") {
    integrity("response-encoding", "Artifact response encoding is not the declared identity representation", { id: declaration.id, observed: encoding });
  }
  const rawLength = response.headers?.get("content-length");
  if (rawLength !== null) {
    const length = Number(rawLength);
    if (!Number.isSafeInteger(length) || length !== declaration.bytes) {
      integrity("response-length", "Artifact response length does not match its declaration", { id: declaration.id, observed: rawLength });
    }
  }
}

async function readExactBytes(response, declaration, signal) {
  const limit = Math.min(declaration.bytes, BH03_ARTIFACT_LIMITS[declaration.role]);
  if (typeof response.body?.getReader !== "function") {
    let bytes;
    try {
      bytes = new Uint8Array(await response.arrayBuffer());
    } catch (error) {
      unavailable(signal.aborted ? "fetch-timeout" : "fetch-network", "Artifact response bytes could not be read", { id: declaration.id, cause: error instanceof Error ? error.name : String(error) });
    }
    assertExactLength(bytes.byteLength, declaration, limit);
    return bytes;
  }
  const reader = response.body.getReader();
  const chunks = [];
  let length = 0;
  try {
    while (true) {
      const { done, value } = await reader.read();
      if (done) break;
      length += value.byteLength;
      if (length > limit) {
        await reader.cancel();
        integrity("stream-oversize", "Artifact response exceeded its declared or permitted byte limit", { id: declaration.id, observed: length });
      }
      chunks.push(value);
    }
  } catch (error) {
    if (error instanceof BlazeXHostError) throw error;
    unavailable(signal.aborted ? "fetch-timeout" : "fetch-network", "Artifact response stream failed", { id: declaration.id, cause: error instanceof Error ? error.name : String(error) });
  }
  assertExactLength(length, declaration, limit);
  const bytes = new Uint8Array(length);
  let offset = 0;
  for (const chunk of chunks) {
    bytes.set(chunk, offset);
    offset += chunk.byteLength;
  }
  return bytes;
}

function assertExactLength(length, declaration, limit) {
  if (length !== declaration.bytes || length > limit) {
    integrity("size", "Artifact bytes do not match the accepted declaration", { id: declaration.id, expected: declaration.bytes, observed: length });
  }
}

async function digestHex(bytes, cryptoImpl, id) {
  if (typeof cryptoImpl?.subtle?.digest !== "function") unavailable("crypto-unavailable", "SubtleCrypto is required for artifact integrity", { id });
  let digest;
  try {
    digest = new Uint8Array(await cryptoImpl.subtle.digest("SHA-256", bytes));
  } catch (error) {
    unavailable("crypto-failed", "Artifact integrity could not be computed", { id, cause: error instanceof Error ? error.name : String(error) });
  }
  return [...digest].map((value) => value.toString(16).padStart(2, "0")).join("");
}

function inspectWebAssembly(bytes, webAssemblyImpl, id) {
  try {
    const module = new webAssemblyImpl.Module(bytes);
    return Object.freeze({ imports: webAssemblyImpl.Module.imports(module).length, exports: webAssemblyImpl.Module.exports(module).length });
  } catch (error) {
    integrity("webassembly", "The declared runtime artifact is not valid WebAssembly", { id, cause: error instanceof Error ? error.name : String(error) });
  }
}

function validateTimeout(value) {
  if (!Number.isSafeInteger(value) || value < 1 || value > 60_000) {
    unavailable("timeout-invalid", "Artifact acquisition timeout must be between 1 and 60000 milliseconds");
  }
  return value;
}

function integrity(reason, message, details = {}) {
  throw new BlazeXHostError("artifact-integrity", message, { class: "artifact-integrity", phase: "acquiring", reason, ...details });
}

function unavailable(reason, message, details = {}) {
  throw new BlazeXHostError("artifact-unavailable", message, { class: "artifact-unavailable", phase: "acquiring", reason, ...details });
}

function isPlainObject(value) {
  return value !== null && typeof value === "object" && !Array.isArray(value) && Object.getPrototypeOf(value) === Object.prototype;
}

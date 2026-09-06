const REQUIRED = Object.freeze([
  "webassembly",
  "workers",
  "modules",
  "shared-memory",
  "atomics",
  "fetch",
  "subtle-crypto",
  "secure-context",
  "cross-origin-isolation",
]);

export const BH03_BROWSER_REQUIRED = Object.freeze([
  "webassembly",
  "workers",
  "module-scripts",
  "fetch",
  "abort-controller",
  "subtle-crypto",
]);
export const BH03_DEPLOYMENT_REQUIRED = Object.freeze([
  "secure-context",
  "cross-origin-isolation",
  "same-origin-artifacts",
]);
export const BH03_OPTIONAL = Object.freeze(["wasm-streaming"]);

export function detectBrowserPrerequisites(environment = globalThis) {
  const capabilities = {
    webassembly: typeof environment.WebAssembly === "object" && typeof environment.WebAssembly.validate === "function",
    workers: typeof environment.Worker === "function",
    modules: supportsModules(environment),
    "shared-memory": supportsSharedMemory(environment),
    atomics: typeof environment.Atomics === "object" && typeof environment.SharedArrayBuffer === "function",
    fetch: typeof environment.fetch === "function" && typeof environment.AbortController === "function",
    "subtle-crypto": typeof environment.crypto?.subtle?.digest === "function",
    "secure-context": environment.isSecureContext === true,
    "cross-origin-isolation": environment.crossOriginIsolated === true,
    "wasm-streaming": typeof environment.WebAssembly?.instantiateStreaming === "function",
  };
  const missing = REQUIRED.filter((name) => capabilities[name] !== true);
  let decision = "proceed";
  let reason = "all-required-capabilities-observed";
  if (missing.some((name) => ["secure-context", "cross-origin-isolation"].includes(name))) {
    decision = "unsupported";
    reason = "deployment-policy-missing";
  } else if (missing.length > 0) {
    decision = "static-server-fallback";
    reason = "browser-capability-missing";
  } else if (!capabilities["wasm-streaming"]) {
    decision = "alternate-loading";
    reason = "buffered-wasm-loading-required";
  }
  return Object.freeze({
    protocol: "blazex.browser-prerequisites/1",
    decision,
    reason,
    missing: Object.freeze(missing),
    capabilities: Object.freeze(capabilities),
    message: accessibleMessage(decision, missing),
  });
}

export function mayActivate(result) {
  return result?.decision === "proceed" || result?.decision === "alternate-loading";
}

export function evaluateHostPrerequisites(requirements, environment = globalThis, context = {}) {
  validateRequirements(requirements);
  const capabilities = Object.freeze({
    webassembly: typeof environment.WebAssembly === "object" && typeof environment.WebAssembly.validate === "function",
    workers: typeof environment.Worker === "function",
    "module-scripts": supportsModules(environment),
    fetch: typeof environment.fetch === "function",
    "abort-controller": typeof environment.AbortController === "function",
    "subtle-crypto": typeof environment.crypto?.subtle?.digest === "function",
    "secure-context": environment.isSecureContext === true,
    "cross-origin-isolation": environment.crossOriginIsolated === true,
    "same-origin-artifacts": context.sameOriginArtifacts === true,
    "wasm-streaming": typeof environment.WebAssembly?.instantiateStreaming === "function",
  });
  const required = [...BH03_BROWSER_REQUIRED, ...BH03_DEPLOYMENT_REQUIRED];
  const missing = required.filter((name) => capabilities[name] !== true);
  const optionalMissing = BH03_OPTIONAL.filter((name) => capabilities[name] !== true);
  const decision = missing.length > 0 ? "unsupported-prerequisite" : optionalMissing.length > 0 ? "alternate-loading" : "compatible";
  return Object.freeze({
    protocol: "blazex.browser-prerequisites/2",
    decision,
    failure_class: missing.length > 0 ? "unsupported-prerequisite" : null,
    phase: "before-artifact-acquisition",
    missing: Object.freeze(missing),
    optional_missing: Object.freeze(optionalMissing),
    capabilities,
    message: hostMessage(decision, missing),
  });
}

export function mayProceedToAcquisition(result) {
  return result?.decision === "compatible" || result?.decision === "alternate-loading";
}

function supportsModules(environment) {
  const script = environment.document?.createElement?.("script");
  return script ? "noModule" in script : typeof environment.WebAssembly === "object";
}

function supportsSharedMemory(environment) {
  if (typeof environment.SharedArrayBuffer !== "function" || typeof environment.WebAssembly?.Memory !== "function") return false;
  try {
    const memory = new environment.WebAssembly.Memory({ initial: 1, maximum: 1, shared: true });
    return memory.buffer instanceof environment.SharedArrayBuffer;
  } catch {
    return false;
  }
}

function accessibleMessage(decision, missing) {
  if (decision === "proceed") return "The experimental BlazeX browser runtime can start.";
  if (decision === "alternate-loading") return "The experimental runtime can start with buffered WebAssembly loading.";
  if (decision === "unsupported") return `This deployment cannot start the experimental runtime because required isolation or secure-context policy is missing: ${missing.join(", ")}.`;
  return `This browser cannot start the experimental runtime. Server-rendered fallback remains available. Missing: ${missing.join(", ")}.`;
}

function validateRequirements(requirements) {
  const valid = requirements && arraysEqual(requirements.browser_required, BH03_BROWSER_REQUIRED) &&
    arraysEqual(requirements.deployment_required, BH03_DEPLOYMENT_REQUIRED) && arraysEqual(requirements.optional, BH03_OPTIONAL);
  if (!valid) {
    const error = new Error("Manifest prerequisite declaration does not match the BH-03 contract");
    error.name = "BlazeXPrerequisiteContractError";
    throw error;
  }
}

function arraysEqual(left, right) {
  return Array.isArray(left) && left.length === right.length && left.every((item, index) => item === right[index]);
}

function hostMessage(decision, missing) {
  if (decision === "compatible") return "The browser profile satisfies the experimental pre-acquisition gate.";
  if (decision === "alternate-loading") return "The browser profile may use buffered WebAssembly loading.";
  return `The browser profile cannot acquire runtime artifacts. Missing prerequisites: ${missing.join(", ")}.`;
}

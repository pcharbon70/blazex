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

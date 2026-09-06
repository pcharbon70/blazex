export { BlazeXHostError, errorRecord, redactDiagnostic } from "./internal/errors.js";
export { REQUIRED_COMPATIBILITY, negotiateCompatibility } from "./compatibility.js";
export { discoverHostManifest, resolveHostUrl } from "./discovery.js";
export { fetchHostManifest, inspectHostManifest, validateHostManifest } from "./host-manifest.js";
export { acquireHostArtifacts, BH03_ARTIFACT_LIMITS, BH03_ARTIFACT_ROLES } from "./artifact-acquisition.js";
export { BH03_RUNTIME_STARTUP, BrowserRuntimeStartup } from "./runtime-startup.js";
export { BH03_RUNTIME_REGISTRY_LIMITS, BrowserRuntimeScope, SharedRuntimeRegistry } from "./runtime-registry.js";
export {
  acquireDeclaredArtifacts,
  fetchDeclaredArtifact,
  fetchRuntimeManifest,
  validateRuntimeManifest,
} from "./manifest-loader.js";
export { BrowserRuntimeFrame } from "./runtime-frame-port.js";
export { BrowserRuntimeLoader } from "./runtime-loader.js";
export {
  BRIDGE_LIMITS,
  BRIDGE_OPERATIONS,
  BRIDGE_PROTOCOL,
  BRIDGE_SIGNAL_TYPES,
  assertBoundedValue,
  createBridgeCancel,
  createBridgeRequest,
  createBridgeSignal,
  validateBridgeRequest,
  validateBridgeResponse,
} from "./bridge-protocol.js";
export { BrowserHostBridge } from "./host-bridge.js";
export { BrowserRuntimeLifecycle, LIFECYCLE_STATES, classifyLifecycleFailure } from "./lifecycle.js";
export { BrowserRecoveryCoordinator, RECOVERY_TERMINAL_STATES } from "./recovery-coordinator.js";
export { ResourceLedger } from "./resource-ledger.js";
export { DiagnosticCollector } from "./diagnostic-collector.js";
export {
  BH03_BROWSER_REQUIRED,
  BH03_DEPLOYMENT_REQUIRED,
  BH03_OPTIONAL,
  detectBrowserPrerequisites,
  evaluateHostPrerequisites,
  mayActivate,
  mayProceedToAcquisition,
} from "./prerequisites.js";

export const __bh01BoundaryProbe = Object.freeze({
  scope: "browser-host-loader-only",
  status: "phase4-loader-experimental",
});

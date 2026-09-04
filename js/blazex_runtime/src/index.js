export { BlazeXHostError, errorRecord } from "./internal/errors.js";
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
export { detectBrowserPrerequisites, mayActivate } from "./prerequisites.js";

export const __bh01BoundaryProbe = Object.freeze({
  scope: "browser-host-loader-only",
  status: "phase4-loader-experimental",
});

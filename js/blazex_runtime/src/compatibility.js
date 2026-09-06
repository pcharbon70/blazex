import { BlazeXHostError } from "./internal/errors.js";

export const REQUIRED_COMPATIBILITY = Object.freeze({
  browser_host: "blazex.browser-host/1",
  runtime_adapter: "blazex.popcorn-runtime-adapter/1",
  runtime_loader: "blazex.browser-runtime-loader/1",
  profile_manifest: "blazex.browser-profile-manifest/1",
  root_lifecycle: "blazex.browser-root-lifecycle/1",
  semantic_tree: "blazex.ui-tree/1",
  renderer: "blazex.renderer/1",
  dom_projection: "blazex.dom-projection/1",
});

const KEY = /^[a-z][a-z0-9_]*$/;
const IDENTITY = /^blazex\.[a-z0-9-]+\/[1-9][0-9]*$/;

export function negotiateCompatibility(observed) {
  const entries = normalizeEntries(observed);
  const malformed = entries.some((entry) => !Array.isArray(entry) || entry.length !== 2 || !KEY.test(entry[0]) || !IDENTITY.test(entry[1]));
  if (malformed) mismatch("malformed", {});

  const counts = new Map();
  for (const [key] of entries) counts.set(key, (counts.get(key) ?? 0) + 1);
  const duplicates = [...counts].filter(([, count]) => count > 1).map(([key]) => key).sort();
  if (duplicates.length > 0) mismatch("duplicate", { keys: duplicates });

  const normalized = Object.fromEntries(entries);
  const requiredKeys = Object.keys(REQUIRED_COMPATIBILITY);
  const observedKeys = Object.keys(normalized);
  const missing = requiredKeys.filter((key) => !Object.hasOwn(normalized, key)).sort();
  if (missing.length > 0) mismatch("missing", { keys: missing });
  const unknown = observedKeys.filter((key) => !Object.hasOwn(REQUIRED_COMPATIBILITY, key)).sort();
  if (unknown.length > 0) mismatch("unknown", { keys: unknown });
  const mismatches = requiredKeys
    .filter((key) => normalized[key] !== REQUIRED_COMPATIBILITY[key])
    .sort()
    .map((key) => ({ key, expected: REQUIRED_COMPATIBILITY[key], observed: normalized[key] }));
  if (mismatches.length > 0) mismatch("mismatch", { identities: mismatches });

  return Object.freeze({
    protocol: "blazex.compatibility-negotiation/1",
    decision: "compatible",
    identities: REQUIRED_COMPATIBILITY,
  });
}

function normalizeEntries(observed) {
  if (Array.isArray(observed)) return observed;
  if (isPlainObject(observed)) return Object.entries(observed);
  mismatch("malformed", { expected: "plain-object-or-entry-array" });
}

function mismatch(reason, details) {
  throw new BlazeXHostError("identity-mismatch", "Browser-host compatibility identities do not match", {
    reason,
    phase: "before-artifact-acquisition",
    ...details,
  });
}

function isPlainObject(value) {
  return value !== null && typeof value === "object" && !Array.isArray(value) && Object.getPrototypeOf(value) === Object.prototype;
}

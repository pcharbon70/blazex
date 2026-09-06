import { BlazeXHostError } from "./internal/errors.js";

const LINK_SELECTOR = 'link[rel~="blazex-runtime-manifest"]';
const META_SELECTOR = 'meta[name="blazex-runtime-manifest"]';

export function discoverHostManifest(options = {}) {
  const baseUrl = options.baseUrl ?? globalThis.location?.href;
  const document = options.document ?? globalThis.document;
  const explicit = options.manifestUrl;
  if (explicit !== undefined && (typeof explicit !== "string" || explicit.length === 0)) {
    invalid("declaration-malformed", { source: "explicit-option" });
  }

  const declarations = documentDeclarations(document);
  if (declarations.length > 1) {
    invalid("declaration-duplicate", { sources: declarations.map((item) => item.source) });
  }

  const explicitUrl = explicit === undefined ? null : resolveHostUrl(explicit, baseUrl);
  const documentDeclaration = declarations[0] ?? null;
  const documentUrl = documentDeclaration ? resolveHostUrl(documentDeclaration.value, baseUrl) : null;
  if (explicitUrl && documentUrl && explicitUrl !== documentUrl) {
    invalid("declaration-conflict", { sources: ["explicit-option", documentDeclaration.source] });
  }
  if (!explicitUrl && !documentUrl) invalid("declaration-missing", {});

  return Object.freeze({
    protocol: "blazex.manifest-discovery/1",
    source: explicitUrl ? "explicit-option" : documentDeclaration.source,
    url: explicitUrl ?? documentUrl,
  });
}

export function resolveHostUrl(value, baseUrl) {
  if (typeof value !== "string" || value.length === 0 || typeof baseUrl !== "string" || baseUrl.length === 0) {
    invalid("url-malformed", {});
  }
  let base;
  let resolved;
  try {
    base = new URL(baseUrl);
    resolved = new URL(value, base);
  } catch {
    invalid("url-malformed", {});
  }
  if (!["http:", "https:"].includes(base.protocol) || !["http:", "https:"].includes(resolved.protocol)) {
    invalid("url-scheme-unsupported", { protocol: resolved.protocol });
  }
  if (base.username || base.password || base.hash || resolved.username || resolved.password || resolved.hash) {
    invalid("url-credentials-or-fragment", {});
  }
  if (resolved.origin !== base.origin) {
    invalid("url-cross-origin", { expected_origin: base.origin, observed_origin: resolved.origin });
  }
  return resolved.href;
}

function documentDeclarations(document) {
  if (typeof document?.querySelectorAll !== "function") return [];
  const links = [...document.querySelectorAll(LINK_SELECTOR)].map((node) => ({
    source: "link-rel-blazex-runtime-manifest",
    value: attribute(node, "href"),
  }));
  const metas = [...document.querySelectorAll(META_SELECTOR)].map((node) => ({
    source: "meta-name-blazex-runtime-manifest",
    value: attribute(node, "content"),
  }));
  const declarations = [...links, ...metas];
  if (declarations.some((item) => typeof item.value !== "string" || item.value.length === 0)) {
    invalid("declaration-malformed", { sources: declarations.map((item) => item.source) });
  }
  return declarations;
}

function attribute(node, name) {
  return node?.getAttribute?.(name) ?? node?.[name] ?? null;
}

function invalid(reason, details) {
  throw new BlazeXHostError("manifest-invalid", "Browser profile manifest discovery failed", {
    reason,
    phase: "before-artifact-acquisition",
    ...details,
  });
}

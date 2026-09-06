import assert from "node:assert/strict";
import test from "node:test";

import { BlazeXHostError, discoverHostManifest, resolveHostUrl } from "../src/index.js";

const baseUrl = "https://example.test/app/index.html";

test("discovers explicit, link, and meta manifest declarations", () => {
  assert.deepEqual(discoverHostManifest({ manifestUrl: "/bh03/manifest.json", baseUrl, document: documentWith() }), {
    protocol: "blazex.manifest-discovery/1",
    source: "explicit-option",
    url: "https://example.test/bh03/manifest.json",
  });
  assert.equal(discoverHostManifest({ baseUrl, document: documentWith({ link: "./manifest.json" }) }).source, "link-rel-blazex-runtime-manifest");
  assert.equal(discoverHostManifest({ baseUrl, document: documentWith({ meta: "./manifest.json" }) }).source, "meta-name-blazex-runtime-manifest");
});

test("allows an explicit declaration only with one equivalent document declaration", () => {
  const result = discoverHostManifest({ manifestUrl: "./manifest.json", baseUrl, document: documentWith({ link: "./manifest.json" }) });
  assert.equal(result.source, "explicit-option");
  assert.throws(
    () => discoverHostManifest({ manifestUrl: "./one.json", baseUrl, document: documentWith({ link: "./two.json" }) }),
    reason("declaration-conflict"),
  );
});

test("rejects absent and duplicate document declarations", () => {
  assert.throws(() => discoverHostManifest({ baseUrl, document: documentWith() }), reason("declaration-missing"));
  assert.throws(() => discoverHostManifest({ baseUrl, document: documentWith({ link: "./one.json", meta: "./two.json" }) }), reason("declaration-duplicate"));
});

test("rejects cross-origin, credentialed, fragmented, and unsupported URLs", () => {
  assert.throws(() => resolveHostUrl("https://other.test/manifest.json", baseUrl), reason("url-cross-origin"));
  assert.throws(() => resolveHostUrl("https://user:pass@example.test/manifest.json", baseUrl), reason("url-credentials-or-fragment"));
  assert.throws(() => resolveHostUrl("./manifest.json#stale", baseUrl), reason("url-credentials-or-fragment"));
  assert.throws(() => resolveHostUrl("data:application/json,{}", baseUrl), reason("url-scheme-unsupported"));
});

function documentWith({ link, meta } = {}) {
  return {
    querySelectorAll(selector) {
      if (selector.startsWith("link")) return link === undefined ? [] : [{ getAttribute: () => link }];
      return meta === undefined ? [] : [{ getAttribute: () => meta }];
    },
  };
}

function reason(value) {
  return (error) => error instanceof BlazeXHostError && error.code === "manifest-invalid" && error.details.reason === value;
}

import test from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs";
import { decode } from "../src/render-transaction-v2.js";
import { Document } from "./support/atomic-fake-dom.js";
import { runAtomicDOMScenarios } from "../../../integration/bh-04/atomic-dom-scenarios.js";
test("shared browser matrix also passes in the strict fake DOM", async () => {
  const rows = fs.readFileSync(new URL("../../../integration/bh-04/atomic-dom-fixtures-v0.1.0.txt", import.meta.url), "utf8").trim().split("\n").map(l => decode(Buffer.from(l.split("|")[1], "base64")));
  const document = new Document(), result = await runAtomicDOMScenarios(document, rows);
  assert.equal(result.result, "passed"); assert.equal(result.counters.injected_boundaries, 1204); assert.equal(document.body.childNodes.length, 0);
});

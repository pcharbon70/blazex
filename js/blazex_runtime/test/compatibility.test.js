import assert from "node:assert/strict";
import test from "node:test";

import { BlazeXHostError, REQUIRED_COMPATIBILITY, negotiateCompatibility } from "../src/index.js";

test("accepts and normalizes the exact BH-03 compatibility table", () => {
  const result = negotiateCompatibility({ ...REQUIRED_COMPATIBILITY });
  assert.equal(result.protocol, "blazex.compatibility-negotiation/1");
  assert.equal(result.decision, "compatible");
  assert.deepEqual(result.identities, REQUIRED_COMPATIBILITY);
  assert.equal(Object.isFrozen(result), true);
});

test("rejects missing and unknown compatibility identities", () => {
  const { renderer: _renderer, ...missing } = REQUIRED_COMPATIBILITY;
  assert.throws(() => negotiateCompatibility(missing), error("missing"));
  assert.throws(() => negotiateCompatibility({ ...REQUIRED_COMPATIBILITY, future_contract: "blazex.future/1" }), error("unknown"));
});

test("rejects duplicate and malformed compatibility identities", () => {
  const duplicate = [...Object.entries(REQUIRED_COMPATIBILITY), ["renderer", "blazex.renderer/1"]];
  assert.throws(() => negotiateCompatibility(duplicate), error("duplicate"));
  assert.throws(() => negotiateCompatibility({ renderer: "not-an-identity" }), error("malformed"));
  assert.throws(() => negotiateCompatibility(null), error("malformed"));
});

test("rejects mismatched versions before artifact acquisition", () => {
  const incompatible = { ...REQUIRED_COMPATIBILITY, renderer: "blazex.renderer/2" };
  assert.throws(
    () => negotiateCompatibility(incompatible),
    (caught) => error("mismatch")(caught) && caught.details.phase === "before-artifact-acquisition",
  );
});

function error(reason) {
  return (caught) => caught instanceof BlazeXHostError && caught.code === "identity-mismatch" && caught.details.reason === reason;
}

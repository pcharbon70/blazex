import test from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs";
import { gunzipSync } from "node:zlib";
import { sha } from "./acceptance-report.mjs";
import { validateCorrectiveMeasurements } from "./corrective-report.mjs";
const raw = JSON.parse(gunzipSync(fs.readFileSync("docs/research/assets/bh-04-correction/stale-queue.json.gz")));
const auth = JSON.parse(fs.readFileSync("docs/research/assets/bh-04-baseline/blazex-bh-04-phase-10-authorization-v0.1.0.json"));
test("current browser evidence has seeded stale rejection and unchanged live state", () => assert.equal(validateCorrectiveMeasurements(raw, auth).result, "passed"));
for (const [name, mutate] of Object.entries({
  generation: r => r.stale[0].generation = 999999,
  seed: r => r.stale[0].seed++,
  delay: r => r.stale[0].delay_ms = 999,
  acknowledgement: r => r.stale[0].ack.transaction_id = "tx-" + "f".repeat(24),
  rejection: r => r.stale[0].ack.state = "committed",
  state: r => r.stale[0].after.revision++,
  effect: r => r.stale[1000].effect_id = "forged",
  effectState: r => r.stale[1000].after.active++,
  queueIdentity: r => r.queues[0].outcomes[0].ack.generation++,
  queueTiming: r => r.queues[0].outcomes[0].terminal = -1,
  queueRejection: r => r.queues[0].outcomes[1].ack.state = "committed"
})) test("reject " + name + " even with refreshed trace hashes", () => {
  const copy = structuredClone(raw); mutate(copy.results[0]);
  for (const row of [...copy.results[0].stale, ...copy.results[0].queues]) {
    const { trace_sha256, ...body } = row; row.trace_sha256 = sha(JSON.stringify(body));
  }
  assert.throws(() => validateCorrectiveMeasurements(copy, auth));
});

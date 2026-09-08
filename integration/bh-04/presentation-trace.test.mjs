import test from "node:test";
import assert from "node:assert/strict";
import { chromePresentation, firefoxPresentation, presentationReport } from "./presentation-trace.mjs";
const chrome = () => [
  ...[["receipt", 1000], ["committed", 2000], ["observation-end", 10000]].map(([name, ts]) => ({ name: "bh04-presentation-0-" + name, ph: "I", pid: 1, ts })),
  { name: "Paint", pid: 1, ts: 3000 },
  ...[["b", 4000], ["e", 6000]].map(([ph, ts]) => ({ name: "SubmitCompositorFrameToPresentationCompositorFrame", pid: 1, tid: 2, id2: { local: "0x1" }, ph, ts }))
];
test("Chrome uses a native same-process paired presentation endpoint", () => {
  assert.equal(chromePresentation(chrome(), 0).latency_ms, 5);
  for (const mutate of [e => e.pop(), e => e[3].pid++, e => e[5].id2.local = "0x2", e => e[5].ts = 11000,
    e => e.push({ ...e[4], id2: { local: "0x2" } }, { ...e[5], ts: 7000, id2: { local: "0x2" } })]) {
    const events = chrome(); mutate(events); assert.throws(() => chromePresentation(events, 0));
  }
});
test("coincident Chrome endpoints retain all native IDs, not a unique frame claim", () => {
  const events = chrome(); events.push({ ...events[4], id2: { local: "0x2" } }, { ...events[5], id2: { local: "0x2" } });
  assert.deepEqual(chromePresentation(events, 0).presentation_ids, ["0x1", "0x2"]);
  events.at(-1).tid = 3; assert.throws(() => chromePresentation(events, 0));
});
const gecko = () => [
  ...[["receipt", 1], ["committed", 2], ["observation-end", 10]].map(([name, start]) => ({ name: "UserTiming", pid: 1, start, data: { name: "bh04-presentation-0-" + name, innerWindowID: 7 } })),
  { name: "ViewManagerFlush", pid: 1, start: 3, end: 4, data: { innerWindowID: 7, name: "Transaction ID: 2" } },
  { name: "ContentPaint Payload Presented", pid: 2, thread: "Compositor", start: 3.5, end: 6 },
  { name: "DOMEvent", pid: 1, start: 7, data: { innerWindowID: 7, eventType: "MozAfterPaint" } }
];
test("Gecko requires the owning window flush, payload and paint notification", () => {
  assert.equal(firefoxPresentation(gecko(), 0).latency_ms, 5);
  for (const mutate of [e => e.pop(), e => e[3].data.innerWindowID++, e => e[4].start = 4.1, e => e[4].end = 11,
    e => e.push({ ...e[4] }), e => e[5].start = 5]) {
    const events = gecko(); mutate(events); assert.throws(() => firefoxPresentation(events, 0));
  }
});
test("a failed native sample is retained and prevents a passing summary", () => {
  const samples = Array.from({ length: 101 }, (_, sample) => ({ sample, warmup: sample === 0, error: "missing observation" }));
  const report = presentationReport("chrome", [], samples);
  assert.equal(report.results.length, 101); assert.equal(report.statistics, null); assert.equal(report.result, "revise");
});

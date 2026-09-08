import assert from "node:assert/strict";
import { statistics } from "./acceptance-report.mjs";
const unique = (rows, label) => { assert.equal(rows.length, 1, label); return rows[0]; };
const prefix = n => `bh04-presentation-${n}-`;

export function chromePresentation(events, sample) {
  const mark = name => unique(events.filter(e => e.name === prefix(sample) + name && e.ph === "I"), name);
  const receipt = mark("receipt"), commit = mark("committed"), limit = mark("observation-end");
  assert.equal(receipt.pid, commit.pid); assert.equal(receipt.pid, limit.pid);
  const paints = events.filter(e => e.name === "Paint" && e.pid === receipt.pid && e.ts >= commit.ts && e.ts < limit.ts);
  assert.ok(paints.length, "missing native Paint");
  const pairs = events.filter(e => e.name === "SubmitCompositorFrameToPresentationCompositorFrame" && e.ph === "b" && e.pid === receipt.pid && e.ts >= paints[0].ts && e.ts < limit.ts).map(begin => {
    const end = unique(events.filter(e => e.name === begin.name && e.ph === "e" && e.pid === begin.pid && e.id2?.local === begin.id2?.local && e.ts >= begin.ts && e.ts < limit.ts), "presentation end");
    assert.equal(typeof begin.id2?.local, "string"); return { begin, end };
  });
  assert.ok(pairs.length, "missing presentation chain");
  // Distinct native trace IDs can describe the exact same observed endpoint.
  // Preserve every ID; never merge different times, processes or threads.
  const endpoints = new Set(pairs.map(({ begin, end }) => JSON.stringify([begin.pid, begin.tid, begin.ts, end.pid, end.tid, end.ts])));
  assert.equal(endpoints.size, 1, "ambiguous presentation endpoints");
  const { begin, end } = pairs[0];
  assert.ok(receipt.ts <= commit.ts && commit.ts <= end.ts);
  return { receipt_ms: receipt.ts / 1000, commit_ms: commit.ts / 1000, presentation_ms: end.ts / 1000,
    latency_ms: (end.ts - receipt.ts) / 1000, pid: receipt.pid, paint_ts: paints.map(e => e.ts), presentation_ids: pairs.map(p => p.begin.id2.local) };
}

export function geckoMarkers(profile) {
  const rows = [], origin = profile.meta.startTime;
  function visit(process) {
    const offset = process.meta.startTime - origin;
    for (const thread of process.threads ?? []) {
      const s = thread.markers.schema;
      for (const row of thread.markers.data) rows.push({ name: thread.stringTable[row[s.name]], start: row[s.startTime] == null ? null : row[s.startTime] + offset,
        end: row[s.endTime] == null ? null : row[s.endTime] + offset, data: row[s.data], pid: thread.pid, tid: thread.tid, thread: thread.name });
    }
    for (const child of process.processes ?? []) visit(child);
  }
  visit(profile); return rows;
}

export function firefoxPresentation(rows, sample) {
  const mark = name => unique(rows.filter(e => e.name === "UserTiming" && e.data?.name === prefix(sample) + name), name);
  const receipt = mark("receipt"), commit = mark("committed"), limit = mark("observation-end"), window = receipt.data.innerWindowID;
  assert.ok(window); assert.equal(commit.data.innerWindowID, window); assert.equal(limit.data.innerWindowID, window);
  const flushes = rows.filter(e => e.name === "ViewManagerFlush" && e.pid === receipt.pid && e.data?.innerWindowID === window && e.start >= commit.start && e.end < limit.start && /Transaction ID: \d+/.test(e.data.name));
  const chains = flushes.flatMap(flush => rows.filter(e => e.name === "ContentPaint Payload Presented" && e.thread === "Compositor" && e.start >= flush.start && e.start <= flush.end && e.end >= commit.start && e.end < limit.start).map(presentation => ({ flush, presentation })));
  const { flush, presentation } = unique(chains, "ambiguous or missing Gecko presentation chain");
  assert.ok(rows.some(e => e.name === "DOMEvent" && e.pid === receipt.pid && e.data?.innerWindowID === window && e.data.eventType === "MozAfterPaint" && e.start >= presentation.end && e.start < limit.start), "missing owning-window paint notification");
  assert.ok(receipt.start <= commit.start);
  return { receipt_ms: receipt.start, commit_ms: commit.start, presentation_ms: presentation.end, latency_ms: presentation.end - receipt.start,
    pid: receipt.pid, inner_window_id: window, transaction: flush.data.name, flush_start: flush.start, payload_start: presentation.start, compositor_pid: presentation.pid };
}

export function presentationReport(browser, native, samples) {
  assert.ok(samples.length <= 101);
  const rows = browser === "firefox" ? geckoMarkers(native) : native;
  const results = samples.map((sample, i) => {
    try {
      assert.equal(sample.sample, i); assert.equal(sample.warmup, i === 0); assert.equal(sample.error, null); assert.equal(sample.ack.state, "committed");
      const times = ["receipt", "pump", "accepted", "apply", "committed", "observation-end"].map(k => sample.marks[k]);
      assert.ok(times.every((t, j) => Number.isFinite(t) && (!j || t >= times[j - 1])), "invalid transaction timing");
      if (browser === "firefox") assert.ok(sample.paints.some(p => p.trusted), "no trusted content paint notification");
      return { sample: i, warmup: sample.warmup, ...(browser === "chrome" ? chromePresentation(rows, i) : firefoxPresentation(rows, i)), result: "passed" };
    } catch (error) { return { sample: i, warmup: sample.warmup, result: "failed", error: String(error) }; }
  });
  const complete = samples.length === 101 && results.every(r => r.result === "passed");
  const summary = complete ? statistics(results.slice(1).map(r => r.latency_ms)) : null;
  return { browser, results, statistics: summary, variance_investigation_required: summary ? summary.cv_percent > 10 : null,
    result: complete && summary.p95 <= 50 ? "measurements-within-budget-not-acceptance" : "revise", support_state: "unsupported" };
}

import fs from "node:fs";
import http from "node:http";
import path from "node:path";
import os from "node:os";
import { fileURLToPath } from "node:url";
import { gzipSync } from "node:zlib";
import { chromium, firefox } from "../../js/blazex_runtime/node_modules/playwright-core/index.mjs";
import { decode } from "../../js/blazex_runtime/src/render-transaction-v2.js";
import { sha } from "./acceptance-report.mjs";
import { presentationReport } from "./presentation-trace.mjs";
const root = fileURLToPath(new URL("../../", import.meta.url)), outputDir = process.argv[2];
if (!outputDir || !fs.statSync(outputDir).isDirectory()) throw Error("Existing output directory required");
const fixturePath = "integration/bh-04/atomic-dom-fixtures-v0.1.0.txt";
const fixture = fs.readFileSync(path.join(root, fixturePath), "utf8").trim().split("\n").map(l => decode(Buffer.from(l.split("|")[1], "base64"))).find(r => r.name === "keyed-reorder");
const files = [fixturePath, "integration/bh-04/presentation-browser.mjs", "integration/bh-04/presentation-scenarios.js", "integration/bh-04/presentation-trace.mjs",
  ...fs.readdirSync(path.join(root, "js/blazex_runtime/src")).filter(p => p.endsWith(".js")).map(p => "js/blazex_runtime/src/" + p)];
const report = { schema_version: "1.0.0", recorded_at: new Date().toISOString(), platform: process.platform, kernel: os.release(), node: process.version,
  headless: true, source_hashes: Object.fromEntries(files.map(p => [p, sha(fs.readFileSync(path.join(root, p)))])), results: [] };
const server = http.createServer((request, response) => {
  const pathname = new URL(request.url, "http://localhost").pathname;
  if (pathname === "/") { response.setHeader("content-type", "text/html"); response.end("<!doctype html><html lang=en><title>BH04 native presentation</title><body></body></html>"); return; }
  const file = path.resolve(root, "." + pathname);
  if (!["integration/bh-04/", "js/blazex_runtime/src/"].some(p => file.startsWith(path.join(root, p))) || !file.endsWith(".js")) { response.writeHead(404).end(); return; }
  try { response.setHeader("content-type", "text/javascript"); response.end(fs.readFileSync(file)); } catch { response.writeHead(404).end(); }
});
await new Promise(r => server.listen(0, "127.0.0.1", r));
try {
  for (const [name, launcher, executablePath] of [["chrome", chromium, "/usr/bin/google-chrome"], ["firefox", firefox, "/home/ducky/.cache/ms-playwright/firefox-1538/firefox/firefox"]]) {
    const profilePath = path.resolve(outputDir, "firefox-profile.json"), errors = [], events = [];
    const entry = { browser: name, executable: executablePath, page_errors: errors };
    report.results.push(entry);
    const browser = await launcher.launch({ executablePath, headless: true, ...(name === "chrome" ? { args: ["--no-sandbox", "--disable-dev-shm-usage"] } : {
      firefoxUserPrefs: { "dom.send_after_paint_to_content": true }, env: { ...process.env, MOZ_PROFILER_STARTUP: "1", MOZ_PROFILER_STARTUP_FILTERS: "GeckoMain,Compositor,Renderer",
        MOZ_PROFILER_STARTUP_FEATURES: "nostacksampling", MOZ_PROFILER_STARTUP_ENTRIES: "16777216", MOZ_PROFILER_SHUTDOWN: profilePath } }) });
    try {
      entry.version = browser.version(); const page = await browser.newPage(); page.on("pageerror", e => errors.push(String(e)));
      let cdp;
      if (name === "chrome") { cdp = await page.context().newCDPSession(page); cdp.on("Tracing.dataCollected", e => events.push(...e.value)); await cdp.send("Tracing.start", { categories: "devtools.timeline,blink.user_timing,cc,viz,benchmark", transferMode: "ReportEvents" }); }
      await page.goto(`http://127.0.0.1:${server.address().port}/`);
      entry.samples = await page.evaluate(async fixture => (await import("/integration/bh-04/presentation-scenarios.js")).presentationSamples(fixture), fixture);
      entry.regression = await page.evaluate(async () => (await import("/integration/bh-04/presentation-scenarios.js")).controlledDraftRegression());
      entry.retention_probe = await page.evaluate(async fixture => (await import("/integration/bh-04/presentation-scenarios.js")).presentationSamples(fixture, true), fixture);
      if (cdp) { const done = new Promise(r => cdp.once("Tracing.tracingComplete", r)); await cdp.send("Tracing.end"); await done; }
    } catch (error) { entry.error = String(error); }
    finally { await browser.close(); }
    const native = name === "chrome" ? events : JSON.parse(fs.readFileSync(profilePath, "utf8"));
    const bytes = gzipSync(JSON.stringify(native)), tracePath = path.join(outputDir, name + "-native.json.gz");
    fs.writeFileSync(tracePath, bytes, { flag: "wx" }); entry.trace = { file: path.basename(tracePath), sha256: sha(bytes) };
    if (entry.samples) entry.presentation = presentationReport(name, native, entry.samples);
    console.log(name, JSON.stringify({ result: entry.presentation?.result, statistics: entry.presentation?.statistics, failures: entry.presentation?.results.filter(r => r.result === "failed").slice(0, 3), error: entry.error }));
  }
} catch (error) { report.error = String(error); process.exitCode = 1; }
finally { server.close(); fs.writeFileSync(path.join(outputDir, "presentation.json"), JSON.stringify(report, null, 2) + "\n", { flag: "wx" }); }
if (report.results.length !== 2 || report.results.some(r => r.error || r.page_errors.length || r.presentation?.result !== "measurements-within-budget-not-acceptance" ||
  r.retention_probe?.length !== 2 || !r.retention_probe[1].error?.includes("injected late cleanup failure"))) process.exitCode = 1;

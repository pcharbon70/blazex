import fs from "node:fs";
import http from "node:http";
import path from "node:path";
import { chromium, firefox } from "../../../js/blazex_runtime/node_modules/playwright-core/index.mjs";

const build = path.resolve(process.argv[2] ?? "");
const output = path.resolve(process.argv[3] ?? "");
const payloadPath = path.resolve(process.argv[4] ?? "");
const attestationPath = path.resolve(process.argv[5] ?? "");
if (!process.argv[2] || !process.argv[3] || !process.argv[4] || !process.argv[5]) throw new Error("usage: run-browser.mjs BUILD OUTPUT PAYLOAD_REPORT ATTESTATION_REPORT");
const payload = JSON.parse(fs.readFileSync(payloadPath));
const attestationBytes = fs.readFileSync(attestationPath);
const attestation = JSON.parse(attestationBytes);
const attestationSha256 = (await import("node:crypto")).createHash("sha256").update(attestationBytes).digest("hex");
const canonicalManifest = JSON.parse(fs.readFileSync(path.join(build, "build-manifest.json")));
const cacheByPath = new Map(canonicalManifest.artifacts.map((item) => [item.path, item.cache_control]));
cacheByPath.set("build-manifest.json", canonicalManifest.delivery_integrity.manifest_cache_control);

const types = new Map([[".html", "text/html"], [".js", "text/javascript"], [".mjs", "text/javascript"], [".wasm", "application/wasm"], [".avm", "application/octet-stream"], [".json", "application/json"]]);
const server = http.createServer((request, response) => {
  response.setHeader("Cross-Origin-Opener-Policy", "same-origin");
  response.setHeader("Cross-Origin-Embedder-Policy", "require-corp");
  response.setHeader("X-BlazeX-Entrypoint-Attestation", attestationSha256);
  const url = new URL(request.url, "http://localhost");
  const relative = url.pathname === "/" ? "index.html" : url.pathname.slice(1);
  if (relative.startsWith("evidence/")) { response.writeHead(404).end(); return; }
  const target = path.resolve(build, relative);
  if (!target.startsWith(`${build}${path.sep}`) || !fs.existsSync(target) || !fs.statSync(target).isFile()) { response.writeHead(404).end(); return; }
  let body = fs.readFileSync(target);
  let mutable = false;
  if (relative === "build-manifest.json" && request.headers.referer?.includes("tamper=1")) {
    const manifest = JSON.parse(body);
    manifest.artifacts.find((item) => item.role === "application-bundle").sha256 = "0".repeat(64);
    body = Buffer.from(JSON.stringify(manifest));
    mutable = true;
  } else if (relative === "build-manifest.json" && request.headers.referer?.includes("tamper=sri")) {
    const manifest = JSON.parse(body);
    manifest.artifacts.find((item) => item.role === "runtime-wasm").integrity = `sha384-${"A".repeat(64)}`;
    body = Buffer.from(JSON.stringify(manifest));
    mutable = true;
  } else if (relative === "build-manifest.json" && request.headers.referer?.includes("tamper=feature")) {
    const manifest = JSON.parse(body);
    manifest.artifacts.find((item) => item.role === "feature-bundle" && item.feature_id === "counter").sha256 = "0".repeat(64);
    body = Buffer.from(JSON.stringify(manifest));
    mutable = true;
  }
  const cacheControl = request.headers.referer?.includes("tamper=cache") && relative.includes("runtime-wasm-")
    ? "no-store"
    : cacheByPath.get(relative);
  if (!cacheControl) { response.writeHead(500).end(); return; }
  response.setHeader("Cache-Control", cacheControl);
  const brotli = `${target}.br`;
  if (!mutable && /(?:^|,)\s*br\s*(?:,|$)/.test(request.headers["accept-encoding"] ?? "") && fs.existsSync(brotli)) {
    body = fs.readFileSync(brotli);
    response.setHeader("Content-Encoding", "br");
    response.setHeader("Vary", "Accept-Encoding");
  }
  response.setHeader("Content-Type", types.get(path.extname(target)) ?? "application/octet-stream");
  response.end(body);
});

await new Promise((resolve) => server.listen(0, "127.0.0.1", resolve));
const report = { schema_version: "1.0.0", milestone: "BH-06", phase: 11, support_state: "unsupported-development-evidence", payload_decision: payload.decision, attestation_id: attestation.attestation_id, attestation_sha256: attestationSha256, failed_budgets: payload.budgets.filter((item) => item.result === "failed"), results: [], negative_integrity: null, negative_feature_integrity: null, negative_sri: null, negative_cache_control: null, negative_attestation_binding: null, negative_private_evidence: null };

try {
  for (const [name, launcher, executablePath] of [["chrome", chromium, "/usr/bin/google-chrome"], ["firefox", firefox, "/home/ducky/.cache/ms-playwright/firefox-1538/firefox/firefox"]]) {
    const browser = await launcher.launch({ executablePath, headless: true, ...(name === "chrome" ? { args: ["--no-sandbox", "--disable-dev-shm-usage"] } : {}) });
    try {
      const page = await browser.newPage();
      await page.addInitScript(({ attestation, sha256 }) => { window.__BH06_ATTESTATION = { attestation, sha256 }; }, { attestation, sha256: attestationSha256 });
      const pageErrors = [];
      const consoleMessages = [];
      page.on("pageerror", (error) => pageErrors.push(String(error)));
      page.on("console", (message) => {
        if (consoleMessages.length < 200) consoleMessages.push({ type: message.type(), text: message.text() });
      });
      await page.goto(`http://127.0.0.1:${server.address().port}/`);
      await page.waitForFunction(() => window.__BH06_RESULT !== null, null, { timeout: 20000 });
      const observed = await page.evaluate(() => window.__BH06_RESULT);
      report.results.push({ browser: name, version: browser.version(), executable: executablePath, ...observed, page_errors: pageErrors, console_messages: consoleMessages });
      if (observed.result !== "passed" || pageErrors.length || !["brotli-negotiation", "sha384-sri", "cache-control", "delivery-policy-binding", "entrypoint-attestation"].every((check) => observed.checks.includes(check))) process.exitCode = 1;
      if (name === "chrome") {
        const privatePath = JSON.parse(fs.readFileSync(path.join(build, "build-manifest.json"))).artifacts.find((item) => item.exposure === "private-build-evidence").path;
        report.negative_private_evidence = await page.evaluate(async (privatePath) => ({ status: (await fetch(`/${privatePath}`)).status }), privatePath);
        if (report.negative_private_evidence.status !== 404) process.exitCode = 1;
        const negative = await browser.newPage();
        await negative.addInitScript(({ attestation, sha256 }) => { window.__BH06_ATTESTATION = { attestation, sha256 }; }, { attestation, sha256: attestationSha256 });
        await negative.goto(`http://127.0.0.1:${server.address().port}/?tamper=1`);
        await negative.waitForFunction(() => window.__BH06_RESULT !== null, null, { timeout: 10000 });
        report.negative_integrity = await negative.evaluate(() => window.__BH06_RESULT);
        if (report.negative_integrity.result !== "failed" || !report.negative_integrity.error.includes("integrity mismatch")) process.exitCode = 1;
        await negative.close();
        const featureNegative = await browser.newPage();
        await featureNegative.addInitScript(({ attestation, sha256 }) => { window.__BH06_ATTESTATION = { attestation, sha256 }; }, { attestation, sha256: attestationSha256 });
        await featureNegative.goto(`http://127.0.0.1:${server.address().port}/?tamper=feature`);
        await featureNegative.waitForFunction(() => window.__BH06_RESULT !== null, null, { timeout: 10000 });
        report.negative_feature_integrity = await featureNegative.evaluate(() => window.__BH06_RESULT);
        if (report.negative_feature_integrity.result !== "failed" || !report.negative_feature_integrity.error.includes("integrity mismatch for feature-bundle")) process.exitCode = 1;
        await featureNegative.close();
        const sriNegative = await browser.newPage();
        await sriNegative.addInitScript(({ attestation, sha256 }) => { window.__BH06_ATTESTATION = { attestation, sha256 }; }, { attestation, sha256: attestationSha256 });
        await sriNegative.goto(`http://127.0.0.1:${server.address().port}/?tamper=sri`);
        await sriNegative.waitForFunction(() => window.__BH06_RESULT !== null, null, { timeout: 10000 });
        report.negative_sri = await sriNegative.evaluate(() => window.__BH06_RESULT);
        if (report.negative_sri.result !== "failed" || !report.negative_sri.error.includes("SRI mismatch")) process.exitCode = 1;
        await sriNegative.close();
        const cacheNegative = await browser.newPage();
        await cacheNegative.addInitScript(({ attestation, sha256 }) => { window.__BH06_ATTESTATION = { attestation, sha256 }; }, { attestation, sha256: attestationSha256 });
        await cacheNegative.goto(`http://127.0.0.1:${server.address().port}/?tamper=cache`);
        await cacheNegative.waitForFunction(() => window.__BH06_RESULT !== null, null, { timeout: 10000 });
        report.negative_cache_control = await cacheNegative.evaluate(() => window.__BH06_RESULT);
        if (report.negative_cache_control.result !== "failed" || !report.negative_cache_control.error.includes("cache policy mismatch")) process.exitCode = 1;
        await cacheNegative.close();
        const attestationNegative = await browser.newPage();
        await attestationNegative.addInitScript(({ attestation }) => { window.__BH06_ATTESTATION = { attestation, sha256: "0".repeat(64) }; }, { attestation });
        await attestationNegative.goto(`http://127.0.0.1:${server.address().port}/`);
        await attestationNegative.waitForFunction(() => window.__BH06_RESULT !== null, null, { timeout: 10000 });
        report.negative_attestation_binding = await attestationNegative.evaluate(() => window.__BH06_RESULT);
        if (report.negative_attestation_binding.result !== "failed" || !report.negative_attestation_binding.error.includes("attestation binding mismatch")) process.exitCode = 1;
        await attestationNegative.close();
      }
    } finally { await browser.close(); }
  }
} catch (error) {
  report.fatal_error = String(error?.stack ?? error);
  process.exitCode = 1;
} finally {
  server.close();
  fs.writeFileSync(output, `${JSON.stringify(report, null, 2)}\n`);
}

if (report.results.length === 2) {
  const canonical = (row) => JSON.stringify({ checks: row.checks, trace: row.trace, dom: row.dom, entrypoint: row.entrypoint });
  report.comparison = { state: canonical(report.results[0]) === canonical(report.results[1]) ? "exact-match" : "failed" };
  if (report.comparison.state !== "exact-match") process.exitCode = 1;
  fs.writeFileSync(output, `${JSON.stringify(report, null, 2)}\n`);
}

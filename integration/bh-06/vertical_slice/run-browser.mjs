import fs from "node:fs";
import http from "node:http";
import path from "node:path";
import { chromium, firefox } from "../../../js/blazex_runtime/node_modules/playwright-core/index.mjs";

const build = path.resolve(process.argv[2] ?? "");
const output = path.resolve(process.argv[3] ?? "");
if (!process.argv[2] || !process.argv[3]) throw new Error("usage: run-browser.mjs BUILD OUTPUT");

const types = new Map([[".html", "text/html"], [".js", "text/javascript"], [".mjs", "text/javascript"], [".wasm", "application/wasm"], [".avm", "application/octet-stream"], [".json", "application/json"]]);
const server = http.createServer((request, response) => {
  response.setHeader("Cross-Origin-Opener-Policy", "same-origin");
  response.setHeader("Cross-Origin-Embedder-Policy", "require-corp");
  const url = new URL(request.url, "http://localhost");
  const relative = url.pathname === "/" ? "index.html" : url.pathname.slice(1);
  const target = path.resolve(build, relative);
  if (!target.startsWith(`${build}${path.sep}`) || !fs.existsSync(target) || !fs.statSync(target).isFile()) { response.writeHead(404).end(); return; }
  let body = fs.readFileSync(target);
  if (relative === "build-manifest.json" && request.headers.referer?.includes("tamper=1")) {
    const manifest = JSON.parse(body);
    manifest.artifacts.find((item) => item.role === "application-bundle").sha256 = "0".repeat(64);
    body = Buffer.from(JSON.stringify(manifest));
  }
  response.setHeader("Content-Type", types.get(path.extname(target)) ?? "application/octet-stream");
  response.end(body);
});

await new Promise((resolve) => server.listen(0, "127.0.0.1", resolve));
const report = { schema_version: "1.0.0", milestone: "BH-06", phase: 1, support_state: "unsupported-development-evidence", results: [], negative_integrity: null };

try {
  for (const [name, launcher, executablePath] of [["chrome", chromium, "/usr/bin/google-chrome"], ["firefox", firefox, "/home/ducky/.cache/ms-playwright/firefox-1538/firefox/firefox"]]) {
    const browser = await launcher.launch({ executablePath, headless: true, ...(name === "chrome" ? { args: ["--no-sandbox", "--disable-dev-shm-usage"] } : {}) });
    try {
      const page = await browser.newPage();
      const pageErrors = [];
      page.on("pageerror", (error) => pageErrors.push(String(error)));
      await page.goto(`http://127.0.0.1:${server.address().port}/`);
      await page.waitForFunction(() => window.__BH06_RESULT !== null, null, { timeout: 20000 });
      const observed = await page.evaluate(() => window.__BH06_RESULT);
      report.results.push({ browser: name, version: browser.version(), executable: executablePath, ...observed, page_errors: pageErrors });
      if (observed.result !== "passed" || pageErrors.length) process.exitCode = 1;
      if (name === "chrome") {
        const negative = await browser.newPage();
        await negative.goto(`http://127.0.0.1:${server.address().port}/?tamper=1`);
        await negative.waitForFunction(() => window.__BH06_RESULT !== null, null, { timeout: 10000 });
        report.negative_integrity = await negative.evaluate(() => window.__BH06_RESULT);
        if (report.negative_integrity.result !== "failed" || !report.negative_integrity.error.includes("integrity mismatch")) process.exitCode = 1;
        await negative.close();
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

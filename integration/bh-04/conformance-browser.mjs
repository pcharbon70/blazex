import fs from "node:fs";
import http from "node:http";
import path from "node:path";
import assert from "node:assert/strict";
import { fileURLToPath } from "node:url";
import { chromium, firefox } from "../../js/blazex_runtime/node_modules/playwright-core/index.mjs";
import { decode, digest } from "../../js/blazex_runtime/src/render-transaction-v2.js";
const root = fileURLToPath(new URL("../../", import.meta.url));
const rows = [];
for (const line of fs.readFileSync(new URL("conformance-fixtures-v0.1.0.txt", import.meta.url), "utf8").trim().split("\n")) {
  const [name, payload, hash] = line.split("|"), row = decode(Buffer.from(payload, "base64"));
  assert.equal(row.scenario_id, name); assert.equal(await digest(row), hash); rows.push(row);
}
assert.equal(rows.length, 51);
const server = http.createServer((request, response) => {
  const pathname = new URL(request.url, "http://localhost").pathname;
  if (pathname === "/") { response.setHeader("content-type", "text/html"); response.end("<!doctype html><html lang=en><title>BlazeX conformance</title><body></body></html>"); return; }
  const file = path.resolve(root, "." + pathname);
  const allowed = [path.join(root, "integration/bh-04/"), path.join(root, "js/blazex_runtime/src/")];
  if (!allowed.some(prefix => file.startsWith(prefix)) || !file.endsWith(".js")) { response.writeHead(404).end(); return; }
  try { response.setHeader("content-type", "text/javascript"); response.end(fs.readFileSync(file)); } catch { response.writeHead(404).end(); }
});
await new Promise(resolve => server.listen(0, "127.0.0.1", resolve));
const output = { schema_version: "1.0.0", phase: 9, platform: process.platform, node: process.version,
  accessibility_method: "Playwright ariaSnapshot computed role/name tree; not platform accessibility API or assistive-technology qualification", results: [] };
try {
  for (const [name, launcher, executablePath] of [["chrome", chromium, "/usr/bin/google-chrome"], ["firefox", firefox, process.env.BH04_FIREFOX ?? "/home/ducky/.cache/ms-playwright/firefox-1538/firefox/firefox"]]) {
    const browser = await launcher.launch({ executablePath, headless: true, ...(name === "chrome" ? { args: ["--no-sandbox", "--disable-dev-shm-usage"] } : {}) });
    try {
      const page = await browser.newPage(), network = [], errors = [];
      page.on("request", r => network.push({ method: r.method(), path: new URL(r.url()).pathname }));
      page.on("pageerror", e => errors.push(String(e)));
      await page.exposeFunction("bh09Accessibility", () => page.locator("[data-conformance=active]").ariaSnapshot());
      await page.goto(`http://127.0.0.1:${server.address().port}/`);
      const result = await page.evaluate(async rows => {
        const { runConformanceScenarios } = await import("/integration/bh-04/conformance-scenarios.js");
        return runConformanceScenarios(document, rows, globalThis.bh09Accessibility);
      }, rows);
      assert.deepEqual(errors, []);
      output.results.push({ browser: name, executable: executablePath, version: browser.version(), ...result, network });
      console.log(name, result.scenarios, result.traces.length, "passed");
    } finally { await browser.close(); }
  }
  if (process.argv[2]) fs.writeFileSync(process.argv[2], JSON.stringify(output, null, 2) + "\n");
} finally { server.close(); }

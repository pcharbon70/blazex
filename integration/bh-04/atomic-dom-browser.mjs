import fs from "node:fs";
import http from "node:http";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { chromium, firefox } from "../../js/blazex_runtime/node_modules/playwright-core/index.mjs";
import { decode } from "../../js/blazex_runtime/src/render-transaction-v2.js";
const root = fileURLToPath(new URL("../../", import.meta.url));
const rows = fs.readFileSync(new URL("atomic-dom-fixtures-v0.1.0.txt", import.meta.url), "utf8").trim().split("\n").map(line => decode(Buffer.from(line.split("|")[1], "base64")));
const server = http.createServer((request, response) => {
  const pathname = new URL(request.url, "http://localhost").pathname;
  if (pathname === "/") { response.setHeader("content-type", "text/html"); response.end("<!doctype html><title>BH-04 atomic DOM evidence</title><body></body>"); return; }
  const file = path.resolve(root, "." + pathname);
  if (!file.startsWith(root) || ![".js", ".mjs"].includes(path.extname(file))) { response.writeHead(404).end(); return; }
  try { response.setHeader("content-type", "text/javascript"); response.end(fs.readFileSync(file)); } catch { response.writeHead(404).end(); }
});
await new Promise(resolve => server.listen(0, "127.0.0.1", resolve));
const output = [];
try {
  for (const [name, launcher, executablePath] of [["chrome", chromium, "/usr/bin/google-chrome"], ["firefox", firefox, process.env.BH04_FIREFOX ?? "/home/ducky/.cache/ms-playwright/firefox-1538/firefox/firefox"]]) {
    const browser = await launcher.launch({ executablePath, headless: true, ...(name === "chrome" ? { args: ["--no-sandbox", "--disable-dev-shm-usage"] } : {}) });
    try {
      const page = await browser.newPage(); await page.goto(`http://127.0.0.1:${server.address().port}/`);
      const result = await page.evaluate(async rows => {
        const { runAtomicDOMScenarios } = await import("/integration/bh-04/atomic-dom-scenarios.js");
        return await runAtomicDOMScenarios(document, rows);
      }, rows);
      output.push({ browser: name, executable: executablePath, version: browser.version(), user_agent: await page.evaluate(() => navigator.userAgent), ...result });
      console.log(name, JSON.stringify(result.counters));
    } finally { await browser.close(); }
  }
  if (process.argv[2]) fs.writeFileSync(process.argv[2], JSON.stringify({ date: new Date().toISOString(), platform: process.platform, node: process.version, results: output }, null, 2) + "\n");
} finally { server.close(); }

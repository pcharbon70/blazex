import fs from "node:fs";
import http from "node:http";
import path from "node:path";
import readline from "node:readline";
import { spawn } from "node:child_process";
import { fileURLToPath } from "node:url";
import { chromium, firefox } from "../../js/blazex_runtime/node_modules/playwright-core/index.mjs";
const root = fileURLToPath(new URL("../../", import.meta.url));
const child = spawn("docker", ["run", "--rm", "-i", "--network", "none", "-e", "MIX_BUILD_PATH=/tmp/bh04-phase6-browser", "-v", `${root}:/workspace`, "-w", "/workspace/integration/conformance", "a2386c21edd5", "mix", "run", "../bh-04/support/continuity_runtime.exs"], { stdio: ["pipe", "pipe", "inherit"] });
let serial = 0, ready;
const startup = new Promise((resolve, reject) => { ready = resolve; child.on("error", reject); child.on("exit", code => { if (code) reject(new Error("Elixir runtime exited " + code)); }); });
const pending = new Map(), runtime = [];
const lines = readline.createInterface({ input: child.stdout });
lines.on("line", line => {
  if (line === "BH06:ready") { ready(); return; }
  if (!line.startsWith("BH06:")) return;
  const row = JSON.parse(line.slice(5)), waiting = pending.get(row.id);
  if (!waiting) { for (const job of pending.values()) { clearTimeout(job.timer); job.reject(new Error("uncorrelated runtime output")); } pending.clear(); child.stdin.end(); return; }
  pending.delete(row.id); clearTimeout(waiting.timer);
  runtime.push({ request: waiting.request, response: row.result });
  if (row.result.error) waiting.reject(new Error(row.result.error)); else waiting.resolve(row.result);
});
function call(request) {
  return new Promise((resolve, reject) => {
    const id = ++serial;
    const timer = setTimeout(() => { pending.delete(id); reject(new Error("Elixir fixture deadline")); }, 15000);
    pending.set(id, { resolve, reject, request, timer }); child.stdin.write(JSON.stringify({ id, request }) + "\n");
  });
}
const server = http.createServer((request, response) => {
  const pathname = new URL(request.url, "http://localhost").pathname;
  if (pathname === "/") { response.setHeader("content-type", "text/html"); response.end("<!doctype html><title>BH-04 interactions</title><body></body>"); return; }
  const file = path.resolve(root, "." + pathname);
  if (!file.startsWith(root) || !file.endsWith(".js")) { response.writeHead(404).end(); return; }
  try { response.setHeader("content-type", "text/javascript"); response.end(fs.readFileSync(file)); } catch { response.writeHead(404).end(); }
});
await new Promise(resolve => server.listen(0, "127.0.0.1", resolve));
const results = [];
try {
  await startup;
  for (const [name, launcher, executable] of [["chrome", chromium, "/usr/bin/google-chrome"], ["firefox", firefox, process.env.BH04_FIREFOX ?? "/home/ducky/.cache/ms-playwright/firefox-1538/firefox/firefox"]]) {
    const browser = await launcher.launch({ executablePath: executable, headless: true, ...(name === "chrome" ? { args: ["--no-sandbox", "--disable-dev-shm-usage"] } : {}) });
    const start = runtime.length;
    try {
      const page = await browser.newPage(), network = [];
      page.on("request", req => network.push({ method: req.method(), url: req.url() }));
      await page.exposeFunction("bh04Runtime", call);
      await page.exposeFunction("bh04Click", async point => { if (point.key) await page.keyboard.press(point.key); else if (point.text !== undefined) await page.keyboard.insertText(point.text); else await page.mouse.click(point.x, point.y); });
      await page.goto(`http://127.0.0.1:${server.address().port}/`);
      const result = await page.evaluate(async () => {
        const { runContinuityScenarios } = await import("/integration/bh-04/continuity-scenarios.js");
        return runContinuityScenarios(document, globalThis.bh04Runtime, globalThis.bh04Click);
      });
      results.push({ browser: name, version: browser.version(), executable, user_agent: await page.evaluate(() => navigator.userAgent), ...result, runtime: runtime.slice(start), network });
      console.log(name, JSON.stringify(result.counters));
    } finally { await browser.close(); }
  }
  if (process.argv[2]) fs.writeFileSync(process.argv[2], JSON.stringify({ schema_version: "1.0.0", phase: 6, platform: "linux", date: new Date().toISOString(), execution: "Elixir 1.17.3 / OTP 26 in offline Docker; test-only DevTools/stdio carrier", results }, null, 2) + "\n");
} finally { server.close(); child.stdin.end(); lines.close(); for (const job of pending.values()) clearTimeout(job.timer); }

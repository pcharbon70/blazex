import assert from "node:assert/strict";
import test from "node:test";

import { createDemoServer, parseOptions, resolveRequestPath } from "../server.js";

test("server options are bounded and explicit", () => {
  assert.deepEqual(parseOptions([]), { host: "127.0.0.1", port: 4100 });
  assert.deepEqual(parseOptions(["--port", "4200"]), { host: "127.0.0.1", port: 4200 });
  assert.throws(() => parseOptions(["--port", "70000"]), /Port/);
  assert.throws(() => parseOptions(["--open"]), /Unknown/);
});

test("server maps the root to the gallery and rejects traversal", () => {
  assert.match(resolveRequestPath("/"), /demos\/browser\/index\.html$/);
  assert.match(resolveRequestPath("/packages/blazex_renderer_dom/js/dom-driver.js"), /dom-driver\.js$/);
  assert.equal(resolveRequestPath("/../../etc/passwd"), null);
});

test("server returns the gallery and imported renderer modules", async (context) => {
  const server = createDemoServer();
  await new Promise((resolve) => server.listen(0, "127.0.0.1", resolve));
  context.after(() => new Promise((resolve) => server.close(resolve)));
  const { port } = server.address();
  const page = await fetch(`http://127.0.0.1:${port}/`);
  const driver = await fetch(`http://127.0.0.1:${port}/packages/blazex_renderer_dom/js/dom-driver.js`);
  assert.equal(page.status, 200);
  const html = await page.text();
  assert.match(html, /BlazeX component demo/);
  assert.match(html, /href="\/demos\/browser\/styles\.css"/);
  assert.match(html, /src="\/demos\/browser\/src\/app\.js"/);
  assert.equal(driver.status, 200);
  assert.match(driver.headers.get("content-type"), /text\/javascript/);

  const base = `http://127.0.0.1:${port}`;
  const stylesheet = await fetch(`${base}/demos/browser/styles.css`);
  assert.equal(stylesheet.status, 200);
  assert.match(stylesheet.headers.get("content-type"), /text\/css/);

  // Follow the actual module graph to catch broken relative imports after moves.
  const pending = [new URL("/demos/browser/src/app.js", base).href];
  const visited = new Set();
  while (pending.length > 0) {
    const url = pending.pop();
    if (visited.has(url)) continue;
    visited.add(url);
    const response = await fetch(url);
    assert.equal(response.status, 200, url);
    assert.match(response.headers.get("content-type"), /text\/javascript/, url);
    const source = await response.text();
    for (const match of source.matchAll(/\bfrom\s+["']([^"']+)["']/g)) {
      pending.push(new URL(match[1], url).href);
    }
  }
  assert(visited.has(`${base}/packages/blazex_renderer_dom/js/dom-driver.js`));
});

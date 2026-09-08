import fs from "node:fs";
import path from "node:path";
import { spawnSync } from "node:child_process";
import { createHash } from "node:crypto";
import { fileURLToPath } from "node:url";
import assert from "node:assert/strict";
const root = fileURLToPath(new URL("../../", import.meta.url));
const packages = ["blazex_core", "blazex_effects", "blazex_ui_tree", "blazex_renderer", "blazex_renderer_headless", "blazex_renderer_dom"];
const mounts = packages.flatMap(name => ["-v", `${root}packages/${name}:/workspace/packages/${name}:ro`]);
mounts.push("-v", `${root}integration/bh-04/protocol-fixtures-v0.1.0.txt:/workspace/integration/bh-04/protocol-fixtures-v0.1.0.txt:ro`);
const command = "test ! -e /workspace/profiles && test ! -e /workspace/packages/blazex_renderer_dom_liveview && cd /workspace/packages/blazex_renderer_headless && mix test && cd /workspace/packages/blazex_renderer_dom && mix test && mix deps.tree && mix run --no-start -e 'bad = :code.all_available() |> Enum.filter(fn {m, _, _} -> String.starts_with?(to_string(m), [\"Elixir.Phoenix\", \"Elixir.Plug\", \"Elixir.LocalLiveView\", \"Elixir.BlazeX.Renderer.DOM.LiveView\"]) end); if bad != [], do: raise(\"framework module closure\"); IO.puts(\"module-closure: clean\")'";
const args = ["run", "--rm", "--network", "none", ...mounts, "-e", "MIX_BUILD_PATH=/tmp/bh09-isolated", "a2386c21edd5", "sh", "-c", command];
const run = spawnSync("docker", args, {encoding:"utf8", timeout:120000, maxBuffer:10_000_000});
assert.equal(run.status, 0, run.stdout + run.stderr + String(run.error ?? ""));
assert.match(run.stdout, /6 tests, 0 failures/); assert.match(run.stdout, /116 tests, 0 failures/);
assert.match(run.stdout, /module-closure: clean/);
const seen = new Set();
function imports(relative) {
  if (seen.has(relative)) return; seen.add(relative);
  assert.ok(relative.startsWith("js/blazex_runtime/src/"), relative);
  const source = fs.readFileSync(path.join(root,relative),"utf8");
  assert.ok(!/phoenix|local_live_view|renderer_dom_liveview/i.test(source), "framework source coupling: " + relative);
  for (const match of source.matchAll(/(?:from\s*|import\s*)["']([^"']+)["']/g)) {
    assert.ok(match[1].startsWith("."), "nonlocal runtime import");
    imports(path.posix.normalize(path.posix.join(path.posix.dirname(relative),match[1])));
  }
}
imports("js/blazex_runtime/src/atomic-dom.js");
imports("js/blazex_runtime/src/effect-dom.js");
const source_hashes = Object.fromEntries([...seen].sort().map(p => [p,createHash("sha256").update(fs.readFileSync(path.join(root,p))).digest("hex")]));
const result = {schema_version:"1.0.0",phase:9,result:"passed",packages,headless_tests:6,standalone_tests:116,framework_directories:"physically-absent",network:"none",source_hashes,command:["docker",...args],stdout:run.stdout,stderr:run.stderr};
if(process.argv[2])fs.writeFileSync(process.argv[2],JSON.stringify(result,null,2)+"\n");
console.log(JSON.stringify({result:result.result,headless:6,standalone:116,asset_modules:seen.size}));

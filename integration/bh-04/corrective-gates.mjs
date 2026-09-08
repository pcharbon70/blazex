import fs from "node:fs";
import path from "node:path";
import { spawnSync, execFileSync } from "node:child_process";
const directory = process.cwd(), output = process.argv[2], results = [];
if (!output || !fs.statSync(output).isDirectory() || path.resolve(output).startsWith(path.join(directory, "docs/research/assets"))) throw Error("Existing temporary output directory required");
const sources = () => JSON.parse(execFileSync("python3", ["docs/research/70-tools/validate_bh04_correction.py", "--sources"], { encoding: "utf8", maxBuffer: 40_000_000 }));
const source_hashes = sources();
const run = (name, command, args) => {
  const start = Date.now(), r = spawnSync(command, args, { cwd: directory, encoding: "utf8", timeout: 600000, maxBuffer: 40_000_000 });
  results.push({ name, command: [command, ...args], exit_code: r.status, signal: r.signal, error: r.error ? String(r.error) : null, elapsed_ms: Date.now() - start, stdout: r.stdout, stderr: r.stderr });
  fs.writeFileSync(path.join(output, "current-gates.json"), JSON.stringify({ source_hashes, results }, null, 2) + "\n"); console.log(name, r.status);
};
const mix = "set -e; cd /workspace; mix format --check-formatted integration/bh-04/support/*.exs; for package in blazex_core blazex_effects blazex_ui_tree blazex_renderer blazex_renderer_headless blazex_renderer_dom; do cd /workspace/packages/$package; mix test; done; cd /workspace/integration/conformance; mix test; mix run ../bh-04/support/conformance_runner.exs";
run("elixir", "docker", ["run", "--rm", "--network", "none", "-v", directory + ":/workspace", "-e", "MIX_BUILD_PATH=/tmp/bh04-corrective", "a2386c21edd5", "sh", "-c", mix]);
run("javascript", "bash", ["-c", "node --test js/blazex_runtime/test/*.test.js && node packages/blazex_renderer_dom/js/test/dom-driver.test.js && node integration/bh-04/conformance-test.mjs && node --test integration/bh-04/acceptance-report.test.mjs integration/bh-04/corrective-report.test.mjs integration/bh-04/presentation-trace.test.mjs"]);
run("current-tool-tests", "python3", ["-m", "unittest", "discover", "-s", "docs/research/70-tools", "-p", "test_validate_bh04_correction.py"]);
for (const [name, script] of [["atomic", "atomic-dom"], ["interaction", "interaction"], ["continuity", "continuity"], ["effect", "effect"], ["semantic", "conformance"]]) {
  const file = path.join(output, name + "-browser.json"); run(name + "-browser", "node", ["integration/bh-04/" + script + "-browser.mjs", file]);
  if (["interaction", "continuity", "effect"].includes(name)) run(name + "-replay", "node", ["integration/bh-04/" + name + "-conformance.mjs", file]);
}
run("isolation", "node", ["integration/bh-04/conformance-isolation.mjs", path.join(output, "isolation.json")]);
run("archive", "python3", ["docs/research/70-tools/validate_archive.py"]);
run("migration", "python3", ["docs/research/70-tools/validate_tooling_migration.py"]);
run("patch-hygiene", "git", ["diff", "--check"]);
const final_source_hashes = sources();
fs.writeFileSync(path.join(output, "current-gates.json"), JSON.stringify({ source_hashes, final_source_hashes, results }, null, 2) + "\n");
if (results.some(r => r.exit_code !== 0) || JSON.stringify(source_hashes) !== JSON.stringify(final_source_hashes)) process.exitCode = 1;

// Copy generated captures without overwriting prior attempts; no acceptance credit.
import fs from "node:fs";
import path from "node:path";
import { gzipSync } from "node:zlib";
import { execFileSync } from "node:child_process";
const [first, verified, destination] = process.argv.slice(2);
if (first === "--gates") {
  const [historicalRoot, finalDirectory, initialDirectory, secondDirectory] = process.argv.slice(3);
  const output = "docs/research/assets/bh-04-correction/";
  const revision = execFileSync("git", ["-C", historicalRoot, "rev-parse", "HEAD"], { encoding: "utf8" }).trim();
  if (revision !== "d61e103b14595acca182611524eb4c7245906f20") throw Error("Wrong historical checkout");
  const put = (name, bytes) => fs.writeFileSync(path.join(output, name), bytes, { flag: "wx" });
  for (const [name, file] of [["first-historical-gates.json.gz", "historical.json"], ["second-historical-gates.json.gz", "historical-verified.json"]]) put(name, gzipSync(fs.readFileSync(path.join(initialDirectory, file))));
  put("first-current-gates.json.gz", gzipSync(fs.readFileSync(path.join(initialDirectory, "current-gates.json"))));
  put("second-current-gates.json.gz", gzipSync(fs.readFileSync(path.join(secondDirectory, "current-gates.json"))));
  put("historical-gates.json", JSON.stringify({ revision, ...JSON.parse(fs.readFileSync(path.join(initialDirectory, "historical-final.json"))) }, null, 2) + "\n");
  put("current-gates.json", fs.readFileSync(path.join(finalDirectory, "current-gates.json")));
  for (const name of ["atomic", "interaction", "continuity", "effect", "semantic"]) put("current-" + name + "-browser-v0.1.0.json", fs.readFileSync(path.join(finalDirectory, name + "-browser.json")));
  put("current-isolation-v0.1.0.json", fs.readFileSync(path.join(finalDirectory, "isolation.json")));
  process.exit(0);
}
if (!first || !verified || !destination) throw Error("First, verified and destination directories required");
fs.mkdirSync(destination, { recursive: true });
for (const [directory, prefix] of [[first, "first-"], [verified, ""]]) {
  for (const file of ["presentation.json", "chrome-native.json.gz", "firefox-native.json.gz"]) {
    fs.writeFileSync(path.join(destination, prefix + file), fs.readFileSync(path.join(directory, file)), { flag: "wx" });
  }
}
fs.writeFileSync(path.join(destination, "stale-queue.json.gz"), gzipSync(fs.readFileSync(path.join(first, "stale-queue.json"))), { flag: "wx" });

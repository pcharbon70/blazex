// Copy generated captures without overwriting prior attempts; no acceptance credit.
import fs from "node:fs";
import path from "node:path";
import { gzipSync } from "node:zlib";
const [first, verified, destination] = process.argv.slice(2);
if (!first || !verified || !destination) throw Error("First, verified and destination directories required");
fs.mkdirSync(destination, { recursive: true });
for (const [directory, prefix] of [[first, "first-"], [verified, ""]]) {
  for (const file of ["presentation.json", "chrome-native.json.gz", "firefox-native.json.gz"]) {
    fs.writeFileSync(path.join(destination, prefix + file), fs.readFileSync(path.join(directory, file)), { flag: "wx" });
  }
}
fs.writeFileSync(path.join(destination, "stale-queue.json.gz"), gzipSync(fs.readFileSync(path.join(first, "stale-queue.json"))), { flag: "wx" });

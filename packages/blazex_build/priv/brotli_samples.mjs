import fs from "node:fs";
import { brotliCompressSync, constants } from "node:zlib";

const [source, qualityText, repetitionsText] = process.argv.slice(2);
const quality = Number(qualityText);
const repetitions = Number(repetitionsText);
if (!source || quality !== 11 || !Number.isSafeInteger(repetitions) || repetitions < 3 || repetitions > 10) process.exit(2);
const bytes = fs.readFileSync(source);
for (let index = 0; index < repetitions; index += 1) {
  const encoded = brotliCompressSync(bytes, { params: { [constants.BROTLI_PARAM_QUALITY]: quality } });
  process.stdout.write(`${encoded.toString("base64")}\n`);
}

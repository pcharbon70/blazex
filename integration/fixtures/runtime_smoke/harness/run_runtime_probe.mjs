import { pathToFileURL } from "node:url";
import { resolve } from "node:path";

const [runtimeModulePath, bundlePath] = process.argv.slice(2);

if (!runtimeModulePath || !bundlePath) {
  console.error("usage: node run_runtime_probe.mjs <AtomVM.mjs> <bundle.avm>");
  process.exit(64);
}

const runtimeUrl = pathToFileURL(resolve(runtimeModulePath)).href;
const bundle = resolve(bundlePath);
const createRuntime = (await import(runtimeUrl)).default;

let observedExit = null;
let observedAbort = null;
const wasmMemory = new WebAssembly.Memory({ initial: 256, maximum: 256, shared: true });

const runtimeOptions = {
  wasmMemory,
  arguments: [bundle],
  thisProgram: "AtomVM",
  print: (line) => process.stdout.write(`${line}\n`),
  printErr: (line) => process.stderr.write(`${line}\n`),
  onExit: (status) => {
    observedExit = status;
  },
  onAbort: (reason) => {
    observedAbort = String(reason);
  },
};

try {
  await createRuntime(runtimeOptions);
} catch (error) {
  console.error(`BXHARNESS|exception=${error.name}:${error.message}`);
  process.exit(1);
}

console.log(`BXHARNESS|memory_pages=${wasmMemory.buffer.byteLength / 65_536}`);
console.log("BXHARNESS|runtime_returned=pass|host_call=deferred-browser-worker");

if (observedAbort !== null) {
  console.error(`BXHARNESS|abort=${observedAbort}`);
  process.exit(1);
}

if (observedExit !== null && observedExit !== 0) {
  console.error(`BXHARNESS|exit=${observedExit}`);
  process.exit(observedExit);
}

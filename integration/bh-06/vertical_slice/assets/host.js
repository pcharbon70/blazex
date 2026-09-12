const result = { result: "failed", runtime: "atomvm-wasm", checks: [], trace: [], dom: null };
window.__BH06_RESULT = null;

function artifact(manifest, role) {
  const rows = manifest.artifacts.filter((item) => item.role === role);
  if (rows.length !== 1) throw new Error(`expected exactly one ${role} artifact`);
  return rows[0];
}

function featureArtifact(manifest, id) {
  const rows = manifest.artifacts.filter((item) => item.role === "feature-bundle" && item.feature_id === id);
  if (rows.length !== 1) throw new Error(`expected exactly one feature bundle ${id}`);
  return rows[0];
}

async function verifiedBytes(item) {
  const response = await fetch(`/${item.path}`, { cache: "no-store" });
  if (!response.ok) throw new Error(`missing ${item.role} artifact`);
  const bytes = new Uint8Array(await response.arrayBuffer());
  const digest = [...new Uint8Array(await crypto.subtle.digest("SHA-256", bytes))]
    .map((value) => value.toString(16).padStart(2, "0")).join("");
  if (digest !== item.sha256 || bytes.byteLength !== item.bytes) throw new Error(`integrity mismatch for ${item.role}`);
  return bytes;
}

function applyProjection(projection) {
  if (projection.version !== 1 || projection.kind !== "button" || projection.binding !== "activate") {
    throw new Error("unsupported semantic projection");
  }
  const button = document.createElement("button");
  button.type = "button";
  button.setAttribute("aria-label", projection.name);
  button.textContent = projection.text;
  document.getElementById("root").replaceChildren(button);
  return button;
}

async function startRuntime(moduleItem, wasmItem, bundleItem) {
  const [moduleBytes, wasmBinary, applicationBundle] = await Promise.all([
    verifiedBytes(moduleItem), verifiedBytes(wasmItem), verifiedBytes(bundleItem),
  ]);
  result.checks.push("manifest-integrity");
  void moduleBytes;
  const moduleUrl = `/${moduleItem.path}`;
  const createRuntime = (await import(moduleUrl)).default;
  const memory = new WebAssembly.Memory({ initial: 256, maximum: 256, shared: true });
  let readyResolve;
  const ready = new Promise((resolve) => { readyResolve = resolve; });
  const options = {
    arguments: ["/application.avm"],
    locateFile: () => `/${wasmItem.path}`,
    mainScriptUrlOrBlob: moduleUrl,
    wasmBinary,
    wasmMemory: memory,
    preRun: [(module) => module.FS.writeFile("/application.avm", applicationBundle)],
    print: () => {},
    printErr: (value) => { (result.runtime_logs ??= []).push(String(value)); },
    onRuntimeInitialized: () => {
      options.serialize = JSON.stringify;
      options.deserialize = (raw) => JSON.parse(raw, (_key, value) => value && typeof value === "object" && Object.hasOwn(value, "popcorn_ref") && Object.keys(value).length === 1 ? options.trackedObjectsMap.get(value.popcorn_ref) : value);
      options.cleanupFunctions = new Map();
      options.onTrackedObjectDelete = (key) => options.trackedObjectsMap.delete(key);
      options.onRunTrackedJs = (source) => { const indirectEval = eval; const fn = indirectEval(source); return (fn(options) ?? []).map((value) => { const key = options.nextTrackedObjectKey(); options.trackedObjectsMap.set(key, value); return key; }); };
      options.onGetTrackedObjects = (keys) => keys.map((key) => options.serialize(options.trackedObjectsMap.get(key)));
      options.sendEvent = (name) => { if (name === "popcorn_app_ready") readyResolve(); };
    },
  };
  const runtime = await createRuntime(options);
  const originalCall = runtime.call;
  runtime.call = (process, value) => originalCall(process, runtime.serialize(value));
  await Promise.race([ready, new Promise((_, reject) => setTimeout(() => reject(new Error("application-ready-timeout")), 8000))]);
  result.checks.push("atomvm-ready");
  return runtime;
}

async function main() {
  try {
    const manifestResponse = await fetch("/build-manifest.json", { cache: "no-store" });
    if (!manifestResponse.ok) throw new Error("missing build manifest");
    const manifest = await manifestResponse.json();
    if (manifest.schema_version !== "1.0.0" || manifest.entrypoint.module !== "Elixir.BlazeX.BH06.VerticalSlice.Counter") throw new Error("invalid entrypoint manifest");
    result.manifest_id = manifest.manifest_id;
    result.entrypoint = manifest.entrypoint;
    const featureBytes = await verifiedBytes(featureArtifact(manifest, "counter"));
    result.checks.push("feature-integrity");
    const runtime = await startRuntime(artifact(manifest, "runtime-module"), artifact(manifest, "runtime-wasm"), artifact(manifest, "application-bundle"));
    const before = runtime.deserialize(await runtime.call("main", { operation: "feature_status" }));
    if (before.loaded !== false) throw new Error("feature present before dynamic load");
    result.checks.push("feature-absent-before-load");
    const encoded = btoa(String.fromCharCode(...featureBytes));
    const loaded = runtime.deserialize(await runtime.call("main", { operation: "load_feature", id: "counter", bytes: encoded }));
    if (loaded.result !== "feature-loaded") throw new Error("feature dynamic load failed");
    result.checks.push("feature-dynamic-load");
    const duplicate = runtime.deserialize(await runtime.call("main", { operation: "load_feature", id: "counter", bytes: encoded }));
    if (duplicate.result !== "rejected" || duplicate.reason !== "already-loaded") throw new Error("duplicate feature load accepted");
    result.checks.push("duplicate-load-rejection");
    const mount = runtime.deserialize(await runtime.call("main", { operation: "mount" }));
    const button = applyProjection(mount.projection);
    result.checks.push("mount", "semantic-render", "dom-commit");
    const updated = new Promise((resolve, reject) => {
      button.addEventListener("click", async () => {
        try {
          const event = runtime.deserialize(await runtime.call("main", { operation: "event", name: "activate" }));
          applyProjection(event.projection);
          resolve(event);
        } catch (error) { reject(error); }
      }, { once: true });
    });
    button.click();
    const event = await updated;
    result.checks.push("browser-interaction", "elixir-state-transition", "updated-dom-commit");
    const disposed = runtime.deserialize(await runtime.call("main", { operation: "dispose" }));
    result.checks.push("dispose");
    result.trace = disposed.trace;
    result.dom = { text: document.querySelector("button").textContent, role: document.querySelector("button").getAttribute("aria-label") };
    if (mount.state !== 0 || event.state !== 1 || disposed.state !== 1 || result.dom.text !== "Wasm counter: 1") throw new Error("invalid lifecycle result");
    result.result = "passed";
    document.getElementById("status").textContent = "AtomVM WebAssembly component passed";
  } catch (error) {
    result.error = String(error);
    document.getElementById("status").textContent = `Failed: ${error}`;
  } finally {
    window.__BH06_RESULT = result;
  }
}

void main();

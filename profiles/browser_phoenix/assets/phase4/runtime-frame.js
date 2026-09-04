const PROTOCOL = "blazex.runtime.frame/1";
let active = null;

addEventListener("message", async (event) => {
  const message = event.data;
  if (event.source !== parent || message?.protocol !== PROTOCOL) return;
  if (message.type === "stop") {
    active?.dispose();
    active = null;
    post(message, "stopped", { reason: message.reason });
    return;
  }
  if (message.type === "bridge-request") {
    await bridgeRequest(message);
    return;
  }
  if (message.type === "bridge-cancel") {
    bridgeCancel(message);
    return;
  }
  if (message.type !== "start" || active) return;

  const objectUrls = [];
  const dispose = () => objectUrls.splice(0).forEach((url) => URL.revokeObjectURL(url));
  active = { channel: message.channel, generation: message.generation, manifest_generation: message.manifest_generation, dispose };
  try {
    post(message, "instantiating");
    const runtimeSource = new TextDecoder("utf-8", { fatal: true }).decode(message.runtimeModule);
    const runtimeBlob = new Blob([runtimeSource], { type: "text/javascript" });
    const runtimeUrl = URL.createObjectURL(runtimeBlob);
    objectUrls.push(runtimeUrl);
    const createRuntime = (await import(runtimeUrl)).default;
    if (typeof createRuntime !== "function") throw new TypeError("Runtime module has no default factory");

    const wasmMemory = new WebAssembly.Memory({ initial: 256, maximum: 256, shared: true });
    let observedAbort = null;
    const runtime = await createRuntime({
      arguments: ["/bundle.avm"],
      mainScriptUrlOrBlob: runtimeBlob,
      wasmBinary: new Uint8Array(message.runtimeWasm),
      wasmMemory,
      preRun: [(module) => module.FS.writeFile("/bundle.avm", new Uint8Array(message.applicationBundle))],
      print: (line) => post(message, "stdout", { line: String(line) }),
      printErr: (line) => post(message, "stderr", { line: String(line) }),
      onAbort: (reason) => {
        observedAbort = String(reason);
        post(message, "runtime-failed", { code: "runtime-abort", reason: observedAbort });
      },
      onExit: (status) => post(message, "runtime-exited", { status }),
      sendEvent: (name, payload) => {
        post(message, "runtime-event", { name, payload });
        if (name === message.startup.readiness_event) post(message, "application-ready", { name });
      },
    });
    if (observedAbort !== null) throw new Error(`Runtime aborted: ${observedAbort}`);
    active.runtime = runtime;
    post(message, "runtime-ready", { memory_pages: wasmMemory.buffer.byteLength / 65_536 });
  } catch (error) {
    post(message, "runtime-failed", { code: "runtime-start-failed", reason: error instanceof Error ? `${error.name}:${error.message}` : String(error) });
    dispose();
    active = null;
  }
});

function post(message, type, details = {}) {
  parent.postMessage({
    protocol: PROTOCOL,
    channel: message.channel,
    generation: message.generation,
    manifest_generation: message.manifest_generation ?? active?.manifest_generation,
    type,
    ...details,
  }, location.origin);
}

async function bridgeRequest(message) {
  const envelope = message.envelope;
  if (!active?.runtime || active.channel !== message.channel || envelope?.generation !== active.generation || envelope?.protocol !== "blazex.host-bridge/1") {
    post(message, "bridge-rejected", { code: "bridge-generation-invalid", correlation_id: envelope?.correlation_id });
    return;
  }
  try {
    const raw = await active.runtime.call("main", JSON.stringify(envelope));
    const response = typeof raw === "string" ? JSON.parse(raw) : raw;
    post(message, "bridge-response", { envelope: response });
  } catch (error) {
    post(message, "bridge-response", {
      envelope: {
        protocol: "blazex.host-bridge/1",
        type: "response",
        scenario_id: envelope.scenario_id,
        generation: envelope.generation,
        correlation_id: envelope.correlation_id,
        sequence: envelope.sequence,
        status: "error",
        error: { code: "runtime-call-failed", message: error instanceof Error ? error.message.slice(0, 256) : "Runtime call failed" },
      },
    });
  }
}

function bridgeCancel(message) {
  const envelope = message.envelope;
  if (active?.runtime && active.channel === message.channel && envelope?.generation === active.generation) {
    active.runtime.cast("main", JSON.stringify(envelope));
  }
  post(message, "bridge-cancelled", { correlation_id: envelope?.correlation_id });
}

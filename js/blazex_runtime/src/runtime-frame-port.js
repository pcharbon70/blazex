import { BlazeXHostError } from "./internal/errors.js";

const FRAME_PROTOCOL = "blazex.runtime.frame/1";

export class BrowserRuntimeFrame {
  #channel;
  #document;
  #frame;
  #listener;
  #onEvent;
  #pending = new Map();
  #stopped = false;

  constructor({ frameUrl, documentImpl = globalThis.document, onEvent = () => {} }) {
    if (!documentImpl?.createElement || typeof globalThis.addEventListener !== "function") {
      throw new BlazeXHostError("frame-host-unavailable", "A browser document and message event target are required");
    }
    this.#document = documentImpl;
    this.#onEvent = onEvent;
    this.#channel = createChannel();
    this.#frame = documentImpl.createElement("iframe");
    this.#frame.hidden = true;
    this.#frame.title = "BlazeX experimental runtime host";
    this.#frame.setAttribute("sandbox", "allow-scripts allow-same-origin");
    this.#frame.src = new URL(frameUrl, documentImpl.baseURI).href;
  }

  async attach(signal) {
    if (this.#stopped) throw new BlazeXHostError("frame-stopped", "A stopped runtime frame cannot be attached");
    this.#listener = (event) => {
      if (event.source !== this.#frame.contentWindow) return;
      const message = event.data;
      if (message?.protocol !== FRAME_PROTOCOL || message.channel !== this.#channel) return;
      if (message.type === "bridge-response") {
        const correlationId = message.envelope?.correlation_id;
        const pending = this.#pending.get(correlationId);
        if (pending) {
          this.#pending.delete(correlationId);
          pending.resolve(message.envelope);
        }
      }
      this.#onEvent(Object.freeze({ ...message }));
    };
    globalThis.addEventListener("message", this.#listener);
    const loaded = waitForFrame(this.#frame, signal);
    this.#document.body.append(this.#frame);
    await loaded;
  }

  start({ manifest, artifacts, generation = manifest.generation }) {
    if (this.#stopped || !this.#frame.contentWindow) throw new BlazeXHostError("frame-not-attached", "The runtime frame is unavailable");
    const runtimeModule = artifacts["runtime-module"].bytes.slice().buffer;
    const runtimeWasm = artifacts["runtime-wasm"].bytes.slice().buffer;
    const applicationBundle = artifacts["application-bundle"].bytes.slice().buffer;
    this.#frame.contentWindow.postMessage({
      protocol: FRAME_PROTOCOL,
      type: "start",
      channel: this.#channel,
      generation,
      manifest_generation: manifest.generation,
      manifest_id: manifest.manifest_id,
      startup: manifest.startup,
      runtimeModule,
      runtimeWasm,
      applicationBundle,
    }, new URL(this.#frame.src).origin, [runtimeModule, runtimeWasm, applicationBundle]);
  }

  request(envelope) {
    if (this.#stopped || !this.#frame.contentWindow) return Promise.reject(new BlazeXHostError("frame-not-attached", "The runtime frame is unavailable"));
    if (this.#pending.has(envelope.correlation_id)) return Promise.reject(new BlazeXHostError("frame-correlation-duplicate", "The frame already owns this correlation ID"));
    return new Promise((resolve, reject) => {
      this.#pending.set(envelope.correlation_id, { resolve, reject });
      this.#post({ type: "bridge-request", generation: envelope.generation, envelope });
    });
  }

  cancel(envelope) {
    const pending = this.#pending.get(envelope.correlation_id);
    if (pending) {
      this.#pending.delete(envelope.correlation_id);
      pending.reject(new BlazeXHostError("frame-request-cancelled", "The frame request was cancelled"));
    }
    if (!this.#stopped && this.#frame.contentWindow) this.#post({ type: "bridge-cancel", generation: envelope.generation, envelope });
  }

  stop(reason = "requested") {
    if (this.#stopped) return;
    this.#stopped = true;
    if (this.#frame.contentWindow) {
      this.#frame.contentWindow.postMessage({ protocol: FRAME_PROTOCOL, type: "stop", channel: this.#channel, reason }, new URL(this.#frame.src).origin);
    }
    for (const { reject } of this.#pending.values()) reject(new BlazeXHostError("frame-stopped", "The runtime frame stopped"));
    this.#pending.clear();
    this.#frame.remove();
    if (this.#listener) globalThis.removeEventListener("message", this.#listener);
    this.#listener = null;
  }

  #post(message) {
    this.#frame.contentWindow.postMessage({ protocol: FRAME_PROTOCOL, channel: this.#channel, ...message }, new URL(this.#frame.src).origin);
  }
}

function createChannel() {
  const values = new Uint32Array(4);
  globalThis.crypto.getRandomValues(values);
  return [...values].map((value) => value.toString(16).padStart(8, "0")).join("");
}

function waitForFrame(frame, signal) {
  return new Promise((resolve, reject) => {
    const cleanup = () => {
      frame.removeEventListener("load", loaded);
      frame.removeEventListener("error", failed);
      signal?.removeEventListener("abort", cancelled);
    };
    const loaded = () => { cleanup(); resolve(); };
    const failed = () => { cleanup(); reject(new BlazeXHostError("frame-load-failed", "The runtime frame failed to load")); };
    const cancelled = () => { cleanup(); reject(new BlazeXHostError("frame-load-cancelled", "Runtime frame loading was cancelled")); };
    frame.addEventListener("load", loaded, { once: true });
    frame.addEventListener("error", failed, { once: true });
    signal?.addEventListener("abort", cancelled, { once: true });
  });
}

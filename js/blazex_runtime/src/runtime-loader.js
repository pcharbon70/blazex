import { acquireDeclaredArtifacts, fetchRuntimeManifest } from "./manifest-loader.js";
import { BrowserRuntimeFrame } from "./runtime-frame-port.js";
import { errorRecord } from "./internal/errors.js";

export class BrowserRuntimeLoader {
  #controller = null;
  #frame = null;
  #onEvent;

  constructor({ onEvent = () => {}, frameFactory = (options) => new BrowserRuntimeFrame(options) } = {}) {
    this.#onEvent = onEvent;
    this.frameFactory = frameFactory;
  }

  async start({ manifestUrl, frameUrl, timeoutMs = 15_000 }) {
    if (this.#controller) throw new Error("BrowserRuntimeLoader already owns an activation");
    this.#controller = new AbortController();
    const emit = (stage, details = {}) => this.#onEvent(Object.freeze({ protocol: "blazex.lifecycle/1", stage, ...details }));
    try {
      emit("manifest-fetching");
      const manifest = await fetchRuntimeManifest(manifestUrl, { signal: this.#controller.signal, timeoutMs });
      emit("manifest-verified", { manifest_id: manifest.manifest_id, generation: manifest.generation });
      const artifacts = await acquireDeclaredArtifacts(manifest, { signal: this.#controller.signal, timeoutMs });
      emit("artifacts-verified", { artifact_ids: Object.values(artifacts).map((item) => item.declaration.id), generation: manifest.generation });
      this.#frame = this.frameFactory({ frameUrl, onEvent: (event) => this.#onEvent(event) });
      await this.#frame.attach(this.#controller.signal);
      emit("frame-attached", { generation: manifest.generation });
      this.#frame.start({ manifest, artifacts });
      return Object.freeze({ manifest_id: manifest.manifest_id, generation: manifest.generation });
    } catch (error) {
      emit("loader-failed", { error: errorRecord(error) });
      this.stop("activation-failed");
      throw error;
    }
  }

  stop(reason = "requested") {
    this.#controller?.abort(reason);
    this.#frame?.stop(reason);
    this.#controller = null;
    this.#frame = null;
  }
}

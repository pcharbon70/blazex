const origins = new Set(["protocol", "dom", "effect", "interaction", "acknowledgement", "lifecycle", "cleanup"]);
const codes = new Set(["malformed", "incompatible", "stale", "duplicate", "missing-target", "ownership", "limit", "apply", "rollback", "disposed-root", "timeout", "failed", "transport", "runtime-loss", "leak"]);
/** One elected recovery owner, one fallback attempt, zero retries, bounded diagnostics. */
export class RendererFailure {
  #records = []; #terminal = false; #fallbacks = 0; #recover; #total = 0;
  constructor(recover) { if (typeof recover !== "function") throw TypeError("Recovery owner required"); this.#recover = recover; }
  report(origin, code, terminal = false) {
    const record = { sequence: ++this.#total, origin: origins.has(origin) ? origin : "protocol", code: codes.has(code) ? code : "failed", terminal: Boolean(terminal) };
    this.#records.push(record); if (this.#records.length > 32) this.#records.shift();
    if (terminal && !this.#terminal) {
      this.#terminal = true; this.#fallbacks++;
      try { this.#recover(); } catch { this.report("cleanup", "leak", false); }
    }
    return record;
  }
  snapshot() { return { terminal: this.#terminal, fallback_attempts: this.#fallbacks, retry_attempts: 0, diagnostic_count: this.#total, diagnostics: this.#records.map(r => ({ ...r })) }; }
}

const REDACTED_KEY = /authorization|body|cookie|credential|csrf|password|private|query|secret|session|source_snippet|stack|token/i;

export class BlazeXHostError extends Error {
  constructor(code, message, details = {}) {
    super(message);
    this.name = "BlazeXHostError";
    this.code = code;
    this.details = redact(details);
  }
}

export function errorRecord(error) {
  if (error instanceof BlazeXHostError) {
    return Object.freeze({ code: error.code, message: error.message, details: error.details });
  }
  return Object.freeze({
    code: typeof error?.code === "string" ? error.code.slice(0, 96) : "unexpected-host-error",
    message: scrubString(error instanceof Error ? error.message : String(error)),
    details: {},
  });
}

export function redactDiagnostic(value, depth = 0) {
  if (depth > 5) return "[bounded]";
  if (Array.isArray(value)) return value.slice(0, 32).map((item) => redactDiagnostic(item, depth + 1));
  if (value && typeof value === "object") {
    return Object.fromEntries(
      Object.entries(value).slice(0, 32).map(([key, item]) => [
        key,
        REDACTED_KEY.test(key) ? "[redacted]" : redactDiagnostic(item, depth + 1),
      ]),
    );
  }
  return typeof value === "string" ? scrubString(value).slice(0, 512) : value;
}

const redact = redactDiagnostic;

function scrubString(value) {
  return value
    .replace(/\bBearer\s+[^\s,;]+/gi, "Bearer [redacted]")
    .replace(/([?&](?:token|secret|password|csrf|session)[^=]*=)[^&\s]+/gi, "$1[redacted]")
    .replace(/\b(cookie|authorization|token|secret|password|csrf|session)\s*[:=]\s*[^\s,;]+/gi, "$1=[redacted]")
    .replace(/\/(?:home|Users|tmp|var)\/[^\s,)]+/g, "[local-path]")
    .replace(/\n\s*at\s+[^\n]+/g, "\n[stack-redacted]");
}

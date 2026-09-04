const REDACTED_KEYS = new Set([
  "authorization",
  "cookie",
  "credential",
  "password",
  "secret",
  "token",
]);

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
    message: error instanceof Error ? error.message : String(error),
    details: {},
  });
}

function redact(value, depth = 0) {
  if (depth > 5) return "[bounded]";
  if (Array.isArray(value)) return value.slice(0, 32).map((item) => redact(item, depth + 1));
  if (value && typeof value === "object") {
    return Object.fromEntries(
      Object.entries(value).slice(0, 32).map(([key, item]) => [
        key,
        REDACTED_KEYS.has(key.toLowerCase()) ? "[redacted]" : redact(item, depth + 1),
      ]),
    );
  }
  return value;
}

import { createReadStream } from "node:fs";
import { stat } from "node:fs/promises";
import { createServer } from "node:http";
import { dirname, extname, resolve, sep } from "node:path";
import { fileURLToPath } from "node:url";

const demoRoot = dirname(fileURLToPath(import.meta.url));
const repositoryRoot = resolve(demoRoot, "../..");
const contentTypes = new Map([
  [".css", "text/css; charset=utf-8"],
  [".html", "text/html; charset=utf-8"],
  [".js", "text/javascript; charset=utf-8"],
  [".json", "application/json; charset=utf-8"],
  [".svg", "image/svg+xml"],
]);

export function parseOptions(argumentsList) {
  const options = { host: "127.0.0.1", port: 4100 };
  for (let index = 0; index < argumentsList.length; index += 1) {
    const option = argumentsList[index];
    const value = argumentsList[index + 1];
    if (option === "--host" && value) options.host = value;
    else if (option === "--port" && value && Number.isSafeInteger(Number(value))) options.port = Number(value);
    else throw new Error(`Unknown or incomplete option: ${option}`);
    index += 1;
  }
  if (options.port < 1 || options.port > 65_535) throw new Error("Port must be between 1 and 65535");
  return options;
}

export function resolveRequestPath(rawUrl) {
  const decodedRequestPath = decodeURIComponent(rawUrl.split("?", 1)[0]);
  if (decodedRequestPath.split("/").includes("..")) return null;
  const url = new URL(rawUrl, "http://localhost");
  const pathname = decodeURIComponent(url.pathname === "/" ? "/demos/browser/index.html" : url.pathname);
  const candidate = resolve(repositoryRoot, `.${pathname}`);
  if (candidate !== repositoryRoot && !candidate.startsWith(`${repositoryRoot}${sep}`)) return null;
  return candidate;
}

export function createDemoServer() {
  return createServer(async (request, response) => {
    if (!request.url || !["GET", "HEAD"].includes(request.method ?? "")) {
      response.writeHead(405, { Allow: "GET, HEAD" });
      response.end();
      return;
    }

    const candidate = resolveRequestPath(request.url);
    if (!candidate) {
      response.writeHead(403);
      response.end("Forbidden");
      return;
    }

    try {
      const details = await stat(candidate);
      if (!details.isFile()) throw new Error("not a file");
      response.writeHead(200, {
        "Cache-Control": "no-store",
        "Content-Security-Policy": "default-src 'self'; script-src 'self'; style-src 'self'; img-src 'self'; connect-src 'self'; base-uri 'none'; form-action 'none'",
        "Content-Type": contentTypes.get(extname(candidate)) ?? "application/octet-stream",
        "X-Content-Type-Options": "nosniff",
      });
      if (request.method === "HEAD") response.end();
      else createReadStream(candidate).pipe(response);
    } catch {
      response.writeHead(404, { "Content-Type": "text/plain; charset=utf-8" });
      response.end("Not found");
    }
  });
}

if (process.argv[1] === fileURLToPath(import.meta.url)) {
  try {
    const { host, port } = parseOptions(process.argv.slice(2));
    const server = createDemoServer();
    server.listen(port, host, () => {
      console.log(`BlazeX component demo: http://${host}:${port}/`);
      console.log("Press Ctrl+C to stop.");
    });
  } catch (error) {
    console.error(error.message);
    process.exitCode = 1;
  }
}

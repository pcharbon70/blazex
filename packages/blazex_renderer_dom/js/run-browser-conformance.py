#!/usr/bin/env python3
"""Run the dependency-free Phase 6 page in installed Chrome and Firefox."""

from __future__ import annotations

import argparse
import json
import os
import queue
import shutil
import subprocess
import tempfile
import threading
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import quote


ROOT = Path(__file__).resolve().parent


class ResultHandler(SimpleHTTPRequestHandler):
    results: queue.Queue[dict[str, object]] = queue.Queue()

    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=str(ROOT), **kwargs)

    def do_POST(self) -> None:
        if self.path != "/result":
            self.send_error(404)
            return
        length = int(self.headers.get("content-length", "0"))
        try:
            value = json.loads(self.rfile.read(length))
        except (UnicodeDecodeError, json.JSONDecodeError):
            self.send_error(400)
            return
        self.results.put(value)
        self.send_response(204)
        self.end_headers()

    def log_message(self, _format: str, *_args: object) -> None:
        return


def browser_command(name: str, executable: str, profile: str, url: str) -> list[str]:
    if name == "chrome":
        return [executable, "--headless=new", "--no-sandbox", "--disable-gpu", "--disable-dev-shm-usage", f"--user-data-dir={profile}", url]
    return [executable, "--headless", "--no-remote", "--profile", profile, url]


def browser_version(executable: str) -> str:
    result = subprocess.run([executable, "--version"], check=False, capture_output=True, text=True, timeout=10)
    return (result.stdout or result.stderr).strip().splitlines()[-1]


def run_one(name: str, executable: str, port: int) -> dict[str, object]:
    with tempfile.TemporaryDirectory(prefix=f"blazex-{name}-") as profile:
        url = f"http://127.0.0.1:{port}/browser-conformance.html?browser={quote(name)}"
        environment = os.environ.copy()
        environment["MOZ_HEADLESS"] = "1"
        process = subprocess.Popen(browser_command(name, executable, profile, url), stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, env=environment)
        try:
            while True:
                result = ResultHandler.results.get(timeout=30)
                if result.get("browser") == name:
                    break
        except queue.Empty as exc:
            process.terminate()
            stdout, stderr = process.communicate(timeout=10)
            raise RuntimeError(f"{name} produced no conformance result: {stdout[-500:]} {stderr[-500:]}") from exc
        finally:
            if process.poll() is None:
                process.terminate()
                try:
                    process.communicate(timeout=10)
                except subprocess.TimeoutExpired:
                    process.kill()
                    process.communicate(timeout=10)
        if result.get("result") != "passed":
            raise RuntimeError(f"{name} conformance failed: {result.get('error')}")
        result["executable"] = executable
        result["version"] = browser_version(executable)
        return result


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--browser", action="append", choices=["chrome", "firefox"])
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    names = args.browser or ["chrome", "firefox"]
    executables = {"chrome": shutil.which("google-chrome"), "firefox": shutil.which("firefox")}
    missing = [name for name in names if not executables[name]]
    if missing:
        raise SystemExit(f"missing required browser executable(s): {', '.join(missing)}")

    server = ThreadingHTTPServer(("127.0.0.1", 0), ResultHandler)
    thread = threading.Thread(target=server.serve_forever, daemon=True)
    thread.start()
    try:
        results = [run_one(name, str(executables[name]), server.server_port) for name in names]
    finally:
        server.shutdown()
        server.server_close()
        thread.join(timeout=5)

    record = {"schema_version": "1.0.0", "matrix": "BH-02 Phase 6 active Linux", "results": results, "support_state": "unsupported"}
    rendered = json.dumps(record, indent=2, sort_keys=True) + "\n"
    if args.output:
        args.output.write_text(rendered, encoding="utf-8")
    print(rendered, end="")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

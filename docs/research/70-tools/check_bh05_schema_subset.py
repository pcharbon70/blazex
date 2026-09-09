"""Run the Phase 3 schema subset through SHA-pinned Popcorn compiler/analyzer sources."""
import argparse
import hashlib
import io
import json
import os
from pathlib import Path
import subprocess
import tarfile
import tempfile
from research_paths import REPO_ROOT


def run(package):
    lock = json.loads((REPO_ROOT / "profiles/browser_phoenix/toolchain/runtime.lock.json").read_text())
    pin = next(row for row in lock["sources"] if row["id"] == "popcorn-hex")
    data = package.read_bytes()
    digest = hashlib.sha256(data).hexdigest()
    if digest != pin["sha256"]:
        raise ValueError("cached Popcorn package does not match accepted SHA-256")
    print("Popcorn package " + pin["version"] + " SHA-256 " + digest, flush=True)
    selected = ["lib/treeshake/utils/beam_reader.ex", "lib/treeshake/utils/beam_analyzer.ex", "lib/popcorn/core_erlang_utils.ex"]
    with tempfile.TemporaryDirectory(prefix="bh05-schema-subset-") as name:
        root = Path(name)
        with tarfile.open(fileobj=io.BytesIO(data)) as outer:
            archive = outer.extractfile("contents.tar.gz").read()
        with tarfile.open(fileobj=io.BytesIO(archive), mode="r:gz") as inner:
            for path in selected:
                content = inner.extractfile(path).read()
                target = root / path
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_bytes(content)
                print(path + " " + hashlib.sha256(content).hexdigest(), flush=True)
        command = ["docker", "run", "--rm", "--network", "none", "--user", f"{os.getuid()}:{os.getgid()}", "-v", str(REPO_ROOT) + ":/workspace:ro", "-v", name + ":/pinned", "-w", "/workspace", "a2386c21edd5", "elixir", "integration/bh-05/schema-subset.exs", "/pinned"]
        return subprocess.run(command).returncode


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--package", type=Path, required=True)
    raise SystemExit(run(parser.parse_args().package))

"""Generate Phase 2 authority from the accepted Phase 1 Git snapshot."""
import argparse
import hashlib
import json
import subprocess
from research_paths import REPO_ROOT

BASE = "968013b9794664fc454619ee08788c3d0c39551f"
AREA = "docs/research/assets/bh-05-baseline/"
PLAN = "docs/research/60-planning/01-browser-host/bh-05-component-programming-model-and-lifecycle/"
TARGET = AREA + "authoring-authorization-v0.1.0.json"
INPUTS = [AREA + "phase-01-completion-v0.1.0.json", AREA + "phase-01-gates-v0.1.0.json",
          AREA + "authorization-v0.1.0.json", AREA + "ownership-v0.1.0.json",
          "docs/research/assets/bh-02-baseline/blazex-bh-02-contract-baseline-v0.1.0.json",
          "docs/research/20-notes/architecture-decisions/adr-0001-host-neutral-semantic-component-kernel.md",
          "profiles/browser_phoenix/toolchain/runtime.lock.json",
          "integration/fixtures/browser_host/mix.lock"] + [
    "packages/blazex_core/lib/blazex/core/" + name + ".ex"
    for name in ["component", "evaluator", "context", "evaluation", "diagnostic", "identity", "portable"]]


def authority(root=REPO_ROOT):
    hashes = {p: hashlib.sha256(subprocess.check_output(["git", "show", BASE + ":" + p], cwd=root)).hexdigest() for p in INPUTS}
    return {"schema_version": "1.0.0", "phase": 2, "base": BASE,
            "authorization": "Owner requested next BH-05 phase on 2026-09-09; Phase 2 only.",
            "branch": "codex/bh05-phase2-authoring", "sections": ["2.1", "2.2", "2.3", "2.4"],
            "delivery": ["commit each verified section", "one PR", "merge", "checkout main", "sync origin", "delete feature branch"],
            "contract_version": "0.1.0-bh05-candidate", "input_hashes": hashes,
            "excluded": ["schema validation", "state retention", "process startup", "event execution", "effect execution", "renderer changes", "forms", "LiveView", "LocalLiveView", "support claims"],
            "support_state": "unsupported", "runtime_parity": False}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    content = json.dumps(authority(), indent=2) + "\n"
    path = REPO_ROOT / TARGET
    if args.check:
        if not path.is_file() or path.read_text() != content:
            raise SystemExit("Phase 2 authority drift")
    else:
        with path.open("x") as output:
            output.write(content)
    print("BH-05 authoring authority: PASS")


if __name__ == "__main__":
    main()

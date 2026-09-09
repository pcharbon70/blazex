"""Generate the Phase 3 authority from the accepted Phase 2 snapshot."""
import argparse
import hashlib
import json
import subprocess
from research_paths import REPO_ROOT

BASE = "5cd382c23c5589404efc8dd7121432dd24c4cd96"
AREA = "docs/research/assets/bh-05-baseline/"
PLAN = "docs/research/60-planning/01-browser-host/bh-05-component-programming-model-and-lifecycle/"
TARGET = AREA + "schema-authorization-v0.1.0.json"
INPUTS = [AREA + "authoring-completion-v0.1.0.json", AREA + "authoring-gates-v0.1.0.json",
          PLAN + "authoring-contract.md", "packages/blazex_core/lib/blazex/component/input.ex",
          "packages/blazex_core/lib/blazex/core/portable.ex", "packages/blazex_core/lib/blazex/core/identity.ex",
          "packages/blazex_core/lib/blazex/core/authoring.ex",
          "profiles/browser_phoenix/toolchain/runtime.lock.json",
          "docs/research/20-notes/architecture-decisions/adr-0001-host-neutral-semantic-component-kernel.md"]


def record(root=REPO_ROOT):
    return {"schema_version": "1.0.0", "phase": 3, "base": BASE,
            "authorization": "Owner requested the next BH-05 phase; Phase 3 only.",
            "branch": "codex/bh05-phase3-schemas", "sections": ["3.1", "3.2", "3.3", "3.4"],
            "delivery": ["one commit per verified section", "single PR", "merge", "checkout main", "sync origin", "delete feature branch"],
            "contract": "0.2.0-bh05-schema-candidate", "legacy_contract": "0.1.0-bh05-candidate",
            "input_hashes": {p: hashlib.sha256(subprocess.check_output(["git", "show", BASE + ":" + p], cwd=root)).hexdigest() for p in INPUTS},
            "excluded": ["component execution", "state retention", "processes", "events/effects", "dynamic registry", "forms", "renderer changes", "LiveView", "LocalLiveView", "support claims"],
            "support_state": "unsupported", "runtime_parity": False}


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    content = json.dumps(record(), indent=2) + "\n"
    target = REPO_ROOT / TARGET
    if args.check:
        if not target.exists() or target.read_text() != content: raise SystemExit("Phase 3 authority drift")
    else:
        with target.open("x") as output: output.write(content)
    print("BH-05 schema authority: PASS")

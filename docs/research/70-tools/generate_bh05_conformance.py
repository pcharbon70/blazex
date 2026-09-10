"""Generate the Phase 11 cross-runtime conformance authorization."""
import argparse
import hashlib
import json
import subprocess
from research_paths import REPO_ROOT

BASE = "c1c453c4dc84c351695953cde0c72a839d783778"
AREA = "docs/research/assets/bh-05-baseline/"
PLAN = "docs/research/60-planning/01-browser-host/bh-05-component-programming-model-and-lifecycle/"
TARGET = AREA + "conformance-authorization-v0.1.0.json"
INPUTS = [
    AREA + "recovery-completion-v0.1.0.json",
    AREA + "recovery-gates-v0.1.0.json",
    PLAN + "authoring-contract.md", PLAN + "schema-contract.md",
    PLAN + "composition-contract.md", PLAN + "nested-contract.md",
    PLAN + "root-lifecycle-contract.md", PLAN + "scheduling-contract.md",
    PLAN + "action-contract.md", PLAN + "scope-contract.md", PLAN + "recovery-contract.md",
    PLAN + "root-supervision-compatibility.md",
    "integration/conformance/dom-browser-matrix-v0.1.0.json",
    "experiments/native_renderer_spike/experiment-index-v0.2.0.json",
    "profiles/browser_phoenix/toolchain/browser.lock.json",
    "profiles/browser_phoenix/toolchain/runtime.lock.json",
    "packages/blazex_runtime_popcorn/runtime/runtime-binary-manifest.json",
]

def sha(data): return hashlib.sha256(data).hexdigest()

def record(root=REPO_ROOT):
    return {
        "schema_version": "1.0.0", "phase": 11, "base": BASE,
        "authorization": "Owner requested next BH-05 phase after merged Phase 10 PR 61; Phase 11 only.",
        "branch": "codex/bh05-phase11-conformance",
        "sections": ["11.1", "11.2", "11.3", "11.4", "11.5"],
        "delivery": ["verified section commits", "single PR", "merge", "checkout main", "sync origin", "delete feature branch"],
        "input_hashes": {p: sha(subprocess.check_output(["git", "show", BASE + ":" + p], cwd=root)) for p in INPUTS},
        "active": ["local ERTS/headless", "Linux Chrome AtomVM/DOM", "Linux Firefox development AtomVM/DOM", "direct GTK portability slice"],
        "deferred_bh22": ["Windows", "macOS", "Safari/WebKit product", "Android/iOS devices", "manual assistive-technology pairings"],
        "normalization_excludes": ["pid", "reference", "clock-origin", "scheduler-reductions", "stack-trace", "adapter-transaction", "browser-generated-id", "private-module"],
        "states": ["exact-match", "allowed-runtime-variation", "fail", "blocked", "not-applicable", "deferred"],
        "support_state": "unsupported", "phase12_authorized": False,
    }

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__); parser.add_argument("--check", action="store_true"); args = parser.parse_args()
    content = json.dumps(record(), indent=2) + "\n"; target = REPO_ROOT / TARGET
    if args.check:
        if not target.exists() or target.read_text() != content: raise SystemExit("conformance authority drift")
    else:
        with target.open("x") as stream: stream.write(content)
    print("BH-05 Phase 11 conformance authority: PASS")

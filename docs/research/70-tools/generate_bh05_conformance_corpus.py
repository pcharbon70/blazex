"""Generate the fixed Phase 11 public application corpus and normalized model."""
import argparse
import hashlib
import json
import re
from research_paths import REPO_ROOT

TARGET = "integration/bh-05/conformance-corpus-v0.1.0.json"
SOURCES = ["integration/bh-05/browser_conformance/lib/components.ex"]
SCENARIOS = {
    "declaration-schema-slots": ["declaration", "required-default-local-host-props", "default-named-contextual-slots"],
    "composition-identity": ["pure", "nested-stateful", "process-root", "controlled-props", "keyed-insert-move-remove-replace"],
    "interaction-actions": ["event", "self-child-parent-message", "timer", "delayed-denied-effect", "lease-transfer-release", "command-intent"],
    "scope-registry-roots": ["tracked-fixed-context", "dynamic-registry", "multi-root"],
    "failure-recovery-disposal": ["callback-schema-output-failure", "renderer-reject", "persistent-retry", "stale-work-result", "root-crash", "fallback", "removal-replacement-remount-disposal"],
    "semantic-backends": ["layout", "action", "field", "selection", "keyed-list", "surface", "focus", "file-choice", "accessibility", "disposal"],
}
FORBIDDEN = re.compile(r"BlazeX\.(?:Core\.(?:Authoring|Evaluator)|Component\.(?:RootProcess|RootGuardian|RecoveryGuardian)|UITree\.(?:CompositionPlan|PureCandidates|SemanticAcceptance|NestedCandidates)|Renderer\.Headless\.Normalizer)|\b(?:document|window|Popcorn|Phoenix|LiveView|LocalLiveView)\b")

def sha(data): return hashlib.sha256(data).hexdigest()

def record(root=REPO_ROOT):
    return {
        "schema_version": "1.0.0", "contract": "blazex.bh05-conformance/0.1",
        "support_state": "unsupported", "fixture_policy": "documented public BlazeX APIs and portable values only",
        "sources": {p: sha((root / p).read_bytes()) for p in SOURCES},
        "scenarios": [{"id": key, "contract_version": 1, "dimensions": value} for key, value in SCENARIOS.items()],
        "steps": ["setup", "bootstrap", "register-root", "inject-input", "checkpoint", "inject-result-or-failure", "capture-final", "dispose", "verify-clean"],
        "normalized_fields": ["scenario", "step", "root", "component", "generation", "revision", "callback", "identity", "state", "semantic-output", "action", "failure", "cleanup", "final-state"],
        "excluded_fields": ["pid", "reference", "clock-origin", "reductions", "stack-trace", "adapter-transaction", "browser-generated-id", "private-module"],
        "conditional_semantics": False,
    }

def validate(root=REPO_ROOT):
    errors=[]
    if json.loads((root / TARGET).read_text()) != record(root): errors.append("corpus drift")
    for path in SOURCES:
        if FORBIDDEN.search((root/path).read_text()): errors.append("private/host import: " + path)
    return errors

if __name__ == "__main__":
    parser=argparse.ArgumentParser(description=__doc__); parser.add_argument("--check",action="store_true"); args=parser.parse_args()
    if args.check:
        errors=validate(); print("\n".join(errors) if errors else "BH-05 public conformance corpus: PASS"); raise SystemExit(bool(errors))
    with (REPO_ROOT/TARGET).open("x") as stream: stream.write(json.dumps(record(),indent=2)+"\n")
    print("BH-05 public conformance corpus generated")

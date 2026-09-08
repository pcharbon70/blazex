"""Generate empty BH-05 evidence and explicit inherited API ownership."""
import json
from pathlib import Path
import re
import sys
from research_paths import REPO_ROOT
from generate_bh05_activation import AREA, BASE, PACKAGES, GROUPS, blob, sha

GRAPH = {"blazex_core": [], "blazex_effects": ["blazex_core"], "blazex_ui_tree": ["blazex_core"],
         "blazex_renderer": ["blazex_core", "blazex_effects", "blazex_ui_tree"],
         "blazex_test": ["blazex_core", "blazex_effects", "blazex_ui_tree", "blazex_renderer"]}
ACTIVATION = {"phase": 1, "state": "governance-only", "behavior_implemented": False}
INVENTORY = {
    "BlazeX.Core": (2, "preserve namespace; supersede documentation with the future facade"),
    "BlazeX.Core.Component": (2, "preserve experimental callbacks; supersede with three-role callback algebra; migrate generic emissions in Phase 8"),
    "BlazeX.Core.Context": (9, "preserve per-evaluation context; migrate to root-scoped named context"),
    "BlazeX.Core.Diagnostic": (10, "preserve redaction; extend governed failure diagnostics without leaking callback values"),
    "BlazeX.Core.Evaluation": (5, "preserve internal accepted evaluation; migrate nested state and root ownership"),
    "BlazeX.Core.Evaluator": (4, "preserve bounded experimental evaluator; migrate composition and scheduling in Phases 4-7, replace generic emissions in Phase 8 and arbitrary module selection in Phase 9"),
    "BlazeX.Core.Event": (7, "preserve versioned semantic envelope; reconcile root transition scheduling"),
    "BlazeX.Core.Identity": (5, "preserve root/path/generation identity; reconcile nested keyed lifetime"),
    "BlazeX.Core.Portable": (3, "preserve bounded portable-value validation; reconcile prop and host-boundary schemas")}


def records(root=REPO_ROOT):
    root = Path(root)
    inventory = []
    for p in sorted((root / "packages/blazex_core/lib").rglob("*.ex")):
        path = p.relative_to(root).as_posix(); source = blob(root, path).decode()
        module = re.search(r"defmodule\s+(\S+)\s+do", source).group(1)
        phase, disposition = INVENTORY[module]
        inventory.append({"module": module, "path": path, "sha256": sha(source.encode()), "state": "inherited-experimental-not-bh05", "owner": "core-owner", "migration_phase": phase, "disposition": disposition,
                          "public_declarations": [line.strip() for line in source.splitlines() if re.match(r"\s*(def\s|@callback\s|defstruct\s)", line)]})
    ownership = {"schema_version": "1.0.0", "phase": 1, "base_revision": BASE, "status": "governance-only", "support_state": "unsupported", "dependency_graph": GRAPH,
                 "owners": {"blazex_core": ["facade-metadata", "schemas", "lifecycle", "identity", "state", "scheduling", "context", "registry", "command-intent", "diagnostics", "root-process-contract"],
                            "blazex_ui_tree": ["semantic-composition", "output-validation"], "blazex_effects": ["typed-effects", "capabilities", "results", "resource-leases", "cancellation", "timeout", "disposal"],
                            "blazex_test": ["public-fixtures", "deterministic-schedulers", "trace-normalization", "cross-runtime-assertions"]},
                 "roles": {"pure": {"retained_state": False, "own_process": False, "failure_owner": "process-root"},
                           "nested-stateful": {"retained_state": True, "own_process": False, "failure_owner": "process-root"},
                           "process-root-local-view": {"retained_state": True, "own_process": True, "failure_owner": "self"}},
                 "vocabulary_state": "planned-not-implemented", "lifecycle": ["unmounted", "mounting", "mounted", "updating", "committing", "failed", "replacing", "disposing", "disposed"],
                 "terminal_outcomes": ["committed", "rejected", "failed", "disposed"],
                 "values": {"props": "parent-controlled input", "slots": "declared semantic composition", "local_state": "unit-owned retained data", "context": "root-scoped named read contracts", "messages": "root-mailbox input", "events": "normalized local semantic input", "effects": "capability-gated intent/results", "resources": "owned cancellable leases", "commands": "typed untrusted remote intent, no server authority"},
                 "adapter_policy": "Runtime, hosts and renderers consume neutral contracts; they do not define component roles or callbacks. Server authorization remains outside local component state.",
                 "framework_deferral": "LiveView and LocalLiveView deferred; local-view means a BlazeX process-root, not either framework",
                 "inherited_api_inventory": inventory,
                 "forbidden_new_surfaces": ["arbitrary module dispatch", "unbounded generic emissions", "private runtime imports", "mutable instance handles", "native toolkit types", "server authority"]}
    index = {"schema_version": "1.0.0", "milestone": "BH-05", "phase": 1, "status": "activated-empty", "support_state": "unsupported", "groups": {name: [] for name in GROUPS}}
    schema = {"$schema": "https://json-schema.org/draft/2020-12/schema", "type": "object", "additionalProperties": False, "required": list(index),
              "properties": {key: {"const": value} for key, value in index.items() if key != "groups"}}
    schema["properties"]["groups"] = {"type": "object", "additionalProperties": False, "required": GROUPS, "properties": {name: {"type": "array", "maxItems": 0} for name in GROUPS}}
    return {AREA + "ownership-v0.1.0.json": ownership, "integration/bh-05/index-v0.1.0.json": index, "integration/bh-05/index.schema.json": schema}


if __name__ == "__main__":
    for name, data in records().items():
        target = REPO_ROOT / name; output = json.dumps(data, indent=2) + "\n"
        if "--write" in sys.argv:
            target.parent.mkdir(parents=True, exist_ok=True); target.write_text(output)
        elif target.read_text() != output:
            raise SystemExit("stale boundary record: " + name)
    print("BH-05 ownership and fourteen empty evidence classes verified.")

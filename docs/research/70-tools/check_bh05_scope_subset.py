"""Audit scoped context and registry APIs; no Wasm execution credit."""
import json
from research_paths import REPO_ROOT
from check_bh05_action_subset import check as action_check


def check(root=REPO_ROOT):
    evidence = action_check(root)
    base = root / "packages/blazex_core/lib/blazex/component"
    for name in ["scoped_context", "scoped_view", "component_registry"]:
        source = (base / (name + ".ex")).read_text()
        for forbidden in ["BlazeX.UITree", "BlazeX.Renderer", "BlazeX.Effects", "Phoenix.", "Popcorn.", "Task.", "Registry.", "DynamicSupervisor.", "File.", "System.", "Application.", "Module.concat", "String.to_atom", "String.to_existing_atom", "Code.", "apply("]:
            if forbidden in source:
                raise ValueError("unreviewed scope dependency: " + name + ":" + forbidden)
        if any(call in source for call in ["Process.", "GenServer.", "send("]):
            raise ValueError("scope admission gained process ownership")
    evidence.update({"scopes": "root-local immutable context and explicit loaded-module registry", "runtime_parity": False, "bundle_generation": False, "server_authority": False})
    return evidence


if __name__ == "__main__":
    print(json.dumps(check(), sort_keys=True))
    print("BH-05 scope subset: PASS (analysis only; no AtomVM execution credit)")

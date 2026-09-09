"""Audit the action subset without awarding Wasm or provider support credit."""
import json
from research_paths import REPO_ROOT
from check_bh05_scheduling_subset import check as scheduling_check


def check(root=REPO_ROOT):
    evidence = scheduling_check(root)
    base = root / "packages/blazex_core/lib/blazex/component"
    for name in ["action", "action_manifest", "action_ledger", "action_runtime", "action_view"]:
        source = (base / (name + ".ex")).read_text()
        for forbidden in ["BlazeX.UITree", "BlazeX.Renderer", "BlazeX.Effects", "Phoenix.", "Popcorn.", "Task.", "Registry.", "DynamicSupervisor.", "File.", "System.", "String.to_atom", "String.to_existing_atom"]:
            if forbidden in source:
                raise ValueError("unreviewed action dependency: " + name + ":" + forbidden)
        if name in ["action", "action_manifest", "action_ledger"]:
            if any(call in source for call in ["Process.", "GenServer.", "send("]):
                raise ValueError("pure action admission gained process ownership")
    runtime = (base / "action_runtime.ex").read_text()
    for required in ["make_ref()", "Process.send_after(", "Process.cancel_timer("]:
        if required not in runtime:
            raise ValueError("missing private action timeout primitive: " + required)
    evidence.update({"actions": "typed post-commit abstract requests, bounded leases and untrusted commands",
        "runtime_parity": False, "concrete_provider_execution": False, "server_authority": False})
    return evidence


if __name__ == "__main__":
    print(json.dumps(check(), sort_keys=True))
    print("BH-05 action subset: PASS (analysis only; no AtomVM execution credit)")

"""Audit new ERTS recovery primitives without claiming AtomVM execution support."""
import json
from research_paths import REPO_ROOT
from check_bh05_scope_subset import check as scope_check


def check(root=REPO_ROOT):
    evidence = scope_check(root)
    base = root / "packages/blazex_core/lib/blazex/component"
    for name in ["recovery_policy", "recovery_port", "recovery_runtime", "recovery_guardian", "recovery_cleanup", "recovery_view"]:
        source = (base / (name + ".ex")).read_text()
        for forbidden in ["BlazeX.UITree", "BlazeX.Renderer", "BlazeX.Effects", "Phoenix.", "Popcorn.", "Task.", "Registry.", "DynamicSupervisor.", "File.", "Application.", "Module.concat", "String.to_atom", "String.to_existing_atom"]:
            if forbidden in source: raise ValueError("unreviewed recovery dependency: " + name + ":" + forbidden)
        if name == "recovery_policy" and any(call in source for call in ["Process.", "GenServer.", "send("]):
            raise ValueError("pure recovery policy gained process ownership")
    port = (base / "recovery_port.ex").read_text()
    if not all(call in port for call in [":erlang.spawn_opt", ":link", ":monitor", "Process.unlink", "Process.exit"]):
        raise ValueError("bounded port worker lifecycle drift")
    evidence.update({"recovery": "bounded ERTS linked/monitored helpers, root guardian and monotonic retry/cleanup deadlines", "runtime_parity": False,
        "new_erts_primitives": ["spawn_opt link/monitor", "monitor DOWN", "unlink/exit", "monotonic_time"],
        "atomvm_execution": False, "qualification_owner": "runtime profile owner", "reactivation_phase": "BH-05 Phase 11"})
    return evidence


if __name__ == "__main__":
    print(json.dumps(check(), sort_keys=True))
    print("BH-05 recovery subset: PASS (ERTS only; new helper primitives require Phase 11 qualification)")

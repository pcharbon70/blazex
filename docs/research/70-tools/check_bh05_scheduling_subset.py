"""Audit the Phase 7 scheduling subset without awarding Wasm execution parity."""
import json
from research_paths import REPO_ROOT
from check_bh05_root_subset import check as root_check


def check(root=REPO_ROOT):
    evidence = root_check(root=root)
    base = root / "packages/blazex_core/lib/blazex/component"
    sources = {name: (base / (name + ".ex")).read_text() for name in ["root_schedule", "root_timers", "scheduling_intents", "scheduled_view"]}
    for name, source in sources.items():
        for forbidden in ["BlazeX.UITree", "BlazeX.Renderer", "BlazeX.Effects", "Phoenix.", "Popcorn.", "DynamicSupervisor.", "Registry.", "Task.", ":timer.send_interval", "Process.send_interval"]:
            if forbidden in source:
                raise ValueError("unreviewed scheduling dependency: " + name + ":" + forbidden)
    for required in ["make_ref()", "Process.send_after(", "Process.cancel_timer(", ":waiting", ":firing"]:
        if required not in sources["root_timers"]:
            raise ValueError("missing owned timer primitive: " + required)
    for name in ["root_schedule", "scheduling_intents"]:
        if any(primitive in sources[name] for primitive in ["Process.", "GenServer.", "send("]):
            raise ValueError("pure scheduling admission gained process ownership")
    evidence.update({"scheduling": "bounded normalized FIFO with commit-bound intents and fixed-delay owned timers", "runtime_parity": False, "raw_vm_mailbox_bounded": False})
    return evidence


if __name__ == "__main__":
    print(json.dumps(check(), sort_keys=True))
    print("BH-05 scheduling subset: PASS (analysis only; no AtomVM execution credit)")

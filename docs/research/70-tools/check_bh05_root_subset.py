"""Check the pinned Popcorn supervision patches and bounded root API subset; not VM execution parity."""
import hashlib
import io
from pathlib import Path
import tarfile
from research_paths import REPO_ROOT

PACKAGE_SHA = "356084a017b3b6e37ad3c947313f7da9031eee083e77d03e1ba1f26b55e04835"
PATCHES = {
    "patches/otp/stdlib/supervisor.erl": "69da759658bf86243810dda8801974021cb8d353006371ba2195bb3ab03aafd6",
    "patches/otp/stdlib/gen_server.erl": "1c777a14eb2a1ba5fb3977f4a8c7950f7c5e0d3c89dafc7c963ed8468390f544",
}


def check(package=None, root=REPO_ROOT):
    package = Path(package or Path.home() / ".hex/packages/hexpm/popcorn-0.3.3.tar")
    data = package.read_bytes()
    if hashlib.sha256(data).hexdigest() != PACKAGE_SHA:
        raise ValueError("Popcorn package hash mismatch")
    with tarfile.open(fileobj=io.BytesIO(data)) as outer:
        archive = outer.extractfile("contents.tar.gz").read()
    with tarfile.open(fileobj=io.BytesIO(archive), mode="r:gz") as inner:
        for name, digest in PATCHES.items():
            if hashlib.sha256(inner.extractfile(name).read()).hexdigest() != digest:
                raise ValueError("supervision patch drift: " + name)
    paths = ["local_view", "root_guardian", "root_process"]
    source = "\n".join((root / "packages/blazex_core/lib/blazex/component" / (name + ".ex")).read_text() for name in paths)
    for prohibited in ["DynamicSupervisor.", "Registry.", "Task.", "handle_continue", ":hibernate", "Process.exit("]:
        if prohibited in source:
            raise ValueError("unreviewed supervision primitive: " + prohibited)
    for required in ["strategy: :one_for_one", "restart: :temporary", "Process.flag(:trap_exit, true)",
                     ":erlang.exit(", "Process.send_after(", "Process.cancel_timer("]:
        if required not in source:
            raise ValueError("missing root lifecycle primitive: " + required)
    return {"popcorn": "0.3.3", "package_sha256": PACKAGE_SHA, "patches": PATCHES,
            "erts_execution": "separate package/conformance gate", "atomvm_execution": False,
            "standalone_atomvm_0_6_6_compatible": False,
            "qualification_owner": "runtime profile owner", "reactivation_phase": "BH-05 Phase 11"}


if __name__ == "__main__":
    import json
    print(json.dumps(check(), sort_keys=True))
    print("BH-05 root supervision subset: PASS (analysis only; no AtomVM execution credit)")

#!/usr/bin/env python3
"""Exercise BH-01 Phase 3 fail-closed paths against the actual Wasm runtime."""

from __future__ import annotations

import argparse
import hashlib
import json
import shutil
import subprocess
import tempfile
from pathlib import Path
from typing import Any

import run_probe


HERE = Path(__file__).resolve().parent
REPO = HERE.parents[2]


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def execute(command: list[str], timeout: int = 15) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        command,
        cwd=REPO,
        capture_output=True,
        text=True,
        check=False,
        timeout=timeout,
    )


def negative_runtime_case(
    case_id: str,
    node: Path,
    harness: Path,
    runtime: Path,
    bundle: Path,
    workspace: Path,
    mutate_runtime: bool = False,
) -> dict[str, Any]:
    runtime_root = workspace / case_id
    runtime_root.mkdir()
    candidate_runtime = runtime_root / "AtomVM.mjs"
    candidate_wasm = runtime_root / "AtomVM.wasm"
    shutil.copyfile(runtime, candidate_runtime)
    wasm = runtime.with_name("AtomVM.wasm").read_bytes()
    if mutate_runtime:
        wasm = b"X" + wasm[1:]
    candidate_wasm.write_bytes(wasm)
    candidate_bundle = runtime_root / "bundle.avm"
    shutil.copyfile(bundle, candidate_bundle)
    result = execute([str(node), str(harness), str(candidate_runtime), str(candidate_bundle)])
    passed = result.returncode != 0 and "BXHARNESS|runtime_returned=pass" not in result.stdout
    return {
        "case_id": case_id,
        "expected": "runtime rejects input",
        "observed": "nonzero-runtime-rejection" if passed else "unexpected-success",
        "returncode_nonzero": result.returncode != 0,
        "passed": passed,
    }


def bundle_failure_case(
    case_id: str,
    node: Path,
    harness: Path,
    runtime: Path,
    bundle_bytes: bytes,
    workspace: Path,
) -> dict[str, Any]:
    candidate = workspace / f"{case_id}.avm"
    candidate.write_bytes(bundle_bytes)
    result = execute([str(node), str(harness), str(runtime), str(candidate)])
    passed = result.returncode != 0 and "cleanup,complete" not in result.stdout
    return {
        "case_id": case_id,
        "expected": "runtime rejects bundle before clean completion",
        "observed": "nonzero-no-clean-completion" if passed else "unexpected-success-or-cleanup",
        "returncode_nonzero": result.returncode != 0,
        "passed": passed,
    }


def node_contract_case(case_id: str, node: Path, script: str) -> dict[str, Any]:
    result = execute([str(node), "--input-type=module", "-e", script])
    passed = result.returncode == 0 and "EXPECTED_REJECTION" in result.stdout
    return {
        "case_id": case_id,
        "expected": "WebAssembly host contract rejects input",
        "observed": "expected-rejection" if passed else "missing-rejection",
        "returncode": result.returncode,
        "passed": passed,
    }


def run(node: Path, runtime: Path, bundle: Path) -> dict[str, Any]:
    harness = HERE / "harness/run_runtime_probe.mjs"
    canonical = execute([str(node), str(harness), str(runtime), str(bundle)])
    required_runtime_results = (
        "controlled_crash",
        "worker_restarted",
        "timer_cancelled",
        "stale_generation_rejected",
        "late_result_drained",
        "forbidden_capability_rejected",
        "post_disposal_rejected",
        "cleanup,complete",
        "BXHARNESS|runtime_returned=pass",
    )
    canonical_passed = canonical.returncode == 0 and all(token in canonical.stdout for token in required_runtime_results)
    results: list[dict[str, Any]] = [
        {
            "case_id": "canonical-runtime-control",
            "expected": "actual Wasm runtime executes crash, timer race, malformed capability, and cleanup paths",
            "observed": "all-required-runtime-traces" if canonical_passed else "missing-runtime-trace",
            "returncode": canonical.returncode,
            "passed": canonical_passed,
        }
    ]

    runtime_url = runtime.with_name("AtomVM.wasm").resolve().as_uri()
    missing_import_script = f"""
import {{readFile}} from 'node:fs/promises';
const bytes = await readFile(new URL('{runtime_url}'));
const module = await WebAssembly.compile(bytes);
try {{ new WebAssembly.Instance(module, {{}}); process.exit(2); }}
catch (error) {{ console.log('EXPECTED_REJECTION missing-import'); }}
"""
    incompatible_memory_script = f"""
import {{readFile}} from 'node:fs/promises';
const bytes = await readFile(new URL('{runtime_url}'));
const module = await WebAssembly.compile(bytes);
const imports = {{}};
for (const item of WebAssembly.Module.imports(module)) {{
  imports[item.module] ??= {{}};
  imports[item.module][item.name] = item.kind === 'memory'
    ? new WebAssembly.Memory({{initial: 128, maximum: 128, shared: true}})
    : () => 0;
}}
try {{ new WebAssembly.Instance(module, imports); process.exit(2); }}
catch (error) {{
  if (!String(error).includes('memory')) process.exit(3);
  console.log('EXPECTED_REJECTION incompatible-memory');
}}
"""
    results.append(node_contract_case("missing-import", node, missing_import_script))
    results.append(node_contract_case("incompatible-memory-contract", node, incompatible_memory_script))

    bundle_data = bundle.read_bytes()
    worker_name = b"Elixir.BlazeX.BH01.RuntimeSmoke.Worker.beam"
    replacement = b"Elixir.BlazeX.BH01.RuntimeSmoke.Xorker.beam"
    if bundle_data.count(worker_name) != 1 or len(worker_name) != len(replacement):
        raise SystemExit("cannot create deterministic missing-module fixture")

    with tempfile.TemporaryDirectory(prefix="blazex-bh01-negative-") as temporary:
        workspace = Path(temporary)
        results.append(negative_runtime_case("invalid-wasm", node, harness, runtime, bundle, workspace, mutate_runtime=True))
        results.append(bundle_failure_case("corrupt-bundle", node, harness, runtime, bundle_data[: len(bundle_data) // 2], workspace))
        results.append(bundle_failure_case("unknown-bundle", node, harness, runtime, b"not-an-avm-bundle", workspace))
        results.append(bundle_failure_case("missing-module", node, harness, runtime, bundle_data.replace(worker_name, replacement, 1), workspace))

    contract = run_probe.load(HERE / "semantics-contract.json")
    retained = run_probe.load(HERE.parent / "raw-evidence/bh01-phase3-runtime-semantics.json")
    manifest = run_probe.load(HERE / "bundle-manifest.json")
    failed_cleanup = json.loads(json.dumps(retained))
    failed_cleanup["observations"]["cleanup"] = "incomplete"
    cleanup_rejected = bool(run_probe.validate_evidence(contract, failed_cleanup, manifest))
    results.append(
        {
            "case_id": "cleanup-evidence-failure",
            "expected": "retained-evidence validator rejects incomplete cleanup",
            "observed": "validator-rejected" if cleanup_rejected else "validator-accepted",
            "passed": cleanup_rejected,
        }
    )

    all_passed = all(item["passed"] for item in results)
    return {
        "schema_version": "1.0.0",
        "evidence_id": "BX-BH01-PHASE3-NEGATIVE-PATHS-0.1",
        "status": "passed" if all_passed else "failed",
        "runtime": {"path": runtime.relative_to(REPO).as_posix(), "sha256": digest(runtime)},
        "wasm": {"path": runtime.with_name("AtomVM.wasm").relative_to(REPO).as_posix(), "sha256": digest(runtime.with_name("AtomVM.wasm"))},
        "bundle": {"path": bundle.relative_to(REPO).as_posix(), "sha256": digest(bundle)},
        "results": results,
        "summary": {"cases": len(results), "passed": sum(item["passed"] for item in results)},
        "limitations": [
            "The Node harness is a non-browser host and does not prove browser loader failure UX.",
            "Malformed protocol/capability, timer race, crash/restart, and late-message behavior execute inside the canonical Wasm fixture.",
            "Cleanup-evidence corruption is a validator negative because a deliberately leaking guest is not retained as a product fixture.",
        ],
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--node", type=Path, required=True)
    parser.add_argument("--runtime", type=Path, required=True)
    parser.add_argument("--bundle", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    args.node = args.node.resolve()
    args.runtime = args.runtime.resolve()
    args.bundle = args.bundle.resolve()
    args.output = args.output.resolve()
    evidence = run(args.node, args.runtime, args.bundle)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(evidence, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    if evidence["status"] != "passed":
        failed = [item["case_id"] for item in evidence["results"] if not item["passed"]]
        raise SystemExit(f"BH-01 Phase 3 negative probes: FAIL {failed}")
    print(f"BH-01 Phase 3 negative probes: PASS ({evidence['summary']['passed']}/{evidence['summary']['cases']})")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

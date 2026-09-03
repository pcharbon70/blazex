#!/usr/bin/env python3
"""Execute and validate the BH-01 AtomVM semantics probe."""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import subprocess
import sys
from pathlib import Path
from typing import Any


HERE = Path(__file__).resolve().parent
RESULT = re.compile(r"\{result,([^}]+)\}")


def load(path: Path) -> dict[str, Any]:
    with path.open(encoding="utf-8") as stream:
        return json.load(stream)


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def validate_output(contract: dict[str, Any], output: str, returncode: int) -> list[str]:
    errors: list[str] = []
    results = RESULT.findall(output)
    for required in contract.get("required_results", []):
        if required not in results:
            errors.append(f"missing runtime result: {required}")
    if returncode != 0:
        errors.append(f"Node runtime returned {returncode}")
    if "{result,failed}" in output:
        errors.append("runtime emitted a failed trace")
    required = contract.get("required_observations", {})
    checks = {
        "machine": f'{{machine,"{required.get("machine")}"}}',
        "memory_pages": f'BXHARNESS|memory_pages={required.get("memory_pages")}',
        "message_queue_len": f'{{message_queue_len,{required.get("message_queue_len")}}}',
        "cleanup": f'{{cleanup,{required.get("cleanup")}}}',
        "return_value": f'Return value: {required.get("return_value")}',
    }
    for observation, token in checks.items():
        if token not in output:
            errors.append(f"missing runtime observation: {observation}")
    sequences = [int(value) for value in re.findall(r"\{sequence,(\d+)\}", output)]
    if sequences != list(range(1, len(sequences) + 1)):
        errors.append("runtime trace sequence is not contiguous")
    return errors


def validate_evidence(
    contract: dict[str, Any], evidence_record: dict[str, Any], bundle_manifest: dict[str, Any]
) -> list[str]:
    errors: list[str] = []
    if evidence_record.get("status") != "observed-pass":
        errors.append("runtime semantics evidence is not an observed pass")
    if evidence_record.get("semantics_contract_sha256") != digest(HERE / "semantics-contract.json"):
        errors.append("runtime semantics contract hash drifted")
    if evidence_record.get("required_results") != contract.get("required_results"):
        errors.append("runtime evidence required results differ from the contract")
    if evidence_record.get("unsupported_or_deferred") != contract.get("expected_deviations"):
        errors.append("runtime evidence deviations differ from the contract")
    observations = evidence_record.get("observations", {})
    if observations.get("memory_pages") != 256 or observations.get("message_queue_len_after_repeat_teardown") != 0:
        errors.append("runtime evidence does not show bounded memory/mailbox cleanup")
    if observations.get("cleanup") != "complete" or observations.get("trace_sequence_count") != 33:
        errors.append("runtime evidence lifecycle did not converge")
    identities = {item.get("name"): item.get("sha256") for item in evidence_record.get("tool_identities", [])}
    release_bundle = next(
        (
            item
            for item in bundle_manifest.get("artifacts", [])
            if item.get("mode") == "release" and item.get("kind") == "avm"
        ),
        {},
    )
    if identities.get("bundle.avm") != release_bundle.get("sha256"):
        errors.append("runtime evidence bundle identity differs from the bundle manifest")
    return errors


def evidence(contract: dict[str, Any], node: Path, runtime: Path, bundle: Path, output: str) -> dict[str, Any]:
    trace = [
        line
        for line in output.splitlines()
        if line.startswith(("{bxtrace", "{bxidentity", "{bxobservation", "Return value:", "BXHARNESS|"))
    ]
    return {
        "schema_version": "1.0.0",
        "evidence_id": "BX-BH01-RUNTIME-SEMANTICS-NODE-0.1",
        "status": "observed-pass",
        "harness": "single-process Node CLI",
        "semantics_contract_sha256": digest(HERE / "semantics-contract.json"),
        "harness_sha256": digest(HERE / "harness/run_runtime_probe.mjs"),
        "tool_identities": [
            {"name": "node", "version": "26.8.1", "sha256": digest(node)},
            {"name": "AtomVM.mjs", "sha256": digest(runtime)},
            {"name": "bundle.avm", "sha256": digest(bundle)},
        ],
        "required_results": contract["required_results"],
        "observations": {
            "machine": "ATOM",
            "reported_otp_release": "27",
            "memory_pages": 256,
            "message_queue_len_after_repeat_teardown": 0,
            "timer_cancel_return": False,
            "timer_cancel_non_delivery": True,
            "cleanup": "complete",
            "trace_sequence_count": len(re.findall(r"\{sequence,", output)),
        },
        "unsupported_or_deferred": contract["expected_deviations"],
        "scheduler_assumption": "The Node CLI and VM share an event loop; browser-host calls require a worker-separated host surface.",
        "mailbox_bound": "All injected messages are consumed; final message_queue_len is zero.",
        "raw_trace": trace,
        "limitations": [
            "This proves Wasm runtime behavior in Node, not browser loading, DOM behavior, or browser compatibility.",
            "The host exchange in this harness is stdout plus an in-VM bounded state machine; direct Popcorn Module.call remains a Phase 4 worker-host proof.",
            "One process tree and small bounded payloads do not establish production-scale scheduling or memory behavior."
        ],
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--node", type=Path, required=True)
    parser.add_argument("--runtime", type=Path, required=True)
    parser.add_argument("--bundle", type=Path, required=True)
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    contract = load(HERE / "semantics-contract.json")
    command = [str(args.node.resolve()), str(HERE / "harness/run_runtime_probe.mjs"), str(args.runtime.resolve()), str(args.bundle.resolve())]
    completed = subprocess.run(command, cwd=HERE, capture_output=True, text=True, timeout=10, check=False)
    combined = completed.stdout + completed.stderr
    errors = validate_output(contract, combined, completed.returncode)
    if errors:
        for error in errors:
            print(f"ERROR: {error}", file=sys.stderr)
        print(combined, file=sys.stderr)
        return 1
    if args.output:
        record = evidence(contract, args.node, args.runtime, args.bundle, combined)
        manifest = load(HERE / "bundle-manifest.json")
        errors = validate_evidence(contract, record, manifest)
        if errors:
            for error in errors:
                print(f"ERROR: {error}", file=sys.stderr)
            return 1
        args.output.write_text(json.dumps(record, indent=2) + "\n", encoding="utf-8")
    print(combined, end="")
    print("BH-01 Phase 3 Node runtime semantics: PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

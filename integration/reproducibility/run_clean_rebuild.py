#!/usr/bin/env python3
"""Execute one cache-empty BH-01 Phase 10 rebuild and browser replay."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import shutil
import subprocess
import time
import urllib.request
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


BEAM_IMAGE = "docker.io/hexpm/elixir@sha256:8d03cfb52e3fa3f5d83d749942b7c45c966dda48a7c4ba4f069390379b59fc39"
BEAM_IMAGE_CONFIG = "a2386c21edd5c612b4ed6e2731daba806177dba55baf977ee456c6e194f60d9f"
EXPECTED_PROFILE = "818ac7b967db6519c766f9d1fff80455cc92d205e3f188252e6da27258ee4aad"


def sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def load(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def stable_semantic(record: dict[str, Any], scenario: str) -> str:
    if scenario == "measurement":
        value = {
            "status": record["status"],
            "browser": record["browser"]["type"],
            "support": record["browser"]["support_status"],
            "manifest": record["artifact_manifest"],
            "configuration": record["configuration"],
            "metric_scenarios": sorted((item["metric_id"], item["scenario"], len(item["samples"])) for item in record["measurements"]),
            "failures": record["failures"],
        }
    else:
        ignored = {"captured_at", "browser", "evidence_id", "implementation_revision", "evidence_sha256"}
        value = {key: item for key, item in record.items() if key not in ignored}
    return hashlib.sha256(json.dumps(value, sort_keys=True, separators=(",", ":")).encode()).hexdigest()


class Runner:
    def __init__(self, args: argparse.Namespace):
        self.args = args
        self.source = args.source.resolve()
        self.output = args.output.resolve()
        self.logs = args.logs_directory.resolve() if args.logs_directory else self.output.parent / f"{self.output.stem}-logs"
        self.commands: list[dict[str, Any]] = []
        self.output.parent.mkdir(parents=True, exist_ok=True)
        self.logs.mkdir(parents=True, exist_ok=False)
        cache_prefix = f"{self.source.name}-{args.environment.lower()}"
        self.mix_home = self.source.parent / f"{cache_prefix}-mix-home"
        self.hex_home = self.source.parent / f"{cache_prefix}-hex-home"
        self.npm_cache = self.source.parent / f"{cache_prefix}-npm-cache"
        for path in (self.mix_home, self.hex_home, self.npm_cache):
            path.mkdir(mode=0o700)
        self.node_env = os.environ.copy()
        self.node_env["PATH"] = f"{args.node.parent}:{os.environ.get('PATH', '')}"
        self.node_env["npm_config_cache"] = str(self.npm_cache)

    def run(self, name: str, command: list[str], *, cwd: Path | None = None, env: dict[str, str] | None = None, network: bool = False, expected: int = 0, timeout: int = 1800) -> subprocess.CompletedProcess[str]:
        started = time.monotonic()
        result = subprocess.run(command, cwd=cwd or self.source, env=env, text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=timeout, check=False)
        duration = round((time.monotonic() - started) * 1000)
        log = self.logs / f"{len(self.commands) + 1:02d}-{name}.log"
        log.write_text(result.stdout, encoding="utf-8")
        if result.returncode != expected:
            raise RuntimeError(f"{name} exited {result.returncode}, expected {expected}; see {log}")
        self.commands.append({"id": name, "network": network, "result": "pass", "duration_ms": duration, "log_sha256": sha(log)})
        return result

    def docker_mix(self, name: str, project: str, arguments: list[str], *, network: bool, mix_env: str = "test", canonical_project_root: bool = False) -> None:
        mounted_source = self.source / project if canonical_project_root else self.source
        workdir = "/workspace" if canonical_project_root else f"/workspace/{project}"
        command = [
            "docker", "run", "--rm", "--network", "bridge" if network else "none",
            "--user", f"{os.getuid()}:{os.getgid()}",
            "--volume", f"{mounted_source}:/workspace",
            "--volume", f"{self.mix_home}:/mix-home",
            "--volume", f"{self.hex_home}:/hex-home",
            "--workdir", workdir,
            "--env", "MIX_HOME=/mix-home", "--env", "HEX_HOME=/hex-home", "--env", f"MIX_ENV={mix_env}",
            BEAM_IMAGE,
        ] + arguments
        self.run(name, command, network=network)

    def acquire_and_build(self) -> dict[str, Any]:
        # The browser package retains Elixir macro literals from dependencies.
        # Mounting this fixture at one fixed root prevents checkout-layout paths
        # from becoming artifact identity. Phase 10 attempt 1 proved this rule is
        # necessary by localizing all AVM drift to Jason's embedded source path.
        fixture = "integration/fixtures/browser_host"
        self.docker_mix("hex-install", fixture, ["mix", "local.hex", "--force"], network=True, canonical_project_root=True)
        self.docker_mix("rebar-install", fixture, ["mix", "local.rebar", "--force"], network=True, canonical_project_root=True)
        self.docker_mix("fixture-deps", fixture, ["mix", "deps.get", "--check-locked"], network=True, mix_env="prod", canonical_project_root=True)
        self.docker_mix("fixture-compile", fixture, ["mix", "compile"], network=False, mix_env="prod", canonical_project_root=True)
        self.docker_mix("fixture-package", fixture, ["mix", "bh01.browser_package", "--out-dir", "generated"], network=False, mix_env="prod", canonical_project_root=True)
        self.docker_mix("fixture-test", fixture, ["mix", "test"], network=False, canonical_project_root=True)
        self.run("fixture-manifest", [str(self.args.python), "generate_manifest.py", "--generated", "generated", "--output", str(self.source / "phase10-browser-bundle-manifest.json")], cwd=self.source / "integration/fixtures/browser_host")

        self.docker_mix("profile-deps", "profiles/browser_phoenix", ["mix", "deps.get", "--check-locked"], network=True)
        self.docker_mix("profile-test", "profiles/browser_phoenix", ["mix", "test"], network=False)

        runtime_output = self.source / "packages/blazex_runtime_popcorn/runtime/generated"
        inputs = self.args.runtime_inputs.resolve()
        self.run(
            "runtime-build",
            [
                str(self.args.python), "packages/blazex_runtime_popcorn/runtime/build_runtime.py",
                "--fissionvm", str(inputs / "fissionvm-6c3208c7.tar.gz"),
                "--mbedtls", str(inputs / "mbedtls-v3.6.3.1.tar.gz"),
                "--ninja", str(inputs / "ninja-linux-v1.12.1.zip"),
                "--gperf", str(inputs / "gperf_3.1-1build1_amd64.deb"),
                "--zlib", str(inputs / "zlib-1.3.1.tar.gz"),
                "--output", str(runtime_output),
            ],
            timeout=3600,
        )
        runtime_manifest = self.source / "phase10-runtime-binary-manifest.json"
        self.run("runtime-manifest", [str(self.args.python), "packages/blazex_runtime_popcorn/runtime/generate_manifest.py", "--artifacts", str(runtime_output), "--output", str(runtime_manifest)])

        runtime_js = self.source / "js/blazex_runtime"
        self.run("npm-acquire", [str(self.args.npm), "ci", "--ignore-scripts", "--no-audit", "--no-fund"], cwd=runtime_js, env=self.node_env, network=True)
        self.run("npm-esbuild-install", [str(self.args.node), "node_modules/esbuild/install.js"], cwd=runtime_js, env=self.node_env)
        self.run("runtime-js-test", [str(self.args.npm), "test"], cwd=runtime_js, env=self.node_env)
        self.run("runtime-js-build", [str(self.args.npm), "run", "build"], cwd=runtime_js, env=self.node_env)
        renderer = self.source / "packages/blazex_renderer_dom"
        self.run("renderer-js-test", [str(self.args.npm), "test"], cwd=renderer, env=self.node_env)
        self.run("renderer-js-build", [str(self.args.npm), "run", "build"], cwd=renderer, env=self.node_env)

        profile = self.source / "profiles/browser_phoenix/priv/static/bh01"
        self.run("profile-build", [str(self.args.python), "profiles/browser_phoenix/assets/phase4/build_profile.py", "--output", str(profile)])
        self.run("profile-verify", [str(self.args.python), "profiles/browser_phoenix/assets/phase4/verify_profile.py", str(profile)])
        profile_sha = sha(profile / "profile-assets-manifest.json")
        if profile_sha != EXPECTED_PROFILE:
            raise RuntimeError(f"profile identity drifted: {profile_sha}")
        retained = []
        for name, source in (
            ("runtime-binary-manifest.json", runtime_manifest),
            ("browser-bundle-manifest.json", self.source / "phase10-browser-bundle-manifest.json"),
            ("profile-assets-manifest.json", profile / "profile-assets-manifest.json"),
            ("runtime-debug-web-build.log", runtime_output / "debug-web/build.log"),
            ("runtime-release-web-build.log", runtime_output / "release-web/build.log"),
            ("runtime-release-node-probe-build.log", runtime_output / "release-node-probe/build.log"),
        ):
            destination = self.logs / name
            shutil.copyfile(source, destination)
            retained.append({"path": f"{self.logs.name}/{name}", "sha256": sha(destination)})
        return {
            "runtime_manifest_sha256": sha(runtime_manifest),
            "browser_bundle_manifest_sha256": sha(self.source / "phase10-browser-bundle-manifest.json"),
            "profile_manifest_sha256": profile_sha,
            "profile_file_count": len(load(profile / "profile-assets-manifest.json")["artifacts"]),
            "retained_files": retained,
        }

    def server(self) -> subprocess.Popen[str]:
        command = [
            "docker", "run", "--rm", "--network", "host", "--user", f"{os.getuid()}:{os.getgid()}",
            "--volume", f"{self.source}:/workspace", "--volume", f"{self.mix_home}:/mix-home", "--volume", f"{self.hex_home}:/hex-home",
            "--workdir", "/workspace/profiles/browser_phoenix", "--env", "MIX_HOME=/mix-home", "--env", "HEX_HOME=/hex-home",
            "--env", "MIX_ENV=test", "--env", "PHX_SERVER=true", "--env", f"PORT={self.args.port}", BEAM_IMAGE, "mix", "run", "--no-halt",
        ]
        log_path = self.logs / f"{len(self.commands) + 1:02d}-profile-server.log"
        log = log_path.open("w", encoding="utf-8")
        process = subprocess.Popen(command, stdout=log, stderr=subprocess.STDOUT, text=True)
        started = time.monotonic()
        url = f"http://127.0.0.1:{self.args.port}/bh01/health"
        try:
            while time.monotonic() - started < 90:
                if process.poll() is not None:
                    raise RuntimeError("profile server exited before readiness")
                try:
                    with urllib.request.urlopen(url, timeout=2) as response:
                        if response.status == 200:
                            self.commands.append({"id": "profile-server", "network": False, "result": "pass", "duration_ms": round((time.monotonic() - started) * 1000), "log_sha256": "pending"})
                            process._blazex_log = log  # type: ignore[attr-defined]
                            process._blazex_log_path = log_path  # type: ignore[attr-defined]
                            return process
                except Exception:
                    time.sleep(0.25)
            raise RuntimeError("profile server readiness timed out")
        except Exception:
            process.terminate()
            log.close()
            raise

    def stop_server(self, process: subprocess.Popen[str]) -> None:
        process.terminate()
        try:
            process.wait(timeout=10)
        except subprocess.TimeoutExpired:
            process.kill()
            process.wait(timeout=10)
        log = process._blazex_log  # type: ignore[attr-defined]
        log.close()
        path = process._blazex_log_path  # type: ignore[attr-defined]
        server_record = next(item for item in reversed(self.commands) if item["id"] == "profile-server" and item["log_sha256"] == "pending")
        server_record["log_sha256"] = sha(path)

    def browser_runs(self) -> list[dict[str, Any]]:
        process = self.server()
        records: list[dict[str, Any]] = []
        runtime_js = self.source / "js/blazex_runtime"
        base = f"http://127.0.0.1:{self.args.port}/bh01/"
        try:
            for browser, binary, authority in (("chromium", self.args.chrome, "required-row"), ("firefox", self.args.firefox, "experimental-development-evidence")):
                for scenario in ("prerequisites", "behavior", "accessibility", "compatibility"):
                    path = self.source / f"phase10-{self.args.environment.lower()}-{browser}-{scenario}.json"
                    env = self.node_env | {
                        "BLAZEX_BASE_URL": base,
                        "BLAZEX_BROWSER_TYPE": browser,
                        "BLAZEX_BROWSER_PATH": str(binary),
                        "BLAZEX_EVIDENCE_PATH": str(path),
                        "BLAZEX_MATRIX_IDENTITY": self.args.source_revision,
                        "BLAZEX_ROW_AUTHORITY": authority,
                    }
                    self.run(f"browser-{browser}-{scenario}", [str(self.args.node), f"test/browser/phase8-{scenario}.integration.mjs"], cwd=runtime_js, env=env)
                    value = load(path)
                    retained = self.logs / f"browser-{browser}-{scenario}.json"
                    shutil.copyfile(path, retained)
                    records.append({"browser": browser, "scenario": scenario, "status": value["status"], "support_status": value["support_status"], "semantic_sha256": stable_semantic(value, scenario), "raw_sha256": sha(path), "evidence_path": f"{self.logs.name}/{retained.name}"})
                path = self.source / f"phase10-{self.args.environment.lower()}-{browser}-measurement.json"
                env = self.node_env | {
                    "BLAZEX_BASE_URL": base,
                    "BLAZEX_BROWSER_TYPE": browser,
                    "BLAZEX_BROWSER_PATH": str(binary),
                    "BLAZEX_BROWSER_PRODUCT": "Chrome for Testing" if browser == "chromium" else "Playwright patched Firefox development build",
                    "BLAZEX_EVIDENCE_PATH": str(path),
                    "BLAZEX_REVISION": self.args.source_revision,
                    "BLAZEX_ENVIRONMENT_ID": f"BX-BH01-ENV-PHASE10-CLEAN-{self.args.environment}-{browser.upper()}-0.1",
                    "BLAZEX_RUN_LABEL": f"CLEAN-{self.args.environment}",
                    "BLAZEX_COLD_START_SAMPLES": "3", "BLAZEX_WARM_START_SAMPLES": "3", "BLAZEX_FALLBACK_SAMPLES": "3",
                    "BLAZEX_INTERACTION_SAMPLES": "5", "BLAZEX_SERVER_SAMPLES": "3", "BLAZEX_CLEANUP_SAMPLES": "3",
                }
                self.run(f"browser-{browser}-measurement", [str(self.args.node), "test/browser/phase9-measurement.integration.mjs"], cwd=runtime_js, env=env)
                value = load(path)
                retained = self.logs / f"browser-{browser}-measurement.json"
                shutil.copyfile(path, retained)
                records.append({"browser": browser, "scenario": "measurement", "status": value["status"], "support_status": value["browser"]["support_status"], "semantic_sha256": stable_semantic(value, "measurement"), "raw_sha256": sha(path), "evidence_path": f"{self.logs.name}/{retained.name}"})
        finally:
            self.stop_server(process)
        return records

    def regenerate_reports(self) -> list[dict[str, Any]]:
        bench = self.source / "integration/benchmarks"
        generated = self.source / "phase10-generated-reports"
        generated.mkdir()
        mapping = {
            "summary": bench / "samples/bh01-phase9-linux-desktop-summary.json",
            "economics": bench / "reports/bh01-phase9-artifact-economics.json",
            "mitigations": bench / "reports/bh01-phase9-mitigation-assessment.json",
            "budgets": bench / "reports/bh01-phase9-budget-evaluation.json",
            "decision": bench / "reports/bh01-phase9-stop-decision.json",
            "rerun-attempt": bench / "reports/bh01-phase9-rerun-comparison-attempt-1.json",
            "rerun-final": bench / "reports/bh01-phase9-rerun-comparison.json",
        }
        outputs = {name: generated / f"{name}.json" for name in mapping}
        raw = bench / "raw-evidence"
        self.run("report-summary", [str(self.args.python), str(bench / "summarize_phase9.py"), "--browser", str(raw / "bh01-phase9-chromium-linux.json"), "--browser", str(raw / "bh01-phase9-firefox-linux.json"), "--build", str(raw / "bh01-phase9-build-linux.json"), "--artifacts", str(raw / "bh01-phase9-artifacts-linux.json"), "--output", str(outputs["summary"])])
        self.run("report-economics", [str(self.args.python), str(bench / "analyze_phase9.py"), "--summary", str(mapping["summary"]), "--artifacts", str(raw / "bh01-phase9-artifacts-linux.json"), "--revision", load(mapping["economics"])["source_revision"], "--economics-output", str(outputs["economics"]), "--mitigations-output", str(outputs["mitigations"]), "--economics-reference-path", str(mapping["economics"])])
        self.run("report-budgets", [str(self.args.python), str(bench / "evaluate_phase9.py"), "--summary", str(mapping["summary"]), "--economics", str(mapping["economics"]), "--mitigations", str(mapping["mitigations"]), "--deferrals", str(bench / "reports/bh01-phase9-deferred-qualification.json"), "--quality-contract", str(self.source / "docs/research/assets/quality-acceptance/blazex-quality-contract-v0.1.0.json"), "--revision", load(mapping["budgets"])["source_revision"], "--budget-output", str(outputs["budgets"]), "--decision-output", str(outputs["decision"]), "--budget-reference-path", str(mapping["budgets"])])
        compare = str(bench / "compare_phase9_reruns.py")
        self.run("report-rerun-attempt", [str(self.args.python), compare, "--primary", str(raw / "bh01-phase9-chromium-linux.json"), "--rerun", str(raw / "bh01-phase9-rerun-chromium-linux.json"), "--primary", str(raw / "bh01-phase9-firefox-linux.json"), "--rerun", str(raw / "bh01-phase9-rerun-firefox-linux.json"), "--revision", load(mapping["rerun-attempt"])["source_revision"], "--attempt-label", "ATTEMPT-1", "--output", str(outputs["rerun-attempt"])], expected=1)
        self.run("report-rerun-final", [str(self.args.python), compare, "--primary", str(raw / "bh01-phase9-chromium-linux.json"), "--rerun", str(raw / "bh01-phase9-rerun2-chromium-linux.json"), "--primary", str(raw / "bh01-phase9-firefox-linux.json"), "--rerun", str(raw / "bh01-phase9-rerun-firefox-linux.json"), "--revision", load(mapping["rerun-final"])["source_revision"], "--output", str(outputs["rerun-final"])], expected=1)
        records = []
        for name, canonical in mapping.items():
            if outputs[name].read_bytes() != canonical.read_bytes():
                raise RuntimeError(f"regenerated {name} differs from canonical report")
            records.append({"id": name, "matches_canonical": True, "sha256": sha(outputs[name])})
        return records

    def recovery(self) -> dict[str, Any]:
        profile = self.source / "profiles/browser_phoenix/priv/static/bh01"
        bundle = profile / "artifacts/bundle.avm"
        bundle.write_bytes(bundle.read_bytes() + b"phase10-tamper")
        self.run("tamper-rejection", [str(self.args.python), "profiles/browser_phoenix/assets/phase4/verify_profile.py", str(profile)], expected=1)
        self.run("profile-restore", [str(self.args.python), "profiles/browser_phoenix/assets/phase4/build_profile.py", "--output", str(profile)])
        self.run("restored-profile-verify", [str(self.args.python), "profiles/browser_phoenix/assets/phase4/verify_profile.py", str(profile)])
        restored = sha(profile / "profile-assets-manifest.json")
        return {"tamper_rejected": True, "restored_from_canonical_inputs": True, "restored_profile_sha256": restored}

    def execute(self) -> dict[str, Any]:
        forbidden = [path for name in ("deps", "_build", "node_modules") for path in self.source.rglob(name)]
        generated = [path for path in (self.source / "packages/blazex_runtime_popcorn/runtime/generated", self.source / "integration/fixtures/browser_host/generated", self.source / "profiles/browser_phoenix/priv/static/bh01") if path.exists()]
        if (self.source / ".git").exists() or forbidden or generated:
            raise RuntimeError("source is not a clean Git archive with empty project/generated state")
        artifacts = self.acquire_and_build()
        scenarios = self.browser_runs()
        reports = self.regenerate_reports()
        recovery = self.recovery()
        return {
            "schema_version": "1.0.0",
            "record_id": f"BX-BH01-PHASE10-CLEAN-{self.args.environment}-0.1",
            "status": "passed",
            "captured_at": datetime.now(timezone.utc).isoformat(timespec="milliseconds").replace("+00:00", "Z"),
            "source_revision": self.args.source_revision,
            "physical_host_scope": "same-linux-host-independent-clean-execution-context",
            "clean_state": {"git_archive": True, "git_metadata_present": False, "dependency_directories_present_before": False, "generated_directories_present_before": False, "mix_home_initially_empty": True, "hex_home_initially_empty": True, "npm_cache_initially_empty": True, "undeclared_preinstalled_tools_used": False, "fixture_mounted_at_canonical_root": True},
            "tools": [
                {"name": "beam-image", "identity": BEAM_IMAGE, "sha256": BEAM_IMAGE_CONFIG},
                {"name": "wasm-image", "identity": load(self.source / "packages/blazex_runtime_popcorn/runtime/build-contract.json")["image"]["reference"], "sha256": load(self.source / "packages/blazex_runtime_popcorn/runtime/build-contract.json")["image"]["config_sha256"]},
                {"name": "node", "identity": "26.8.1", "sha256": sha(self.args.node)},
                {"name": "chrome-for-testing", "identity": "152.0.7977.75", "sha256": sha(self.args.chrome)},
                {"name": "playwright-firefox-development-build", "identity": "153.0", "sha256": sha(self.args.firefox)},
            ],
            "commands": self.commands,
            "artifacts": artifacts,
            "browser_scenarios": scenarios,
            "reports": reports,
            "recovery": recovery,
            "deferred_qualification": {"status": "deferred", "reactivation_milestone": "BH-22", "excluded_from_pass": True},
            "manual_actions": [],
            "failures": [],
            "limitations": [
                "Both clean executions share one physical Linux host and do not establish cross-machine reproducibility.",
                "Firefox is a Playwright patched development build and all browsers remain unsupported.",
                "Representative browser timings are scheduler-sensitive observations, not exact-output comparisons.",
                "External platform, mobile, Safari, device, and unavailable manual qualification remains deferred to BH-22."
            ],
        }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--source", type=Path, required=True)
    parser.add_argument("--environment", choices=("A", "B"), required=True)
    parser.add_argument("--source-revision", required=True)
    parser.add_argument("--runtime-inputs", type=Path, required=True)
    parser.add_argument("--node", type=Path, required=True)
    parser.add_argument("--npm", type=Path, required=True)
    parser.add_argument("--python", type=Path, default=Path("/usr/bin/python3"))
    parser.add_argument("--chrome", type=Path, required=True)
    parser.add_argument("--firefox", type=Path, required=True)
    parser.add_argument("--port", type=int, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--logs-directory", type=Path)
    args = parser.parse_args()
    if len(args.source_revision) != 40 or any(char not in "0123456789abcdef" for char in args.source_revision):
        raise SystemExit("--source-revision must be an exact lowercase commit")
    runner = Runner(args)
    try:
        record = runner.execute()
    except Exception as error:
        print(f"ERROR: {error}")
        return 1
    args.output.write_text(json.dumps(record, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    print(f"BH-01 Phase 10 clean rebuild {args.environment}: PASS ({len(record['commands'])} commands; {len(record['browser_scenarios'])} browser scenarios)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

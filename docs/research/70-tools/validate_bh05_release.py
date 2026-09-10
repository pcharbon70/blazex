"""Validate deterministic BH-05 release artifacts and the negative BH-06 decision."""
import json
import subprocess
import sys

from research_paths import REPO_ROOT
from generate_bh05_release import TARGETS


def validate():
    errors = []
    generator = __file__.replace("validate_bh05_release.py", "generate_bh05_release.py")
    result = subprocess.run([sys.executable, generator, "--check"], cwd=REPO_ROOT, capture_output=True, text=True)
    if result.returncode:
        errors.append("generated release drift")
    try:
        release = json.loads((REPO_ROOT / TARGETS["release"]).read_text())
        overlay = json.loads((REPO_ROOT / TARGETS["overlay"]).read_text())
        entry = json.loads((REPO_ROOT / TARGETS["entry"]).read_text())
        if release.get("decision") != "revise" or release.get("candidate_kind") != "revision-candidate":
            errors.append("release decision drift")
        inventory = release.get("implementation_inventory", [])
        if not inventory or len(inventory) != len(release.get("public_api_inventory", [])) + len(release.get("private_api_inventory", [])):
            errors.append("public/private API inventory incomplete")
        if any(release["dependency_audit"]["forbidden_source_occurrences"].values()):
            errors.append("prohibited dependency reachable from BH-05 source")
        if len(overlay.get("outcomes", [])) != 9 or not overlay.get("active_blockers"):
            errors.append("acceptance overlay incomplete")
        if entry.get("state") != "ineligible" or entry.get("authorized") or entry.get("manifest_generated"):
            errors.append("BH-06 entry was improperly granted")
        if release.get("support_state") != "unsupported" or overlay.get("support_state") != "unsupported":
            errors.append("support-state drift")
    except (OSError, ValueError, KeyError, TypeError):
        errors.append("missing/malformed release artifacts")
    return errors


if __name__ == "__main__":
    problems = validate()
    print("\n".join(problems) if problems else "BH-05 release candidate: REVISE (validated)")
    sys.exit(bool(problems))

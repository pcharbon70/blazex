"""Generate/check the source-bound BH-04 successor only after its gates pass."""
import json
import sys
from research_paths import REPO_ROOT
from validate_bh04_correction import AREA, candidate

if __name__ == "__main__":
    output = json.dumps(candidate(), indent=2) + "\n"
    target = REPO_ROOT / AREA / "decision.json"
    if "--write" in sys.argv:
        target.write_text(output)
    elif target.read_text() != output:
        raise SystemExit("stale corrective decision")
    print("Source-bound corrective decision verified.")

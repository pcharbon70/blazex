"""Check relocation provenance without promoting historical acceptance."""

import sys
from tooling_migration import validate_migration

if __name__ == "__main__":
    try:
        result = validate_migration()
    except (OSError, ValueError, KeyError) as error:
        print("Tooling migration failed:", error, file=sys.stderr)
        raise SystemExit(1) from error
    print("Tooling migration validated:", result)

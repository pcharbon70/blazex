#!/usr/bin/env bash
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
binary="$(${root_dir}/scripts/build_gtk4.sh)"
fixture="${root_dir}/fixtures/representative-v0.1.0.bxn1"
stale="${root_dir}/fixtures/stale-update-v0.1.0.bxn1"

xvfb-run -a "${binary}" "${fixture}" "${stale}"

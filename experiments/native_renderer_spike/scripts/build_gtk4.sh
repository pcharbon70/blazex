#!/usr/bin/env bash
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
build_dir="${root_dir}/build"
mkdir -p "${build_dir}"

cc -std=c11 -Wall -Wextra -Werror -pedantic \
  "${root_dir}/platform/native_protocol.c" \
  "${root_dir}/platform/gtk4_adapter.c" \
  -l:libgtk-4.so.1 -l:libgobject-2.0.so.0 -l:libglib-2.0.so.0 \
  -o "${build_dir}/blazex-native-spike-gtk4"

printf '%s\n' "${build_dir}/blazex-native-spike-gtk4"

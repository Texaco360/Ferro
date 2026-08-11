#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

rm -rf "${ROOT_DIR}/build/bin" "${ROOT_DIR}/build/units"
mkdir -p "${ROOT_DIR}/build/bin" "${ROOT_DIR}/build/units"

echo "Clean completed: build/bin and build/units reset."

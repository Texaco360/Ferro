#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

BINARY_PATH="${ROOT_DIR}/build/bin/ferroserver"
PORT="${PORT:-9010}"

if [[ "${SKIP_BUILD:-0}" != "1" ]]; then
  "${SCRIPT_DIR}/build.sh"
fi

if [[ ! -x "${BINARY_PATH}" ]]; then
  echo "Error: binary not found at ${BINARY_PATH}" >&2
  echo "Run scripts/build.sh first." >&2
  exit 1
fi

echo "Starting FerroServer on port ${PORT}"
exec env PORT="${PORT}" "${BINARY_PATH}"

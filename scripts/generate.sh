#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

BUILD_DIR="${ROOT_DIR}/build"
BIN_DIR="${BUILD_DIR}/bin"
UNITS_DIR="${BUILD_DIR}/units/generate"
TOOL_SRC="${ROOT_DIR}/tools/generate.lpr"
TOOL_BIN="${BIN_DIR}/generate"

if ! command -v fpc >/dev/null 2>&1; then
  echo "Error: fpc not found in PATH." >&2
  exit 1
fi

mkdir -p "${BIN_DIR}" "${UNITS_DIR}"

UNIT_PATHS=(
  "${ROOT_DIR}/src"
  "${ROOT_DIR}/src/bootstrap"
  "${ROOT_DIR}/src/controllers"
  "${ROOT_DIR}/src/services"
  "${ROOT_DIR}/src/repositories"
  "${ROOT_DIR}/src/database"
  "${ROOT_DIR}/src/dto"
)

while IFS= read -r -d '' src_dir; do
  UNIT_PATHS+=("${src_dir}")
done < <(find "${ROOT_DIR}/modules" -mindepth 2 -maxdepth 2 -type d -name src -print0 2>/dev/null || true)

FPC_ARGS=(
  "-Mdelphi"
  "-FU${UNITS_DIR}"
  "-FE${BIN_DIR}"
  "-o${TOOL_BIN}"
)

for path in "${UNIT_PATHS[@]}"; do
  FPC_ARGS+=("-Fu${path}")
done

echo "Compiling generate tool..."
fpc "${FPC_ARGS[@]}" "${TOOL_SRC}"

echo ""
"${TOOL_BIN}" "$@"

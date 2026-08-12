#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

BUILD_DIR="${ROOT_DIR}/build"
BIN_DIR="${BUILD_DIR}/bin"
TOOLS_UNITS_DIR="${BUILD_DIR}/units/tools"

if ! command -v fpc >/dev/null 2>&1; then
  echo "Error: fpc not found in PATH." >&2
  echo "Install Free Pascal and retry." >&2
  exit 1
fi

mkdir -p "${BIN_DIR}" "${TOOLS_UNITS_DIR}/generate" "${TOOLS_UNITS_DIR}/migrate"

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
  "-FE${BIN_DIR}"
)

for path in "${UNIT_PATHS[@]}"; do
  FPC_ARGS+=("-Fu${path}")
done

echo "Compiling generate tool..."
fpc "${FPC_ARGS[@]}" "-FU${TOOLS_UNITS_DIR}/generate" "-o${BIN_DIR}/generate" "${ROOT_DIR}/tools/generate.lpr"

echo "Compiling migrate tool..."
fpc "${FPC_ARGS[@]}" "-FU${TOOLS_UNITS_DIR}/migrate" "-o${BIN_DIR}/migrate" "${ROOT_DIR}/tools/migrate.lpr"

echo "Tools build completed."
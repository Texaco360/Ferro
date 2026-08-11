#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

TEST_MAIN_FILE="${ROOT_DIR}/tests/FerroServerTests.lpr"
BUILD_DIR="${ROOT_DIR}/build/tests"
BIN_DIR="${BUILD_DIR}/bin"
UNITS_DIR="${BUILD_DIR}/units"
OUTPUT_NAME="${OUTPUT_NAME:-ferroserver-tests}"
RUN_TESTS=1

if [[ "${1:-}" == "--build-only" ]]; then
  RUN_TESTS=0
fi

if ! command -v fpc >/dev/null 2>&1; then
  echo "Error: fpc not found in PATH." >&2
  echo "Install Free Pascal and retry." >&2
  exit 1
fi

echo "Building application binary for controller integration tests..."
"${ROOT_DIR}/scripts/build.sh"

mkdir -p "${BIN_DIR}" "${UNITS_DIR}"

DB_FILE="${DB_FILE:-${BUILD_DIR}/ferroserver-tests.sqlite}"
export DB_PATH="${DB_FILE}"

UNIT_PATHS=(
  "${ROOT_DIR}/src"
  "${ROOT_DIR}/src/bootstrap"
  "${ROOT_DIR}/src/controllers"
  "${ROOT_DIR}/src/services"
  "${ROOT_DIR}/src/repositories"
  "${ROOT_DIR}/src/database"
  "${ROOT_DIR}/src/dto"
  "${ROOT_DIR}/tests"
)

while IFS= read -r -d '' src_dir; do
  UNIT_PATHS+=("${src_dir}")
done < <(find "${ROOT_DIR}/modules" -mindepth 2 -maxdepth 2 -type d -name src -print0 2>/dev/null || true)

FPC_ARGS=(
  "-Mdelphi"
  "-FU${UNITS_DIR}"
  "-FE${BIN_DIR}"
  "-o${BIN_DIR}/${OUTPUT_NAME}"
)

for path in "${UNIT_PATHS[@]}"; do
  FPC_ARGS+=("-Fu${path}")
done

echo "Building test runner with fpc..."
echo "Output binary: ${BIN_DIR}/${OUTPUT_NAME}"
echo "Database path: ${DB_PATH}"

fpc "${FPC_ARGS[@]}" "${TEST_MAIN_FILE}"

if [[ "${RUN_TESTS}" == "1" ]]; then
  echo "Running tests..."
  "${BIN_DIR}/${OUTPUT_NAME}" --all
fi
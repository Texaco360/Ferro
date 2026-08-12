#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

MAIN_FILE=""
BUILD_DIR="${ROOT_DIR}/build"
BIN_DIR="${BUILD_DIR}/bin"
OUTPUT_NAME="${OUTPUT_NAME:-ferroserver}"
DEBUG_MODE="${DEBUG:-0}"

if [[ "${DEBUG_MODE}" == "1" ]]; then
  BUILD_PROFILE="debug"
else
  BUILD_PROFILE="release"
fi

UNITS_DIR="${BUILD_DIR}/units/${BUILD_PROFILE}"

# Pick the first existing entrypoint from common Pascal main file names.
for candidate in \
  "${ROOT_DIR}/src/main.lpr" \
  "${ROOT_DIR}/src/Main.lpr" \
  "${ROOT_DIR}/src/TodoApi.lpr" \
  "${ROOT_DIR}/src/todoapi.lpr"
do
  if [[ -f "${candidate}" ]]; then
    MAIN_FILE="${candidate}"
    break
  fi
done

if [[ -z "${MAIN_FILE}" ]]; then
  echo "Error: no entrypoint .lpr found in ${ROOT_DIR}/src" >&2
  exit 1
fi

if ! command -v fpc >/dev/null 2>&1; then
  echo "Error: fpc not found in PATH." >&2
  echo "Install Free Pascal and retry." >&2
  exit 1
fi

mkdir -p "${BIN_DIR}" "${UNITS_DIR}"

UNIT_PATHS=(
  "${ROOT_DIR}/src"
  "${ROOT_DIR}/src/database"
  "${ROOT_DIR}/src/domain/shared"
  "${ROOT_DIR}/src/domain/todo"
  "${ROOT_DIR}/src/domain/project"
  "${ROOT_DIR}/src/application/todo"
  "${ROOT_DIR}/src/application/project"
  "${ROOT_DIR}/src/infrastructure/bootstrap"
  "${ROOT_DIR}/src/infrastructure/shared"
  "${ROOT_DIR}/src/infrastructure/todo"
  "${ROOT_DIR}/src/infrastructure/project"
  "${ROOT_DIR}/src/presentation/shared"
  "${ROOT_DIR}/src/presentation/todo"
  "${ROOT_DIR}/src/presentation/project"
  "${ROOT_DIR}/src/presentation/routes"
)

# Add all dependency source directories under modules/*/src.
while IFS= read -r -d '' src_dir; do
  UNIT_PATHS+=("${src_dir}")
done < <(find "${ROOT_DIR}/modules" -mindepth 2 -maxdepth 2 -type d -name src -print0 2>/dev/null || true)

FPC_ARGS=(
  "-Mdelphi"
  "-FU${UNITS_DIR}"
  "-FE${BIN_DIR}"
  "-o${BIN_DIR}/${OUTPUT_NAME}"
)

if [[ "${DEBUG_MODE}" == "1" ]]; then
  FPC_ARGS+=("-gl" "-O-")
fi

if [[ -n "${EXTRA_FPC_ARGS:-}" ]]; then
  # shellcheck disable=SC2206
  EXTRA_ARGS=( ${EXTRA_FPC_ARGS} )
  FPC_ARGS+=("${EXTRA_ARGS[@]}")
fi

for path in "${UNIT_PATHS[@]}"; do
  FPC_ARGS+=("-Fu${path}")
done

echo "Building with fpc..."
echo "Output binary: ${BIN_DIR}/${OUTPUT_NAME}"
if [[ "${DEBUG_MODE}" == "1" ]]; then
  echo "Build mode: debug"
else
  echo "Build mode: release"
fi
echo "Unit output: ${UNITS_DIR}"

fpc "${FPC_ARGS[@]}" "${MAIN_FILE}"

echo "Build completed."

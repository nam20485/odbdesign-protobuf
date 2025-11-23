#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="$ROOT_DIR/build/native"
INSTALL_DIR="$ROOT_DIR/artifacts/native/local"

if [[ ! -d "$ROOT_DIR/generated/cpp" ]]; then
  echo "error: generated C++ sources not found. Run scripts/generate_protos.sh first." >&2
  exit 1
fi

rm -rf "$BUILD_DIR" "$INSTALL_DIR"
cmake -S "$ROOT_DIR/cpp/native" -B "$BUILD_DIR" -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$INSTALL_DIR"
cmake --build "$BUILD_DIR" --config Release --target install

echo "Native library installed under $INSTALL_DIR"

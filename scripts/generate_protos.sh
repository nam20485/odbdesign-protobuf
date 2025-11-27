#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROTO_DIR="$ROOT_DIR/protoc"
CPP_OUT="$ROOT_DIR/generated/cpp"
CS_OUT="$ROOT_DIR/generated/csharp"

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "error: required executable '$1' not found in PATH" >&2
    exit 1
  fi
}

require_cmd protoc
require_cmd grpc_cpp_plugin
require_cmd grpc_csharp_plugin

if [[ ! -d "$PROTO_DIR" ]]; then
  echo "error: expected proto directory at $PROTO_DIR" >&2
  exit 1
fi

mapfile -t ROOT_PROTOS < <(find "$PROTO_DIR" -maxdepth 1 -name '*.proto' -print | sort)
mapfile -t GRPC_PROTOS < <(find "$PROTO_DIR/grpc" -name '*.proto' -print 2>/dev/null | sort)

ALL_PROTOS=("${ROOT_PROTOS[@]}")
if [[ ${#GRPC_PROTOS[@]} -gt 0 ]]; then
  ALL_PROTOS+=("${GRPC_PROTOS[@]}")
fi

if [[ ${#ALL_PROTOS[@]} -eq 0 ]]; then
  echo "error: no .proto files found under $PROTO_DIR" >&2
  exit 1
fi

rm -rf "$CPP_OUT" "$CS_OUT"
mkdir -p "$CPP_OUT" "$CS_OUT"

PROTO_ARGS=(--proto_path="$PROTO_DIR")

# Add protobuf well-known types include path if available (for built-from-source protoc)
if [[ -n "${PROTOBUF_INCLUDE_PATH:-}" && -d "$PROTOBUF_INCLUDE_PATH" ]]; then
  echo "[protoc] Using protobuf include path: $PROTOBUF_INCLUDE_PATH"
  PROTO_ARGS+=(--proto_path="$PROTOBUF_INCLUDE_PATH")
fi

echo "[protoc] Generating C++ message types"
protoc "${PROTO_ARGS[@]}" --cpp_out="$CPP_OUT" "${ALL_PROTOS[@]}"

if [[ ${#GRPC_PROTOS[@]} -gt 0 ]]; then
  echo "[protoc] Generating C++ gRPC services"
  protoc "${PROTO_ARGS[@]}" --grpc_out="$CPP_OUT" --plugin=protoc-gen-grpc="$(command -v grpc_cpp_plugin)" "${GRPC_PROTOS[@]}"
fi

echo "[protoc] Generating C# message types"
protoc "${PROTO_ARGS[@]}" --csharp_out="$CS_OUT" "${ALL_PROTOS[@]}"

if [[ ${#GRPC_PROTOS[@]} -gt 0 ]]; then
  echo "[protoc] Generating C# gRPC services"
  protoc "${PROTO_ARGS[@]}" --grpc_out="$CS_OUT" --plugin=protoc-gen-grpc="$(command -v grpc_csharp_plugin)" "${GRPC_PROTOS[@]}"
fi

echo "Generation complete. Outputs:"
echo "  C++   => $CPP_OUT"
echo "  C#    => $CS_OUT"

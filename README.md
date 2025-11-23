# ODB Design Protobuf

This repository contains the canonical ODB++ protobuf definitions plus automation for generating strongly-typed message and gRPC service stubs for both C++ and C# consumers.

## Language generation workflow

A GitHub Actions workflow (`Generate Protobuf SDKs`) executes on every push or pull request that touches the `protoc/` directory or the generator itself. The workflow:

1. Installs `protoc`, the C++ gRPC plugin, and the Linux `grpc_csharp_plugin` binary.
2. Runs `scripts/generate_protos.sh` to emit message types and service stubs for both languages.
3. Uploads the `generated/cpp` and `generated/csharp` directories as build artifacts (`protobuf-cpp` and `protobuf-csharp`).

You can also trigger the workflow manually via **Run workflow** in the Actions tab.

## Local generation

To reproduce the same output locally:

1. Install the following tooling and ensure each binary is on your `PATH`:
   - `protoc` (3.21+ recommended)
   - `grpc_cpp_plugin`
   - `grpc_csharp_plugin` (obtainable from the [gRPC release assets](https://github.com/grpc/grpc/releases))
2. From the repository root, run the generator script:

   ```bash
   bash scripts/generate_protos.sh
   ```

The script wipes and recreates `generated/cpp` and `generated/csharp`, so commit any local modifications elsewhere before running it.

Generated code is ignored via `.gitignore`; rely on the workflow artifacts or regenerate locally when needed.

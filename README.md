# ODB Design Protobuf

This repository contains the canonical ODB++ protobuf definitions plus automation for generating strongly-typed message and gRPC service stubs for both C++ and C# consumers.

## Language generation & NuGet workflow

A GitHub Actions workflow (`Generate Protobuf SDKs`) executes on every push or pull request that touches the protobuf definitions, generator script, or .NET packaging project. The workflow:

1. Installs `protoc`, the C++ gRPC plugin, and the Linux `grpc_csharp_plugin` binary.
2. Runs `scripts/generate_protos.sh` to emit message types and service stubs for both languages.
3. Performs a .NET build of `src/dotnet/OdbDesign.Protobuf/OdbDesign.Protobuf.csproj`, which links against the freshly generated C# sources.
4. Packs the linked project into a NuGet package and publishes it to the repository's GitHub Packages feed (`https://nuget.pkg.github.com/<owner>/index.json`).
5. Uploads the `generated/cpp` and `generated/csharp` directories as build artifacts (`protobuf-cpp` and `protobuf-csharp`).
6. Triggers a matrix build that compiles the shared native library on Windows, Linux, and macOS using CMake + gRPC's FetchContent. Each run publishes per-platform artifacts (DLL/SO/dylib plus headers) named `native-<os>`.

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

## Native shared libraries

The repository ships a thin wrapper around the generated C++ types to guarantee that Windows DLLs export at least one concrete class. The wrapper lives under `cpp/native` and exposes helpers in `odbdesign::protobuf::DesignServiceBridge`.

To build the shared library locally:

1. Run `bash scripts/generate_protos.sh` (WSL/bash on Windows is fine) to populate `generated/cpp`.
2. Execute:

   ```bash
   bash scripts/build_cpp_shared.sh
   ```

   This script configures CMake, fetches gRPC/Protobuf via `FetchContent`, and installs the outputs under `artifacts/native/local`.

The GitHub workflow automatically builds the same library for Windows, Linux, and macOS. Download the `native-<os>` artifact to retrieve the headers and shared objects produced for your platform of choice.

## NuGet packaging

The `.NET` project located at `src/dotnet/OdbDesign.Protobuf/OdbDesign.Protobuf.csproj` links every C# file in `generated/csharp`. Build steps:

1. Run `bash scripts/generate_protos.sh` (from WSL or another Unix shell) to populate `generated/csharp`.
2. Restore, build, and pack using the .NET SDK (8.0+):

   ```bash
   dotnet pack src/dotnet/OdbDesign.Protobuf/OdbDesign.Protobuf.csproj -c Release -o artifacts/nuget
   ```

3. Push the resulting `.nupkg` to a NuGet feed of your choice. For GitHub Packages:

   ```bash
   dotnet nuget add source \
     --username "$GITHUB_ACTOR" \
     --password "$GITHUB_TOKEN" \
     --store-password-in-clear-text \
     --name github \
     "https://nuget.pkg.github.com/<owner>/index.json"
   dotnet nuget push artifacts/nuget/*.nupkg --source github --api-key "$GITHUB_TOKEN" --skip-duplicate
   ```

Replace `<owner>` with `nam20485`, and supply a personal access token with the `write:packages` scope when running locally.

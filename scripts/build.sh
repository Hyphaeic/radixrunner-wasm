#!/bin/bash
set -euo pipefail

# cd to repo root
SCRIPT_DIR="$(cd -- "$(dirname "$0")" >/dev/null 2>&1 && pwd -P)"
ROOT_DIR="$(cd -- "$SCRIPT_DIR/.." >/dev/null 2>&1 && pwd -P)"
cd "$ROOT_DIR"

echo "→ Building raw Wasm (no wasm-bindgen) in $ROOT_DIR"

# Ensure wasm target is installed (safe to call repeatedly)
rustup target add wasm32-unknown-unknown >/dev/null 2>&1 || true

# Build a module that IMPORTS memory so JS can pass the SAB-backed WebAssembly.Memory.
# We use no_std + panic=abort (via profile) to keep things lean.
export RUSTFLAGS="-C target-feature=+atomics,+bulk-memory,+mutable-globals \
  -C link-arg=--shared-memory \
  -C link-arg=--import-memory \
  -C link-arg=--initial-memory=16777216 \
  -C link-arg=--max-memory=16777216"

# With no_std and our simple code, we can build on stable. If you prefer nightly, add '+nightly'.
cargo build --target wasm32-unknown-unknown --release

# Stage artifact where the site expects it
TARGET_WASM="target/wasm32-unknown-unknown/release/radixrunner.wasm"
[[ -f "$TARGET_WASM" ]] || { echo "❌ Not found: $TARGET_WASM"; exit 1; }

rm -rf pkg
mkdir -p pkg
cp "$TARGET_WASM" "pkg/radixrunner_bg.wasm"

ls -lh pkg
echo "✓ Built: pkg/radixrunner_bg.wasm (imports env.memory; 16 MiB shared)"

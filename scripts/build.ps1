# build.ps1
$ErrorActionPreference = "Continue"  # Change from "Stop" to allow info messages

# Get script directory and navigate to radix-runtime root
$scriptDir = Split-Path -Parent $PSCommandPath
$rootDir = Split-Path -Parent $scriptDir
Push-Location $rootDir

Write-Host "Building raw Wasm (no wasm-bindgen) in $rootDir"

# Use nightly Rust for shared memory features (MUST come first)
Write-Host "Switching to nightly toolchain..."
rustup default nightly

# NOW install wasm target for nightly
Write-Host "Adding wasm32-unknown-unknown target for nightly..."
rustup target add wasm32-unknown-unknown

# Build with special WASM flags
Write-Host "Building WASM module..."
$env:RUSTFLAGS = "-C target-feature=+atomics,+bulk-memory,+mutable-globals -C link-arg=--shared-memory -C link-arg=--import-memory -C link-arg=--initial-memory=16777216 -C link-arg=--max-memory=16777216"
cargo build --target wasm32-unknown-unknown --release

# Stage artifact where the site expects it
$targetWasm = "target/wasm32-unknown-unknown/release/radixrunner.wasm"
if (-not (Test-Path $targetWasm)) {
    Write-Host "ERROR: Not found: $targetWasm" -ForegroundColor Red
    Pop-Location
    exit 1
}

$outDir = "../public/radix-runtime/pkg"
if (Test-Path $outDir) {
    Remove-Item -Recurse -Force $outDir
}
New-Item -ItemType Directory -Force -Path $outDir | Out-Null
Copy-Item $targetWasm "$outDir/radixrunner_bg.wasm"
Write-Host "SUCCESS: Built $outDir/radixrunner_bg.wasm" -ForegroundColor Green

Pop-Location

# Clean up: remove RUSTFLAGS so they don't interfere with other builds
Remove-Item Env:\RUSTFLAGS -ErrorAction SilentlyContinue
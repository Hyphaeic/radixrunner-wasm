# PowerShell build script for Windows
# Builds the WASM module and places it in the pkg directory

Write-Host "Building raw Wasm (no wasm-bindgen)" -ForegroundColor Cyan

# Ensure wasm target is installed
Write-Host "Checking for wasm32-unknown-unknown target..." -ForegroundColor Yellow
& rustup target add wasm32-unknown-unknown 2>&1 | Out-Null
$ErrorActionPreference = "Stop"

# Build the WASM module
# The .cargo/config.toml already has the necessary rustflags
Write-Host "Building WASM module..." -ForegroundColor Yellow
cargo build --target wasm32-unknown-unknown --release

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Build failed!" -ForegroundColor Red
    exit 1
}

# Stage artifact where the site expects it
$TARGET_WASM = "target\wasm32-unknown-unknown\release\radixrunner.wasm"

if (-not (Test-Path $TARGET_WASM)) {
    Write-Host "❌ Not found: $TARGET_WASM" -ForegroundColor Red
    exit 1
}

# Create pkg directory if it doesn't exist
$OUT_DIR = "pkg"
if (-not (Test-Path $OUT_DIR)) {
    New-Item -ItemType Directory -Path $OUT_DIR | Out-Null
}

# Copy WASM file to pkg directory
Copy-Item -Path $TARGET_WASM -Destination "$OUT_DIR\radixrunner_bg.wasm" -Force

$fileSize = (Get-Item "$OUT_DIR\radixrunner_bg.wasm").Length
$fileSizeKB = [math]::Round($fileSize/1KB, 2)
Write-Host "Built: $OUT_DIR\radixrunner_bg.wasm" -ForegroundColor Green
Write-Host "  Size: $fileSizeKB KB" -ForegroundColor Gray
Write-Host "  (imports env.memory; 16 MiB shared)" -ForegroundColor Gray


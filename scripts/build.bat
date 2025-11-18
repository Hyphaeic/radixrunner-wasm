@echo off
REM Batch build script for Windows (alternative to PowerShell)

echo → Building raw Wasm (no wasm-bindgen)

REM Ensure wasm target is installed
echo Checking for wasm32-unknown-unknown target...
rustup target add wasm32-unknown-unknown >nul 2>&1

REM Build the WASM module
echo Building WASM module...
cargo build --target wasm32-unknown-unknown --release

if errorlevel 1 (
    echo ❌ Build failed!
    exit /b 1
)

REM Stage artifact where the site expects it
set TARGET_WASM=target\wasm32-unknown-unknown\release\radixrunner.wasm

if not exist "%TARGET_WASM%" (
    echo ❌ Not found: %TARGET_WASM%
    exit /b 1
)

REM Create pkg directory if it doesn't exist
if not exist "pkg" mkdir pkg

REM Copy WASM file to pkg directory
copy /Y "%TARGET_WASM%" "pkg\radixrunner_bg.wasm" >nul

echo ✓ Built: pkg\radixrunner_bg.wasm
echo   (imports env.memory; 16 MiB shared)


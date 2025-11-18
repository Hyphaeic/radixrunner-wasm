# RadixRunner WASM

A WebAssembly-based mixed-radix clock implementation using SharedArrayBuffer for shared memory between the main thread and Web Workers.

## Prerequisites

- **Rust** (install from https://rustup.rs/)
- **Python 3** (for running the local server) OR **Node.js** (alternative)
- A modern browser that supports SharedArrayBuffer (Chrome, Edge, Firefox)

## Building on Windows

1. **Install Rust** (if not already installed):
   ```powershell
   # Visit https://rustup.rs/ or run:
   # winget install Rustlang.Rustup
   ```

2. **Build the WASM module**:
   ```powershell
   .\scripts\build.ps1
   ```

   This will:
   - Install the `wasm32-unknown-unknown` target if needed
   - Build the WASM module in release mode
   - Copy the output to `pkg/radixrunner_bg.wasm`

## Running in Browser

1. **Start the local server**:
   ```powershell
   .\scripts\run.ps1
   ```

   This starts a Python HTTP server on `http://localhost:8080` with the required headers for SharedArrayBuffer.

2. **Open your browser**:
   - Navigate to `http://localhost:8080`
   - The page should display a real-time clock with multiple precision levels (P0-P5)

## Alternative: Using Node.js http-server

If you don't have Python, you can use Node.js:

```powershell
npx http-server . -p 8080 --cors -c-1 --headers '{"Cross-Origin-Opener-Policy":"same-origin","Cross-Origin-Embedder-Policy":"require-corp"}'
```

## Important Notes

- **SharedArrayBuffer requires specific HTTP headers**: The server must send `Cross-Origin-Opener-Policy: same-origin` and `Cross-Origin-Embedder-Policy: require-corp` headers. Opening the HTML file directly (`file://`) will NOT work.

- **Browser compatibility**: SharedArrayBuffer is supported in:
  - Chrome/Edge 92+
  - Firefox 79+
  - Safari 15.2+

## Project Structure

- `src/` - Rust source code
- `pkg/` - Built WASM output (created by build script)
- `index.html` - Main HTML page
- `main.js` - Main JavaScript that sets up shared memory
- `tick_worker.js` - Web Worker that runs the WASM tick loop

## Troubleshooting

- **"Failed to fetch radixrunner_bg.wasm"**: Make sure you've run the build script first
- **"SharedArrayBuffer is not defined"**: Make sure you're accessing via HTTP/HTTPS, not `file://`
- **Build errors**: Ensure Rust is installed and `wasm32-unknown-unknown` target is available


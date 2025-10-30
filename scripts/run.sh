#!/bin/bash
set -euo pipefail

cd "$(dirname "$0")/.."

echo "Starting radixrunner test server..."
echo "Open: http://localhost:8080"
echo ""
echo "Press Ctrl+C to stop"
echo ""

miniserve . --port 8080 \
  --interfaces 127.0.0.1 \
  --header "Cross-Origin-Opener-Policy: same-origin" \
  --header "Cross-Origin-Embedder-Policy: require-corp"

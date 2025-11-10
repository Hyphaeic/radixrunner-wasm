# PowerShell run script for Windows
# Starts a local HTTP server with required headers for SharedArrayBuffer

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "Starting radixrunner test server..." -ForegroundColor Cyan
Write-Host ""

# Check if Python is available
$pythonCmd = $null
if (Get-Command python -ErrorAction SilentlyContinue) {
    $pythonCmd = "python"
} elseif (Get-Command python3 -ErrorAction SilentlyContinue) {
    $pythonCmd = "python3"
} elseif (Get-Command py -ErrorAction SilentlyContinue) {
    $pythonCmd = "py"
}

if ($pythonCmd) {
    Write-Host "Using Python HTTP server..." -ForegroundColor Yellow
    Write-Host ""
    
    # Check if port 8080 is available, try other ports if needed
    $port = 8080
    $portFound = $false
    $maxAttempts = 10
    
    for ($i = 0; $i -lt $maxAttempts; $i++) {
        $testPort = $port + $i
        $connection = Get-NetTCPConnection -LocalPort $testPort -ErrorAction SilentlyContinue
        if (-not $connection) {
            $port = $testPort
            $portFound = $true
            break
        }
    }
    
    if (-not $portFound) {
        Write-Host "Could not find an available port. Please close other servers or specify a port manually." -ForegroundColor Red
        exit 1
    }
    
    if ($port -ne 8080) {
        Write-Host "Port 8080 is in use. Using port $port instead." -ForegroundColor Yellow
    }
    
    Write-Host "Open: http://localhost:$port" -ForegroundColor Green
    Write-Host ""
    Write-Host "Press Ctrl+C to stop" -ForegroundColor Yellow
    Write-Host ""
    
    # Python 3 HTTP server with custom headers
    $portStr = $port.ToString()
    $script = @"
import http.server
import socketserver
from http.server import HTTPServer, SimpleHTTPRequestHandler
import os

class CustomHandler(SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header('Cross-Origin-Opener-Policy', 'same-origin')
        self.send_header('Cross-Origin-Embedder-Policy', 'require-corp')
        super().end_headers()
    
    def log_message(self, format, *args):
        return

PORT = $portStr
Handler = CustomHandler

try:
    with socketserver.TCPServer(("127.0.0.1", PORT), Handler) as httpd:
        print(f"Server running at http://127.0.0.1:{PORT}/")
        httpd.serve_forever()
except OSError as e:
    print(f"Error: Port {PORT} is already in use.")
    print("Please close the other server or use a different port.")
    exit(1)
"@
    
    $script | & $pythonCmd -
} else {
    Write-Host "Python not found. Please install Python 3 or use one of these alternatives:" -ForegroundColor Red
    Write-Host ""
    Write-Host "Option 1: Install Python 3 from https://www.python.org/" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Option 2: Use Node.js http-server:" -ForegroundColor Yellow
    Write-Host "  npx http-server . -p 8080 --cors -c-1 --headers '{\"Cross-Origin-Opener-Policy\":\"same-origin\",\"Cross-Origin-Embedder-Policy\":\"require-corp\"}'" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Option 3: Use VS Code Live Server extension" -ForegroundColor Yellow
    Write-Host ""
    exit 1
}


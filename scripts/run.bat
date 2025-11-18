@echo off
REM Batch run script for Windows (alternative to PowerShell)

echo.
echo Starting radixrunner test server...
echo.

REM Check if Python is available
where python >nul 2>&1
if %errorlevel% equ 0 (
    set PYTHON_CMD=python
    goto :found_python
)

where python3 >nul 2>&1
if %errorlevel% equ 0 (
    set PYTHON_CMD=python3
    goto :found_python
)

where py >nul 2>&1
if %errorlevel% equ 0 (
    set PYTHON_CMD=py
    goto :found_python
)

echo Python not found. Please install Python 3 or use Node.js:
echo.
echo   npx http-server . -p 8080 --cors -c-1 --headers "{\"Cross-Origin-Opener-Policy\":\"same-origin\",\"Cross-Origin-Embedder-Policy\":\"require-corp\"}"
echo.
exit /b 1

:found_python
echo Using Python HTTP server...
echo.
echo Open: http://localhost:8080
echo.
echo Press Ctrl+C to stop
echo.

REM Create a temporary Python script
echo import http.server > temp_server.py
echo import socketserver >> temp_server.py
echo from http.server import HTTPServer, BaseHTTPRequestHandler >> temp_server.py
echo. >> temp_server.py
echo class CustomHandler(BaseHTTPRequestHandler): >> temp_server.py
echo     def end_headers(self): >> temp_server.py
echo         self.send_header('Cross-Origin-Opener-Policy', 'same-origin') >> temp_server.py
echo         self.send_header('Cross-Origin-Embedder-Policy', 'require-corp') >> temp_server.py
echo         super().end_headers() >> temp_server.py
echo     def log_message(self, format, *args): >> temp_server.py
echo         return >> temp_server.py
echo. >> temp_server.py
echo PORT = 8080 >> temp_server.py
echo Handler = CustomHandler >> temp_server.py
echo. >> temp_server.py
echo with socketserver.TCPServer(("127.0.0.1", PORT), Handler) as httpd: >> temp_server.py
echo     print(f"Server running at http://127.0.0.1:{PORT}/") >> temp_server.py
echo     httpd.serve_forever() >> temp_server.py

%PYTHON_CMD% temp_server.py

REM Cleanup
del temp_server.py 2>nul


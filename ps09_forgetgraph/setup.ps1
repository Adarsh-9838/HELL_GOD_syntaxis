$ErrorActionPreference = 'Stop'
Set-Location -Path $PSScriptRoot

$venvPython = Join-Path $PSScriptRoot '.venv\Scripts\python.exe'
if (-not (Test-Path $venvPython)) {
    $launcher = Get-Command py -ErrorAction SilentlyContinue
    $python312Available = $false
    if ($launcher) {
        & py -3.12 --version 2>$null
        $python312Available = ($LASTEXITCODE -eq 0)
    }

    if ($python312Available) {
        & py -3.12 -m venv .venv
    } else {
        Write-Warning 'Python 3.12 was not found. Trying the Python version on PATH; Python 3.12 is recommended.'
        & python -m venv .venv
    }
    if ($LASTEXITCODE -ne 0) {
        throw 'Could not create the virtual environment. Install Python 3.12 and try again.'
    }
}

Write-Host 'Upgrading pip...' -ForegroundColor Cyan
& $venvPython -m pip install --upgrade pip
if ($LASTEXITCODE -ne 0) { throw 'pip upgrade failed.' }

Write-Host 'Installing project dependencies...' -ForegroundColor Cyan
& $venvPython -m pip install -r requirements.txt
if ($LASTEXITCODE -ne 0) { throw 'Dependency installation failed. Check your internet connection and Python version.' }

Write-Host ''
Write-Host 'Setup complete.' -ForegroundColor Green
Write-Host 'Start the app with: .\run.ps1'
Write-Host 'Run tests with: .\.venv\Scripts\python.exe -m pytest -v'

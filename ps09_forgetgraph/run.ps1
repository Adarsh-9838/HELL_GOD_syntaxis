$ErrorActionPreference = 'Stop'
Set-Location -Path $PSScriptRoot

$venvPython = Join-Path $PSScriptRoot '.venv\Scripts\python.exe'
if (-not (Test-Path $venvPython)) {
    Write-Host 'Virtual environment not found. Run .\setup.ps1 first.' -ForegroundColor Yellow
    exit 1
}

& $venvPython -c "import streamlit" 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host 'Streamlit is not installed in this environment. Run .\setup.ps1 first.' -ForegroundColor Yellow
    exit 1
}

& $venvPython -m streamlit run app.py
exit $LASTEXITCODE

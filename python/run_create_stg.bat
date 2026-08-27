@echo off
cd /d "%~dp0\.."

set "PY=python"
if exist ".venv\Scripts\python.exe" set "PY=.venv\Scripts\python.exe"

"%PY%" -c "import yaml" 1>nul 2>nul
if errorlevel 1 (
  echo Faltan deps Python. En esta carpeta ejecuta:
  echo   "%PY%" -m pip install -r python\requirements.txt
  echo O crea un venv:
  echo   python -m venv .venv
  echo   .venv\Scripts\pip install -r python\requirements.txt
  exit /b 1
)

"%PY%" python\create_stg.py
exit /b %ERRORLEVEL%

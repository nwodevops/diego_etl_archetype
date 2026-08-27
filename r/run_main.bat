@echo off
cd /d "%~dp0\.."

set "RSCRIPT="
for %%R in (Rscript.exe) do set "RSCRIPT=%%~$PATH:R"
if not defined RSCRIPT (
  if exist "C:\Program Files\R\latest\bin\Rscript.exe" (
    set "RSCRIPT=C:\Program Files\R\latest\bin\Rscript.exe"
  )
)
if not defined RSCRIPT (
  if exist "C:\Program Files\R\R-4.5.2\bin\Rscript.exe" (
    set "RSCRIPT=C:\Program Files\R\R-4.5.2\bin\Rscript.exe"
  ) else (
    for /d %%D in ("C:\Program Files\R\R-4.*") do set "RSCRIPT=%%~D\bin\Rscript.exe"
  )
)
if not defined RSCRIPT (
  echo No se encontro Rscript. Instala R o agrega R\bin al PATH.
  exit /b 1
)
echo Usando R: %RSCRIPT%
call "%RSCRIPT%" r/main.R
exit /b %ERRORLEVEL%
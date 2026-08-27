@echo off
setlocal EnableExtensions
cd /d "%~dp0"

REM Corrida headless de wf_main (Programador de tareas Windows).
REM Override: set HOP_HOME=D:\ruta\a\hop

if not defined HOP_HOME set "HOP_HOME=D:\Eder\hop"
if not exist "%HOP_HOME%\hop-run.bat" if exist "%USERPROFILE%\apps\hop\hop-run.bat" (
  set "HOP_HOME=%USERPROFILE%\apps\hop"
)

if not exist "%HOP_HOME%\hop-run.bat" (
  echo No se encuentra hop-run.bat. Define HOP_HOME o instala Hop.
  echo Probado: D:\Eder\hop  y  %%USERPROFILE%%\apps\hop
  exit /b 1
)

set "PROJECT_HOME=%CD%"
set "PROJECT_NAME=diego_etl_archetype"
set "WF=%PROJECT_HOME%\workflows\wf_main.hwf"

echo [%date% %time%] HOP_HOME=%HOP_HOME%
echo [%date% %time%] PROJECT_HOME=%PROJECT_HOME%
echo [%date% %time%] Ejecutando %WF%

call "%HOP_HOME%\hop-run.bat" ^
  --project=%PROJECT_NAME% ^
  --file="%WF%" ^
  --level=Basic ^
  --runconfig=local

set "RC=%ERRORLEVEL%"
echo [%date% %time%] Fin wf_main exit=%RC%
exit /b %RC%

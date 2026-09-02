@echo off
setlocal EnableExtensions
cd /d "%~dp0"

REM Corrida headless de wf_main (Programador de tareas Windows).
REM Override: set HOP_HOME=D:\ruta\a\hop

REM --- Log por fecha (diez días de retención) ---
set "LOGDIR=%~dp0logs"
if not exist "%LOGDIR%" mkdir "%LOGDIR%"
for /f %%a in ('powershell -NoProfile -Command "Get-Date -Format yyyyMMdd"') do set "STAMP=%%a"
set "LOGFILE=%LOGDIR%\wf_main_%STAMP%.log"
if exist "%LOGFILE%" del "%LOGFILE%" >nul 2>&1

call :log Inicio: %date% %time%

REM Levantar H2 como tarea independiente (desacoplado de la consola de Hop,
REM evita el cuelgue por Ctrl-C del batch). reset_and_create.bat solo aplica
REM DDL; no lanza ni detiene el server H2.
call "%~dp0h2\scripts\start_h2_svc.bat" >> "%LOGFILE%" 2>&1

if not defined HOP_HOME set "HOP_HOME=D:\Eder\hop"
if not exist "%HOP_HOME%\hop-run.bat" if exist "%USERPROFILE%\apps\hop\hop-run.bat" (
  set "HOP_HOME=%USERPROFILE%\apps\hop"
)

if not exist "%HOP_HOME%\hop-run.bat" (
  call :log ERROR: No se encuentra hop-run.bat. Define HOP_HOME o instala Hop.
  exit /b 1
)

set "PROJECT_HOME=%CD%"
set "PROJECT_NAME=diego_etl_archetype"
set "WF=%PROJECT_HOME%\workflows\wf_main.hwf"

call :log HOP_HOME=%HOP_HOME%
call :log PROJECT_HOME=%PROJECT_HOME%
call :log Ejecutando %WF%

call "%HOP_HOME%\hop-run.bat" ^
  --project=%PROJECT_NAME% ^
  --file="%WF%" ^
  --level=Basic ^
  --runconfig=local >> "%LOGFILE%" 2>&1

set "RC=%ERRORLEVEL%"
call :log Fin wf_main exit=%RC%
exit /b %RC%

:log
echo [%date% %time%] %*>> "%LOGFILE%"
exit /b 0

@echo off
REM ===========================================================================
REM start_h2_svc.bat — Levanta el server H2 (mem:csep, TCP 9092) como tarea
REM programada INDEPENDIENTE del workflow. Al correrla el Programador de tareas
REM el proceso java NO hereda la consola del batch de Hop, por lo que no recibe
REM el Ctrl-C que hacía colgar a reset_and_create.bat (prompt "^C Terminar el
REM trabajo por lotes (S/N)?" sin respuesta en entorno no interactivo).
REM
REM Crear/Sobrescribir la tarea y ejecutarla una vez.
REM ===========================================================================
setlocal
cd /d "%~dp0\.."

set H2_JAR=lib\h2-2.4.240.jar
if not exist "%H2_JAR%" set H2_JAR=h2-2.4.240.jar
set H2_PORT=9092
set "TASKID=H2_SERVICE_MEM_CSEP"

REM Si ya escucha, no hacer nada.
netstat -an | findstr ":%H2_PORT% " | findstr "LISTENING" >nul 2>&1
if %ERRORLEVEL%==0 (
  echo H2 ya esta arriba en puerto %H2_PORT%
  exit /b 0
)

REM Comando del servidor H2 (rutas absolutas).
set "JAVA_EXE=java"
set "JAR_ABS=%CD%\%H2_JAR%"
set "H2CMD="%JAVA_EXE%" -cp "%JAR_ABS%" org.h2.tools.Server -tcp -web -webPort 8082 -tcpPort %H2_PORT% -ifNotExists"

REM Crear la tarea (si existe, se sobrescribe con /f). "/st" se pone en el
REM futuro cercano para evitar la advertencia de hora pasada.
for /f "tokens=1-2 delims=:." %%a in ("%time%") do set "HH=%%a" & set "MM=%%b"
schtasks /create /tn "%TASKID%" /tr "%H2CMD%" /sc once /st %HH%:%MM% /f >nul 2>&1

REM Ejecutarla.
schtasks /run /tn "%TASKID%" >nul 2>&1

REM Esperar el puerto.
set /a _i=0
:wait_loop
netstat -an | findstr ":%H2_PORT% " | findstr "LISTENING" >nul 2>&1
if %ERRORLEVEL%==0 (
  echo H2 OK puerto %H2_PORT% (tarea %TASKID%)
  exit /b 0
)
set /a _i+=1
if %_i% GEQ 30 (
  echo FAIL: H2 no abrio puerto %H2_PORT%
  exit /b 1
)
ping -n 2 127.0.0.1 >nul
goto wait_loop

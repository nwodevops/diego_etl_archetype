@echo off
setlocal
cd /d "%~dp0\.."

set H2_JAR=lib\h2-2.4.240.jar
if not exist "%H2_JAR%" set H2_JAR=h2-2.4.240.jar
set "DB_H2_URL=jdbc:h2:tcp://localhost:9092/mem:csep;DB_CLOSE_DELAY=-1;MODE=Oracle;DATABASE_TO_UPPER=TRUE;DEFAULT_NULL_ORDERING=HIGH;AUTO_RECONNECT=TRUE"

REM H2 es in-memory (mem:csep) y se levanta de forma INDEPENDIENTE del workflow
REM (start_h2_svc.bat / tarea H2_SERVICE_MEM_CSEP), NO desde este batch:
REM lanzar el server aqui hereda la consola de Hop y un Ctrl-C lo deja colgado
REM esperando el prompt "^C Terminar el trabajo por lotes? (S/N)" sin respuesta
REM en el entorno no interactivo de la tarea programada.
REM Aqui SOLO se verifica que el puerto este escuchando y se re-aplica el DDL.
REM El reset de memoria se hace con "DROP ALL OBJECTS" (00_reset.sql), asi que
REM no es necesario parar/reiniciar el server H2 entre corridas.

echo === Verificar H2 TCP (mem:csep) en puerto 9092 ===
set /a _i=0
:wait_h2
netstat -an | findstr ":9092 " | findstr "LISTENING" >nul 2>&1
if %ERRORLEVEL%==0 (
  echo H2 OK puerto 9092
  goto h2_ready
)
set /a _i+=1
if %_i% GEQ 30 (
  echo FAIL: H2 no abrio puerto 9092. Ejecuta h2\scripts\start_h2_svc.bat.
  exit /b 1
)
ping -n 2 127.0.0.1 >nul
goto wait_h2
:h2_ready

echo === Aplicar DDL (sql\00_reset.sql) ===
java -cp "%H2_JAR%" org.h2.tools.RunScript -url "%DB_H2_URL%" -user sa -password csep -script "sql\00_reset.sql"
if errorlevel 1 (
  echo FAIL reset
  exit /b 1
)

echo === Aplicar DDL (sql\01_schema.sql) ===
java -cp "%H2_JAR%" org.h2.tools.RunScript -url "%DB_H2_URL%" -user sa -password csep -script "sql\01_schema.sql"
if errorlevel 1 (
  echo FAIL schema
  exit /b 1
)

echo === Reset+Create OK ===
echo Pipelines / R usan: %DB_H2_URL%
endlocal
exit /b 0

#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

H2_JAR=lib/h2-2.4.240.jar
[[ -f "$H2_JAR" ]] || H2_JAR=h2-2.4.240.jar
H2_PORT=9092

port_up() {
  if command -v ss >/dev/null 2>&1; then
    ss -ltn 2>/dev/null | grep -qE ":${H2_PORT}\\s"
  else
    netstat -ltn 2>/dev/null | grep -qE ":${H2_PORT}\\s"
  fi
}

if port_up; then
  echo "H2 ya esta arriba en puerto $H2_PORT"
  exit 0
fi

echo "Levantando H2 TCP+WEB..."
nohup java -cp "$H2_JAR" org.h2.tools.Server -tcp -web -webPort 8082 -tcpPort "$H2_PORT" -ifNotExists >/dev/null 2>&1 &

for _i in $(seq 1 30); do
  if port_up; then
    echo "H2 OK puerto $H2_PORT"
    exit 0
  fi
  sleep 1
done

echo "FAIL: H2 no abrio puerto $H2_PORT"
exit 1

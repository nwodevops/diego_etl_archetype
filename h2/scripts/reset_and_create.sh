#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

H2_JAR=lib/h2-2.4.240.jar
[[ -f "$H2_JAR" ]] || H2_JAR=h2-2.4.240.jar
DB_H2_URL='jdbc:h2:tcp://localhost:9092/mem:csep;DB_CLOSE_DELAY=-1;MODE=Oracle;DATABASE_TO_UPPER=TRUE;DEFAULT_NULL_ORDERING=HIGH;AUTO_RECONNECT=TRUE'

# H2 in-memory (mem:csep): al parar el server se limpia sola.
# DDL por TCP DESPUES del start.

echo "=== Stop H2 (limpia mem) ==="
bash scripts/stop_h2.sh

echo "=== Start H2 TCP (mem:csep) ==="
bash scripts/start_h2.sh

echo "=== Aplicar DDL (sql/00_reset.sql) ==="
java -cp "$H2_JAR" org.h2.tools.RunScript -url "$DB_H2_URL" -user sa -password csep -script "sql/00_reset.sql"

echo "=== Aplicar DDL (sql/01_schema.sql) ==="
java -cp "$H2_JAR" org.h2.tools.RunScript -url "$DB_H2_URL" -user sa -password csep -script "sql/01_schema.sql"

echo "=== Reset+Create OK ==="
echo "Pipelines / R usan: $DB_H2_URL"

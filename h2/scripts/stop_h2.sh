#!/usr/bin/env bash
set -euo pipefail
echo "Deteniendo H2 Server si existe..."

# Mata procesos Java cuyo comando incluye org.h2.tools.Server
pkill -f 'org.h2.tools.Server' 2>/dev/null || true
sleep 2

echo "Stop H2 listo"

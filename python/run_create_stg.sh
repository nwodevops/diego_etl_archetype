#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

if [[ -x .venv/bin/python ]]; then
  PY=.venv/bin/python
elif command -v python3 >/dev/null 2>&1; then
  PY=python3
else
  PY=python
fi

if ! "$PY" -c "import yaml" 2>/dev/null; then
  echo "Faltan deps Python. En esta carpeta ejecuta:"
  echo "  $PY -m pip install -r python/requirements.txt"
  echo "O con venv: python3 -m venv .venv && .venv/bin/pip install -r python/requirements.txt"
  exit 1
fi

exec "$PY" python/create_stg.py

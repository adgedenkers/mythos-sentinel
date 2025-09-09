#!/usr/bin/env bash
set -euo pipefail
BASE_URL="${BASE_URL:-http://127.0.0.1:8000}"
curl -sSf "${BASE_URL}/version" | grep -q '"version"'
echo "[test_version] OK"

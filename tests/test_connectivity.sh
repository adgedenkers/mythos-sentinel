#!/usr/bin/env bash
set -euo pipefail

BASE_URL_LOCAL="http://127.0.0.1:8000"
BASE_URL_NGINX="https://loom.denkers.co"

echo "➤ Checking local backend ($BASE_URL_LOCAL)"
if curl -fsS -m 5 "$BASE_URL_LOCAL" >/dev/null; then
  echo "✔ Local backend reachable"
else
  echo "✖ Local backend unreachable" && exit 1
fi

echo "➤ Checking nginx frontend ($BASE_URL_NGINX)"
if curl -kfsS -m 5 "$BASE_URL_NGINX" >/dev/null; then
  echo "✔ Nginx frontend reachable"
else
  echo "✖ Nginx frontend unreachable" && exit 1
fi


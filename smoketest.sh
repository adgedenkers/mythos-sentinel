#!/usr/bin/env bash
ts=$(date +%Y%m%d_%H%M%S)
out=~/sentinel_smoketest_${ts}.txt

{
  echo "=== Mythos Sentinel Smoke Test @ $ts ==="

  echo -e "\n-- systemd status --"
  systemctl is-active sentinel.service
  systemctl show -p MainPID,ExecStart -p FragmentPath sentinel.service

  echo -e "\n-- listener (8000) --"
  ss -ltnp | grep -E "(:8000|gunicorn)" || echo "no 8000 listener"

  echo -e "\n-- backend (127.0.0.1:8000) --"
  echo -n "health no-key http: ";   curl -s -o /dev/null -w "%{http_code}\n"  http://127.0.0.1:8000/health
  echo -n "health with-key http: "; curl -s -o /dev/null -w "%{http_code}\n" -H "x-api-key: adriaan-harold-denkers" http://127.0.0.1:8000/health
  echo -n "version http: ";         curl -s http://127.0.0.1:8000/version; echo
  echo -n "mirror http: ";          curl -s http://127.0.0.1:8000/mirror | head -c 200; echo "...(trunc)"

  echo -e "\n-- public (https://loom.denkers.co) --"
  echo -n "health no-key https: ";   curl -sk -o /dev/null -w "%{http_code}\n" https://loom.denkers.co/health
  echo -n "health with-key https: "; curl -sk -o /dev/null -w "%{http_code}\n" -H "x-api-key: adriaan-harold-denkers" https://loom.denkers.co/health
  echo -n "version https: ";         curl -sk https://loom.denkers.co/version; echo
  echo -n "mirror https: ";          curl -sk https://loom.denkers.co/mirror | head -c 200; echo "...(trunc)"

  echo -e "\n-- nginx site (key locations) --"
  grep -nE "server_name|location|proxy_pass|health" /etc/nginx/sites-available/sentinel || true

  echo -e "\n-- recent app logs --"
  journalctl -u sentinel.service -n 60 --no-pager

  echo -e "\n-- env + ports --"
  printf "DB=%s\nNEO4J=%s\n" "$POSTGRES_NO_PSYCOPG" "$NEO4J_URI"
  ss -ltn | grep -E ":5432|:7687" || echo "no db listeners on 5432/7687"
} | tee "$out"

echo "Wrote report: $out"

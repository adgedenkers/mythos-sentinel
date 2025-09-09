# Mythos Sentinel — Operations Guide

_Last updated: 2025-09-09 17:24 UTC_

This document captures how to run health checks, view logs, test the API (local and public),
and common troubleshooting steps. It reflects the current deployed state:
- **App**: FastAPI served by **gunicorn** with **uvicorn workers**
- **Service**: `sentinel.service` (systemd)
- **Public endpoint**: `https://loom.denkers.co`
- **Auth**: `/health` requires `x-api-key` matched by the server’s configured keys
- **Version**: `/version` returns the app version (currently `0.0.5`)
- **Mirror**: `/mirror` echoes request metadata (for debugging)

---

## Quick status
```bash
# On the server
sudo systemctl status sentinel.service -n 20
ss -ltnp | grep -E '(:8000|gunicorn)' || echo "no 8000 listener"
journalctl -u sentinel.service -n 80 --no-pager
```

## Health / Version / Mirror (public via nginx)
```bash
# Health (expect 401 then 200 with x-api-key)
curl -sk -o /dev/null -w "health no-key https: %{http_code}\n" https://loom.denkers.co/health
curl -sk -o /dev/null -w "health with-key https: %{http_code}\n" -H "x-api-key: <YOUR_KEY>" https://loom.denkers.co/health

# Version & mirror
curl -sk https://loom.denkers.co/version; echo
curl -sk https://loom.denkers.co/mirror | head -c 200; echo
```

## Health / Version / Mirror (backend on the box)
```bash
# SSH then hit localhost:8000
printf "health no-key http: ";   curl -s -o /dev/null -w "%{http_code}\n"  http://127.0.0.1:8000/health
printf "health with-key http: "; curl -s -o /dev/null -w "%{http_code}\n" -H "x-api-key: <YOUR_KEY>" http://127.0.0.1:8000/health
printf "version http: ";         curl -s http://127.0.0.1:8000/version; echo
printf "mirror  http: ";         curl -s http://127.0.0.1:8000/mirror | head -c 200; echo
```

## OpenAPI (for ChatGPT Actions / Custom GPT)
A minimal spec you can paste into ChatGPT “Action” (set **Auth Header** to `x-api-key`):  
`GET /health` is protected; `GET /version` and `GET /mirror` are public.
```yaml
openapi: 3.0.3
info:
  title: Mythos Sentinel API
  version: "0.1"
servers:
  - url: https://loom.denkers.co/
paths:
  /health:
    get:
      security: [ { ApiKeyAuth: [] } ]
      responses:
        "200": { description: ok }
        "401": { description: unauthorized }
  /version:
    get:
      responses:
        "200": { description: version }
  /mirror:
    get:
      responses:
        "200": { description: echo }
components:
  securitySchemes:
    ApiKeyAuth:
      type: apiKey
      in: header
      name: x-api-key
```

### Live OpenAPI JSON
```bash
# Title, version, and server URL
curl -sk https://loom.denkers.co/openapi.json | jq -r '.info.title, .info.version, (.servers[0].url // "no-servers")'
```

> If `.servers` shows `no-servers`, apply **Patch 0006** (openapi-servers) to inject the server URL.

---

## Smoke test (convenience script)
A helper script lives at: **/opt/mythos-sentinel/smoketest.sh**

```bash
# Run on the server
/opt/mythos-sentinel/smoketest.sh

# It writes a timestamped report to ~/sentinel_smoketest_<ts>.txt
ls -1 ~/sentinel_smoketest_*.txt | tail -n 1 | xargs -r cat
```

What it checks:
- systemd status and ExecStart for `sentinel.service`
- Listener on `:8000` and gunicorn workers
- Backend and public `health/version/mirror` (with and without API key)
- Nginx proxy configuration highlights
- Recent app logs (journalctl)
- DB/Neo4j env and listeners (if any configured)

---

## Auth / API keys
- The `/health` endpoint requires the header: `x-api-key: <KEY>`
- Keys are validated by the app’s auth layer (e.g. a users/key source).  
- Make sure the deployment contains the expected keys (e.g. `adriaan-harold-denkers`).

> Note: If using a `users.yaml` file, ensure it’s present on the server and readable by the app.  
> In earlier changes we **added** `app/core/users.yaml` and validated `/health` with it.

---

## Service control
```bash
# Start/stop/restart & logs
sudo systemctl restart sentinel.service
sudo systemctl status sentinel.service -n 30
journalctl -u sentinel.service -f
```

## Nginx notes (public ingress)
The site config proxies `/` to the backend:
```
server_name loom.denkers.co;
location /        { proxy_pass http://127.0.0.1:8000; }
location /cypher  { proxy_pass http://127.0.0.1:8000; }
```

---

## Troubleshooting tips
- **401 vs 200** on `/health` is expected without/with the `x-api-key` header.
- **502 from nginx** usually means the backend wasn’t listening yet or crashed.
- If gunicorn fails to boot, check `journalctl -u sentinel.service -n 200` and fix import errors.
- For OpenAPI **missing servers**, apply Patch 0006 and re-check:
  ```bash
  curl -sk https://loom.denkers.co/openapi.json | jq -r '.servers[0].url // "no-servers"'
  ```

---

## Change log (recent highlights)
- **v0.0.5**: fixed auth middleware order, added `/version`, ensured `users.yaml` present, nginx + backend checks wired.  
- Added **smoketest.sh** script for one-command verification.
- Patch **0006** available to inject `servers` into `/openapi.json` when needed.

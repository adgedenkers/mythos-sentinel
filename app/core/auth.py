from typing import Dict
from fastapi import Request
from fastapi.responses import JSONResponse
import yaml, os

USERS_FILE = os.environ.get("SENTINEL_USERS_FILE", "/opt/mythos-sentinel/app/core/users.yaml")
ALLOWLIST = {"/", "/mirror", "/version", "/openapi.json"}

def _load_keys() -> Dict[str, str]:
    try:
        with open(USERS_FILE, "r", encoding="utf-8") as f:
            data = yaml.safe_load(f) or {}
        keys = {}
        for u in (data.get("users") or []):
            k = (u or {}).get("api_key")
            if k:
                keys[k] = (u.get("role") or "user")
        return keys
    except Exception:
        return {}

def attach_api_key_middleware(app):
    valid_keys = _load_keys()

    @app.middleware("http")
    async def api_key_guard(request: Request, call_next):
        path = request.url.path
        if path in ALLOWLIST:
            return await call_next(request)
        api_key = request.headers.get("x-api-key")
        if not api_key or api_key not in valid_keys:
            return JSONResponse({"detail": "Unauthorized"}, status_code=401)
        return await call_next(request)

from fastapi import APIRouter, Request
from fastapi.responses import JSONResponse

router = APIRouter()

SENSITIVE_HEADERS = {"authorization", "cookie", "set-cookie", "x-api-key"}
SENSITIVE_QUERY_PARAMS = {"token", "password", "apikey", "access_token", "secret"}

@router.api_route("/mirror", methods=["GET", "POST"])
async def mirror(request: Request):
    # Extract method, path, and query params
    method = request.method
    path = request.url.path
    query_params = dict(request.query_params)
    sanitized_query = []
    for key in list(query_params.keys()):
        if key.lower() in SENSITIVE_QUERY_PARAMS:
            query_params[key] = "[REDACTED]"
            sanitized_query.append(key.lower())

    # Extract headers
    headers = dict(request.headers)
    sanitized_headers = []
    for key in list(headers.keys()):
        if key.lower() in SENSITIVE_HEADERS:
            headers[key] = "[REDACTED]"
            sanitized_headers.append(key.lower())

    # Extract body (JSON if possible)
    try:
        body = await request.json()
    except Exception:
        try:
            body = (await request.body()).decode("utf-8")
        except Exception:
            body = None

    # Client info
    client = {
        "ip": request.client.host if request.client else None,
        "user-agent": headers.get("user-agent")
    }

    return JSONResponse(content={
        "method": method,
        "path": path,
        "query": query_params,
        "sanitized_query_params": sanitized_query,
        "headers": headers,
        "sanitized_headers": sanitized_headers,
        "body": body,
        "client": client
    })

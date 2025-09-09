from fastapi import APIRouter, Request

router = APIRouter()

@router.api_route("/mirror", methods=["GET", "POST", "PUT", "PATCH", "DELETE"])
async def mirror(request: Request):
    # Get headers
    headers = dict(request.headers)

    # Get query params
    query_params = dict(request.query_params)

    # Get body (try to parse as JSON, else return raw text)
    try:
        body = await request.json()
    except Exception:
        body = await request.body()
        body = body.decode("utf-8") if body else None

    return {
        "method": request.method,
        "url": str(request.url),
        "headers": headers,
        "query_params": query_params,
        "body": body,
    }

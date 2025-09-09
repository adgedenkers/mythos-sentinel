from fastapi import APIRouter, Request

router = APIRouter()

@router.post("/mirror")
async def mirror(request: Request):
    try:
        body = await request.json()
    except Exception:
        body = None
    return {
        "headers": dict(request.headers),
        "body": body
    }

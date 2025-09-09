from fastapi import APIRouter, Depends, Header, HTTPException
from app.auth.auth import get_api_key

router = APIRouter()

@router.get("/health", tags=["System"])
async def health_check(api_key: str = Depends(get_api_key)):
    return {"status": "ok", "message": "Mythos Sentinel API is alive"}

@router.get("/diagnostics/app", tags=["Diagnostics"])
async def get_main_file(x_api_key: str = Header(...)):
    from pathlib import Path
    if x_api_key not in get_api_key.valid_keys():
        raise HTTPException(status_code=401, detail="Invalid API Key")
    file = Path("/opt/mythos-sentinel/app/main.py")
    if not file.exists():
        raise HTTPException(status_code=404, detail="main.py not found")
    return {"filename": str(file), "content": file.read_text()}


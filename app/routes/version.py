from fastapi import APIRouter
from app.core.versioning import get_app_version
router = APIRouter()
@router.get("/version")
def version():
    return {"version": get_app_version()}

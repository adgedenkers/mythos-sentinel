from fastapi import FastAPI
from app.routes import health
from app.routes import version as version_route
from app.core.auth import attach_api_key_middleware
from app.routes import mirror
attach_api_key_middleware(app)

app = FastAPI(title="Mythos Sentinel API", version="0.1")
app.include_router(version_route.router)

app.include_router(health.router)
app.include_router(mirror.router)

from fastapi.openapi.utils import get_openapi
from fastapi.responses import JSONResponse

@app.get("/openapi.json", include_in_schema=False)
async def custom_openapi():
    openapi_schema = get_openapi(
        title="Mythos Sentinel API",
        version="0.1",
        routes=app.routes,
    )
    # Force servers block for GPT Actions validation
    openapi_schema["servers"] = [{"url": "https://loom.denkers.co/"}]
    return JSONResponse(openapi_schema)
from app.routes import version as version_route
app.include_router(version_route.router)

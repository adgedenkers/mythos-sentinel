from fastapi import FastAPI
from app.routes import health, mirror
from app.routes import version as version_route
from app.core.auth import attach_api_key_middleware

app = FastAPI(title="Mythos Sentinel API", version="0.1")
attach_api_key_middleware(app)

app.include_router(health.router)
app.include_router(mirror.router)
app.include_router(version_route.router)

from fastapi.openapi.utils import get_openapi
from fastapi.responses import JSONResponse

def custom_openapi():
    if getattr(app, "openapi_schema", None):
        return app.openapi_schema
    openapi_schema = get_openapi(
        title="Mythos Sentinel API",
        version="0.1",
        routes=app.routes,
    )
    openapi_schema["openapi"] = "3.1.0"
    openapi_schema["servers"] = [{"url": "https://loom.denkers.co"}]
    app.openapi_schema = openapi_schema
    return app.openapi_schema

app.openapi = custom_openapi

@app.get("/openapi.json", include_in_schema=False)
async def openapi_endpoint():
    return JSONResponse(app.openapi())

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from fastapi.responses import FileResponse
from starlette.middleware.base import BaseHTTPMiddleware
import os.path as osp

from database import engine, Base
from api.auth import router as auth_router
from api.postcards import router as postcards_router
from api.upload import router as upload_router
from api.materials import router as materials_router
from admin_page import router as admin_page_router

# Create tables
Base.metadata.create_all(bind=engine)

# Migration: add status column and new template fields for existing databases
from sqlalchemy import text as sa_text
with engine.connect() as conn:
    for table in ["templates", "stamps", "postmarks"]:
        try:
            conn.execute(sa_text(f"ALTER TABLE {table} ADD COLUMN status VARCHAR(32) DEFAULT 'draft'"))
            conn.commit()
        except Exception:
            pass
    # New template fields for text styling, position, stamp/postmark placement
    template_new_cols = [
        ("from_font", "VARCHAR(64) DEFAULT 'sans-serif'"),
        ("to_font", "VARCHAR(64) DEFAULT 'sans-serif'"),
        ("message_font", "VARCHAR(64) DEFAULT 'sans-serif'"),
        ("from_color", "VARCHAR(16) DEFAULT '333333'"),
        ("to_color", "VARCHAR(16) DEFAULT '333333'"),
        ("message_color", "VARCHAR(16) DEFAULT '555555'"),
        ("from_size", "INTEGER DEFAULT 14"),
        ("to_size", "INTEGER DEFAULT 14"),
        ("message_size", "INTEGER DEFAULT 13"),
        ("from_x", "INTEGER DEFAULT 10"),
        ("from_y", "INTEGER DEFAULT 82"),
        ("to_x", "INTEGER DEFAULT 55"),
        ("to_y", "INTEGER DEFAULT 82"),
        ("message_x", "INTEGER DEFAULT 10"),
        ("message_y", "INTEGER DEFAULT 60"),
        ("message_w", "INTEGER DEFAULT 80"),
        ("stamp_x", "INTEGER DEFAULT 78"),
        ("stamp_y", "INTEGER DEFAULT 5"),
        ("stamp_rotation", "INTEGER DEFAULT 0"),
        ("stamp_scale", "INTEGER DEFAULT 100"),
        ("postmark_x", "INTEGER DEFAULT 45"),
        ("postmark_y", "INTEGER DEFAULT 45"),
        ("postmark_rotation", "INTEGER DEFAULT 0"),
        ("postmark_scale", "INTEGER DEFAULT 100"),
        ("message_h", "INTEGER DEFAULT 80"),
        ("from_w", "INTEGER DEFAULT 120"),
        ("from_h", "INTEGER DEFAULT 28"),
        ("to_w", "INTEGER DEFAULT 120"),
        ("to_h", "INTEGER DEFAULT 28"),
        ("from_border_color", "VARCHAR(16) DEFAULT 'CCCCCC'"),
        ("to_border_color", "VARCHAR(16) DEFAULT 'CCCCCC'"),
        ("from_border_width", "INTEGER DEFAULT 0"),
        ("to_border_width", "INTEGER DEFAULT 0"),
        ("from_bg_color", "VARCHAR(16) DEFAULT 'FFFFFF'"),
        ("to_bg_color", "VARCHAR(16) DEFAULT 'FFFFFF'"),
        ("from_bg_opacity", "INTEGER DEFAULT 0"),
        ("to_bg_opacity", "INTEGER DEFAULT 0"),
    ]
    for col_name, col_type in template_new_cols:
        try:
            conn.execute(sa_text(f"ALTER TABLE templates ADD COLUMN {col_name} {col_type}"))
            conn.commit()
        except Exception:
            pass

# Find Flutter app directory (handle both static/app/ and static/app/web/ layouts)
def _find_app_dir():
    for candidate in ["static/app", "static/app/web"]:
        if osp.isfile(osp.join(candidate, "index.html")):
            return candidate
    return "static/app"  # fallback


app = FastAPI(title="明信片设计器 API", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth_router)
app.include_router(postcards_router)
app.include_router(upload_router)
app.include_router(materials_router)
app.include_router(admin_page_router)

class ImageCORSHandler(BaseHTTPMiddleware):
    """Ensure all responses (including static files) have CORS headers for CanvasKit image loading."""
    async def dispatch(self, request: Request, call_next):
        response = await call_next(request)
        response.headers["Access-Control-Allow-Origin"] = "*"
        response.headers["Timing-Allow-Origin"] = "*"
        return response


app.mount("/static", StaticFiles(directory="static"), name="static")

# Serve Flutter Web app static files
app.mount("/app-assets", StaticFiles(directory=_find_app_dir()), name="app_assets")

app.add_middleware(ImageCORSHandler)


@app.get("/api/health")
def health():
    return {"status": "ok"}


@app.get("/api/images/{file_path:path}")
async def serve_image(file_path: str, size: str = ""):
    """Serve static images with explicit CORS and cache headers.
    Routes through API layer so CORSMiddleware + ImageCORSHandler both apply,
    and we can set Cache-Control to prevent stale-cache issues on mobile.
    Supports ?size=thumb (200px) or ?size=small (600px) for thumbnails."""
    full_path = osp.join("static", file_path)

    # Thumbnail support: /api/images/cards/abc.png?size=thumb -> static/cards/abc_thumb.png
    if size in ("thumb", "small"):
        base_dir = osp.dirname(full_path)
        base_name = osp.basename(full_path)
        stem, ext = osp.splitext(base_name)
        thumb_path = osp.join(base_dir, f"{stem}_{size}{ext}")
        if osp.isfile(thumb_path):
            full_path = thumb_path

    if not osp.isfile(full_path):
        from fastapi import HTTPException
        raise HTTPException(404)
    return FileResponse(full_path, headers={
        "Cache-Control": "public, max-age=86400",
        "Access-Control-Allow-Origin": "*",
        "Timing-Allow-Origin": "*",
    })


# Catch-all: serve Flutter SPA for all non-API paths (must be last)
@app.get("/{full_path:path}")
async def serve_spa(full_path: str):
    app_dir = _find_app_dir()
    file_path = osp.join(app_dir, full_path)
    if full_path and osp.isfile(file_path):
        return FileResponse(file_path)
    return FileResponse(osp.join(app_dir, "index.html"))

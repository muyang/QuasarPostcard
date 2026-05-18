from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from fastapi.responses import FileResponse
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

app.mount("/static", StaticFiles(directory="static"), name="static")

# Serve Flutter Web app static files
app.mount("/app-assets", StaticFiles(directory=_find_app_dir()), name="app_assets")


@app.get("/api/health")
def health():
    return {"status": "ok"}


# Catch-all: serve Flutter SPA for all non-API paths (must be last)
@app.get("/{full_path:path}")
async def serve_spa(full_path: str):
    app_dir = _find_app_dir()
    file_path = osp.join(app_dir, full_path)
    if full_path and osp.isfile(file_path):
        return FileResponse(file_path)
    return FileResponse(osp.join(app_dir, "index.html"))

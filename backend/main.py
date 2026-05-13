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

# Migration: add status column for existing databases
from sqlalchemy import text as sa_text
with engine.connect() as conn:
    for table in ["templates", "stamps", "postmarks"]:
        try:
            conn.execute(sa_text(f"ALTER TABLE {table} ADD COLUMN status VARCHAR(32) DEFAULT 'draft'"))
            conn.commit()
        except Exception:
            pass

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
app.mount("/app-assets", StaticFiles(directory="static/app"), name="app_assets")


@app.get("/api/health")
def health():
    return {"status": "ok"}


# Catch-all: serve Flutter SPA for all non-API paths (must be last)
@app.get("/{full_path:path}")
async def serve_spa(full_path: str):
    app_dir = "static/app"
    file_path = osp.join(app_dir, full_path)
    if full_path and osp.isfile(file_path):
        return FileResponse(file_path)
    return FileResponse(osp.join(app_dir, "index.html"))

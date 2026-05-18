import uuid
import os
from fastapi import APIRouter, UploadFile, File, Depends
from api.auth import verify_admin

router = APIRouter(prefix="/api/upload", tags=["upload"])

UPLOAD_DIR = "static/cards"
os.makedirs(UPLOAD_DIR, exist_ok=True)


@router.post("/image")
async def upload_image(
    file: UploadFile = File(...),
    _: str = Depends(verify_admin),
):
    ext = os.path.splitext(file.filename or ".png")[1] or ".png"
    filename = f"{uuid.uuid4().hex[:12]}{ext}"
    filepath = os.path.join(UPLOAD_DIR, filename)

    content = await file.read()
    with open(filepath, "wb") as f:
        f.write(content)

    url = f"/static/cards/{filename}"
    return {"success": True, "url": url}

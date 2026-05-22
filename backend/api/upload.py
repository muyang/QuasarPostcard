import uuid
import os
from io import BytesIO
from PIL import Image, ImageOps
from fastapi import APIRouter, UploadFile, File, Depends
from api.auth import verify_user

router = APIRouter(prefix="/api/upload", tags=["upload"])

UPLOAD_DIR = "static/cards"
os.makedirs(UPLOAD_DIR, exist_ok=True)

MAX_DIM = 2048
THUMB_SIZES = {"thumb": 200, "small": 600}


def _save_image(im, path, fmt="JPEG"):
    if im.mode == "RGBA":
        bg = Image.new("RGB", im.size, (255, 255, 255))
        bg.paste(im, mask=im.split()[3])
        im = bg
    im.save(path, format=fmt, quality=85, optimize=True)


@router.post("/image")
async def upload_image(
    file: UploadFile = File(...),
    _: dict = Depends(verify_user),
):
    ext = os.path.splitext(file.filename or ".png")[1].lower() or ".png"
    base = uuid.uuid4().hex[:12]
    filename = f"{base}{ext}"
    filepath = os.path.join(UPLOAD_DIR, filename)

    content = await file.read()
    im = Image.open(BytesIO(content))
    im = ImageOps.exif_transpose(im)  # fix orientation

    # Resize if exceeds max dimension
    w, h = im.size
    if max(w, h) > MAX_DIM:
        ratio = MAX_DIM / max(w, h)
        im = im.resize((int(w * ratio), int(h * ratio)), Image.LANCZOS)

    fmt = "JPEG" if ext in (".jpg", ".jpeg") else "PNG"
    _save_image(im, filepath, fmt)

    # Generate thumbnails
    for suffix, size in THUMB_SIZES.items():
        tw, th = im.size
        ratio = size / max(tw, th)
        thumb = im.resize((int(tw * ratio), int(th * ratio)), Image.LANCZOS)
        thumb_path = os.path.join(UPLOAD_DIR, f"{base}_{suffix}{ext}")
        _save_image(thumb, thumb_path, fmt)

    url = f"/static/cards/{filename}"
    return {"success": True, "url": url}

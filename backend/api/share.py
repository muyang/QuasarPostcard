import os
import uuid
import smtplib
import base64
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from email.mime.image import MIMEImage

from fastapi import APIRouter, HTTPException, Depends
from sqlalchemy.orm import Session

from database import get_db
from api.auth import verify_user

router = APIRouter(prefix="/api/share", tags=["share"])

SHARE_DIR = "static/shares"
os.makedirs(SHARE_DIR, exist_ok=True)


@router.post("/upload-image")
async def upload_share_image(data: dict, user=Depends(verify_user)):
    """Upload a postcard image for sharing (base64 encoded). Returns a public URL."""
    image_data = data.get("image_data", "")
    if not image_data:
        raise HTTPException(400, "缺少图片数据")

    ext = ".png"
    base = uuid.uuid4().hex[:16]
    filename = f"share_{base}{ext}"
    filepath = os.path.join(SHARE_DIR, filename)

    content = base64.b64decode(image_data)
    with open(filepath, "wb") as f:
        f.write(content)

    url = f"/static/shares/{filename}"
    return {"success": True, "url": url}


@router.post("/email")
def share_email(data: dict, user=Depends(verify_user)):
    """Send postcard image via email using SMTP. Falls back to mailto if not configured."""
    to_email = data.get("email", "")
    subject = data.get("subject", "有人给你寄了一张明信片")
    body = data.get("body", "请查收附件中的明信片～")
    image_url = data.get("image_url", "")

    if not to_email:
        raise HTTPException(400, "请输入收件人邮箱")

    smtp_host = os.environ.get("SMTP_HOST", "")
    base_url = os.environ.get("BASE_URL", "")

    if not smtp_host:
        # No SMTP configured: return mailto fallback info
        share_url = f"{base_url}/share/view/{os.path.basename(image_url)}"
        return {"success": False, "fallback": "mailto", "share_url": share_url}

    # Build email with inline image attachment
    msg = MIMEMultipart("related")
    msg["Subject"] = subject
    msg["From"] = os.environ.get("SMTP_FROM", smtp_host)
    msg["To"] = to_email

    image_path = os.path.join(SHARE_DIR, os.path.basename(image_url))
    if os.path.isfile(image_path):
        with open(image_path, "rb") as f:
            img_data = f.read()
        img = MIMEImage(img_data, _subtype="png")
        img.add_header("Content-ID", "<postcard_image>")
        img.add_header("Content-Disposition", "attachment", filename="postcard.png")
        msg.attach(img)

    msg.attach(MIMEText(body, "plain", "utf-8"))

    try:
        with smtplib.SMTP(smtp_host, int(os.environ.get("SMTP_PORT", "587"))) as server:
            server.starttls()
            server.login(os.environ.get("SMTP_USER", ""), os.environ.get("SMTP_PASSWORD", ""))
            server.send_message(msg)
        return {"success": True, "message": "邮件已发送"}
    except Exception as e:
        raise HTTPException(500, f"邮件发送失败: {e}")

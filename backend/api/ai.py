"""Proxy router for the AI anime-face service.

Forwards requests to the local AI inference service (port 8200 via Nginx LB,
or direct worker ports) and saves the result image to static storage so
the frontend can use it as a stamp image_url.
"""
import base64
import os
import uuid

import requests
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field
from fastapi.responses import JSONResponse

from api.auth import verify_user

router = APIRouter(prefix="/api/ai", tags=["ai"])

AI_SERVICE_URL = os.environ.get("AI_SERVICE_URL", "http://localhost:8200")
STATIC_CARDS_DIR = "static/cards"


class AnimeFaceRequest(BaseModel):
    image_base64: str = Field(..., description="Base64-encoded portrait photo")
    prompt: str = ""
    num_inference_steps: int = Field(30, ge=1, le=100)
    guidance_scale: float = Field(7.0, ge=1.0, le=20.0)
    controlnet_conditioning_scale: float = Field(0.8, ge=0.0, le=2.0)


@router.post("/anime-face")
def anime_face(req: AnimeFaceRequest, _: dict = Depends(verify_user)):
    """Convert a portrait photo to anime style and return a saved image URL.

    The returned URL can be used directly as a stamp image_url in the postcard.
    """
    try:
        resp = requests.post(
            f"{AI_SERVICE_URL}/api/anime-face",
            json={
                "image_base64": req.image_base64,
                "prompt": req.prompt,
                "num_inference_steps": req.num_inference_steps,
                "guidance_scale": req.guidance_scale,
                "controlnet_conditioning_scale": req.controlnet_conditioning_scale,
            },
            timeout=120,
        )
    except requests.exceptions.ConnectionError:
        raise HTTPException(503, "AI 服务不可用，请确认 ai-service 已启动")
    except requests.exceptions.Timeout:
        raise HTTPException(504, "AI 服务响应超时")

    if resp.status_code != 200:
        raise HTTPException(502, f"AI 服务错误: {resp.text}")

    data = resp.json()
    if not data.get("success"):
        raise HTTPException(500, f"AI 推理失败: {data.get('error', '未知错误')}")

    # Save the generated image to static storage
    os.makedirs(STATIC_CARDS_DIR, exist_ok=True)
    filename = f"anime_{uuid.uuid4().hex[:12]}.png"
    filepath = os.path.join(STATIC_CARDS_DIR, filename)

    img_bytes = base64.b64decode(data["image_base64"])
    with open(filepath, "wb") as f:
        f.write(img_bytes)

    image_url = f"/static/cards/{filename}"

    return JSONResponse(content={
        "success": True,
        "image_url": image_url,
        "elapsed_ms": data.get("elapsed_ms", 0),
    })

"""FastAPI service for face anime-ification.

Each worker loads one pipeline pinned to a single GPU.
Deploy two workers (one per GPU) behind Nginx for load balancing.
"""
import base64
import io
import os
import time
import uuid

from fastapi import FastAPI
from pydantic import BaseModel, Field
from PIL import Image

from pipeline import AnimePipeline
from face_utils import process_image

app = FastAPI(title="Anime Face API", version="1.0.0")

# Load pipeline at startup (pinned to GPU via CUDA_VISIBLE_DEVICES env)
_gpu_id = int(os.environ.get("GPU_ID", "0"))
_pipeline: AnimePipeline | None = None


def get_pipeline() -> AnimePipeline:
    global _pipeline
    if _pipeline is None:
        print(f"[app] loading pipeline on GPU {_gpu_id}...")
        _pipeline = AnimePipeline(gpu_id=_gpu_id)
    return _pipeline


# ---------- Schemas ----------

class AnimeRequest(BaseModel):
    image_base64: str = Field(..., description="Base64-encoded JPG/PNG portrait photo")
    prompt: str = Field("", description="Optional custom prompt")
    negative_prompt: str = Field("", description="Optional negative prompt")
    num_inference_steps: int = Field(30, ge=1, le=100)
    guidance_scale: float = Field(7.0, ge=1.0, le=20.0)
    controlnet_scale: float = Field(0.8, ge=0.0, le=2.0, alias="controlnet_conditioning_scale")
    seed: int = Field(-1, description="-1 for random")


class AnimeResponse(BaseModel):
    success: bool
    image_base64: str = ""
    error: str = ""
    elapsed_ms: int = 0


# ---------- Endpoints ----------

@app.get("/health")
def health():
    return {"status": "ok", "gpu_id": _gpu_id, "pipeline_loaded": _pipeline is not None}


@app.post("/api/anime-face", response_model=AnimeResponse)
def anime_face(req: AnimeRequest):
    t0 = time.time()
    try:
        # Decode base64 -> PIL
        raw = base64.b64decode(req.image_base64)
        image = Image.open(io.BytesIO(raw)).convert("RGB")

        # Preprocess: face crop + depth map
        _, depth_map = process_image(image, target_size=512)

        # Generate anime portrait
        pipe = get_pipeline()
        result = pipe.generate(
            image=depth_map,
            prompt=req.prompt,
            negative_prompt=req.negative_prompt,
            num_inference_steps=req.num_inference_steps,
            guidance_scale=req.guidance_scale,
            controlnet_conditioning_scale=req.controlnet_scale,
            seed=req.seed,
        )

        # Encode result -> base64
        buf = io.BytesIO()
        result.save(buf, format="PNG")
        b64 = base64.b64encode(buf.getvalue()).decode()

        elapsed = int((time.time() - t0) * 1000)
        return AnimeResponse(success=True, image_base64=b64, elapsed_ms=elapsed)

    except Exception as e:
        elapsed = int((time.time() - t0) * 1000)
        return AnimeResponse(success=False, error=str(e), elapsed_ms=elapsed)


# Load pipeline eagerly if configured (avoids cold-start latency on first request)
if os.environ.get("EAGER_LOAD", "1") == "1":
    get_pipeline()

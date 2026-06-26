"""FastAPI service for face anime-ification.

Each worker loads one pipeline pinned to a single GPU.
Deploy two workers (one per GPU) behind Nginx for load balancing.

Model loading happens in a background thread so the server starts
immediately and the health check passes during model download.
"""
import base64
import io
import os
import threading
import time

from fastapi import FastAPI
from pydantic import BaseModel, Field
from PIL import Image

from pipeline import AnimePipeline
from face_utils import process_image

_gpu_id = int(os.environ.get("GPU_ID", "0"))

app = FastAPI(title="Anime Face API", version="1.0.0")

# Pipeline state — loaded in background thread
_pipeline: AnimePipeline | None = None
_pipeline_lock = threading.Lock()
_pipeline_status = "idle"  # idle -> loading -> ready / error
_pipeline_error: str | None = None


def _load_pipeline_async():
    """Load the SD pipeline in a background thread."""
    global _pipeline, _pipeline_status, _pipeline_error
    with _pipeline_lock:
        if _pipeline_status == "loading":
            return
        _pipeline_status = "loading"
    try:
        print(f"[app] loading pipeline on GPU {_gpu_id}...", flush=True)
        pipe = AnimePipeline(gpu_id=_gpu_id)
        with _pipeline_lock:
            _pipeline = pipe
            _pipeline_status = "ready"
            _pipeline_error = None
        print("[app] pipeline ready", flush=True)
    except Exception as e:
        with _pipeline_lock:
            _pipeline_status = "error"
            _pipeline_error = str(e)
        print(f"[app] pipeline load failed: {e}", flush=True)


def get_pipeline() -> AnimePipeline | None:
    global _pipeline
    with _pipeline_lock:
        if _pipeline is None and _pipeline_status == "idle":
            _load_pipeline_async()
        return _pipeline


# ---------- Startup ----------

@app.on_event("startup")
def _startup():
    if os.environ.get("EAGER_LOAD", "1") == "1":
        threading.Thread(target=_load_pipeline_async, daemon=True).start()


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
    """Always returns 200 — the server is alive even while models load."""
    return {
        "status": "ok",
        "gpu_id": _gpu_id,
        "pipeline_status": _pipeline_status,
        "pipeline_error": _pipeline_error,
    }


@app.get("/ready")
def ready():
    """Returns 200 only when the pipeline is loaded and ready for inference."""
    if _pipeline_status != "ready":
        from fastapi import HTTPException
        raise HTTPException(503, f"pipeline not ready (status={_pipeline_status})")
    return {"status": "ready"}


@app.post("/api/anime-face", response_model=AnimeResponse)
def anime_face(req: AnimeRequest):
    t0 = time.time()

    # Check if pipeline is ready
    with _pipeline_lock:
        if _pipeline_status == "loading":
            return AnimeResponse(
                success=False,
                error="模型正在加载中，请稍后重试",
                elapsed_ms=int((time.time() - t0) * 1000),
            )
        if _pipeline_status == "error":
            return AnimeResponse(success=False, error=_pipeline_error or "模型加载失败", elapsed_ms=0)
        if _pipeline is None:
            _load_pipeline_async()
            return AnimeResponse(
                success=False,
                error="模型正在加载中，请稍后重试",
                elapsed_ms=int((time.time() - t0) * 1000),
            )

    try:
        # Decode base64 -> PIL
        raw = base64.b64decode(req.image_base64)
        image = Image.open(io.BytesIO(raw)).convert("RGB")

        # Preprocess: face crop + depth map
        _, depth_map = process_image(image, target_size=512)

        # Generate anime portrait
        result = _pipeline.generate(
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

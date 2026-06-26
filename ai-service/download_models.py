"""Pre-download all models so Docker build doesn't re-download on every run.

Run this before `docker compose up` to populate the model cache volume:
    python3 download_models.py

Or run inside the container to populate /app/models.
"""
import os

MODELS_DIR = os.environ.get("MODEL_CACHE_DIR", "/app/models")
os.environ["HF_HOME"] = os.path.join(MODELS_DIR, "hf_cache")

def main():
    print(f"=== Downloading models to {MODELS_DIR} ===")

    # 1. Stable Diffusion base model
    print("\n[1/3] SD base model: runwayml/stable-diffusion-v1-5")
    from diffusers import StableDiffusionControlNetPipeline
    StableDiffusionControlNetPipeline.from_pretrained(
        "runwayml/stable-diffusion-v1-5",
        torch_dtype="auto",
        safety_checker=None,
    )
    print("  done")

    # 2. ControlNet depth
    print("\n[2/3] ControlNet depth: lllyasviel/control_v11f1p_sd15_depth")
    from diffusers import ControlNetModel
    ControlNetModel.from_pretrained(
        "lllyasviel/control_v11f1p_sd15_depth",
        torch_dtype="auto",
    )
    print("  done")

    # 3. MiDaS depth annotator (used by controlnet_aux)
    print("\n[3/3] MiDaS depth annotator: lllyasviel/Annotators")
    from controlnet_aux import MidasDetector
    MidasDetector.from_pretrained("lllyasviel/Annotators")
    print("  done")

    # 4. Mediapipe face detection model (auto-downloaded by face_utils)
    print("\n[4/4] Mediapipe blaze face model")
    from face_utils import _download_mediapipe_model
    _download_mediapipe_model()
    print("  done")

    print(f"\n=== All models cached in {MODELS_DIR} ===")


if __name__ == "__main__":
    main()

"""Stable Diffusion + ControlNet + LoRA inference pipeline for face anime-ification."""
import os
import torch
import numpy as np
from PIL import Image
from diffusers import (
    StableDiffusionControlNetPipeline,
    ControlNetModel,
    EulerAncestralDiscreteScheduler,
    DDIMScheduler,
)
from diffusers.utils import load_image


class AnimePipeline:
    """Wraps SD1.5 + ControlNet(depth) + optional anime LoRA.

    Flow: input photo -> face crop -> depth map -> ControlNet generation -> anime portrait
    """

    def __init__(self, gpu_id: int = 0):
        self.device = f"cuda:{gpu_id}" if torch.cuda.is_available() else "cpu"
        self.dtype = torch.float16 if torch.cuda.is_available() else torch.float32

        base_model = os.environ.get("SD_BASE_MODEL", "runwayml/stable-diffusion-v1-5")
        controlnet_model = os.environ.get(
            "CONTROLNET_MODEL", "lllyasviel/control_v11f1p_sd15_depth"
        )
        lora_path = os.environ.get("LORA_PATH", "")  # path or HF repo
        lora_scale = float(os.environ.get("LORA_SCALE", "0.8"))

        # --- ControlNet (depth) ---
        self.controlnet = ControlNetModel.from_pretrained(
            controlnet_model, torch_dtype=self.dtype
        )

        # --- SD pipeline ---
        self.pipe = StableDiffusionControlNetPipeline.from_pretrained(
            base_model,
            controlnet=self.controlnet,
            torch_dtype=self.dtype,
            safety_checker=None,
            requires_safety_checker=False,
        )

        # --- Anime LoRA (optional) ---
        self.lora_scale = 0.0
        if lora_path:
            try:
                self.pipe.load_lora_weights(lora_path)
                self.lora_scale = lora_scale
                print(f"[pipeline] LoRA loaded: {lora_path} (scale={lora_scale})")
            except Exception as e:
                print(f"[pipeline] LoRA load failed: {e}, continuing without LoRA")

        # --- Scheduler: Euler ancestral gives crisp anime lineart ---
        self.pipe.scheduler = EulerAncestralDiscreteScheduler.from_config(
            self.pipe.scheduler.config
        )

        # --- Move to GPU & optimize ---
        self.pipe.to(self.device)
        try:
            self.pipe.enable_xformers_memory_efficient_attention()
        except Exception:
            pass  # xformers not installed, fall back to default attention

        # Warm up with a dummy run (first inference is always slow due to CUDA init)
        self._warmup()

        print(f"[pipeline] Ready on {self.device} (dtype={self.dtype})")

    def _warmup(self):
        """Run a tiny dummy generation to initialise CUDA kernels."""
        try:
            dummy = Image.new("RGB", (512, 512), (128, 128, 128))
            self.pipe(
                prompt="anime portrait",
                image=dummy,
                num_inference_steps=2,
                guidance_scale=1.0,
            )
            print("[pipeline] warmup done")
        except Exception as e:
            print(f"[pipeline] warmup skipped: {e}")

    def generate(
        self,
        image: Image.Image,
        prompt: str = "",
        negative_prompt: str = "",
        num_inference_steps: int = 30,
        guidance_scale: float = 7.0,
        controlnet_conditioning_scale: float = 0.8,
        seed: int = -1,
    ) -> Image.Image:
        """Generate an anime-style portrait from a face image + depth map.

        Args:
            image: 512x512 PIL RGB image (already face-cropped).
            prompt: text prompt, defaults to anime portrait if empty.
            Returns: 512x512 PIL RGB anime portrait.
        """
        if not prompt:
            prompt = (
                "anime portrait, 1girl, beautiful detailed eyes, "
                "cel shading, high quality, masterpiece, anime style, "
                "smooth skin, detailed face"
            )
        if not negative_prompt:
            negative_prompt = (
                "lowres, bad anatomy, bad hands, deformed, blurry, "
                "extra limbs, ugly, text, watermark, photorealistic, 3d"
            )

        generator = None
        if seed >= 0:
            generator = torch.Generator(device=self.device).manual_seed(seed)

        # Cross-attention kwargs for LoRA
        cross_attn_kwargs = {}
        if self.lora_scale > 0:
            cross_attn_kwargs["cross_attention_kwargs"] = {"scale": self.lora_scale}

        result = self.pipe(
            prompt=prompt,
            negative_prompt=negative_prompt,
            image=image,  # depth map as control image
            num_inference_steps=num_inference_steps,
            guidance_scale=guidance_scale,
            controlnet_conditioning_scale=controlnet_conditioning_scale,
            generator=generator,
            **cross_attn_kwargs,
        )

        return result.images[0]

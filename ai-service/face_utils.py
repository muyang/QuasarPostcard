"""Face detection, cropping, and depth-map extraction for the anime pipeline."""
import numpy as np
from PIL import Image

# Lazy-loaded singletons (heavy models load on first call)
_face_detector = None
_depth_estimator = None


def _get_face_detector():
    """Mediapipe face detection — fast, CPU-only, no GPU contention."""
    global _face_detector
    if _face_detector is None:
        import mediapipe as mp
        _face_detector = mp.tasks.vision.FaceDetector
        model_path = _download_mediapipe_model()
        _face_detector = _face_detector.create_from_options(
            mp.tasks.vision.FaceDetectorOptions(
                base_options=mp.BaseOptions(model_asset_path=model_path),
                min_detection_confidence=0.3,
            )
        )
    return _face_detector


def _download_mediapipe_model():
    """Download the mediapipe blaze face model if not cached."""
    import os, urllib.request
    cache_dir = os.environ.get("MODEL_CACHE_DIR", "/app/models")
    path = os.path.join(cache_dir, "blaze_face_short_range.tflite")
    if not os.path.exists(path):
        os.makedirs(cache_dir, exist_ok=True)
        url = "https://storage.googleapis.com/mediapipe-models/face_detector/blaze_face_short_range/float16/latest/blaze_face_short_range.tflite"
        urllib.request.urlretrieve(url, path)
    return path


def _get_depth_estimator():
    """MiDaS depth estimator via controlnet_aux."""
    global _depth_estimator
    if _depth_estimator is None:
        from controlnet_aux import MidasDetector
        _depth_estimator = MidasDetector.from_pretrained("lllyasviel/Annotators")
    return _depth_estimator


def detect_and_crop_face(
    image: Image.Image,
    target_size: int = 512,
    padding_ratio: float = 2.2,
) -> Image.Image:
    """Detect the largest face, crop around it with padding, resize to square.

    Args:
        image: PIL RGB input photo (any size).
        target_size: output dimension (512 for SD1.5).
        padding_ratio: how much context around the face to include.
                       2.2 = face occupies ~45% of the crop.
    Returns: target_size x target_size PIL RGB image.
    """
    import mediapipe as mp

    arr = np.array(image.convert("RGB"))
    h, w = arr.shape[:2]

    detector = _get_face_detector()
    mp_image = mp.Image(image_format=mp.ImageFormat.SRGB, data=arr)
    result = detector.detect(mp_image)

    if not result.detections:
        # No face found — fall back to center crop
        print("[face_utils] no face detected, using center crop")
        return _center_crop(image, target_size)

    # Pick the largest detection
    best = max(result.detections, key=lambda d: d.bounding_box.width * d.bounding_box.height)
    box = best.bounding_box
    cx = box.origin_x + box.width / 2
    cy = box.origin_y + box.height / 2
    face_size = max(box.width, box.height)

    # Expand to include hair, ears, neck
    crop_size = face_size * padding_ratio
    half = crop_size / 2

    # Clamp to image bounds, then compute actual crop rect
    left = max(0, int(cx - half))
    top = max(0, int(cy - half))
    right = min(w, int(cx + half))
    bottom = min(h, int(cy + half))

    cropped = image.crop((left, top, right, bottom))

    # Pad to square if aspect ratio isn't 1:1
    cw, ch = cropped.size
    if cw != ch:
        size = max(cw, ch)
        bg = Image.new("RGB", (size, size), (255, 255, 255))
        bg.paste(cropped, ((size - cw) // 2, (size - ch) // 2))
        cropped = bg

    return cropped.resize((target_size, target_size), Image.LANCZOS)


def _center_crop(image: Image.Image, target_size: int) -> Image.Image:
    """Fallback: center-crop to square then resize."""
    w, h = image.size
    size = min(w, h)
    left = (w - size) // 2
    top = (h - size) // 2
    cropped = image.crop((left, top, left + size, top + size))
    return cropped.resize((target_size, target_size), Image.LANCZOS)


def extract_depth_map(image: Image.Image, target_size: int = 512) -> Image.Image:
    """Extract a depth map from an image for ControlNet conditioning.

    Uses MiDaS via controlnet_aux. The depth map preserves facial structure
    so the generated anime portrait matches the original face geometry.
    """
    estimator = _get_depth_estimator()
    depth = estimator(image)
    # Ensure output is the right size
    if depth.size != (target_size, target_size):
        depth = depth.resize((target_size, target_size), Image.LANCZOS)
    return depth


def process_image(image: Image.Image, target_size: int = 512) -> tuple:
    """Full preprocessing: face crop + depth extraction.

    Returns:
        (face_crop_512, depth_map_512) — both PIL RGB 512x512.
    """
    face_crop = detect_and_crop_face(image, target_size=target_size)
    depth_map = extract_depth_map(face_crop, target_size=target_size)
    return face_crop, depth_map

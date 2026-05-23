"""
Generate missing thumbnails for all static card images.
Run from backend/ directory: python generate_thumbs.py
"""
import os
import sys
from PIL import Image, ImageOps

UPLOAD_DIR = "static/cards"
THUMB_SIZE = 200   # for ?size=thumb
SMALL_SIZE = 600   # for ?size=small

def generate():
    os.chdir(os.path.dirname(os.path.abspath(__file__)))
    files = sorted(os.listdir(UPLOAD_DIR))
    originals = set()

    for f in files:
        if "_thumb" in f or "_small" in f:
            continue
        name, ext = os.path.splitext(f)
        if ext.lower() not in (".png", ".jpg", ".jpeg", ".webp"):
            continue
        originals.add(name)

    missing_thumb = 0
    missing_small = 0

    for name in originals:
        # Find the original file
        for ext_try in (".png", ".jpg", ".jpeg", ".webp"):
            orig_path = os.path.join(UPLOAD_DIR, name + ext_try)
            if os.path.isfile(orig_path):
                real_ext = ext_try
                break
        else:
            continue

        thumb_path = os.path.join(UPLOAD_DIR, f"{name}_thumb{real_ext}")
        small_path = os.path.join(UPLOAD_DIR, f"{name}_small{real_ext}")

        if os.path.isfile(thumb_path) and os.path.isfile(small_path):
            continue

        try:
            im = Image.open(orig_path).convert("RGBA")
        except Exception as e:
            print(f"  SKIP {name}: {e}")
            continue

        w, h = im.size
        if w <= 0 or h <= 0:
            continue

        ratio = min(THUMB_SIZE / max(w, h), 1.0)

        # Thumbnail (200px)
        if not os.path.isfile(thumb_path):
            tw = max(int(w * ratio), 1)
            th = max(int(h * ratio), 1)
            thumb = im.resize((tw, th), Image.LANCZOS)
            save_optimized(thumb, thumb_path, real_ext)
            missing_thumb += 1
            print(f"  thumb: {name}{real_ext} ({w}x{h} -> {tw}x{th})")

        # Small (600px)
        if not os.path.isfile(small_path):
            ratio_s = min(SMALL_SIZE / max(w, h), 1.0)
            sw = max(int(w * ratio_s), 1)
            sh = max(int(h * ratio_s), 1)
            small = im.resize((sw, sh), Image.LANCZOS)
            save_optimized(small, small_path, real_ext)
            missing_small += 1

        im.close()

    print(f"\nDone: {missing_thumb} thumbnails, {missing_small} smalls generated.")


def save_optimized(im, path, ext):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    ext_l = ext.lower()
    if ext_l in (".jpg", ".jpeg"):
        im = im.convert("RGB")
        im.save(path, "JPEG", quality=82, optimize=True)
    elif ext_l == ".png":
        # Use palette mode if possible (fewer colors = smaller)
        if im.mode == "RGBA":
            alpha = im.getchannel("A")
            if alpha.getextrema() == (255, 255):
                im = im.convert("RGB")
            else:
                im = im.convert("RGBA")
        if im.mode == "RGB":
            im = im.quantize(colors=256, method=Image.Quantize.MEDIANCUT).convert("RGB")
        im.save(path, "PNG", optimize=True)
    else:
        im.save(path, optimize=True)


if __name__ == "__main__":
    generate()

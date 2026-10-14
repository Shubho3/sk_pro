"""Generate size-appropriate logo variants from the two committed sources.

Sources (do not edit by hand):
  assets/logo_no_bg.png     RGBA, transparent  -> every in-app placement
  assets/logo_white_bg.png  RGB,  cream bg     -> favicon, PWA icons, documents

Run: python tool/gen_logo_assets.py
"""
import os

from PIL import Image

SRC_T = "assets/logo_no_bg.png"
SRC_O = "assets/logo_white_bg.png"

# The cup mark occupies this vertical band; below it sit the two wordmark
# lines ("INDORE CHAI" / "COMPANY"), which are illegible under ~96px.
MARK_BAND = (0, 158, 1024, 686)


def save(im, path, colors=64):
    """Quantise before writing: the artwork is three flat brand colours, so a
    palette costs nothing visually and cuts PNG weight by ~10x."""
    if colors:
        im = im.quantize(colors=colors, method=Image.FASTOCTREE)
    im.save(path, optimize=True)
    kb = os.path.getsize(path) / 1024
    print(f"  {path:44s} {im.size[0]}x{im.size[1]}  {kb:6.1f} KB")


def pad_square(im, scale=1.0, bg=None):
    """Centre `im` on a square canvas, occupying `scale` of the side."""
    side = round(max(im.size) / scale)
    mode, fill = ("RGB", bg) if bg else ("RGBA", (0, 0, 0, 0))
    sq = Image.new(mode, (side, side), fill)
    sq.paste(im, ((side - im.width) // 2, (side - im.height) // 2),
             im if im.mode == "RGBA" else None)
    return sq


transparent = Image.open(SRC_T).convert("RGBA")
opaque = Image.open(SRC_O).convert("RGB")
CREAM = opaque.getpixel((0, 0))

print("transparent variants (from logo_no_bg.png):")

# Full lockup: trim the ~22% dead padding, keep a 4% breathing margin.
box = transparent.getbbox()
full = transparent.crop(box)
m = round(max(full.size) * 0.04)
canvas = Image.new("RGBA", (full.width + 2 * m, full.height + 2 * m), (0, 0, 0, 0))
canvas.paste(full, (m, m))
W = 480
save(canvas.resize((W, round(canvas.height * W / canvas.width)), Image.LANCZOS),
     "assets/logo_full.png")

# Mark only, squared, for app bars and other small placements.
mark_box = transparent.crop(MARK_BAND).getbbox()
MARK_ABS = (mark_box[0], MARK_BAND[1] + mark_box[1],
            mark_box[2], MARK_BAND[1] + mark_box[3])
mark_t = transparent.crop(MARK_ABS)
save(pad_square(mark_t, 0.92).resize((256, 256), Image.LANCZOS),
     "assets/logo_mark.png")

print("opaque variants (from logo_white_bg.png):")
mark_o = opaque.crop(MARK_ABS)

# Favicon + standard PWA icons: mark filling most of a cream tile.
save(pad_square(mark_o, 0.86, CREAM).resize((64, 64), Image.LANCZOS), "web/favicon.png")
for size in (192, 512):
    save(pad_square(mark_o, 0.86, CREAM).resize((size, size), Image.LANCZOS),
         f"web/icons/Icon-{size}.png")

# Maskable icons: content must survive an aggressive circular crop, so the
# mark sits inside the central 60% safe zone.
for size in (192, 512):
    save(pad_square(mark_o, 0.60, CREAM).resize((size, size), Image.LANCZOS),
         f"web/icons/Icon-maskable-{size}.png")

# Document header logo for the PDF invoice.
save(pad_square(mark_o, 0.90, CREAM).resize((160, 160), Image.LANCZOS),
     "assets/logo_doc.png")

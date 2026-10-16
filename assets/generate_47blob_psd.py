import os
import itertools
import numpy as np
from PIL import Image, ImageDraw, ImageFont
import pytoshop
from pytoshop import layers
from pytoshop.enums import ColorMode, Compression

# Industry-standard 47-tile blob / 3x3 minimal terrain template.
# Each grid cell is exactly 655 x 655 pixels.
CELL = 655
COLS = ROWS = 7
W = H = CELL * COLS
OUT_DIR = "D:/TapTapspotlight/assets"
PSD_PATH = os.path.join(OUT_DIR, "tilemap_47blob_655px_template.psd")
PREVIEW_PATH = os.path.join(OUT_DIR, "tilemap_47blob_655px_template_preview.png")
FONT = "C:/Windows/Fonts/msyh.ttc"

os.makedirs(OUT_DIR, exist_ok=True)

# A 47-blob tile has 4 cardinal-neighbour bits plus diagonal bits that are only
# valid when both adjoining cardinal neighbours exist. This yields exactly 47 states.
# bit order: N, E, S, W, NE, SE, SW, NW
states = []
for n, e, s, w in itertools.product((0, 1), repeat=4):
    allowed_diags = [("NE", n and e), ("SE", s and e), ("SW", s and w), ("NW", n and w)]
    possible = [name for name, allowed in allowed_diags if allowed]
    for diagonal_bits in itertools.product((0, 1), repeat=len(possible)):
        diag = {"NE": 0, "SE": 0, "SW": 0, "NW": 0}
        diag.update(dict(zip(possible, diagonal_bits)))
        states.append({"N": n, "E": e, "S": s, "W": w, **diag})

assert len(states) == 47, len(states)

# Stable, documented layout: cardinal mask then valid diagonal variants.
# This is a proper 47-blob topology; its exact physical cell order is defined by
# the labels in the PSD, not assumed by Godot.

font_title = ImageFont.truetype(FONT, 24)
font_bits = ImageFont.truetype(FONT, 18)
font_small = ImageFont.truetype(FONT, 15)
font_header = ImageFont.truetype(FONT, 24)

# Bottom guide: every slot contains a terrain silhouette and its exact neighbour mask.
guide = Image.new("RGBA", (W, H), (0, 0, 0, 0))
g = ImageDraw.Draw(guide)

# Use a semantic legend in a small corner of each cell rather than a global UI
# because this PSD is used directly as a tracing template on iPad.
for i, st in enumerate(states):
    r, c = divmod(i, COLS)
    ox, oy = c * CELL, r * CELL
    x0, y0, x1, y1 = ox, oy, ox + CELL, oy + CELL

    # Working boundary and faint opaque grid so cell limits remain visible.
    g.rectangle((x0, y0, x1 - 1, y1 - 1), fill=(32, 40, 50, 215), outline=(65, 205, 255, 255), width=4)

    # Terrain fill: center field. Exposed sides are deliberately gold and connected
    # sides cyan: artist traces the gold treatment only on exposed boundaries.
    pad = 86
    g.rounded_rectangle((x0 + pad, y0 + pad, x1 - pad, y1 - pad), radius=64, fill=(103, 114, 128, 235))

    # Strokes are an art-direction guide, not part of final output.
    exposed = {"N": not st["N"], "E": not st["E"], "S": not st["S"], "W": not st["W"]}
    side_lines = {
        "N": (x0 + pad, y0 + pad, x1 - pad, y0 + pad),
        "E": (x1 - pad, y0 + pad, x1 - pad, y1 - pad),
        "S": (x0 + pad, y1 - pad, x1 - pad, y1 - pad),
        "W": (x0 + pad, y0 + pad, x0 + pad, y1 - pad),
    }
    for side, line in side_lines.items():
        g.line(line, fill=(255, 183, 55, 255) if exposed[side] else (45, 218, 235, 255), width=18)

    # Diagonal markers: red = concave inner-corner treatment needed (both
    # cardinals exist but diagonal cell is absent); cyan = connected diagonal.
    diag_pos = {
        "NE": (x1 - pad - 38, y0 + pad + 38),
        "SE": (x1 - pad - 38, y1 - pad - 38),
        "SW": (x0 + pad + 38, y1 - pad - 38),
        "NW": (x0 + pad + 38, y0 + pad + 38),
    }
    requirements = {"NE": st["N"] and st["E"], "SE": st["S"] and st["E"], "SW": st["S"] and st["W"], "NW": st["N"] and st["W"]}
    for key, needed in requirements.items():
        if needed:
            cx, cy = diag_pos[key]
            col = (42, 210, 232, 255) if st[key] else (255, 85, 88, 255)
            g.ellipse((cx - 20, cy - 20, cx + 20, cy + 20), fill=col)

    # Cell index plus machine-readable neighbour spec.
    g.rectangle((x0 + 18, y0 + 18, x0 + 235, y0 + 86), fill=(12, 17, 23, 225))
    g.text((x0 + 32, y0 + 31), f"#{i + 1:02d} / 47", font=font_title, fill=(255, 255, 255, 255))
    bits = f"N{st['N']} E{st['E']} S{st['S']} W{st['W']}"
    corners = f"NE{st['NE']} SE{st['SE']} SW{st['SW']} NW{st['NW']}"
    g.text((x0 + 20, y1 - 66), bits, font=font_bits, fill=(255, 255, 255, 255))
    g.text((x0 + 20, y1 - 40), corners, font=font_small, fill=(210, 220, 230, 255))

# Slots 48 and 49 are intentionally blank: the 7x7 canvas contains precisely 47 states.
for i in (47, 48):
    r, c = divmod(i, COLS)
    ox, oy = c * CELL, r * CELL
    g.rectangle((ox, oy, ox + CELL - 1, oy + CELL - 1), fill=(18, 21, 26, 220), outline=(80, 88, 98, 255), width=4)
    g.text((ox + 40, oy + 40), "留空", font=font_title, fill=(150, 158, 166, 255))
    g.text((ox + 40, oy + 75), "47-Blob 无此组合", font=font_small, fill=(150, 158, 166, 255))

# Transparent drawing layer. A full-canvas blank layer lets Procreate users draw on top;
# the guide layer remains below and is hidden before PNG export.
paint = Image.new("RGBA", (W, H), (0, 0, 0, 0))

psd = pytoshop.core.PsdFile(num_channels=3, height=H, width=W, depth=8, color_mode=ColorMode.rgb)

def add_layer(pil_img, name, visible=True):
    data = np.array(pil_img)
    record = layers.LayerRecord(name=name, top=0, bottom=H, left=0, right=W, visible=visible, opacity=255)
    record.channels = {
        0: layers.ChannelImageData(image=data[:, :, 0], compression=Compression.zip),
        1: layers.ChannelImageData(image=data[:, :, 1], compression=Compression.zip),
        2: layers.ChannelImageData(image=data[:, :, 2], compression=Compression.zip),
        -1: layers.ChannelImageData(image=data[:, :, 3], compression=Compression.zip),
    }
    psd.layer_and_mask_info.layer_info.layer_records.append(record)

add_layer(guide, "【指引】47-Blob 拓扑模板（画完隐藏）")
add_layer(paint, "★【美术绘制层】仅在此层作画")

with open(PSD_PATH, "wb") as f:
    psd.write(f)

# Lightweight preview; use nearest neighbour so individual cell structure remains inspectable.
preview = guide.resize((1400, 1400), Image.Resampling.LANCZOS)
preview.save(PREVIEW_PATH)

print(f"GENERATED: {PSD_PATH}")
print(f"CANVAS: {W}x{H}; CELL: {CELL}x{CELL}; STATES: {len(states)}; BLANK: 2")

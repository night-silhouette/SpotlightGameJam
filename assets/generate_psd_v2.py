import os
import numpy as np
from PIL import Image, ImageDraw, ImageFont
import pytoshop
from pytoshop import layers
from pytoshop.enums import ColorMode, Compression

W, H = 655, 655
font_path = "C:/Windows/Fonts/msyh.ttc"

bg_img = Image.new("RGBA", (W, H), (26, 28, 32, 255))

guide_img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
draw_guide = ImageDraw.Draw(guide_img)

demo_img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
draw_demo = ImageDraw.Draw(demo_img)

font_label = ImageFont.truetype(font_path, 13)
font_sub = ImageFont.truetype(font_path, 10)
font_inner = ImageFont.truetype(font_path, 11)

# 4x4 Grid layout:
# 655 px: 3px outer margin, cells:
# col 0: 3..164 (161)
# col 1: 165..326 (161)
# col 2: 327..488 (161)
# col 3: 489..650 (161)
coords = [3, 165, 327, 489, 651]

# 16 cells full 47-blob core 16 tiles (Wang / 3x3 autotile complete set):
# Row 0: Top-Left outer, Top edge, Top-Right outer, Top-Left inner corner
# Row 1: Left wall, Center core, Right wall, Top-Right inner corner
# Row 2: Bottom-Left outer, Bottom edge, Bottom-Right outer, Bottom-Left inner corner
# Row 3: Single column/vertical, Single row/horizontal, Single point island, Bottom-Right inner corner

cells = [
    # (r, c, title, desc, category)
    # Row 0
    (0, 0, "左上外凸角", "Top-Left Outer", "outer"),
    (0, 1, "平地上边缘", "Top Surface", "edge"),
    (0, 2, "右上外凸角", "Top-Right Outer", "outer"),
    (0, 3, "★左上内凹角", "Inner Corner TL", "inner"),
    
    # Row 1
    (1, 0, "左立墙", "Left Wall", "edge"),
    (1, 1, "实心内部", "Full Solid", "solid"),
    (1, 2, "右立墙", "Right Wall", "edge"),
    (1, 3, "★右上内凹角", "Inner Corner TR", "inner"),
    
    # Row 2
    (2, 0, "左下外凸角", "Bottom-Left Outer", "outer"),
    (2, 1, "悬挂底面", "Bottom Surface", "edge"),
    (2, 2, "右下外凸角", "Bottom-Right Outer", "outer"),
    (2, 3, "★左下内凹角", "Inner Corner BL", "inner"),
    
    # Row 3
    (3, 0, "垂直独柱", "Single Vertical", "single"),
    (3, 1, "水平独梁", "Single Horizontal", "single"),
    (3, 2, "独立悬空岛", "Single Island", "single"),
    (3, 3, "★右下内凹角", "Inner Corner BR", "inner"),
]

# Draw guide background & borders
for r in range(4):
    for c in range(4):
        x1, y1 = coords[c], coords[r]
        x2, y2 = coords[c+1], coords[r+1]
        
        # Color coding: Inner corners highlighted in distinct orange/amber border
        is_inner = (c == 3)
        if is_inner:
            fill_c = (55, 45, 35, 180)
            out_c = (255, 170, 40, 240)
        else:
            fill_c = (38, 44, 54, 160)
            out_c = (0, 190, 240, 200)
            
        draw_guide.rectangle([x1, y1, x2, y2], fill=fill_c, outline=out_c, width=2)

for r, c, title, desc, cat in cells:
    x1, y1 = coords[c], coords[r]
    x2, y2 = coords[c+1], coords[r+1]
    
    is_inner = (cat == "inner")
    text_color = (255, 215, 120, 255) if is_inner else (255, 255, 255, 255)
    sub_color = (255, 180, 100, 220) if is_inner else (150, 195, 235, 220)
    
    draw_guide.text((x1 + 8, y1 + 8), title, font=font_label, fill=text_color)
    draw_guide.text((x1 + 8, y1 + 26), desc, font=font_sub, fill=sub_color)

# Demo colors
soil_c = (120, 80, 50, 255)
soil_dark = (95, 60, 38, 255)
grass_c = (65, 165, 65, 255)
grass_hl = (115, 210, 95, 255)
margin_tile = 12

def tile_box(c, r):
    return coords[c], coords[r], coords[c+1], coords[r+1]

# 1. Solid center (1, 1)
x1, y1, x2, y2 = tile_box(1, 1)
draw_demo.rectangle([x1, y1, x2, y2], fill=soil_c)
for sx in range(x1 + 20, x2 - 20, 35):
    for sy in range(y1 + 20, y2 - 20, 35):
        draw_demo.rectangle([sx, sy, sx + 12, sy + 12], fill=soil_dark)

# 2. Top Edge (1, 0)
x1, y1, x2, y2 = tile_box(1, 0)
draw_demo.rectangle([x1, y1 + 25, x2, y2], fill=soil_c)
draw_demo.rectangle([x1, y1 + 10, x2, y1 + 25], fill=grass_c)
draw_demo.rectangle([x1, y1 + 6, x2, y1 + 14], fill=grass_hl)

# 3. Outer TL (0, 0)
x1, y1, x2, y2 = tile_box(0, 0)
draw_demo.rectangle([x1 + 25, y1 + 25, x2, y2], fill=soil_c)
draw_demo.pieslice([x1 + 10, y1 + 10, x1 + 55, y1 + 55], 180, 270, fill=grass_hl)
draw_demo.rectangle([x1 + 30, y1 + 10, x2, y1 + 25], fill=grass_c)
draw_demo.rectangle([x1 + 10, y1 + 30, x1 + 25, y2], fill=soil_c)

# 4. Outer TR (2, 0)
x1, y1, x2, y2 = tile_box(2, 0)
draw_demo.rectangle([x1, y1 + 25, x2 - 25, y2], fill=soil_c)
draw_demo.pieslice([x2 - 55, y1 + 10, x2 - 10, y1 + 55], 270, 360, fill=grass_hl)
draw_demo.rectangle([x1, y1 + 10, x2 - 30, y1 + 25], fill=grass_c)
draw_demo.rectangle([x2 - 25, y1 + 30, x2 - 10, y2], fill=soil_c)

# 5. Left Wall (0, 1)
x1, y1, x2, y2 = tile_box(0, 1)
draw_demo.rectangle([x1 + 15, y1, x2, y2], fill=soil_c)
draw_demo.rectangle([x1 + 8, y1, x1 + 15, y2], fill=soil_dark)

# 6. Right Wall (2, 1)
x1, y1, x2, y2 = tile_box(2, 1)
draw_demo.rectangle([x1, y1, x2 - 15, y2], fill=soil_c)
draw_demo.rectangle([x2 - 15, y1, x2 - 8, y2], fill=soil_dark)

# 7. Bottom Edge (1, 2)
x1, y1, x2, y2 = tile_box(1, 2)
draw_demo.rectangle([x1, y1, x2, y2 - 15], fill=soil_c)

# 8. Outer BL (0, 2)
x1, y1, x2, y2 = tile_box(0, 2)
draw_demo.rectangle([x1 + 20, y1, x2, y2 - 20], fill=soil_c)
draw_demo.pieslice([x1 + 10, y2 - 50, x1 + 50, y2 - 10], 90, 180, fill=soil_c)

# 9. Outer BR (2, 2)
x1, y1, x2, y2 = tile_box(2, 2)
draw_demo.rectangle([x1, y1, x2 - 20, y2 - 20], fill=soil_c)
draw_demo.pieslice([x2 - 50, y2 - 50, x2 - 10, y2 - 10], 0, 90, fill=soil_c)

# --- 4 INNER CORNERS (Column 3) ---
# Inner corners are FULL solid blocks except for ONE empty quarter corner

# Inner TL (3, 0): Solid everywhere EXCEPT top-left corner is empty space/sky
x1, y1, x2, y2 = tile_box(3, 0)
draw_demo.rectangle([x1, y1, x2, y2], fill=soil_c)
# carve out top-left empty corner (air)
draw_demo.rectangle([x1, y1, x1 + 70, y1 + 70], fill=(26, 28, 32, 255))
# draw ground grass on the bottom of the carved hole & left wall
draw_demo.rectangle([x1 + 70, y1 + 15, x2, y1 + 30], fill=grass_c)
draw_demo.rectangle([x1 + 70, y1 + 10, x2, y1 + 18], fill=grass_hl)
draw_demo.rectangle([x1 + 15, y1 + 70, x2, y1 + 85], fill=grass_c)
draw_demo.rectangle([x1 + 10, y1 + 70, x2, y1 + 76], fill=grass_hl)
draw_demo.rectangle([x1 + 70, y1, x1 + 78, y1 + 70], fill=soil_dark)

# Inner TR (3, 1): Solid everywhere EXCEPT top-right corner is empty space
x1, y1, x2, y2 = tile_box(3, 1)
draw_demo.rectangle([x1, y1, x2, y2], fill=soil_c)
draw_demo.rectangle([x2 - 70, y1, x2, y1 + 70], fill=(26, 28, 32, 255))
draw_demo.rectangle([x1, y1 + 15, x2 - 70, y1 + 30], fill=grass_c)
draw_demo.rectangle([x1, y1 + 10, x2 - 70, y1 + 18], fill=grass_hl)
draw_demo.rectangle([x1, y1 + 70, x2 - 15, y1 + 85], fill=grass_c)
draw_demo.rectangle([x1, y1 + 70, x2 - 10, y1 + 76], fill=grass_hl)
draw_demo.rectangle([x2 - 78, y1, x2 - 70, y1 + 70], fill=soil_dark)

# Inner BL (3, 2): Solid everywhere EXCEPT bottom-left corner is empty space
x1, y1, x2, y2 = tile_box(3, 2)
draw_demo.rectangle([x1, y1, x2, y2], fill=soil_c)
draw_demo.rectangle([x1, y2 - 70, x1 + 70, y2], fill=(26, 28, 32, 255))
draw_demo.rectangle([x1 + 15, y1, x2, y2 - 70], fill=soil_c)
draw_demo.rectangle([x1 + 70, y2 - 70, x1 + 78, y2], fill=soil_dark)

# Inner BR (3, 3): Solid everywhere EXCEPT bottom-right corner is empty space
x1, y1, x2, y2 = tile_box(3, 3)
draw_demo.rectangle([x1, y1, x2, y2], fill=soil_c)
draw_demo.rectangle([x2 - 70, y2 - 70, x2, y2], fill=(26, 28, 32, 255))
draw_demo.rectangle([x1, y1, x2 - 15, y2 - 70], fill=soil_c)
draw_demo.rectangle([x2 - 78, y2 - 70, x2 - 70, y2], fill=soil_dark)

# --- SINGLES (Row 3, Col 0, 1, 2) ---
# Single Column (0, 3)
x1, y1, x2, y2 = tile_box(0, 3)
cx = (x1 + x2) // 2
draw_demo.rectangle([cx - 25, y1 + 15, cx + 25, y2 - 15], fill=soil_c)
draw_demo.rectangle([cx - 25, y1 + 10, cx + 25, y1 + 22], fill=grass_c)

# Single Horizontal (1, 3)
x1, y1, x2, y2 = tile_box(1, 3)
cy = (y1 + y2) // 2
draw_demo.rectangle([x1 + 10, cy - 20, x2 - 10, cy + 20], fill=soil_c)
draw_demo.rectangle([x1 + 10, cy - 25, x2 - 10, cy - 15], fill=grass_c)

# Single Island (2, 3)
x1, y1, x2, y2 = tile_box(2, 3)
cx, cy = (x1 + x2) // 2, (y1 + y2) // 2
draw_demo.ellipse([cx - 35, cy - 30, cx + 35, cy + 30], fill=soil_c)
draw_demo.pieslice([cx - 35, cy - 30, cx + 35, cy + 30], 180, 360, fill=grass_c)

empty_img = Image.new("RGBA", (W, H), (0, 0, 0, 0))

# Write PSD
psd = pytoshop.core.PsdFile(num_channels=3, height=H, width=W, depth=8, color_mode=ColorMode.rgb)

def add_layer(psd_obj, pil_img, name, visible=True):
    arr = np.array(pil_img)
    rec = layers.LayerRecord(
        name=name,
        top=0, bottom=H, left=0, right=W,
        visible=visible,
        opacity=255
    )
    rec.channels = {
        0: layers.ChannelImageData(image=arr[:, :, 0], compression=Compression.raw),
        1: layers.ChannelImageData(image=arr[:, :, 1], compression=Compression.raw),
        2: layers.ChannelImageData(image=arr[:, :, 2], compression=Compression.raw),
        -1: layers.ChannelImageData(image=arr[:, :, 3], compression=Compression.raw)
    }
    psd_obj.layer_and_mask_info.layer_info.layer_records.append(rec)

add_layer(psd, bg_img, "【底衬】暗色背景(可隐藏)")
add_layer(psd, demo_img, "【参考范例】16格全地形包含内角(可隐藏)", visible=False)
add_layer(psd, guide_img, "【网格指引】4x4规范网格(含4个内凹角标注)")
add_layer(psd, empty_img, "★【美术在此图层绘制】")

out_dir = "D:/TapTapspotlight/assets"
os.makedirs(out_dir, exist_ok=True)
psd_path = os.path.join(out_dir, "tilemap_655x655_template.psd")
with open(psd_path, "wb") as f:
    psd.write(f)

comp = Image.alpha_composite(bg_img, guide_img)
preview_guide_path = os.path.join(out_dir, "tilemap_655x655_guide_preview.png")
comp.save(preview_guide_path)

demo_comp = Image.alpha_composite(bg_img, demo_img)
demo_comp = Image.alpha_composite(demo_comp, guide_img)
preview_demo_path = os.path.join(out_dir, "tilemap_655x655_demo_preview.png")
demo_comp.save(preview_demo_path)

print("FULL_4X4_WITH_INNER_CORNERS_COMPLETE")

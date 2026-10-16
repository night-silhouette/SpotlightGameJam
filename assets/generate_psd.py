import os
import numpy as np
from PIL import Image, ImageDraw, ImageFont
import pytoshop
from pytoshop import layers
from pytoshop.enums import ColorMode, Compression

W, H = 655, 655
font_path = "C:/Windows/Fonts/msyh.ttc"

bg_img = Image.new("RGBA", (W, H), (28, 30, 34, 255))

guide_img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
draw_guide = ImageDraw.Draw(guide_img)

demo_img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
draw_demo = ImageDraw.Draw(demo_img)

font_label = ImageFont.truetype(font_path, 18)
font_sub = ImageFont.truetype(font_path, 13)

# 3x3 layout: 5px outer margin, cells 215x215
grid_xs = [5, 220, 435, 650]
grid_ys = [5, 220, 435, 650]

grid_info = [
    (0, 0, "左上外角", "Top-Left (角)"),
    (0, 1, "平地上边缘", "Top Edge (地表)"),
    (0, 2, "右上外角", "Top-Right (角)"),
    (1, 0, "左侧立墙", "Left Wall (立面)"),
    (1, 1, "内部实心填充", "Center (实体内部)"),
    (1, 2, "右侧立墙", "Right Wall (立面)"),
    (2, 0, "左下外角", "Bottom-Left (底角)"),
    (2, 1, "下边缘底面", "Bottom Edge (底面)"),
    (2, 2, "右下外角", "Bottom-Right (底角)"),
]

for r in range(3):
    for c in range(3):
        x1, y1 = grid_xs[c], grid_ys[r]
        x2, y2 = grid_xs[c+1], grid_ys[r+1]
        draw_guide.rectangle([x1, y1, x2, y2], fill=(40, 45, 55, 160), outline=(0, 200, 255, 220), width=2)

for r, c, title, desc in grid_info:
    x1, y1 = grid_xs[c], grid_ys[r]
    x2, y2 = grid_xs[c+1], grid_ys[r+1]
    draw_guide.text((x1 + 10, y1 + 10), title, font=font_label, fill=(255, 255, 255, 255))
    draw_guide.text((x1 + 10, y1 + 34), desc, font=font_sub, fill=(160, 200, 240, 220))

# Ground demo colors
soil_color = (120, 80, 50, 255)
grass_color = (65, 165, 65, 255)
highlight_grass = (115, 210, 95, 255)
inner_soil = (95, 60, 38, 255)

# 1,1 center
draw_demo.rectangle([grid_xs[1], grid_ys[1], grid_xs[2], grid_ys[2]], fill=soil_color)
for sx in range(grid_xs[1] + 25, grid_xs[2] - 25, 45):
    for sy in range(grid_ys[1] + 25, grid_ys[2] - 25, 45):
        draw_demo.rectangle([sx, sy, sx + 16, sy + 16], fill=inner_soil)

# 0,1 top edge
draw_demo.rectangle([grid_xs[1], grid_ys[0] + 35, grid_xs[2], grid_ys[1]], fill=soil_color)
draw_demo.rectangle([grid_xs[1], grid_ys[0] + 15, grid_xs[2], grid_ys[0] + 35], fill=grass_color)
draw_demo.rectangle([grid_xs[1], grid_ys[0] + 10, grid_xs[2], grid_ys[0] + 20], fill=highlight_grass)

# 0,0 top-left
draw_demo.rectangle([grid_xs[0] + 35, grid_ys[0] + 35, grid_xs[1], grid_ys[1]], fill=soil_color)
draw_demo.pieslice([grid_xs[0] + 10, grid_ys[0] + 10, grid_xs[0] + 70, grid_ys[0] + 70], 180, 270, fill=highlight_grass)
draw_demo.rectangle([grid_xs[0] + 40, grid_ys[0] + 10, grid_xs[1], grid_ys[0] + 35], fill=grass_color)
draw_demo.rectangle([grid_xs[0] + 10, grid_ys[0] + 40, grid_xs[0] + 35, grid_ys[1]], fill=soil_color)

# 0,2 top-right
draw_demo.rectangle([grid_xs[2], grid_ys[0] + 35, grid_xs[3] - 35, grid_ys[1]], fill=soil_color)
draw_demo.pieslice([grid_xs[3] - 70, grid_ys[0] + 10, grid_xs[3] - 10, grid_ys[0] + 70], 270, 360, fill=highlight_grass)
draw_demo.rectangle([grid_xs[2], grid_ys[0] + 10, grid_xs[3] - 40, grid_ys[0] + 35], fill=grass_color)
draw_demo.rectangle([grid_xs[3] - 35, grid_ys[0] + 40, grid_xs[3] - 10, grid_ys[1]], fill=soil_color)

# 1,0 left wall
draw_demo.rectangle([grid_xs[0] + 20, grid_ys[1], grid_xs[1], grid_ys[2]], fill=soil_color)
draw_demo.rectangle([grid_xs[0] + 10, grid_ys[1], grid_xs[0] + 20, grid_ys[2]], fill=(85, 52, 32, 255))

# 1,2 right wall
draw_demo.rectangle([grid_xs[2], grid_ys[1], grid_xs[3] - 20, grid_ys[2]], fill=soil_color)
draw_demo.rectangle([grid_xs[3] - 20, grid_ys[1], grid_xs[3] - 10, grid_ys[2]], fill=(85, 52, 32, 255))

# 2,0 bottom-left
draw_demo.rectangle([grid_xs[0] + 30, grid_ys[2], grid_xs[1], grid_ys[3] - 30], fill=soil_color)
draw_demo.pieslice([grid_xs[0] + 10, grid_ys[3] - 70, grid_xs[0] + 70, grid_ys[3] - 10], 90, 180, fill=soil_color)

# 2,1 bottom edge
draw_demo.rectangle([grid_xs[1], grid_ys[2], grid_xs[2], grid_ys[3] - 20], fill=soil_color)

# 2,2 bottom-right
draw_demo.rectangle([grid_xs[2], grid_ys[2], grid_xs[3] - 30, grid_ys[3] - 30], fill=soil_color)
draw_demo.pieslice([grid_xs[3] - 70, grid_ys[3] - 70, grid_xs[3] - 10, grid_ys[3] - 10], 0, 90, fill=soil_color)

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
add_layer(psd, demo_img, "【参考范例】地块填充示范(可隐藏)", visible=False)
add_layer(psd, guide_img, "【网格指引】3x3规范网格与标注")
add_layer(psd, empty_img, "★【美术在此图层绘制】")

out_dir = "D:/TapTapspotlight/assets"
os.makedirs(out_dir, exist_ok=True)
psd_path = os.path.join(out_dir, "tilemap_655x655_template.psd")
with open(psd_path, "wb") as f:
    psd.write(f)

# Save composite previews
comp = Image.alpha_composite(bg_img, guide_img)
preview_guide_path = os.path.join(out_dir, "tilemap_655x655_guide_preview.png")
comp.save(preview_guide_path)

demo_comp = Image.alpha_composite(bg_img, demo_img)
demo_comp = Image.alpha_composite(demo_comp, guide_img)
preview_demo_path = os.path.join(out_dir, "tilemap_655x655_demo_preview.png")
demo_comp.save(preview_demo_path)

print("GENERATION_COMPLETE")

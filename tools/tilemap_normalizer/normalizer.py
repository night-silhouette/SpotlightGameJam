"""
Tilemap Normalizer (贴图网格规范化工具)
将美术手绘/不规则排版的长条、阶梯、砖块贴图，自动重排为严格满足 Godot TileSet 网格的规范贴图。
"""
import sys
import os
import argparse
import numpy as np
from PIL import Image

def analyze_and_extract_rows(im, min_gap=30, alpha_thresh=10):
    """提取纵向分离的行区域"""
    w, h = im.size
    alpha = np.array(im.split()[-1])
    row_has_content = (alpha > alpha_thresh).any(axis=1)

    row_slices = []
    in_block = False
    start = 0
    for y in range(h):
        if row_has_content[y] and not in_block:
            in_block = True
            start = y
        elif not row_has_content[y] and in_block:
            in_block = False
            if y - start > 20:
                row_slices.append((start, y))
    if in_block and h - start > 20:
        row_slices.append((start, h))

    elements = []
    for (r0, r1) in row_slices:
        sub_alpha = alpha[r0:r1, :]
        col_has = (sub_alpha > alpha_thresh).any(axis=0)
        if not col_has.any():
            continue
        c0, c1 = np.where(col_has)[0][[0, -1]]
        elements.append({
            'box': (int(c0), int(r0), int(c1 + 1), int(r1)),
            'w': int(c1 + 1 - c0),
            'h': int(r1 - r0)
        })
    return elements

def determine_alignment(elem, tile_size, row_index, total_rows):
    """
    智能判断对齐方式：
    - 高度接近单格 (~0.6 - 0.85 tile_size):
        - 如果处于前半部分行（地面）：bottom（下半面，留出走道）
        - 如果处于后半部分行（天花板）：top（上半面，实心顶下留空）
    - 特殊多格结构（地基、立柱、楼梯）：bottom（底部对齐基准线）
    """
    h = elem['h']
    if h <= tile_size:
        # 靠近底部的行倾向于是天花板（下砖块）
        if row_index >= total_rows - 2:
            return 'top'
        return 'bottom'
    else:
        return 'bottom'

def normalize_sheet(input_path, output_path=None, tile_size=665):
    if not os.path.isfile(input_path):
        print(f"[错误] 文件不存在: {input_path}")
        return False

    if output_path is None:
        base, ext = os.path.splitext(input_path)
        output_path = f"{base}_grid{tile_size}{ext}"

    print(f"正在载入: {input_path}")
    im = Image.open(input_path).convert("RGBA")
    w, h = im.size
    print(f"原图分辨率: {w} x {h}")

    elements = analyze_and_extract_rows(im)
    print(f"检测到独立元素/行数量: {len(elements)}")

    if not elements:
        print("[警告] 未检测到有效内容，跳过。")
        return False

    # 计算各元素需要的网格规格
    items_to_place = []
    max_cols = 1
    total_grid_rows = 0

    for i, elem in enumerate(elements):
        crop_box = elem['box']
        cropped = im.crop(crop_box)
        ew, eh = elem['w'], elem['h']

        cols_needed = int(np.ceil(ew / tile_size))
        rows_needed = int(np.ceil(eh / tile_size))
        align = determine_alignment(elem, tile_size, i, len(elements))

        max_cols = max(max_cols, cols_needed)
        items_to_place.append({
            'img': cropped,
            'w': ew,
            'h': eh,
            'cols': cols_needed,
            'rows': rows_needed,
            'align': align,
            'start_row': total_grid_rows
        })
        total_grid_rows += rows_needed
        print(f"  行 {i+1}: 尺寸 {ew}x{eh} -> 占用网格 {cols_needed}x{rows_needed}格, 对齐方式: {align}")

    canvas_w = max_cols * tile_size
    canvas_h = total_grid_rows * tile_size
    print(f"\n生成目标画布: {canvas_w} x {canvas_h} px ({max_cols} 列 x {total_grid_rows} 行)")

    out_canvas = Image.new("RGBA", (canvas_w, canvas_h), (0, 0, 0, 0))

    for item in items_to_place:
        r = item['start_row']
        grid_h_total = item['rows'] * tile_size
        
        # 纵向偏移
        if item['align'] == 'bottom':
            y_offset = r * tile_size + (grid_h_total - item['h'])
        elif item['align'] == 'top':
            y_offset = r * tile_size
        else: # center
            y_offset = r * tile_size + (grid_h_total - item['h']) // 2

        x_offset = 0  # 左对齐到网格 0
        out_canvas.paste(item['img'], (x_offset, y_offset), item['img'])

    out_canvas.save(output_path, "PNG")
    print(f"\n[成功] 已保存规范化贴图至:\n-> {output_path}")
    print(f"\nGodot 导入设置提示:")
    print(f"  - Tile Size: {tile_size} x {tile_size}")
    print(f"  - Margins: 0 x 0")
    print(f"  - Separation: 0 x 0")
    return True

def main():
    if len(sys.argv) < 2:
        print("用法:")
        print("  1. 拖拽 PNG 图片到本脚本或 .bat 批处理文件上")
        print("  2. 命令行: python normalizer.py <图片路径> [网格大小, 默认665]")
        input("\n按回车键退出...")
        return

    input_file = sys.argv[1].strip('"\'')
    tile_size = 665
    if len(sys.argv) >= 3:
        try:
            tile_size = int(sys.argv[2])
        except ValueError:
            pass

    normalize_sheet(input_file, tile_size=tile_size)
    if len(sys.argv) <= 2:
        # 如果是拖拽运行，暂停以便查看结果
        print("\n处理完成！")
        input("按任意键关闭窗口...")

if __name__ == '__main__':
    main()

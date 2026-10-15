extends RefCounted
## 将矩形地形合并成连续蓝边黑芯外观；只绘制，不创建碰撞。
const ATLAS: Texture2D = preload("res://Art/New/map2/2_grid665.png")
const CORE := Rect2(1100, 3900, 256, 256)
const TOP := Rect2(461, 2959, 2034, 460)
const BOTTOM := Rect2(461, 4859, 2034, 460)
const LEFT := Rect2(1, 3419, 460, 1440)
const RIGHT := Rect2(2495, 3419, 460, 1440)

## 将同坐标系的矩形合并为互不重叠的水平带，并提取外轮廓，消除内部接缝。
static func Build(rectangles: Array[Rect2]) -> Dictionary:
	var ys: Array[float] = []
	for rect in rectangles:
		if rect.has_area():
			ys.append(rect.position.y)
			ys.append(rect.end.y)
	ys.sort()
	var levels: Array[float] = []
	for y in ys:
		if levels.is_empty() or not is_equal_approx(y, levels.back()):
			levels.append(y)
	var bands: Array = []
	var fills: Array[Rect2] = []
	for index in range(levels.size() - 1):
		var top: float = levels[index]
		var bottom: float = levels[index + 1]
		var middle := (top + bottom) * 0.5
		var spans: Array[Vector2] = []
		for rect in rectangles:
			if rect.position.y <= middle and rect.end.y > middle and rect.has_area():
				spans.append(Vector2(rect.position.x, rect.end.x))
		spans.sort_custom(func(a: Vector2, b: Vector2) -> bool: return a.x < b.x)
		var merged: Array[Vector2] = []
		for span in spans:
			if not merged.is_empty() and span.x <= merged.back().y + 0.01:
				merged[-1].y = maxf(merged.back().y, span.y)
			else:
				merged.append(span)
		bands.append(merged)
		for span in merged:
			fills.append(Rect2(span.x, top, span.y - span.x, bottom - top))
	var edges: Array = []
	for index in range(bands.size()):
		var spans: Array = bands[index]
		var above: Array = bands[index - 1] if index > 0 else []
		var below: Array = bands[index + 1] if index + 1 < bands.size() else []
		for span: Vector2 in spans:
			for exposed in _subtract_spans(span, above):
				edges.append([0, levels[index], exposed])
			for exposed in _subtract_spans(span, below):
				edges.append([1, levels[index + 1], exposed])
			edges.append([2, span.x, Vector2(levels[index], levels[index + 1])])
			edges.append([3, span.y, Vector2(levels[index], levels[index + 1])])
	return {"fills": fills, "edges": edges, "corners": _build_corners(fills, edges)}


static func _build_corners(fills: Array[Rect2], edges: Array) -> Array:
	# 只在外轮廓转向处补原画转角；水平带之间的直线接点不重复加角。
	var vertices: Dictionary = {}
	for edge: Array in edges:
		if int(edge[0]) < 2:
			var span: Vector2 = edge[2]
			vertices[Vector2(span.x, float(edge[1]))] = true
			vertices[Vector2(span.y, float(edge[1]))] = true
	var corners: Array = []
	var directions := [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]
	for point: Vector2 in vertices:
		var mask := 0
		for quadrant in range(4):
			var probe: Vector2 = point + directions[quadrant] * 0.01
			for rect in fills:
				if rect.has_point(probe):
					mask |= 1 << quadrant
					break
		match mask:
			1, 2, 4, 8:
				# 凸角：唯一实心象限使用面向该拐点的完整转角。
				for quadrant in range(4):
					if mask == 1 << quadrant:
						corners.append([point, quadrant])
			7, 11, 13, 14:
				# 凹角：在空象限的对角补 L 形内衔接，让台阶转折也闭合。
				for quadrant in range(4):
					if (mask & (1 << quadrant)) == 0:
						corners.append([point, 3 - quadrant, true])
			6, 9:
				# 两块地形仅在一个点接触时，各自保持完整包边。
				for quadrant in range(4):
					if mask & (1 << quadrant):
						corners.append([point, quadrant])
	return corners

static func _subtract_spans(span: Vector2, cuts: Array) -> Array[Vector2]:
	var remaining: Array[Vector2] = [span]
	for cut: Vector2 in cuts:
		var next: Array[Vector2] = []
		for part in remaining:
			if cut.y <= part.x or cut.x >= part.y:
				next.append(part)
			else:
				if cut.x > part.x:
					next.append(Vector2(part.x, cut.x))
				if cut.y < part.y:
					next.append(Vector2(cut.y, part.y))
		remaining = next
	return remaining

## 在 CanvasItem 的 _draw 中绘制 Build 的结果；border 为边框厚度（像素）。
static func Draw(canvas: CanvasItem, mesh: Dictionary, border: float) -> void:
	for rect: Rect2 in mesh.get("fills", []):
		canvas.draw_texture_rect_region(ATLAS, rect, CORE)
	for edge: Array in mesh.get("edges", []):
		var side: int = edge[0]
		var line: float = edge[1]
		var span: Vector2 = edge[2]
		var rect: Rect2
		var sample: Rect2
		match side:
			0:
				rect = Rect2(span.x, line, span.y - span.x, border)
				sample = TOP
			1:
				rect = Rect2(span.x, line - border, span.y - span.x, border)
				sample = BOTTOM
			2:
				rect = Rect2(line, span.x, border, span.y - span.x)
				sample = LEFT
			3:
				rect = Rect2(line - border, span.x, border, span.y - span.x)
				sample = RIGHT
		_draw_edge(canvas, rect, sample, side < 2, span.x)

	# 直边含黑芯过渡，直接互相覆盖会把另一条蓝边盖黑；最后用整块转角收口。
	var samples := [
		Rect2(2495, 4859, 460, 460), Rect2(1, 4859, 460, 460),
		Rect2(2495, 2959, 460, 460), Rect2(1, 2959, 460, 460),
	]
	for corner: Array in mesh.get("corners", []):
		var point: Vector2 = corner[0]
		var quadrant: int = corner[1]
		var offset := Vector2(-border if quadrant % 2 == 0 else 0.0, -border if quadrant < 2 else 0.0)
		var patch := Rect2(point + offset, Vector2.ONE * border)
		canvas.draw_texture_rect_region(ATLAS, patch, CORE)
		if corner.size() > 2:
			_draw_inner_corner(canvas, point, quadrant, border)
		else:
			canvas.draw_texture_rect_region(ATLAS, patch, samples[quadrant])

static func _draw_inner_corner(canvas: CanvasItem, point: Vector2, quadrant: int, border: float) -> void:
	# 凹角按对角线拼接两条直边，各占一个三角形；黑芯过渡不会互盖或伸出方块。
	var dx := -1.0 if quadrant % 2 == 0 else 1.0
	var dy := -1.0 if quadrant < 2 else 1.0
	var x_end := point + Vector2(dx * border, 0)
	var y_end := point + Vector2(0, dy * border)
	var diagonal := point + Vector2(dx, dy) * border
	var vertical := LEFT if dx > 0 else RIGHT
	var horizontal := TOP if dy > 0 else BOTTOM
	var uv_v := Vector2(vertical.position.x if dx > 0 else vertical.end.x, vertical.position.y + (460.0 if dy < 0 else 0.0))
	var uv_h := Vector2(horizontal.position.x + (460.0 if dx < 0 else 0.0), horizontal.position.y if dy > 0 else horizontal.end.y)
	var texture_size := ATLAS.get_size()
	canvas.draw_polygon(PackedVector2Array([point, x_end, diagonal]), PackedColorArray([Color.WHITE]),
		PackedVector2Array([uv_v / texture_size, (uv_v + Vector2(dx * 460.0, 0)) / texture_size,
			(uv_v + Vector2(dx, dy) * 460.0) / texture_size]), ATLAS)
	canvas.draw_polygon(PackedVector2Array([point, diagonal, y_end]), PackedColorArray([Color.WHITE]),
		PackedVector2Array([uv_h / texture_size, (uv_h + Vector2(dx, dy) * 460.0) / texture_size,
			(uv_h + Vector2(0, dy * 460.0)) / texture_size]), ATLAS)

static func _draw_edge(canvas: CanvasItem, destination: Rect2, sample: Rect2, horizontal: bool, phase: float) -> void:
	# 用边框厚度确定等比缩放，长边重复裁切，避免将砖纹拉成长条。
	var factor := destination.size.y / sample.size.y if horizontal else destination.size.x / sample.size.x
	var length := destination.size.x if horizontal else destination.size.y
	var source_length := sample.size.x if horizontal else sample.size.y
	if factor <= 0.0:
		return
	var offset := 0.0
	var source_offset := fposmod(phase / factor, source_length)
	while offset < length - 0.00001:
		var count := minf(length - offset, (source_length - source_offset) * factor)
		var target := destination
		var region := sample
		if horizontal:
			target.position.x += offset
			target.size.x = count
			region.position.x += source_offset
			region.size.x = count / factor
		else:
			target.position.y += offset
			target.size.y = count
			region.position.y += source_offset
			region.size.y = count / factor
		canvas.draw_texture_rect_region(ATLAS, target, region)
		offset += count
		source_offset = 0.0



extends Control

const FRAME_SKIN = preload("res://Code/Entities/Setting/SettingsSkin.gd")
# 两张裁图共享顶部 23px 花纹与底部 20px 毛边，描边围绕墨面而非透明画布。
const ART_TOP := 23.0
const ART_BOTTOM := 20.0

@onready var _background: TextureRect = get_parent()
var _image: Image

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_image = _background.texture.get_image()
	resized.connect(queue_redraw)
	queue_redraw()

func _draw() -> void:
	if _image == null or size.x <= 0.0 or size.y <= 0.0:
		return
	var art_size := Vector2(_image.get_size())
	var factor := minf(size.x / art_size.x, size.y / art_size.y)
	var origin := (size - art_size * factor) * 0.5
	var body := Rect2(origin + Vector2(0.0, ART_TOP) * factor, Vector2(art_size.x, art_size.y - ART_TOP - ART_BOTTOM) * factor)
	var width: float = ExportSettings.setting_panel_edge_width
	for inset in [5.0, 11.0]:
		var bounds := body.grow(-inset)
		if bounds.size.x <= 0.0 or bounds.size.y <= 0.0:
			continue
		var corners := [bounds.position, Vector2(bounds.end.x, bounds.position.y), bounds.end, Vector2(bounds.position.x, bounds.end.y), bounds.position]
		var ink := Color(FRAME_SKIN.PAPER, 0.8 if inset == 5.0 else 0.45)
		var outline := PackedVector2Array()
		for edge in range(4):
			var start: Vector2 = corners[edge]
			var finish: Vector2 = corners[edge + 1]
			var normal := (finish - start).normalized().orthogonal()
			var steps := maxi(32, ceili(start.distance_to(finish) / 2.0))
			for step in range(steps + 1):
				var t := float(step) / steps
				var point := start.lerp(finish, t)
				point += normal * (sin(t * 39.0 + edge * 2.1 + inset) * 0.8 + sin(t * 83.0) * 0.25)
				if _is_ink_surface((point - origin) / factor, (width * 0.5 + 1.0) / factor):
					outline.append(point)
				else:
					if outline.size() > 1:
						draw_polyline(outline, ink, width, true)
					outline.clear()
		if outline.size() > 1:
			draw_polyline(outline, ink, width, true)

func _is_ink_surface(point: Vector2, clearance: float) -> bool:
	# 透明镂空处断笔，不给头像窗口或花纹铺色。
	for offset in [Vector2.ZERO, Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
		var pixel := Vector2i(point + offset * clearance)
		if pixel.x < 0 or pixel.y < 0 or pixel.x >= _image.get_width() or pixel.y >= _image.get_height():
			return false
		if _image.get_pixelv(pixel).a < 0.95:
			return false
	return true

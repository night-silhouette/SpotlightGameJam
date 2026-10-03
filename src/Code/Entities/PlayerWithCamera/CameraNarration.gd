extends Control
## 演出字幕：按字渐显；纵排从右到左换列，横排自动换行。

var message: String = ""
var vertical: bool = false
var reveal_time: float = -1.0


func _process(delta: float) -> void:
	if reveal_time >= 0.0:
		reveal_time += delta
		queue_redraw()
		if reveal_time > message.length() * ExportSettings.camera_text_interval + ExportSettings.camera_text_fade:
			set_process(false)


## 设置字幕内容及排版方向；空字符串清除字幕，不解析 BBCode。
func ShowText(value: String, is_vertical: bool) -> void:
	message = value
	vertical = is_vertical
	reveal_time = 0.0 if not value.is_empty() else -1.0
	set_process(not value.is_empty())
	queue_redraw()


func _draw() -> void:
	var font: Font = ThemeDB.fallback_font
	var font_size: int = ExportSettings.camera_text_font_size
	var spacing: float = font_size * 1.5
	var cursor := Vector2(size.x - spacing, spacing) if vertical else Vector2(0, spacing)
	for index in message.length():
		var character: String = message[index]
		if character == "\n":
			if vertical:
				cursor = Vector2(cursor.x - spacing, spacing)
			else:
				cursor = Vector2(0, cursor.y + spacing)
			continue
		var opacity: float = clampf((reveal_time - index * ExportSettings.camera_text_interval) / maxf(0.01, ExportSettings.camera_text_fade), 0, 1)
		var width: float = font.get_string_size(character, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		if not vertical and cursor.x + width > size.x:
			cursor = Vector2(0, cursor.y + spacing)
		draw_string(font, cursor + Vector2(1, 2), character, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(0, 0, 0, opacity * 0.8))
		draw_string(font, cursor, character, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(0.95, 0.93, 0.86, opacity))
		if vertical:
			cursor.y += spacing
			if cursor.y > size.y:
				cursor = Vector2(cursor.x - spacing, spacing)
		else:
			cursor.x += width

extends Node2D
## 局部薄雾、浮尘和柔光；独立于机关逻辑，关闭后不修改任何原对象。
@onready var _settings: Node = get_node("/root/ExportSettings")
@onready var _mist: Sprite2D = $WaterMist
@onready var _fountain_mist: Sprite2D = $FountainMist
@onready var _dial_glow: Sprite2D = $DialGlow
@onready var _book_glow: Sprite2D = $BookGlow
var _elapsed: float = 0.0
var _dial: Sprite2D
var _book: Sprite2D
var _dust_bounds := Rect2()
var _dust_color := Color.WHITE
var _dust_count: int = 0
var _resolve_delay: float = 0.0

func _ready() -> void:
	_mist.material = _mist.material.duplicate()
	_fountain_mist.material = _fountain_mist.material.duplicate()
	_resolve_sources.call_deferred()

func _resolve_sources() -> void:
	var world := get_tree().current_scene
	if world == null:
		return
	# These props are authored in World, outside Level2Map. Follow their actual artwork.
	_dial = world.get_node_or_null("story/c2/月相刻盘/月相刻盘贴图") as Sprite2D
	_book = world.get_node_or_null("story/c2/残缺的绘本/残缺的绘本贴图") as Sprite2D

func _process(delta: float) -> void:
	visible = _settings.level2_atmosphere_enabled
	if not visible:
		return
	_elapsed += delta
	_resolve_delay -= delta
	if _resolve_delay <= 0.0:
		_resolve_delay = 2.0
		if not is_instance_valid(_dial) or not is_instance_valid(_book):
			_resolve_sources()
	_apply_mist(_mist, _settings.level2_atmosphere_water_mist_bounds, 0.0)
	_apply_mist(_fountain_mist, _settings.level2_atmosphere_fountain_mist_bounds, 21.0)
	_dust_bounds = _settings.level2_atmosphere_dust_bounds
	_dust_color = _settings.level2_atmosphere_dust_color
	_dust_count = clampi(_settings.level2_atmosphere_dust_count, 0, 40)
	if is_instance_valid(_book):
		_dust_bounds.position = to_local(_book.global_position) + Vector2(-150, -125)
	var cycle: float = maxf(_settings.level2_atmosphere_glow_period, 2.0)
	var pulse := 0.78 + 0.22 * sin(_elapsed * TAU / cycle)
	var glow: Color = _settings.level2_atmosphere_glow_color
	glow.a *= _settings.level2_atmosphere_glow_opacity * pulse
	_dial_glow.modulate = glow
	_book_glow.modulate = Color(glow, glow.a * 0.65)
	_dial_glow.position = _settings.level2_atmosphere_dial_position
	_book_glow.position = _settings.level2_atmosphere_book_position
	_dial_glow.visible = not is_instance_valid(_dial) or _dial.is_visible_in_tree()
	_book_glow.visible = not is_instance_valid(_book) or _book.is_visible_in_tree()
	if is_instance_valid(_dial):
		_dial_glow.global_position = _dial.to_global(_dial.get_rect().get_center())
	if is_instance_valid(_book):
		_book_glow.global_position = _book.to_global(_book.get_rect().get_center())
	_dial_glow.scale = Vector2.ONE * _settings.level2_atmosphere_glow_radius / 64.0
	_book_glow.scale = _dial_glow.scale * 0.65
	queue_redraw()

func _apply_mist(sprite: Sprite2D, bounds: Rect2, phase: float) -> void:
	sprite.position = bounds.position
	sprite.scale = bounds.size
	var shader_material := sprite.material as ShaderMaterial
	shader_material.set_shader_parameter("elapsed", _elapsed * _settings.level2_atmosphere_mist_speed + phase)
	shader_material.set_shader_parameter("strength", _settings.level2_atmosphere_mist_opacity)
	shader_material.set_shader_parameter("mist_color", _settings.level2_atmosphere_mist_color)

func _draw() -> void:
	if _dust_count == 0 or (is_instance_valid(_book) and not _book.is_visible_in_tree()):
		return
	# Fixed seeds: slow independent paths, no spawning nodes or random flashing.
	for i in _dust_count:
		var seed_x := fposmod(float(i) * 0.618034, 1.0)
		var seed_y := fposmod(float(i) * 0.381966 + 0.21, 1.0)
		var phase := fposmod(seed_y + _elapsed * (0.014 + float(i % 3) * 0.003), 1.0)
		var fade := sin(phase * PI)
		var point := _dust_bounds.position + Vector2(
			seed_x * _dust_bounds.size.x + sin(_elapsed * 0.23 + float(i) * 2.1) * 9.0,
			(1.0 - phase) * _dust_bounds.size.y)
		var color := Color(_dust_color, _dust_color.a * fade * fade)
		draw_circle(point, 1.0 + float(i % 3) * 0.3, color, true, -1.0, true)

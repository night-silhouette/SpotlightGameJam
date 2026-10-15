@tool
extends Area2D
## 蓝色区域与碰撞形状共用尺寸；编辑器可直接移动各 CollisionShape2D。
## 接触即通过既有死亡流程复活，不新增检查点、不控制镜头。
const ATLAS: Texture2D = preload("res://Art/New/map2/2_grid665.png")
# 与第二关 TerrainArt 使用相同的半透明蓝色砖块裁切区域。
const GLASS_WIDE := Rect2(0, 5975, 2774, 2004)
const SETTINGS: Script = preload("res://Code/Autoloads/ExportSettings.gd")
var _redraw_time: float = 0.0

func _ready() -> void:
	queue_redraw()
	if not Engine.is_editor_hint():
		body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	_redraw_time += delta
	if _redraw_time >= 0.25:
		_redraw_time = 0.0
		queue_redraw()

func _physics_process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	# 同时覆盖出生已在水里，以及关闭调试飞行后仍与水接触的情况。
	for body: Node2D in get_overlapping_bodies():
		_on_body_entered(body)

func _on_body_entered(body: Node2D) -> void:
	if not ExportSettings.level2_death_boundary_enabled or not body.is_in_group("player"):
		return
	if float(body.get("now_HP")) <= 0.0:
		return
	if ExportSettings.level2_death_boundary_ignore_debug_flight and bool(body.get("debug_flight_enabled")):
		return
	SignalBus.PlayerInstantDeathRequested.emit(body, self)

func _draw() -> void:
	var enabled: bool = bool(SETTINGS.get_property_default_value("level2_death_boundary_enabled")) if Engine.is_editor_hint() else ExportSettings.level2_death_boundary_enabled
	if not enabled:
		return
	var visual_size: float = float(SETTINGS.get_property_default_value("level2_death_boundary_texture_size")) if Engine.is_editor_hint() else ExportSettings.level2_death_boundary_texture_size
	visual_size = maxf(32.0, visual_size)
	for child in get_children():
		var collider := child as CollisionShape2D
		if collider == null or collider.disabled or not collider.shape is RectangleShape2D:
			continue
		var shape := collider.shape as RectangleShape2D
		var rect: Rect2 = collider.transform * Rect2(-shape.size * 0.5, shape.size)
		# 月影水道与下层天花板合为同一块外观，死亡形状仍保持原尺寸。
		if collider.name == &"MoonAqueductDeathWater":
			var join_depth: float = float(SETTINGS.get_property_default_value("level2_death_boundary_moon_join_depth")) if Engine.is_editor_hint() else ExportSettings.level2_death_boundary_moon_join_depth
			rect.size.y += maxf(0.0, join_depth)
		_draw_blue_brick(rect, visual_size)

func _draw_blue_brick(rect: Rect2, texture_size: float) -> void:
	# 与 TerrainArt 相同的九宫格：保留原图颜色、透明度及圆角，内部连续铺满。
	# 默认 96 对应 10 像素边缘，与相邻蓝色地形一致。
	var cap := minf(10.0 * texture_size / 96.0, minf(rect.size.x, rect.size.y) * 0.3)
	var source_cap := 300.0
	var dx := [rect.position.x, rect.position.x + cap, rect.end.x - cap, rect.end.x]
	var dy := [rect.position.y, rect.position.y + cap, rect.end.y - cap, rect.end.y]
	var sx := [GLASS_WIDE.position.x, GLASS_WIDE.position.x + source_cap, GLASS_WIDE.end.x - source_cap, GLASS_WIDE.end.x]
	var sy := [GLASS_WIDE.position.y, GLASS_WIDE.position.y + source_cap, GLASS_WIDE.end.y - source_cap, GLASS_WIDE.end.y]
	for y in range(3):
		for x in range(3):
			var destination := Rect2(dx[x], dy[y], dx[x + 1] - dx[x], dy[y + 1] - dy[y])
			var sample := Rect2(sx[x], sy[y], sx[x + 1] - sx[x], sy[y + 1] - sy[y])
			draw_texture_rect_region(ATLAS, destination, sample)

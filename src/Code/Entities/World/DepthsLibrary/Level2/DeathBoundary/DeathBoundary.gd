@tool
extends Area2D
## 蓝色区域与碰撞形状共用尺寸；编辑器可直接移动各 CollisionShape2D。
## 接触即通过既有死亡流程复活，不新增检查点、不控制镜头。
const SURFACE = preload("res://Code/Entities/World/DepthsLibrary/Level2/Terrain/StoneSurface.gd")
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
	# 地图中由 TerrainArt 合并外轮廓，防止相接处重复出现蓝边。
	var art := get_parent().get_node_or_null("TerrainArt") as CanvasItem
	var art_enabled: bool = bool(SETTINGS.get_property_default_value("level2_terrain_art_enabled")) if Engine.is_editor_hint() else ExportSettings.level2_terrain_art_enabled
	if art != null and art.is_visible_in_tree() and art_enabled:
		return
	var rectangles: Array[Rect2] = []
	for child in get_children():
		var collider := child as CollisionShape2D
		if collider == null or collider.disabled or not collider.shape is RectangleShape2D:
			continue
		var shape := collider.shape as RectangleShape2D
		rectangles.append(collider.transform * Rect2(-shape.size * 0.5, shape.size))
	var ratio: float = float(SETTINGS.get_property_default_value("level2_terrain_art_border_ratio")) if Engine.is_editor_hint() else ExportSettings.level2_terrain_art_border_ratio
	SURFACE.Draw(self, SURFACE.Build(rectangles), 32.0 * ratio)

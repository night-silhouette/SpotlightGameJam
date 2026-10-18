extends Node2D

@onready var _platform: Node2D = get_parent() as Node2D
@onready var _map_space: Node2D = _platform.get_parent() as Node2D
@onready var _cross_rope: Line2D = $CrossRope
@onready var _hanging_rope: Line2D = $HangingRope
@onready var _platform_art: Sprite2D = $PlatformArt

func _ready() -> void:
	_update_ropes()

func _process(_delta: float) -> void:
	_update_ropes()

func _update_ropes() -> void:
	var left := to_local(_map_space.to_global(ExportSettings.sunken_lift_rope_left_anchor))
	var right := to_local(_map_space.to_global(ExportSettings.sunken_lift_rope_right_anchor))
	var attachment: Vector2 = ExportSettings.sunken_lift_rope_attachment
	var junction := Vector2(attachment.x, left.y)
	_cross_rope.points = PackedVector2Array([left, right])
	_hanging_rope.points = PackedVector2Array([junction, attachment])
	_cross_rope.width = ExportSettings.sunken_lift_rope_width
	_hanging_rope.width = ExportSettings.sunken_lift_rope_width
	_platform_art.position = ExportSettings.sunken_lift_rope_art_offset
	_platform_art.scale = Vector2.ONE * ExportSettings.sunken_lift_rope_art_scale

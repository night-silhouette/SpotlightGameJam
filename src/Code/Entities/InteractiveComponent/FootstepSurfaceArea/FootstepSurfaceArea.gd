extends Area2D

## 仅对该路径指向的玩家生效；在场景实例中指定目标 Player。
@export var player_path: NodePath
@export_group("Left Side")
@export_enum("Brick", "Sand") var left_surface: String = "Brick"
@export var left_footstep_bus: StringName = &"SFX_Footstep_Dry"
@export var left_move_bus: StringName = &"SFX_Move_Dry"
@export_group("Right Side")
@export_enum("Brick", "Sand") var right_surface: String = "Sand"
@export var right_footstep_bus: StringName = &"SFX_Footstep_Wet"
@export var right_move_bus: StringName = &"SFX_Move_Wet"

var _tracked_player: Node2D
var _entry_side: int = 0


func _init() -> void:
	if ExportSettings:
		left_surface = ExportSettings.footstep_surface_area_left_surface
		left_footstep_bus = ExportSettings.footstep_surface_area_left_footstep_bus
		left_move_bus = ExportSettings.footstep_surface_area_left_move_bus
		right_surface = ExportSettings.footstep_surface_area_right_surface
		right_footstep_bus = ExportSettings.footstep_surface_area_right_footstep_bus
		right_move_bus = ExportSettings.footstep_surface_area_right_move_bus


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _physics_process(_delta: float) -> void:
	if is_instance_valid(_tracked_player):
		_check_side()


func _side_of(player: Node2D) -> int:
	var local_x: float = to_local(player.global_position).x
	if local_x < 0.0:
		return -1
	if local_x > 0.0:
		return 1
	return 0


func _check_side() -> void:
	var side: int = _side_of(_tracked_player)
	if side == 0:
		return
	if _entry_side == 0:
		_entry_side = side
	elif side != _entry_side:
		_entry_side = side
		if side < 0:
			SignalBus.PlayerFootstepSurfaceChangeRequested.emit(_tracked_player, left_surface, left_footstep_bus, left_move_bus)
		else:
			SignalBus.PlayerFootstepSurfaceChangeRequested.emit(_tracked_player, right_surface, right_footstep_bus, right_move_bus)


func _on_body_entered(body: Node2D) -> void:
	if body != get_node_or_null(player_path):
		return
	_tracked_player = body
	_entry_side = _side_of(body)


func _on_body_exited(body: Node2D) -> void:
	if body != _tracked_player:
		return
	_check_side()
	_tracked_player = null
	_entry_side = 0

@tool
extends StaticBody2D
class_name OneWayDropPlatformComponent

## 可从下方跳上、站在顶部；站在平台上按“下 + 跳跃”会向下穿过。
## 使用现有输入动作 down 与 jump，不需要修改玩家脚本。

@export var platform_size: Vector2 = Vector2(128.0, 16.0):
	set(value):
		platform_size = Vector2(maxf(value.x, 1.0), maxf(value.y, 1.0))
		_sync_geometry()
@export_range(0.0, 32.0, 0.5) var one_way_margin: float = 4.0:
	set(value):
		one_way_margin = maxf(value, 0.0)
		_sync_geometry()
@export_range(16.0, 160.0, 1.0) var detection_height: float = 72.0:
	set(value):
		detection_height = maxf(value, 1.0)
		_sync_geometry()
@export_range(0.05, 2.0, 0.05) var max_ignore_time: float = 0.6
@export_range(0.0, 400.0, 5.0) var drop_start_speed: float = 90.0
@export_range(0.0, 64.0, 1.0) var restore_clearance: float = 24.0
@export var platform_color: Color = Color("8bc6a4"):
	set(value):
		platform_color = value
		if is_instance_valid(_visual):
			_visual.color = platform_color

@onready var _platform_collision: CollisionShape2D = $CollisionShape2D
@onready var _sensor: Area2D = $DropSensor
@onready var _sensor_collision: CollisionShape2D = $DropSensor/CollisionShape2D
@onready var _visual: Polygon2D = $Visual
var _dropping_players: Dictionary = {}

func _ready() -> void:
	_sync_geometry()
	if Engine.is_editor_hint():
		set_physics_process(false)
		return
	process_physics_priority = 100

func _physics_process(delta: float) -> void:
	_update_dropping_players(delta)
	if not Input.is_action_pressed("down") or not Input.is_action_just_pressed("jump"):
		return
	for body in _sensor.get_overlapping_bodies():
		var player := body as CharacterBody2D
		if player == null or not player.is_in_group("player"):
			continue
		if not player.is_on_floor() or _dropping_players.has(player):
			continue
		_begin_drop(player)

func _begin_drop(player: CharacterBody2D) -> void:
	add_collision_exception_with(player)
	_dropping_players[player] = 0.0
	player.velocity.y = maxf(player.velocity.y, drop_start_speed)
	player.global_position.y += 2.0

func _update_dropping_players(delta: float) -> void:
	for player_variant in _dropping_players.keys():
		var player := player_variant as CharacterBody2D
		if not is_instance_valid(player):
			_dropping_players.erase(player_variant)
			continue
		var elapsed: float = float(_dropping_players[player]) + delta
		_dropping_players[player] = elapsed
		var passed_platform := player.global_position.y > global_position.y + platform_size.y * 0.5 + restore_clearance
		if passed_platform or elapsed >= max_ignore_time:
			remove_collision_exception_with(player)
			_dropping_players.erase(player)

func _sync_geometry() -> void:
	if not is_inside_tree():
		return
	if is_instance_valid(_platform_collision):
		var platform_shape := _platform_collision.shape as RectangleShape2D
		if platform_shape:
			platform_shape.size = platform_size
		_platform_collision.one_way_collision = true
		_platform_collision.one_way_collision_margin = one_way_margin
	if is_instance_valid(_sensor_collision):
		var sensor_shape := _sensor_collision.shape as RectangleShape2D
		if sensor_shape:
			sensor_shape.size = Vector2(platform_size.x, detection_height)
		_sensor_collision.position.y = -(platform_size.y + detection_height) * 0.5
	if is_instance_valid(_visual):
		var half := platform_size * 0.5
		_visual.polygon = PackedVector2Array([
			Vector2(-half.x, -half.y), Vector2(half.x, -half.y),
			Vector2(half.x, half.y), Vector2(-half.x, half.y),
		])
		_visual.color = platform_color

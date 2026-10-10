extends Node2D

var _active: bool = false
var _elapsed: float = 0.0
var _facing: float = 1.0

@onready var _player: Player = get_parent() as Player
@onready var _body: Node2D = get_parent().get_node("sprite")
@onready var _source_line: Line2D = get_parent().get_node("RopeController/Line2D")
@onready var _deploy: Sprite2D = $Deploy
@onready var _rope: Sprite2D = $Rope
@onready var _hook: Sprite2D = $Hook
@onready var _rope_origin: Marker2D = $Deploy/RopeOrigin

## 返回绳索发射点的世界坐标；无参数，位置随部署人物的镜像、缩放及偏移变化。
func GetRopeOrigin() -> Vector2:
	return _rope_origin.global_position

func _ready() -> void:
	_deploy.material = _body.get_node("Action").material
	# 保留控制器的线段坐标与显隐逻辑，独立视觉层只替换绘制。
	_source_line.self_modulate.a = 0.0
	SignalBus.PlayerGrappleLaunched.connect(_on_launched)
	SignalBus.PlayerGrappleReleased.connect(_on_released)
	SignalBus.PlayerHurt.connect(_on_hurt)
	SignalBus.PlayerRespawned.connect(_on_respawned)

func _process(delta: float) -> void:
	if _active and (_player.now_HP <= 0.0 or _player.move_state_machine.cur_state_name in ["hurt", "died"]):
		_on_released()
	if not _active:
		return
	_elapsed += delta
	_deploy.frame = mini(int(_elapsed * ExportSettings.rope_visual_deploy_fps), 1)
	_deploy.position = ExportSettings.rope_visual_player_offset * Vector2(_facing, 1.0)
	_deploy.scale = Vector2(_facing, 1.0) * ExportSettings.rope_visual_player_scale
	_deploy.modulate = _body.modulate
	if _source_line.get_point_count() < 2:
		return
	var start := to_local(GetRopeOrigin())
	var end := to_local(_source_line.to_global(_source_line.get_point_position(1)))
	var direction := end - start
	_rope.visible = _source_line.visible and direction.length_squared() > 0.0
	_hook.visible = _rope.visible
	_rope.position = start
	_rope.rotation = direction.angle()
	_rope.scale = Vector2(direction.length() / _rope.texture.get_width(), ExportSettings.rope_visual_width / _rope.texture.get_height())
	_rope.offset.y = -_rope.texture.get_height() * 0.5
	_hook.position = end
	_hook.rotation = direction.angle()
	_hook.scale = Vector2.ONE * ExportSettings.rope_visual_hook_scale

func _on_launched(target: Vector2) -> void:
	_active = true
	_elapsed = 0.0
	_facing = -1.0 if target.x < _player.global_position.x else 1.0
	_body.visible = false
	_deploy.visible = true
	_deploy.frame = 0
	_process(0.0)

func _on_released() -> void:
	if not _active:
		return
	_active = false
	_body.visible = true
	_deploy.visible = false
	_rope.visible = false
	_hook.visible = false

func _on_hurt(_damage: float, _knockback: Vector2) -> void:
	_on_released()

func _on_respawned(_position: Vector2) -> void:
	_on_released()

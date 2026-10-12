extends Area2D
class_name InstantKillArea

const LETHAL_DAMAGE: float = 999999.0

## 是否启用即死区域。由禁用切换为启用时，会立即检查区域内已有的玩家。
@export var enabled: bool = true:
	set(value):
		enabled = value
		if is_node_ready() and enabled:
			_check_overlapping_bodies.call_deferred()

## 玩家触发即死区域时播放的可选音效。
@export var kill_sound: AudioStream

@onready var _audio_player: AudioStreamPlayer2D = $AudioStreamPlayer2D


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	# 等待物理服务器完成首次同步，覆盖玩家出生时已经位于区域内的情况。
	await get_tree().physics_frame
	_check_overlapping_bodies()


func _on_body_entered(body: Node2D) -> void:
	if enabled:
		_kill_body(body)


func _check_overlapping_bodies() -> void:
	if not enabled or not is_inside_tree():
		return
	for body: Node2D in get_overlapping_bodies():
		_kill_body(body)


func _kill_body(body: Node2D) -> void:
	if not _is_player_body(body):
		return

	if kill_sound != null:
		_audio_player.stream = kill_sound
		_audio_player.play()

	# 优先走玩家公开伤害接口；若无敌帧等机制拦截伤害，再直接归零生命值。
	if body.has_method("ApplyDamage"):
		body.call("ApplyDamage", LETHAL_DAMAGE, Vector2.ZERO)
	if "now_HP" in body and float(body.get("now_HP")) > 0.0:
		body.set("now_HP", 0.0)


func _is_player_body(body: Node2D) -> bool:
	if body is Player:
		return true
	if not body.is_in_group("player"):
		return false
	return body.has_method("ApplyDamage") or "now_HP" in body

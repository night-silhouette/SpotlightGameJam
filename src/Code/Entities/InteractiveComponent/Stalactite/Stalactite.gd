extends Node2D
class_name Stalactite

## =============================================================================
## Stalactite.gd - 钟乳石交互组件
## 悬挂在洞顶，利用向下射线检测走过的玩家。
## 玩家走过触发短暂松动微震后脱落坠下，砸中玩家造成伤害，命中物体/地面后碎裂消失。
## =============================================================================

@export_category("Stalactite Settings")
## 钟乳石尺寸 (基底宽度, 高度)
@export var stalactite_size: Vector2 = Vector2(24.0, 48.0):
	set(value):
		stalactite_size = value
		_update_dimensions()

## 向下探测玩家的射线检测距离
@export var ray_length: float = 400.0:
	set(value):
		ray_length = value
		_update_dimensions()

## 触发后松动震颤延迟 (秒)
@export var shake_duration: float = 0.35
## 基础伤害量
@export var damage: float = 50.0
## 击退力 (像素/秒)
@export var knockback_force: float = 350.0
## 重力加速度 (像素/秒^2)
@export var gravity: float = 1600.0
## 最大坠落速度 (像素/秒)
@export var max_fall_speed: float = 900.0

enum StalactiteState { HANGING, WARNING, FALLING, SHATTERED }

var current_state: StalactiteState = StalactiteState.HANGING
var _vertical_velocity: float = 0.0
var _original_visual_pos: Vector2 = Vector2.ZERO
var _shake_tween: Tween = null

@onready var detect_ray: RayCast2D = $DetectRay
@onready var hit_area: Area2D = $HitArea
@onready var hit_collision: CollisionShape2D = $HitArea/HitCollision
@onready var visual_root: Node2D = $VisualRoot
@onready var visual_polygon: Polygon2D = $VisualRoot/VisualPolygon
@onready var debris_particles: CPUParticles2D = $DebrisParticles

func _ready() -> void:
	_sync_from_export_settings()
	_update_dimensions()
	if visual_root:
		_original_visual_pos = visual_root.position

	if hit_area:
		hit_area.body_entered.connect(_on_hit_area_body_entered)
		# 悬挂阶段关闭伤害检测区域，下落时才开启
		hit_collision.set_deferred("disabled", true)

func _sync_from_export_settings() -> void:
	if ExportSettings:
		ray_length = ExportSettings.stalactite_ray_length
		shake_duration = ExportSettings.stalactite_shake_duration
		gravity = ExportSettings.stalactite_gravity
		max_fall_speed = ExportSettings.stalactite_max_fall_speed
		damage = ExportSettings.stalactite_damage
		knockback_force = ExportSettings.stalactite_knockback_force

func _update_dimensions() -> void:
	if not is_inside_tree():
		return

	if detect_ray:
		detect_ray.target_position = Vector2(0.0, ray_length)

	if hit_collision:
		# 碰撞形状涵盖尖石主体，向下居中
		var rect = RectangleShape2D.new()
		rect.size = Vector2(stalactite_size.x * 0.8, stalactite_size.y)
		hit_collision.shape = rect
		hit_collision.position = Vector2(0.0, stalactite_size.y * 0.5)

	if visual_polygon:
		# 倒三角尖尖钟乳石外形：基底在顶部(0, 0)，尖端在底部(0, stalactite_size.y)
		var half_w = stalactite_size.x * 0.5
		var points = PackedVector2Array([
			Vector2(-half_w, 0.0),
			Vector2(-half_w * 0.4, stalactite_size.y * 0.5),
			Vector2(0.0, stalactite_size.y),
			Vector2(half_w * 0.4, stalactite_size.y * 0.5),
			Vector2(half_w, 0.0)
		])
		visual_polygon.polygon = points

func _physics_process(delta: float) -> void:
	match current_state:
		StalactiteState.HANGING:
			_check_ray_detection()
		StalactiteState.FALLING:
			_process_falling(delta)

func _check_ray_detection() -> void:
	if not detect_ray or not detect_ray.is_colliding():
		return

	var collider = detect_ray.get_collider()
	if collider and (collider.is_in_group("player") or collider is CharacterBody2D):
		_trigger_warning()

func _trigger_warning() -> void:
	if current_state != StalactiteState.HANGING:
		return

	current_state = StalactiteState.WARNING
	if SignalBus:
		SignalBus.StalactiteTriggered.emit(self)

	# 禁用检测射线
	detect_ray.enabled = false

	# 震颤预警动画
	if _shake_tween and _shake_tween.is_valid():
		_shake_tween.kill()

	_shake_tween = create_tween().set_loops(int(shake_duration / 0.05))
	_shake_tween.tween_property(visual_root, "position:x", _original_visual_pos.x + randf_range(-2.0, 2.0), 0.025)
	_shake_tween.tween_property(visual_root, "position:x", _original_visual_pos.x, 0.025)

	get_tree().create_timer(shake_duration).timeout.connect(_start_fall)

func _start_fall() -> void:
	if current_state != StalactiteState.WARNING:
		return

	if _shake_tween and _shake_tween.is_valid():
		_shake_tween.kill()
	visual_root.position = _original_visual_pos

	current_state = StalactiteState.FALLING
	_vertical_velocity = 80.0
	hit_collision.set_deferred("disabled", false)

func _process_falling(delta: float) -> void:
	_vertical_velocity = min(_vertical_velocity + gravity * delta, max_fall_speed)
	global_position.y += _vertical_velocity * delta

func _on_hit_area_body_entered(body: Node2D) -> void:
	if current_state != StalactiteState.FALLING:
		return

	# 命中玩家：造成伤害并击退（向两侧斜上方挑飞弹开，避免直接向下压进地面）
	if body.is_in_group("player") or body is CharacterBody2D:
		var push_dir_x: float = 1.0
		if body.global_position.x < global_position.x:
			push_dir_x = -1.0
		elif body.global_position.x > global_position.x:
			push_dir_x = 1.0
		else:
			push_dir_x = -1.0 if ("face_dir" in body and body.face_dir < 0) else 1.0

		var knockback_dir = Vector2(push_dir_x * 0.7, -0.7).normalized()
		var knockback_vector = knockback_dir * knockback_force

		if body.has_method("ApplyDamage"):
			body.ApplyDamage(damage, knockback_vector)
		elif body.has_method("be_hurted"):
			body.be_hurted(damage)

		if SignalBus:
			SignalBus.StalactiteHit.emit(self, body)
		_shatter()
		return

	# 命中地面/墙壁/固体刚体
	if body is TileMap or body is TileMapLayer or body is StaticBody2D:
		if SignalBus:
			SignalBus.StalactiteHit.emit(self, body)
		_shatter()

func _shatter() -> void:
	if current_state == StalactiteState.SHATTERED:
		return

	current_state = StalactiteState.SHATTERED
	hit_collision.set_deferred("disabled", true)
	visual_root.visible = false

	if SignalBus:
		SignalBus.StalactiteShattered.emit(self)

	# 播放碎屑爆炸粒子特效
	if debris_particles:
		debris_particles.emitting = true
		get_tree().create_timer(debris_particles.lifetime + 0.1).timeout.connect(queue_free)
	else:
		queue_free()

## 触发下落的公共方法
func TriggerFall() -> void:
	if current_state == StalactiteState.HANGING:
		_trigger_warning()

## 实体数据导出
func ExportSaveData() -> Dictionary:
	return {
		"position_x": global_position.x,
		"position_y": global_position.y,
		"current_state": int(current_state)
	}

## 实体数据加载
## @param data 存档字典
func LoadSaveData(data: Dictionary) -> void:
	if data.has("position_x") and data.has("position_y"):
		global_position = Vector2(data["position_x"], data["position_y"])
	if data.has("current_state"):
		var state_val = data["current_state"]
		if state_val == StalactiteState.SHATTERED:
			queue_free()
		elif state_val == StalactiteState.FALLING:
			current_state = StalactiteState.FALLING
			hit_collision.set_deferred("disabled", false)
			detect_ray.enabled = false

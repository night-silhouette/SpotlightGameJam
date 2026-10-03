extends CharacterBody2D
class_name FallingBlock

## =============================================================================
## FallingBlock.gd - 坠落方块/落石交互组件
## 初始悬挂在洞顶或高处；
## 玩家走过下方触发射线检测后，经短暂松动预警后垂直坠落。
## 坠落中对下方玩家造成碰撞伤害与击退；
## 落地后稳定成为普通的固体平台（支持踩踏、站立、站人）。
## =============================================================================

@export_category("FallingBlock Settings")
## 方块尺寸 (宽度, 高度)
@export var block_size: Vector2 = Vector2(48.0, 48.0):
	set(value):
		block_size = value
		_update_dimensions()

## 向下探测玩家的射线检测距离
@export var ray_length: float = 400.0:
	set(value):
		ray_length = value
		_update_dimensions()

## 触发后松动震颤延迟 (秒)
@export var shake_duration: float = 0.4
## 坠落中砸中玩家造成的伤害
@export var damage: float = 30.0
## 击退力 (像素/秒)
@export var knockback_force: float = 300.0
## 重力加速度 (像素/秒^2)
@export var block_gravity: float = 1400.0
## 最大坠落速度 (像素/秒)
@export var max_fall_speed: float = 800.0

enum BlockState { HANGING, WARNING, FALLING, LANDED }

var current_state: BlockState = BlockState.HANGING
var _original_visual_pos: Vector2 = Vector2.ZERO
var _shake_tween: Tween = null

@onready var detect_ray: RayCast2D = $DetectRay
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var hit_area: Area2D = $HitArea
@onready var hit_collision: CollisionShape2D = $HitArea/HitCollision
@onready var visual_root: Node2D = $VisualRoot
@onready var visual_rect: ColorRect = $VisualRoot/VisualRect
@onready var border_rect: ReferenceRect = $VisualRoot/BorderRect
@onready var impact_particles: CPUParticles2D = $ImpactParticles

func _ready() -> void:
	_sync_from_export_settings()
	_update_dimensions()
	if visual_root:
		_original_visual_pos = visual_root.position

	if hit_area:
		hit_area.body_entered.connect(_on_hit_area_body_entered)
		hit_collision.set_deferred("disabled", true)

func _sync_from_export_settings() -> void:
	if ExportSettings:
		ray_length = ExportSettings.falling_block_ray_length
		shake_duration = ExportSettings.falling_block_shake_duration
		block_gravity = ExportSettings.falling_block_gravity
		max_fall_speed = ExportSettings.falling_block_max_fall_speed
		damage = ExportSettings.falling_block_damage
		knockback_force = ExportSettings.falling_block_knockback_force

func _update_dimensions() -> void:
	if not is_inside_tree():
		return

	if detect_ray:
		detect_ray.target_position = Vector2(0.0, ray_length)

	var rect = RectangleShape2D.new()
	rect.size = block_size

	if collision_shape:
		collision_shape.shape = rect

	if hit_collision:
		# 底部伤害判定区：位于方块底面附近
		var hit_rect = RectangleShape2D.new()
		hit_rect.size = Vector2(block_size.x * 0.9, 12.0)
		hit_collision.shape = hit_rect
		hit_collision.position = Vector2(0.0, block_size.y * 0.5 - 2.0)

	if visual_rect:
		visual_rect.offset_left = -block_size.x * 0.5
		visual_rect.offset_right = block_size.x * 0.5
		visual_rect.offset_top = -block_size.y * 0.5
		visual_rect.offset_bottom = block_size.y * 0.5

	if border_rect:
		border_rect.offset_left = -block_size.x * 0.5
		border_rect.offset_right = block_size.x * 0.5
		border_rect.offset_top = -block_size.y * 0.5
		border_rect.offset_bottom = block_size.y * 0.5

func _physics_process(delta: float) -> void:
	match current_state:
		BlockState.HANGING:
			_check_ray_detection()
		BlockState.FALLING:
			_process_falling(delta)

func _check_ray_detection() -> void:
	if not detect_ray or not detect_ray.is_colliding():
		return

	var collider = detect_ray.get_collider()
	if collider and (collider.is_in_group("player") or collider is CharacterBody2D):
		_trigger_warning()

func _trigger_warning() -> void:
	if current_state != BlockState.HANGING:
		return

	current_state = BlockState.WARNING
	if SignalBus:
		SignalBus.FallingBlockTriggered.emit(self)

	detect_ray.enabled = false

	# 震颤预警动画
	if _shake_tween and _shake_tween.is_valid():
		_shake_tween.kill()

	_shake_tween = create_tween().set_loops(int(shake_duration / 0.05))
	_shake_tween.tween_property(visual_root, "position", _original_visual_pos + Vector2(randf_range(-2.0, 2.0), randf_range(-1.0, 1.0)), 0.025)
	_shake_tween.tween_property(visual_root, "position", _original_visual_pos, 0.025)

	get_tree().create_timer(shake_duration).timeout.connect(_start_fall)

func _start_fall() -> void:
	if current_state != BlockState.WARNING:
		return

	if _shake_tween and _shake_tween.is_valid():
		_shake_tween.kill()
	visual_root.position = _original_visual_pos

	current_state = BlockState.FALLING
	velocity.y = 80.0
	hit_collision.set_deferred("disabled", false)

func _process_falling(delta: float) -> void:
	velocity.y = min(velocity.y + block_gravity * delta, max_fall_speed)
	velocity.x = 0.0
	
	move_and_slide()

	# 检查是否砸到/接触到地面
	for i in range(get_slide_collision_count()):
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		# 如果法线朝上，说明落到了地面或平台上
		if collision.get_normal().y < -0.5:
			_land()
			return

	if is_on_floor():
		_land()

func _on_hit_area_body_entered(body: Node2D) -> void:
	if current_state != BlockState.FALLING:
		return

	# 砸中玩家：造成伤害并将其水平推出（避免被直接垂直压入地面以下）
	if body.is_in_group("player") or body is CharacterBody2D:
		var push_dir_x: float = 1.0
		# 若玩家在方块中轴线左侧，则往左推开；如果在右侧或正中，则根据玩家朝向或位置往外推
		if body.global_position.x < global_position.x:
			push_dir_x = -1.0
		elif body.global_position.x > global_position.x:
			push_dir_x = 1.0
		else:
			push_dir_x = -1.0 if ("face_dir" in body and body.face_dir < 0) else 1.0

		var knockback_dir = Vector2(push_dir_x, -0.4).normalized()
		var knockback_vector = knockback_dir * knockback_force

		# 安全位移修正：如果玩家正被方块从正上方完全覆盖，将玩家略微外移，防止陷入地面卡入地下
		var half_w = block_size.x * 0.5 + 14.0
		var target_x = global_position.x + push_dir_x * half_w
		body.global_position.x = move_toward(body.global_position.x, target_x, 24.0)

		if body.has_method("ApplyDamage"):
			body.ApplyDamage(damage, knockback_vector)
		elif body.has_method("be_hurted"):
			body.be_hurted(damage)

		if SignalBus:
			SignalBus.FallingBlockHit.emit(self, body)

func _land() -> void:
	if current_state == BlockState.LANDED:
		return

	current_state = BlockState.LANDED
	velocity = Vector2.ZERO
	hit_collision.set_deferred("disabled", true)

	if SignalBus:
		SignalBus.FallingBlockLanded.emit(self)

	# 扬尘震地粒子与微弹反馈
	if impact_particles:
		impact_particles.emitting = true

	var land_tween = create_tween()
	land_tween.tween_property(visual_root, "scale", Vector2(1.15, 0.85), 0.06).set_trans(Tween.TRANS_QUAD)
	land_tween.tween_property(visual_root, "scale", Vector2.ONE, 0.1).set_trans(Tween.TRANS_BOUNCE)

## 外部主动触发下落公共方法
func TriggerFall() -> void:
	if current_state == BlockState.HANGING:
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
		if state_val == BlockState.LANDED:
			current_state = BlockState.LANDED
			detect_ray.enabled = false
			hit_collision.set_deferred("disabled", true)
		elif state_val == BlockState.FALLING:
			current_state = BlockState.FALLING
			detect_ray.enabled = false
			hit_collision.set_deferred("disabled", false)

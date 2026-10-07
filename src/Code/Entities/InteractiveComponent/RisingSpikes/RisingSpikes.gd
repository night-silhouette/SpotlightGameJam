extends Node2D
class_name RisingSpikes

## =============================================================================
## RisingSpikes.gd - 时序突刺交互组件
## 按可配置的时间周期在【石缝安全态】与【伸出危险态】之间切换
## 伸出时触发 SpikesExtended，缩回时触发 SpikesRetracted，触碰对玩家造成伤害与击退
## =============================================================================

@export_category("RisingSpikes Timing Settings")
## 突刺缩回在石缝内的安全等待时长 (秒)
@export var retracted_duration: float = 2.0
## 突刺完全伸出暴露的危险持续时长 (秒)
@export var extended_duration: float = 1.5
## 突刺伸出/缩回的平滑移动时间 (秒)
@export var transition_time: float = 0.2
## 初始启动延迟偏移 (秒)，用于多个突刺机关交错时序
@export var start_delay: float = 0.0
## 初始状态是否已经伸出
@export var starts_extended: bool = false

@export_category("Combat & Dimension Settings")
## 突刺伤害量
@export var damage: float = 50.0
## 击退力大小 (像素/秒)
@export var knockback_force: float = 450.0
## 突刺尺寸 (宽度, 伸出高度)
@export var spikes_size: Vector2 = Vector2(32.0, 20.0):
	set(value):
		spikes_size = value
		_update_dimensions()

@onready var base_rect: ColorRect = $BaseSlot
@onready var spike_area: Area2D = $SpikeMovingRoot/SpikeArea
@onready var spike_collision: CollisionShape2D = $SpikeMovingRoot/SpikeArea/SpikeCollision
@onready var visual_polygon: Polygon2D = $SpikeMovingRoot/VisualPolygon
@onready var spike_moving_root: Node2D = $SpikeMovingRoot

var _is_extended: bool = false
var _active_tween: Tween = null
var _timer: Timer = null

func _ready() -> void:
	_sync_from_export_settings()
	_update_dimensions()
	
	if spike_area:
		spike_area.body_entered.connect(_on_body_entered)
	
	# 初始化位置状态
	_is_extended = starts_extended
	if _is_extended:
		spike_moving_root.position.y = -spikes_size.y
		spike_collision.set_deferred("disabled", false)
	else:
		spike_moving_root.position.y = 0.0
		spike_collision.set_deferred("disabled", true)
	
	_start_cycle()

func _sync_from_export_settings() -> void:
	if ExportSettings:
		damage = ExportSettings.rising_spikes_damage
		knockback_force = ExportSettings.rising_spikes_knockback_force
		retracted_duration = ExportSettings.rising_spikes_retracted_duration
		extended_duration = ExportSettings.rising_spikes_extended_duration
		transition_time = ExportSettings.rising_spikes_transition_time

func _update_dimensions() -> void:
	if not is_inside_tree():
		return
	
	if base_rect:
		base_rect.offset_left = -spikes_size.x * 0.5
		base_rect.offset_right = spikes_size.x * 0.5
		base_rect.offset_top = -4.0
		base_rect.offset_bottom = 2.0

	if spike_collision:
		var rect = RectangleShape2D.new()
		rect.size = Vector2(spikes_size.x, spikes_size.y)
		spike_collision.shape = rect
		spike_collision.position = Vector2(0.0, spikes_size.y * 0.5)

	if visual_polygon:
		var points = PackedVector2Array()
		var count: int = max(2, int(spikes_size.x / 8.0))
		var step: float = spikes_size.x / float(count)
		var start_x: float = -spikes_size.x * 0.5
		
		# 在 moving_root 下，顶部在 Y=0，尖刺底部在 Y=spikes_size.y
		points.append(Vector2(start_x, spikes_size.y))
		for i in range(count):
			var seg_x: float = start_x + i * step
			var tip_x: float = seg_x + step * 0.5
			var next_x: float = seg_x + step
			points.append(Vector2(tip_x, 0.0))
			points.append(Vector2(next_x, spikes_size.y))
		visual_polygon.polygon = points

func _start_cycle() -> void:
	var first_wait: float = (extended_duration if _is_extended else retracted_duration) + start_delay
	get_tree().create_timer(first_wait).timeout.connect(_on_cycle_timeout)

func _on_cycle_timeout() -> void:
	if not is_inside_tree():
		return
	if _is_extended:
		_retract_spikes()
	else:
		_extend_spikes()

func _extend_spikes() -> void:
	if _active_tween and _active_tween.is_valid():
		_active_tween.kill()
	
	# 伸出过程：开启碰撞，播放位移至 -spikes_size.y
	spike_collision.set_deferred("disabled", false)
	_active_tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_active_tween.tween_property(spike_moving_root, "position:y", -spikes_size.y, transition_time)
	_active_tween.finished.connect(func():
		_is_extended = true
		if SignalBus:
			SignalBus.SpikesExtended.emit(self)
		# 伸出保持时长后缩回
		get_tree().create_timer(extended_duration).timeout.connect(_on_cycle_timeout)
	)

func _retract_spikes() -> void:
	if _active_tween and _active_tween.is_valid():
		_active_tween.kill()
	
	# 缩回过程：移动至 0.0，随后关闭碰撞
	_active_tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_active_tween.tween_property(spike_moving_root, "position:y", 0.0, transition_time)
	_active_tween.finished.connect(func():
		_is_extended = false
		spike_collision.set_deferred("disabled", true)
		if SignalBus:
			SignalBus.SpikesRetracted.emit(self)
		# 缩回等待时长后再次伸出
		get_tree().create_timer(retracted_duration).timeout.connect(_on_cycle_timeout)
	)

func _on_body_entered(body: Node2D) -> void:
	if not _is_extended and spike_moving_root.position.y > -spikes_size.y * 0.3:
		return
	if body.is_in_group("player") or body is CharacterBody2D:
		_trigger_damage(body)

func _trigger_damage(player: Node2D) -> void:
	# 突刺向外的法线方向（局部坐标-Y轴对应尖端朝向）
	var spike_normal: Vector2 = -global_transform.y.normalized()
	if spike_normal == Vector2.ZERO:
		spike_normal = Vector2.UP

	# 计算水平横向弹开方向：根据玩家相对于突刺中心的X位置远离刺中心
	var horiz_dir: float = 1.0
	if player.global_position.x < global_position.x:
		horiz_dir = -1.0
	elif player.global_position.x > global_position.x:
		horiz_dir = 1.0
	else:
		horiz_dir = -1.0 if ("face_dir" in player and player.face_dir > 0) else 1.0

	var knockback_dir: Vector2 = Vector2.ZERO
	# 若突刺基本朝上（地面），合成斜向上方的挑飞击退
	if spike_normal.y < -0.3:
		knockback_dir = Vector2(horiz_dir * 0.7, -0.85).normalized()
	# 若突刺基本朝下（顶部），向下并向外弹开
	elif spike_normal.y > 0.3:
		knockback_dir = Vector2(horiz_dir * 0.7, 0.7).normalized()
	# 若突刺在左右墙壁（壁刺），主要沿刺法线向外推，并给予适度向上弹跳
	else:
		knockback_dir = Vector2(spike_normal.x * 0.85, -0.55).normalized()
	
	var knockback_vector: Vector2 = knockback_dir * knockback_force
	
	if player.has_method("ApplyDamage"):
		player.ApplyDamage(damage, knockback_vector)
	elif player.has_method("be_hurted"):
		player.be_hurted(damage)
	
	if SignalBus:
		SignalBus.SpikesTriggered.emit(self, player)

## 实体数据导出
func ExportSaveData() -> Dictionary:
	return {
		"position_x": global_position.x,
		"position_y": global_position.y,
		"rotation": rotation,
		"is_extended": _is_extended
	}

## 实体数据加载
## @param data 存档字典
func LoadSaveData(data: Dictionary) -> void:
	if data.has("position_x") and data.has("position_y"):
		global_position = Vector2(data["position_x"], data["position_y"])
	if data.has("rotation"):
		rotation = data["rotation"]
	if data.has("is_extended"):
		_is_extended = data["is_extended"]
		spike_moving_root.position.y = -spikes_size.y if _is_extended else 0.0
		spike_collision.set_deferred("disabled", not _is_extended)

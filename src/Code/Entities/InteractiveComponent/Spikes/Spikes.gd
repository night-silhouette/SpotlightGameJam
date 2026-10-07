extends Area2D
class_name Spikes

## =============================================================================
## Spikes.gd - 通用地刺/壁刺/顶刺交互组件
## 可放置在地面、墙面或顶部（支持按 rotation 自由调整朝向）
## 触碰后对玩家造成大量伤害并按刺的法线/背离方向击退，通过 SignalBus 派发事件
## =============================================================================

@export_category("Spikes Settings")
## 尖刺伤害量
@export var damage: float = 40.0
## 击退力大小 (像素/秒)
@export var knockback_force: float = 400.0
## 尖刺覆盖尺寸 (宽度, 高度)
@export var spikes_size: Vector2 = Vector2(32.0, 16.0):
	set(value):
		spikes_size = value
		_update_dimensions()

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var visual_polygon: Polygon2D = $VisualPolygon

func _ready() -> void:
	_sync_from_export_settings()
	_update_dimensions()
	body_entered.connect(_on_body_entered)

func _sync_from_export_settings() -> void:
	if ExportSettings:
		damage = ExportSettings.spikes_damage
		knockback_force = ExportSettings.spikes_knockback_force

func _update_dimensions() -> void:
	if not is_inside_tree():
		return
	
	if collision_shape:
		var rect = RectangleShape2D.new()
		rect.size = spikes_size
		collision_shape.shape = rect
		# 碰撞形状中心位于底座上方 spikes_size.y * 0.5 处（局部坐标Y轴负方向向上）
		collision_shape.position = Vector2(0.0, -spikes_size.y * 0.5)

	if visual_polygon:
		# 生成锯齿状尖刺多边形，底部在 Y=0，刺尖在 Y=-spikes_size.y
		var points = PackedVector2Array()
		var count: int = max(2, int(spikes_size.x / 8.0))
		var step: float = spikes_size.x / float(count)
		var start_x: float = -spikes_size.x * 0.5
		
		points.append(Vector2(start_x, 0.0))
		for i in range(count):
			var seg_x: float = start_x + i * step
			var tip_x: float = seg_x + step * 0.5
			var next_x: float = seg_x + step
			points.append(Vector2(tip_x, -spikes_size.y))
			points.append(Vector2(next_x, 0.0))
		visual_polygon.polygon = points

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") or body is CharacterBody2D:
		_trigger_spike_damage(body)

func _trigger_spike_damage(player: Node2D) -> void:
	# 尖刺向外的法线方向（局部坐标-Y轴对应尖刺尖端朝向）
	var spike_normal: Vector2 = -global_transform.y.normalized()
	if spike_normal == Vector2.ZERO:
		spike_normal = Vector2.UP

	# 计算水平横向弹开方向：根据玩家相对于尖刺中心的X位置远离刺中心
	var horiz_dir: float = 1.0
	if player.global_position.x < global_position.x:
		horiz_dir = -1.0
	elif player.global_position.x > global_position.x:
		horiz_dir = 1.0
	else:
		# 正中心时按玩家反方向弹开
		horiz_dir = -1.0 if ("face_dir" in player and player.face_dir > 0) else 1.0

	var knockback_dir: Vector2 = Vector2.ZERO
	# 若尖刺基本朝上（地面地刺），合成斜向上方的挑飞击退
	if spike_normal.y < -0.3:
		knockback_dir = Vector2(horiz_dir * 0.7, -0.85).normalized()
	# 若尖刺基本朝下（顶刺），向下并向外弹开
	elif spike_normal.y > 0.3:
		knockback_dir = Vector2(horiz_dir * 0.7, 0.7).normalized()
	# 若尖刺在左右墙壁（壁刺），主要沿刺法线向外推，并给予适度向上弹跳
	else:
		knockback_dir = Vector2(spike_normal.x * 0.85, -0.55).normalized()

	var knockback_vector: Vector2 = knockback_dir * knockback_force
	
	# 若实体具备 ApplyDamage 方法直接调用，附带击退冲量
	if player.has_method("ApplyDamage"):
		player.ApplyDamage(damage, knockback_vector)
	elif player.has_method("be_hurted"):
		player.be_hurted(damage)
	
	# 实体解耦：通过 SignalBus 发送全局事件
	if SignalBus:
		SignalBus.SpikesTriggered.emit(self, player)

## 实体数据导出
func ExportSaveData() -> Dictionary:
	return {
		"position_x": global_position.x,
		"position_y": global_position.y,
		"rotation": rotation
	}

## 实体数据加载
## @param data 存档字典
func LoadSaveData(data: Dictionary) -> void:
	if data.has("position_x") and data.has("position_y"):
		global_position = Vector2(data["position_x"], data["position_y"])
	if data.has("rotation"):
		rotation = data["rotation"]

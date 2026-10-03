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
	# 击退方向优先使用人物当前运动速度的反方向 (-velocity)
	var knockback_dir: Vector2 = Vector2.ZERO
	if "velocity" in player and (player.velocity as Vector2).length_squared() > 100.0:
		knockback_dir = -player.velocity.normalized()
	else:
		# 若玩家当前速度几乎为零（例如静止受击），则使用背离尖刺的朝向或尖刺法线向外击退
		var relative_dir: Vector2 = (player.global_position - global_position).normalized()
		var outward_dir: Vector2 = -global_transform.y.normalized()
		knockback_dir = outward_dir if outward_dir != Vector2.ZERO else relative_dir
		if knockback_dir == Vector2.ZERO:
			knockback_dir = Vector2.UP

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

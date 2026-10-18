extends InteractableComponent
class_name Tent

## 帐篷重生点：玩家靠近时可点击帐篷碰撞区域激活。
## 激活后广播全局 TentActivated 信号，其他帐篷自动取消激活。

@export_category("Tent Settings")
## 是否在初始时即为当前激活的重生点
@export var is_active: bool = false:
	set(value):
		is_active = value
		if is_node_ready():
			_update_visual_state()

## 重生点相对帐篷的局部位置偏移
@export var respawn_offset: Vector2 = Vector2.ZERO

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var tent_sprite: CanvasItem = $TentVisual
@onready var light_glow: PointLight2D = $LightGlow

var _glow_tween: Tween = null

func _ready() -> void:
	super._ready()
	_sync_from_export_settings()
	SignalBus.TentActivated.connect(_on_tent_activated_externally)
	_update_visual_state()

func Interact(interactor: Node2D) -> bool:
	if not super.Interact(interactor):
		return false
	ActivateTent()
	return true

func _sync_from_export_settings() -> void:
	if ExportSettings:
		if "tent_respawn_offset" in ExportSettings:
			respawn_offset = ExportSettings.tent_respawn_offset
		if "tent_interaction_size" in ExportSettings and collision_shape and collision_shape.shape is RectangleShape2D:
			(collision_shape.shape as RectangleShape2D).size = ExportSettings.tent_interaction_size

## 激活当前帐篷为重生点。
func ActivateTent() -> void:
	is_active = true
	_update_visual_state()
	var spawn_pos = GetRespawnPosition()
	if SignalBus:
		SignalBus.TentActivated.emit(self, spawn_pos)

## 获取此帐篷对应的全局重生位置。
## @return 重生点的世界坐标。
func GetRespawnPosition() -> Vector2:
	return global_position + respawn_offset

func _on_tent_activated_externally(tent_node: Node2D, _spawn_pos: Vector2) -> void:
	if tent_node != self:
		if is_active:
			is_active = false
			_update_visual_state()

func _update_visual_state() -> void:
	if not is_inside_tree():
		return
	if _glow_tween and _glow_tween.is_valid():
		_glow_tween.kill()

	# 更新光照与呼吸动画
	if light_glow:
		light_glow.enabled = is_active
	if is_active:
		if light_glow:
			_glow_tween = create_tween().set_loops()
			_glow_tween.tween_property(light_glow, "energy", 1.4, 0.8).set_trans(Tween.TRANS_SINE)
			_glow_tween.tween_property(light_glow, "energy", 0.8, 0.8).set_trans(Tween.TRANS_SINE)

## 导出帐篷持久化数据。
## @return 位置、重生偏移和激活状态组成的字典。
func ExportSaveData() -> Dictionary:
	var data := super.ExportSaveData()
	data.merge({
		"position_x": global_position.x,
		"position_y": global_position.y,
		"respawn_offset_x": respawn_offset.x,
		"respawn_offset_y": respawn_offset.y,
		"respawn_world_x": GetRespawnPosition().x,
		"respawn_world_y": GetRespawnPosition().y,
		"is_active": is_active
	})
	return data

## 加载帐篷持久化数据。
## @param data 存档字典。
func LoadSaveData(data: Dictionary) -> void:
	super.LoadSaveData(data)
	if data.has("position_x") and data.has("position_y"):
		global_position = Vector2(data["position_x"], data["position_y"])
	if data.has("respawn_offset_x") and data.has("respawn_offset_y"):
		respawn_offset = Vector2(data["respawn_offset_x"], data["respawn_offset_y"])
	if data.has("is_active"):
		is_active = data["is_active"]
		_update_visual_state()
		if is_active and SignalBus:
			SignalBus.TentActivated.emit(self, GetRespawnPosition())

extends Area2D
## 可删除的房间固定镜头触发区。通过信号使用现有主镜头，不创建 Camera2D。
## TriggerShape 是进入范围；ViewTopLeft/ViewBottomRight 是房间取景边界。
@onready var _trigger: CollisionShape2D = $TriggerShape
@onready var _top_left: Marker2D = $ViewTopLeft
@onready var _bottom_right: Marker2D = $ViewBottomRight
@onready var _anchor: Marker2D = $CameraAnchor
var _player: Node2D
var _inside: bool = false
var _owns_shot: bool = false
var _sending: bool = false
var _viewport_size := Vector2.ZERO

func _ready() -> void:
	SignalBus.PlayerDied.connect(_on_player_died)
	SignalBus.PlayerRespawned.connect(_on_respawned)
	SignalBus.SaveSlotLoaded.connect(_on_save_loaded)
	SignalBus.CameraShotRequested.connect(_on_other_shot)
	SignalBus.CameraNormalRequested.connect(_on_other_request)
	SignalBus.CameraFixedRequested.connect(func(p: Node2D, _a: Node2D, _t: String, _s: String, _b: Rect2): _on_other_request(p))
	SignalBus.CameraRitualRequested.connect(func(p: Node2D, _a: Node2D, _t: String, _s: String, _b: Rect2): _on_other_request(p))
	SignalBus.CameraDescentRequested.connect(func(p: Node2D, _t: String, _s: String, _b: Rect2): _on_other_request(p))
	SignalBus.CameraDesertRequested.connect(func(p: Node2D, _t: String, _s: String, _i: bool, _b: Rect2): _on_other_request(p))
	SignalBus.CameraBoatRequested.connect(func(p: Node2D, _a: Node2D, _t: String, _s: String, _b: Rect2): _on_other_request(p))

func _physics_process(_delta: float) -> void:
	if not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group(&"player") as Node2D
		_inside = false
		_owns_shot = false
	if not is_instance_valid(_player):
		return
	if not ExportSettings.room_camera_zone_enabled or _trigger.disabled or float(_player.get("now_HP")) <= 0.0:
		_release()
		_inside = false
		return
	if not _trigger.shape is RectangleShape2D:
		return
	var shape := _trigger.shape as RectangleShape2D
	var area := Rect2(-shape.size * 0.5, shape.size)
	if _inside:
		area = area.grow(maxf(0.0, ExportSettings.room_camera_zone_exit_margin))
	var contained := area.has_point(_trigger.to_local(_player.global_position))
	if contained and not _inside:
		_inside = true
		_request_fixed()
	elif not contained and _inside:
		_inside = false
		_release()
	elif _owns_shot and get_viewport_rect().size != _viewport_size:
		_request_fixed()

func _request_fixed() -> void:
	var bounds := Rect2(_top_left.global_position, _bottom_right.global_position - _top_left.global_position).abs()
	if not bounds.has_area():
		return
	_viewport_size = get_viewport_rect().size
	# 画面限制在取景框内并贴住左上角；等比放大，屏幕比例不同时裁掉右侧或底部。
	var zoom_value := maxf(0.05, maxf(_viewport_size.x / bounds.size.x, _viewport_size.y / bounds.size.y))
	var visible_size := _viewport_size / zoom_value
	var view := Rect2(bounds.position, visible_size)
	_anchor.global_position = view.get_center()
	_owns_shot = true
	_sending = true
	SignalBus.CameraShotRequested.emit(_player, &"fixed", {
		"anchor": _anchor, "bounds": view, "intro": false,
		"zoom": zoom_value, "transition_duration": ExportSettings.room_camera_zone_transition_time,
	})
	_sending = false

func _release() -> void:
	if _owns_shot and is_instance_valid(_player):
		_owns_shot = false
		SignalBus.CameraNormalRequested.emit(_player)

func _on_other_shot(player: Node2D, _mode: StringName, _options: Dictionary) -> void:
	_on_other_request(player)

func _on_other_request(player: Node2D) -> void:
	# 剧情、喷泉等镜头接管后不逐帧抢回，也不在离区时覆盖它们。
	if player == _player and not _sending:
		_owns_shot = false

func _on_player_died(player: Node2D) -> void:
	if player == _player:
		_release()
		_inside = false

func _on_respawned(_position: Vector2) -> void:
	# 主镜头先完成重生复位，下一物理帧按新的位置重新判定。
	call_deferred("_reset_membership")

func _on_save_loaded(_slot: int) -> void:
	call_deferred("_reset_membership")

func _reset_membership() -> void:
	_release()
	_inside = false

func _exit_tree() -> void:
	_release()

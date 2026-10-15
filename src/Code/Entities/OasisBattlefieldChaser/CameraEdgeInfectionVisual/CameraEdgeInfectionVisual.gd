extends Node2D
class_name CameraEdgeInfectionVisual

## 视觉完全取决于物理追逐体的真实边界，不自行累计追赶进度。
const MIN_ZOOM: float = 0.0001
const MIN_VISIBLE_DEPTH: float = 0.001

@export_category("Camera Edge Infection Visual")
@export var mover_path: NodePath = NodePath("../DirectionalChaseMover")
## 可选的玩家路径；留空时自动读取 player 分组。
@export var target_path: NodePath
@export_range(1.0, 1.5, 0.01) var viewport_size_multiplier: float = 1.1
## 垂直于追逐方向的最小尺寸倍率，确保玩家看不到贴图上下边界。
@export_range(2.0, 3.0, 0.05) var cross_axis_overscan: float = 2.0
## 目标位于镜头边缘时，贴图边界仍额外留在屏幕外的世界单位。
@export_range(0.0, 1024.0, 1.0) var boundary_safe_margin: float = 160.0
@export var appearance_depth: float = 0.0
@export var inward_depth_offset: float = 0.0
@export var edge_axis_offset: float = 0.0
@export var mask_color: Color = Color.BLACK
@export_range(-4096, 4096, 1) var visual_depth: int = 80

@onready var _black_mask: Polygon2D = $BlackMask
@onready var _boss_animation: AnimatedSprite2D = $BossAnimation
var _mover: DirectionalChaseMover = null
var _target: Node2D = null

func _ready() -> void:
	_mover = get_node_or_null(mover_path) as DirectionalChaseMover
	_target = _resolve_target()
	z_index = visual_depth
	visible = false
	_black_mask.color = mask_color
	if not SignalBus.ChaseMoverActiveChanged.is_connected(_on_mover_active_changed):
		SignalBus.ChaseMoverActiveChanged.connect(_on_mover_active_changed)

func _physics_process(_delta: float) -> void:
	if not is_instance_valid(_mover):
		_mover = get_node_or_null(mover_path) as DirectionalChaseMover
	if not is_instance_valid(_mover) or not bool(_mover.get("_active")):
		visible = false
		return
	var camera := get_viewport().get_camera_2d()
	if camera == null:
		visible = false
		return
	var camera_rect := _get_camera_world_rect(camera)
	if not is_instance_valid(_target):
		_target = _resolve_target()
	var direction := _get_cardinal_direction(_mover.movement_direction)
	var target_position := camera_rect.get_center() if not is_instance_valid(_target) else _target.global_position
	var layout := CalculateVisualLayout(camera_rect, direction, CalculatePhysicalFront(direction), target_position)
	if not bool(layout["visible"]):
		visible = false
		return
	global_position = camera_rect.get_center()
	_boss_animation.position = Vector2(layout["position"]) - global_position
	_boss_animation.scale = Vector2(layout["scale"])
	_black_mask.polygon = _world_polygon_to_local(PackedVector2Array(layout["mask_polygon"]))
	_black_mask.color = mask_color
	visible = true

## 返回碰撞矩形沿追逐方向的真实世界前沿坐标。
func CalculatePhysicalFront(direction: Vector2) -> float:
	if not is_instance_valid(_mover):
		return 0.0
	var collision := _mover.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision != null and collision.shape is RectangleShape2D:
		var half_size := (collision.shape as RectangleShape2D).size * 0.5
		var corners := [Vector2(-half_size.x, -half_size.y), Vector2(half_size.x, -half_size.y), Vector2(half_size.x, half_size.y), Vector2(-half_size.x, half_size.y)]
		var front := -INF
		for corner in corners:
			front = maxf(front, collision.to_global(corner).dot(direction))
		return front
	return _mover.global_position.dot(direction)

## 仅由物理前沿和摄像机边界计算显隐、动画位置与后方黑色遮罩。
func CalculateVisualLayout(camera_rect: Rect2, chase_direction: Vector2, physical_front: float, target_position: Vector2 = Vector2.INF) -> Dictionary:
	var direction := _get_cardinal_direction(chase_direction)
	if not target_position.is_finite():
		target_position = camera_rect.get_center()
	var texture_size := _get_animation_texture_size()
	var visual_size := camera_rect.size * maxf(viewport_size_multiplier, 0.01)
	if absf(direction.x) > 0.0:
		visual_size.y = maxf(visual_size.y, camera_rect.size.y * cross_axis_overscan + boundary_safe_margin * 2.0)
	else:
		visual_size.x = maxf(visual_size.x, camera_rect.size.x * cross_axis_overscan + boundary_safe_margin * 2.0)
	var sprite_scale := Vector2(visual_size.x / maxf(texture_size.x, 1.0), visual_size.y / maxf(texture_size.y, 1.0))
	var center := camera_rect.get_center()
	var depth: float
	var front: float
	var mask := Rect2()
	var edge: StringName
	if direction == Vector2.RIGHT:
		edge = &"left"
		depth = physical_front - camera_rect.position.x - appearance_depth
		front = physical_front + inward_depth_offset
		center = Vector2(front - visual_size.x * 0.5, target_position.y + edge_axis_offset)
		var mask_end := clampf(front, camera_rect.position.x, camera_rect.end.x)
		mask = Rect2(camera_rect.position, Vector2(mask_end - camera_rect.position.x, camera_rect.size.y))
	elif direction == Vector2.LEFT:
		edge = &"right"
		depth = camera_rect.end.x - physical_front - appearance_depth
		front = physical_front - inward_depth_offset
		center = Vector2(front + visual_size.x * 0.5, target_position.y + edge_axis_offset)
		var mask_start := clampf(front, camera_rect.position.x, camera_rect.end.x)
		mask = Rect2(Vector2(mask_start, camera_rect.position.y), Vector2(camera_rect.end.x - mask_start, camera_rect.size.y))
	elif direction == Vector2.DOWN:
		edge = &"top"
		depth = physical_front - camera_rect.position.y - appearance_depth
		front = physical_front + inward_depth_offset
		center = Vector2(target_position.x + edge_axis_offset, front - visual_size.y * 0.5)
		var mask_end := clampf(front, camera_rect.position.y, camera_rect.end.y)
		mask = Rect2(camera_rect.position, Vector2(camera_rect.size.x, mask_end - camera_rect.position.y))
	else:
		edge = &"bottom"
		depth = camera_rect.end.y - physical_front - appearance_depth
		front = physical_front - inward_depth_offset
		center = Vector2(target_position.x + edge_axis_offset, front + visual_size.y * 0.5)
		var mask_start := clampf(front, camera_rect.position.y, camera_rect.end.y)
		mask = Rect2(Vector2(camera_rect.position.x, mask_start), Vector2(camera_rect.size.x, camera_rect.end.y - mask_start))
	return {"visible": depth > MIN_VISIBLE_DEPTH, "edge": edge, "position": center, "scale": sprite_scale, "physical_front": physical_front, "intrusion_depth": depth, "mask_rect": mask, "mask_polygon": _rect_to_polygon(mask), "cardinal_direction": direction}

func _resolve_target() -> Node2D:
	if not target_path.is_empty():
		var explicit_target := get_node_or_null(target_path) as Node2D
		if explicit_target != null:
			return explicit_target
	return get_tree().get_first_node_in_group("player") as Node2D

func _get_camera_world_rect(camera: Camera2D) -> Rect2:
	var safe_zoom := Vector2(maxf(absf(camera.zoom.x), MIN_ZOOM), maxf(absf(camera.zoom.y), MIN_ZOOM))
	var world_size := get_viewport().get_visible_rect().size / safe_zoom
	return Rect2(camera.get_screen_center_position() - world_size * 0.5, world_size)

func _get_cardinal_direction(direction: Vector2) -> Vector2:
	if direction.is_zero_approx():
		return Vector2.RIGHT
	if absf(direction.x) >= absf(direction.y):
		return Vector2.RIGHT if direction.x >= 0.0 else Vector2.LEFT
	return Vector2.DOWN if direction.y >= 0.0 else Vector2.UP

func _get_animation_texture_size() -> Vector2:
	if _boss_animation == null or _boss_animation.sprite_frames == null:
		return Vector2.ONE
	var texture := _boss_animation.sprite_frames.get_frame_texture(&"default", 0)
	return Vector2.ONE if texture == null else Vector2(texture.get_size())

func _rect_to_polygon(rect: Rect2) -> PackedVector2Array:
	return PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)])

func _world_polygon_to_local(points: PackedVector2Array) -> PackedVector2Array:
	var result := PackedVector2Array()
	for point in points:
		result.append(to_local(point))
	return result

func _on_mover_active_changed(mover_node: Node2D, active: bool) -> void:
	if mover_node == _mover and not active:
		visible = false
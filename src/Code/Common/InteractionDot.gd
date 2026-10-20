extends Node2D
class_name InteractionDot
## 实体中心的普通交互提示圆点；不发光，不参与照明。

@onready var _entity: Node2D = get_parent() as Node2D

var _dot_texture: GradientTexture2D

func _ready() -> void:
	top_level = true
	process_mode = Node.PROCESS_MODE_ALWAYS
	z_index = 20
	var dot_material := CanvasItemMaterial.new()
	dot_material.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	material = dot_material
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.3, 1.0])
	gradient.colors = PackedColorArray([Color.WHITE, Color(1.0, 1.0, 1.0, 0.8), Color(1.0, 1.0, 1.0, 0.0)])
	_dot_texture = GradientTexture2D.new()
	_dot_texture.gradient = gradient
	_dot_texture.width = 64
	_dot_texture.height = 64
	_dot_texture.fill = GradientTexture2D.FILL_RADIAL
	_dot_texture.fill_from = Vector2(0.5, 0.5)
	_dot_texture.fill_to = Vector2(1.0, 0.5)
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_update_dot()

func _process(_delta: float) -> void:
	_update_dot()

func _update_dot() -> void:
	visible = ExportSettings.interaction_dot_enabled and not _entity.get_meta("interaction_dot_hidden", false) and _entity.is_visible_in_tree() and _entity.can_process()
	if "enable_interaction" in _entity:
		visible = visible and _entity.enable_interaction
	elif "is_available" in _entity:
		visible = visible and _entity.is_available
	elif "available" in _entity:
		visible = visible and _entity.available
	if not visible:
		return
	var source: Node2D = _entity
	var bounds := Rect2()
	if _entity is MiniChaliceStation:
		if not _entity.is_node_ready():
			visible = false
			return
		var art := _entity.get_node("AnimatedSprite2D") as AnimatedSprite2D
		source = art
		bounds = _entity.GetInteractionRect()
		visible = art.is_visible_in_tree() and bounds.has_area()
	elif "area_size" in _entity:
		bounds = Rect2(-_entity.area_size * 0.5, _entity.area_size)
	else:
		var sprite := _find_sprite(_entity)
		if sprite != null:
			source = sprite
			bounds = sprite.get_rect()
			visible = sprite.is_visible_in_tree() and sprite.texture != null
		elif "available" in _entity:
			var visual := _entity.get_node("Visual") as Polygon2D
			source = visual
			visible = visual.is_visible_in_tree() and not visual.polygon.is_empty()
			if not visual.polygon.is_empty():
				bounds = Rect2(visual.polygon[0], Vector2.ZERO)
				for point in visual.polygon:
					bounds = bounds.expand(point)
		else:
			var collision := _entity.get_node_or_null("CollisionShape2D") as CollisionShape2D
			if collision != null and collision.shape != null:
				source = collision
				bounds = collision.shape.get_rect()
	global_transform = Transform2D(0.0, source.to_global(bounds.get_center()))
	queue_redraw()

func _find_sprite(entity: Node2D) -> Sprite2D:
	# 只检查实体自身及明确的设备美术路径，不遍历关卡或 UI。
	for path in ["ItemArt", "Sprite2D", "Node2D/FountainIdle"]:
		var sprite := entity.get_node_or_null(path) as Sprite2D
		if sprite != null:
			return sprite
	if not "available" in entity:
		for child in entity.get_children():
			if child is Sprite2D:
				return child as Sprite2D
	if entity is Sprite2D:
		return entity as Sprite2D
	if entity.get_parent() is Sprite2D:
		return entity.get_parent() as Sprite2D
	return null

func _draw() -> void:
	var radius: float = ExportSettings.interaction_dot_radius
	draw_texture_rect(_dot_texture, Rect2(Vector2(-radius, -radius), Vector2.ONE * radius * 2.0), false, ExportSettings.interaction_dot_color)

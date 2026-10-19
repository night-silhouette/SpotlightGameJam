extends Node2D
## 只增强第二关角色与实体书本的可读性，不改人物材质、碰撞或存档。
const PLAYER_MASK: int = 262144
const BOOK_MASK: int = 524288
const BOOK_SHADER: Shader = preload("res://Code/Entities/World/DepthsLibrary/Level2/Lighting/BookReadability.gdshader")
@onready var _settings: Node = get_node("/root/ExportSettings")
@onready var _lighting: Node = get_parent()
@onready var _player_fill: PointLight2D = $PlayerFill
@onready var _book_fill: PointLight2D = $BookFill
@onready var _player_rim: PointLight2D = $PlayerRim
var _targets: Dictionary = {}
var _scan_time: float = 0.0

func _ready() -> void:
	_scan_targets.call_deferred()

func _process(delta: float) -> void:
	_scan_time -= delta
	if _scan_time <= 0.0:
		_scan_time = 2.0
		_scan_targets()
	var amount: float = _lighting._darkness if _settings.level2_readability_enabled else 0.0
	_player_fill.enabled = amount > 0.001
	_book_fill.enabled = amount > 0.001
	_player_fill.color = _settings.level2_readability_fill_color
	_book_fill.color = _settings.level2_readability_fill_color
	_player_fill.energy = _settings.level2_readability_player_energy * amount
	_book_fill.energy = _settings.level2_readability_book_energy * amount
	var player: Node2D = _lighting._player
	_player_rim.enabled = amount > 0.001 and is_instance_valid(player)
	if is_instance_valid(player):
		_player_rim.global_position = player.global_position + _settings.level2_readability_rim_offset
	_player_rim.color = _settings.level2_readability_fill_color
	_player_rim.energy = _settings.level2_readability_rim_energy * amount
	_player_rim.texture_scale = _settings.level2_readability_rim_radius / 128.0
	for sprite in _targets:
		if not is_instance_valid(sprite):
			continue
		var material: ShaderMaterial = _targets[sprite].material
		if material != null:
			material.set_shader_parameter("edge_strength", _settings.level2_readability_book_edge_strength * amount)
			material.set_shader_parameter("edge_texels", _settings.level2_readability_book_edge_width / maxf(absf(sprite.global_scale.y), 0.001))

func _scan_targets() -> void:
	if not is_instance_valid(_lighting._level) or get_tree().current_scene == null:
		return
	var candidates: Dictionary = {}
	var player := get_tree().get_first_node_in_group("player")
	if player != null:
		var visual := player.get_node_or_null("sprite")
		if visual != null:
			for sprite in visual.find_children("*", "Sprite2D", true, false):
				candidates[sprite] = PLAYER_MASK
	# World contains hand-placed platforms outside Level2Map's subtree.
	for sprite: Sprite2D in get_tree().current_scene.find_children("*", "Sprite2D", true, false):
		if sprite.texture == null:
			continue
		var room: Node2D = _lighting._level.GetRoomAt(sprite.global_position)
		# The surface entrance overlaps camp props; leave those authored colors alone.
		if room == null or room.name == &"EntryCollapse":
			continue
		var filename := sprite.texture.resource_path.get_file()
		if not filename.begins_with("prop_book_") and not filename.begins_with("prop_paper_scroll_rolled"):
			continue
		var ancestor := sprite.get_parent()
		while ancestor != null and not ancestor is PhysicsBody2D:
			ancestor = ancestor.get_parent()
		if ancestor != null:
			candidates[sprite] = BOOK_MASK
	for sprite in _targets.keys():
		if not is_instance_valid(sprite):
			_targets.erase(sprite)
			continue
		if not candidates.has(sprite):
			_restore_target(sprite)
			_targets.erase(sprite)
	for sprite: Sprite2D in candidates:
		if _targets.has(sprite):
			continue
		var mask: int = candidates[sprite]
		var material: ShaderMaterial = null
		# Dissolving platforms and inherited custom materials keep their shaders.
		if mask == BOOK_MASK and sprite.material == null and not sprite.use_parent_material:
			material = ShaderMaterial.new()
			material.shader = BOOK_SHADER
			sprite.material = material
		_targets[sprite] = {"added_mask": mask & ~sprite.light_mask, "material": material}
		sprite.light_mask |= mask

func _restore_target(sprite: Sprite2D) -> void:
	if not is_instance_valid(sprite):
		return
	sprite.light_mask &= ~int(_targets[sprite].added_mask)
	if _targets[sprite].material != null and sprite.material == _targets[sprite].material:
		sprite.material = null

func _exit_tree() -> void:
	for sprite in _targets:
		if is_instance_valid(sprite):
			_restore_target(sprite)
	_targets.clear()

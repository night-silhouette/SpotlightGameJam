extends Node2D

const DIRT_TEXTURES: Array[Texture2D] = [
	preload("res://Art/New/map1/back/dirt1.png"),
	preload("res://Art/New/map1/back/dirt2.png"),
]

@onready var _background_layers: Array[TileMapLayer] = [
	$"../TileMapLayer2",
	$"../TileMapLayer3",
]


func _ready() -> void:
	_build_wall_decorations()


func _build_wall_decorations() -> void:
	for layer_index in range(_background_layers.size()):
		var background_layer := _background_layers[layer_index]
		if not is_instance_valid(background_layer):
			continue
		for cell in background_layer.get_used_cells():
			var random := _make_cell_random(layer_index, cell)
			if random.randf() < ExportSettings.sunken_wall_detail_chance:
				_add_wall_detail(background_layer, cell, layer_index, random)


func _make_cell_random(layer_index: int, cell: Vector2i) -> RandomNumberGenerator:
	var random := RandomNumberGenerator.new()
	var cell_seed := (
		ExportSettings.sunken_wall_decoration_seed
		+ layer_index * 92821
		+ cell.x * 68917
		+ cell.y * 31337
	)
	random.seed = absi(cell_seed)
	return random


func _add_wall_detail(
	background_layer: TileMapLayer,
	cell: Vector2i,
	layer_index: int,
	random: RandomNumberGenerator
) -> void:
	var detail := Sprite2D.new()
	detail.name = "Dirt_%d_%d_%d" % [layer_index, cell.x, cell.y]
	detail.texture = DIRT_TEXTURES[random.randi_range(0, DIRT_TEXTURES.size() - 1)]

	var tile_size := Vector2(background_layer.tile_set.tile_size)
	var offset_ratio := ExportSettings.sunken_wall_detail_offset_ratio
	var random_offset := Vector2(
		random.randf_range(-tile_size.x * offset_ratio.x, tile_size.x * offset_ratio.x),
		random.randf_range(-tile_size.y * offset_ratio.y, tile_size.y * offset_ratio.y)
	)
	detail.position = _cell_position(background_layer, cell, random_offset)
	var scale_factor := random.randf_range(
		minf(
			ExportSettings.sunken_wall_detail_scale_range.x,
			ExportSettings.sunken_wall_detail_scale_range.y
		),
		maxf(
			ExportSettings.sunken_wall_detail_scale_range.x,
			ExportSettings.sunken_wall_detail_scale_range.y
		)
	)
	detail.scale = background_layer.scale * scale_factor
	detail.rotation = background_layer.rotation + deg_to_rad(random.randf_range(-6.0, 6.0))
	var detail_modulate := background_layer.self_modulate
	detail_modulate.a *= random.randf_range(0.58, 0.82)
	detail.self_modulate = detail_modulate
	add_child(detail)


func _cell_position(
	background_layer: TileMapLayer,
	cell: Vector2i,
	local_offset: Vector2 = Vector2.ZERO
) -> Vector2:
	return background_layer.transform * (background_layer.map_to_local(cell) + local_offset)

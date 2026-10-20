extends Node2D
## 独立墙上火把：预置逐帧动画、点光源和柔光，不参与碰撞或存档。
func _ready() -> void:
	var settings := get_node_or_null("/root/ExportSettings")
	if settings == null:
		return
	visible = settings.level2_wall_torch_enabled
	var flame: AnimatedSprite2D = $Flame
	flame.scale = Vector2.ONE * settings.level2_wall_torch_art_scale
	flame.sprite_frames = flame.sprite_frames.duplicate()
	flame.sprite_frames.set_animation_speed(&"burn", settings.level2_wall_torch_fps)
	flame.play(&"burn")
	var light: PointLight2D = $WarmLight
	light.enabled = visible
	light.color = settings.level2_wall_torch_color
	light.energy = settings.level2_wall_torch_energy
	light.texture_scale = settings.level2_wall_torch_radius / 128.0
	var glow: Sprite2D = $SoftGlow
	glow.modulate = Color(light.color, settings.level2_wall_torch_glow_opacity)
	glow.scale = Vector2.ONE * settings.level2_wall_torch_radius * 0.3 / 128.0

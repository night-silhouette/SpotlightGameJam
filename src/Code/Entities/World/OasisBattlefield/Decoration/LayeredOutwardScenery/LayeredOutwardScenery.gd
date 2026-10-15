extends Node2D

## Keeps non-repeating Parallax2D layers aligned with this scene when it is
## instanced below the level's translated world root. Sprite transforms remain
## authored directly in the scene and no whole-layer per-frame work is used.


func _enter_tree() -> void:
	_align_parallax_layers()


func _align_parallax_layers() -> void:
	for child in get_children():
		if child is Parallax2D:
			child.top_level = true
			child.scroll_offset = global_position * child.scroll_scale

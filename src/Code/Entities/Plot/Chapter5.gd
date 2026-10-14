extends "res://Code/Entities/Plot/Chapter2.gd"

func _on_body_entered(body: Node2D, index: int) -> void:
	var trigger := get_child(index) as InteractableComponent
	if trigger == null or not body.is_in_group("player"):
		return
	# 初始营地也会加载本场景。持有枯骨才算从绿洲返程，避免抢播第一章。
	if index != 0 or not bool(body.get("has_scarred_bones")):
		return
	super._on_body_entered(body, index)

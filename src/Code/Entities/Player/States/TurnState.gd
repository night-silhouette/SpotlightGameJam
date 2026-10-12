extends State

@onready var turn_sprite: Sprite2D = get_parent().get_parent().get_node("sprite/Trun")

func _ready() -> void:
	turn_sprite.visible = false

func enter() -> void:
	if animation_player:
		if not animation_player.animation_finished.is_connected(_on_animation_finished):
			animation_player.animation_finished.connect(_on_animation_finished)
		animation_player.play("turn")
		animation_player.advance(0.0)
	turn_sprite.visible = true
	obj.PlayFootstepTurnSFX()

func exit() -> void:
	if animation_player and animation_player.animation_finished.is_connected(_on_animation_finished):
		animation_player.animation_finished.disconnect(_on_animation_finished)
	turn_sprite.visible = false

func _on_animation_finished(animation_name: StringName) -> void:
	if animation_name == &"turn" and state_machine.current_state == self:
		finished.emit("fall" if not obj.is_on_floor() else "run" if gameInputControl.row_dir != 0.0 else "idle")

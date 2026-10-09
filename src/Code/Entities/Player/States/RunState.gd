extends State

func enter() -> void:
	if animation_player:
		animation_player.play("run")
		if not animation_player.animation_finished.is_connected(_on_animation_finished):
			animation_player.animation_finished.connect(_on_animation_finished)
	_check_turn()

func exit() -> void:
	if animation_player and animation_player.animation_finished.is_connected(_on_animation_finished):
		animation_player.animation_finished.disconnect(_on_animation_finished)

func physics_process(_delta: float) -> void:
	_check_turn()

func _check_turn() -> void:
	if animation_player and obj.is_on_floor() and gameInputControl.row_dir != 0.0 \
			and sign(gameInputControl.row_dir) != obj.face_dir \
			and animation_player.current_animation != "turn":
		animation_player.play("turn")

func _on_animation_finished(animation_name: StringName) -> void:
	if animation_name == &"turn" and state_machine.current_state == self:
		animation_player.play("run")

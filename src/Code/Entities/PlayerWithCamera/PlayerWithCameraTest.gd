extends Node2D
## Test-only wrapper; original player abilities are unchanged.
@export var restrict_test_abilities: bool = true

func _ready() -> void:
	if not restrict_test_abilities:
		return
	var player: Player = $PlayerWithCamera/Player
	player.enable_double_jump = false
	player.max_double_jumps = 0
	player.ResetDoubleJump()
	player.rope_controller.process_mode = Node.PROCESS_MODE_DISABLED
	player.rope_controller.can_use_rope = false

extends Camera2D

@export var move_speed: float = 300.0

var _start_position: Vector2


func _ready() -> void:
	# 让初始画面左上角对应世界原点。
	position = get_viewport_rect().size * 0.5
	_start_position = position
	make_current()


func _process(delta: float) -> void:
	var direction: float = 0.0

	if Input.is_physical_key_pressed(KEY_LEFT):
		direction -= 1.0

	if Input.is_physical_key_pressed(KEY_RIGHT):
		direction += 1.0

	position.x += direction * move_speed * delta

	if Input.is_physical_key_pressed(KEY_R):
		position = _start_position

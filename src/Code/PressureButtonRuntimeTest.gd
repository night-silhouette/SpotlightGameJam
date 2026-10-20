extends Node

const BUTTON_SCENE := preload("res://Code/Entities/InteractiveComponent/PressureButton/PressureButton.tscn")
const DOOR_SCENE := preload("res://Code/Entities/InteractiveComponent/SignalDoor/SignalDoor.tscn")
const PALACE_SCENE := preload("res://Code/Entities/World/SunkenPalace/SunkenPalace.tscn")
const SaveManager := preload("res://Code/Entities/Setting/SaveManager.gd")

var _failures: Array[String] = []

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	await _test_initial_and_sunken_palace_state()
	await _test_physics_press_release_and_reset()
	await _test_save_load_migration_and_door_sync()
	if _failures.is_empty():
		print("PRESSURE_BUTTON_TEST: PASS")
		get_tree().quit(0)
		return
	for failure in _failures:
		push_error(failure)
	print("PRESSURE_BUTTON_TEST: FAIL (%d)" % _failures.size())
	get_tree().quit(1)

func _test_initial_and_sunken_palace_state() -> void:
	var button: PressureButton = BUTTON_SCENE.instantiate()
	button.is_pressed = true
	get_tree().root.add_child(button)
	await get_tree().process_frame
	_expect(not button.IsPressed(), "Button must ignore serialized is_pressed=true on ready.")
	_expect(button.position == Vector2.ZERO, "Unpressed button must be at its rest position.")
	_expect(button.get_node("UnpressedSprite2D").visible, "Unpressed button must show the raised texture state.")
	_expect(not button.get_node("PressedSprite2D").visible, "Unpressed button must hide the pressed texture state.")
	var raised_sprite := button.get_node("UnpressedSprite2D") as Sprite2D
	var compressed_sprite := button.get_node("PressedSprite2D") as Sprite2D
	var raised_bottom := raised_sprite.position.y + raised_sprite.texture.get_height() * raised_sprite.scale.y * 0.5
	var compressed_bottom := compressed_sprite.position.y + compressed_sprite.texture.get_height() * compressed_sprite.scale.y * 0.5
	_expect(is_equal_approx(raised_bottom, compressed_bottom), "Both texture states must share the same bottom edge.")
	button.queue_free()
	await get_tree().process_frame

	var palace := PALACE_SCENE.instantiate()
	get_tree().root.add_child(palace)
	await get_tree().process_frame
	for index in range(1, 5):
		var palace_button := palace.get_node_or_null("collisionlayer/button/%d" % index) as PressureButton
		_expect(palace_button != null, "SunkenPalace button %d must exist." % index)
		if palace_button:
			_expect(not palace_button.IsPressed(), "SunkenPalace button %d must start unpressed." % index)
			_expect(palace_button.stay_pressed, "SunkenPalace button %d must stay pressed for the current game." % index)
	palace.queue_free()
	await get_tree().process_frame

func _test_physics_press_release_and_reset() -> void:
	var button: PressureButton = BUTTON_SCENE.instantiate()
	button.stay_pressed = false
	get_tree().root.add_child(button)
	await get_tree().physics_frame
	await get_tree().physics_frame
	_expect(not button.IsPressed(), "Button without an overlapping body must remain unpressed.")
	var rest_position := button.position
	var solid_bottom := _get_solid_collision_bottom(button)

	var body := StaticBody2D.new()
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(20.0, 20.0)
	collision.shape = shape
	body.add_child(collision)
	body.position = Vector2(0.0, -4.0)
	get_tree().root.add_child(body)
	await get_tree().physics_frame
	await get_tree().physics_frame
	_expect(button.IsPressed(), "Overlapping PhysicsBody2D must press the button.")
	_expect(button.position == rest_position, "Pressing must not move the button node.")
	_expect(is_equal_approx(_get_solid_collision_bottom(button), solid_bottom), "Pressing must keep the collision bottom fixed.")
	_expect(not button.get_node("UnpressedSprite2D").visible, "Pressed button must hide the raised texture state.")
	_expect(button.get_node("PressedSprite2D").visible, "Pressed button must show the compressed texture state.")

	body.position = Vector2(300.0, 300.0)
	await get_tree().physics_frame
	await get_tree().physics_frame
	_expect(not button.IsPressed(), "Non-latching button must release after the body exits.")
	_expect(button.position == rest_position, "Releasing must not move the button node.")
	_expect(is_equal_approx(_get_solid_collision_bottom(button), solid_bottom), "Releasing must keep the collision bottom fixed.")
	_expect(button.get_node("UnpressedSprite2D").visible, "Released button must restore the raised texture state.")
	_expect(not button.get_node("PressedSprite2D").visible, "Released button must hide the compressed texture state.")

	button.stay_pressed = true
	body.position = Vector2(0.0, -4.0)
	await get_tree().physics_frame
	await get_tree().physics_frame
	_expect(button.IsPressed(), "Latching button must press when a body enters.")
	body.position = Vector2(300.0, 300.0)
	await get_tree().physics_frame
	await get_tree().physics_frame
	_expect(button.IsPressed(), "stay_pressed=true must retain runtime latch until ResetState.")
	_expect(button.position == rest_position, "A latched button must stay at its original position.")
	button.ResetState()
	_expect(not button.IsPressed(), "ResetState must force a latched button to release.")
	_expect(button.position == Vector2.ZERO, "ResetState must immediately restore rest position.")
	body.queue_free()
	button.queue_free()
	await get_tree().process_frame

func _test_save_load_migration_and_door_sync() -> void:
	var host := Node2D.new()
	host.name = "TestScene"
	get_tree().root.add_child(host)
	var button: PressureButton = BUTTON_SCENE.instantiate()
	button.name = "Button"
	host.add_child(button)
	var door: SignalDoor = DOOR_SCENE.instantiate()
	door.name = "Door"
	door.bound_buttons = [button]
	host.add_child(door)
	await get_tree().process_frame

	var legacy_entities := {
		"Button": {"output_channel": "door_1", "is_pressed": true},
		"Door": {
			"position_x": 999.0,
			"position_y": 999.0,
			"closed_position_x": 10.0,
			"closed_position_y": 20.0,
			"should_open": true,
		},
	}
	SaveManager._apply_save_data_smart(host, legacy_entities)
	_expect(button.IsPressed(), "Saved is_pressed=true must restore the pressed state.")
	_expect(door.IsOpenRequested(), "Door must synchronize with the restored pressed button.")
	_expect(button.ExportSaveData().get("is_pressed", false) == true, "New saves must persist the current pressed state.")
	_expect(door.ExportSaveData().is_empty(), "Door must not persist transient open position/state.")
	host.queue_free()
	await get_tree().process_frame

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)

func _get_solid_collision_bottom(button: PressureButton) -> float:
	var collision := button.get_node("SolidCollision") as CollisionShape2D
	var shape := collision.shape as RectangleShape2D
	return collision.position.y + shape.size.y * 0.5

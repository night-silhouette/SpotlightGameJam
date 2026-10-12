extends SceneTree

func _initialize() -> void:
	var project_path := ProjectSettings.globalize_path("res://")
	var test_scene := "res://Code/PressureButtonRuntimeTest.tscn"
	var output: Array = []
	var exit_code := OS.execute(
		OS.get_executable_path(),
		["--headless", "--path", project_path, test_scene],
		output,
		true
	)
	for line in output:
		print(line)
	quit(exit_code)

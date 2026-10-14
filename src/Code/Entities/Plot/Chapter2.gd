extends Node2D

var _completed: Array[int] = []
var _line_index: int = 0
var _active_event: int = -1
var _generation: int = 0
var _pending: Array[int] = []
var _restoring: bool = false
var _dialog_box: Node

func _ready() -> void:
	var ancestor: Node = self
	while ancestor != null and _dialog_box == null:
		_dialog_box = ancestor.get_node_or_null("DialogBox")
		ancestor = ancestor.get_parent()
	for index in range(get_child_count()):
		var trigger := get_child(index) as InteractableComponent
		if trigger != null:
			trigger.body_entered.connect(_on_body_entered.bind(index))
	# 读档时玩家可能已经站在区域内；没有进入区域就不会自动播开场。
	await get_tree().physics_frame
	if is_inside_tree():
		_check_overlaps()

func _on_body_entered(body: Node2D, index: int) -> void:
	if body.is_in_group("player") and index not in _completed and index != _active_event and index not in _pending:
		_pending.append(index)
		_play_next()

func _check_overlaps() -> void:
	for index in range(get_child_count()):
		var trigger := get_child(index) as InteractableComponent
		if trigger == null:
			continue
		for body in trigger.get_overlapping_bodies():
			_on_body_entered(body, index)

func _play_next() -> void:
	if _restoring or _active_event != -1 or _pending.is_empty() or _dialog_box == null:
		return
	_active_event = _pending.pop_front()
	var event_index := _active_event
	var generation := _generation
	var trigger := get_child(event_index) as InteractableComponent
	var lines := trigger.story_lines
	while _line_index < lines.size():
		var line := lines[_line_index]
		SignalBus.DialogBox.emit(StringName(line.dialog_type), line.text)
		await _dialog_box.Closed
		if generation != _generation or not is_inside_tree():
			return
		_line_index += 1
	_completed.append(event_index)
	_line_index = 0
	_active_event = -1
	_play_next()

func ExportSaveData() -> Dictionary:
	return {"completed": _completed.duplicate(), "active_event": _active_event, "line_index": _line_index}

func LoadSaveData(data: Dictionary) -> void:
	_generation += 1
	_restoring = true
	if _active_event != -1 and _dialog_box != null:
		_dialog_box.Dismiss()
	_pending.clear()
	_completed.clear()
	for value in data.get("completed", []):
		var index := int(value)
		if index >= 0 and index < get_child_count() and index not in _completed:
			_completed.append(index)
	_active_event = -1
	_line_index = 0
	var saved_event := int(data.get("active_event", -1))
	if saved_event >= 0 and saved_event < get_child_count() and saved_event not in _completed:
		_pending.append(saved_event)
		var trigger := get_child(saved_event) as InteractableComponent
		_line_index = clampi(int(data.get("line_index", 0)), 0, maxi(trigger.story_lines.size() - 1, 0))
	if is_node_ready():
		await get_tree().physics_frame
		if not is_inside_tree():
			_restoring = false
			return
		# 当前场景中仍位于区域内的事件才继续；离开后可再次进入。
		if saved_event >= 0 and not _pending.is_empty():
			var trigger := get_child(saved_event) as InteractableComponent
			var overlapping := false
			for body in trigger.get_overlapping_bodies():
				if body.is_in_group("player"):
					overlapping = true
					break
			if not overlapping:
				_pending.erase(saved_event)
				_line_index = 0
		_check_overlaps()
	_restoring = false
	_play_next()

extends Node2D

## 开场对话，按数组顺序播放；每句类型与文字均在检查器中编辑。
@export var opening_lines: Array[PlotDialogLine] = []

const CHAPTER_CARD = preload("res://Code/Entities/Plot/chapter/ChapterCard.tscn")

@onready var _dialog_box = get_node("../../DialogBox")

var _next_event: int = 0
var _line_index: int = 0
var _running: bool = false
var _generation: int = 0

func _ready() -> void:
	for trigger in get_children():
		if trigger is InteractableComponent:
			trigger.body_entered.connect(_on_trigger_body_entered.bind(trigger))
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	if not is_inside_tree():
		return
	if _next_event == 0:
		_run_event(0)
	else:
		_try_next_if_overlapping()

func _on_trigger_body_entered(body: Node2D, trigger: InteractableComponent) -> void:
	if not body.is_in_group("player") or _running:
		return
	var event_index := trigger.get_index() + 1
	if event_index == _next_event:
		_run_event(event_index)

func _run_event(event_index: int) -> void:
	if _running:
		return
	_running = true
	var generation := _generation
	var lines: Array[PlotDialogLine] = _event_lines(event_index)
	while _line_index < lines.size():
		var line := lines[_line_index]
		var trigger := get_child(event_index - 1) as InteractableComponent if event_index > 0 else null
		if trigger != null:
			trigger.ShowStoryDialogLine(line)
		else:
			SignalBus.DialogBox.emit(StringName(line.dialog_type), line.text)
		await _dialog_box.Closed
		if generation != _generation or not is_inside_tree():
			return
		_line_index += 1
	_next_event = event_index + 1
	_line_index = 0
	_running = false
	if event_index == 0:
		var card_layer := CHAPTER_CARD.instantiate()
		var card := card_layer.get_node("ChapterCard")
		card.set("auto_play", false)
		get_parent().add_child(card_layer)
		card.connect("Finished", card_layer.queue_free)
		card.call("ShowChapter", "第一章", "沙海初醒")
	_try_next_if_overlapping()

func _try_next_if_overlapping() -> void:
	if _running or _next_event < 1 or _next_event > get_child_count():
		return
	var trigger := get_child(_next_event - 1) as InteractableComponent
	if trigger == null:
		return
	for body in trigger.get_overlapping_bodies():
		if body.is_in_group("player"):
			_run_event(_next_event)
			return

func _event_lines(event_index: int) -> Array[PlotDialogLine]:
	if event_index == 0:
		return opening_lines
	if event_index > 0 and event_index <= get_child_count():
		var trigger := get_child(event_index - 1) as InteractableComponent
		if trigger != null:
			return trigger.story_lines
	return []

func ExportSaveData() -> Dictionary:
	return {"next_event": _next_event, "line_index": _line_index}

func LoadSaveData(data: Dictionary) -> void:
	_generation += 1
	_next_event = clampi(int(data.get("next_event", 0)), 0, get_child_count() + 1)
	_line_index = clampi(int(data.get("line_index", 0)), 0, maxi(_event_lines(_next_event).size() - 1, 0))
	if _running:
		_dialog_box.Dismiss()
		_running = false
	if is_node_ready():
		if _next_event == 0:
			_run_event(0)
		else:
			_try_next_if_overlapping()

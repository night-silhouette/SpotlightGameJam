extends Node2D

## 开场对话，按数组顺序播放；每句类型与文字均在检查器中编辑。
@export var opening_lines: Array[PlotDialogLine] = []

const CHAPTER_CARD = preload("res://Code/Entities/Plot/chapter/ChapterCard.tscn")

@onready var _dialog_box = get_node("../../DialogBox")
@onready var _stele: InteractableComponent = $SteleStory_1_12_to_1_14
@onready var _leave: InteractableComponent = $LeaveStory_1_15

var _next_event: int = 0
var _line_index: int = 0
var _running: bool = false
var _generation: int = 0

func _ready() -> void:
	SignalBus.PlayerOpeningHoldRequested.emit()
	SignalBus.ComponentInteracted.connect(_on_component_interacted)
	_leave.body_entered.connect(_on_leave_body_entered)
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	if not is_inside_tree():
		return
	if _next_event == 0:
		_run_opening()
	else:
		SignalBus.PlayerOpeningReleaseRequested.emit()
		_try_leave_if_overlapping()

func _on_component_interacted(component: Node2D, interactor: Node2D) -> void:
	if component != _stele or not interactor.is_in_group("player") or _next_event != 1:
		return
	_next_event = 2
	_try_leave_if_overlapping()

func _on_leave_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player") or _next_event != 2:
		return
	_next_event = 3
	for line in _leave.enter_dialog_lines:
		_leave.ShowStoryDialogLine(line)

func _run_opening() -> void:
	if _running:
		return
	_running = true
	var generation := _generation
	while _line_index < opening_lines.size():
		var line := opening_lines[_line_index]
		SignalBus.PlotDialogLineRequested.emit(line)
		await _dialog_box.Closed
		if generation != _generation or not is_inside_tree():
			return
		_line_index += 1
	_next_event = 1
	_line_index = 0
	_running = false
	SignalBus.PlayerOpeningStandUpRequested.emit()
	var card_layer := CHAPTER_CARD.instantiate()
	var card := card_layer.get_node("ChapterCard")
	card.set("auto_play", false)
	get_parent().add_child(card_layer)
	card.connect("Finished", card_layer.queue_free)
	card.call("ShowChapter", "第一章", "沙海初醒")

func _try_leave_if_overlapping() -> void:
	if _next_event != 2:
		return
	for body in _leave.get_overlapping_bodies():
		if body.is_in_group("player"):
			_on_leave_body_entered(body)
			return

## 导出开场和石碑、离开剧情的推进位置及开场当前句索引。
## 返回包含 next_event 与 line_index 的字典。
func ExportSaveData() -> Dictionary:
	return {"next_event": _next_event, "line_index": _line_index}

## 恢复开场和石碑、离开剧情的推进位置。
## data 为 ExportSaveData 返回的字典。
func LoadSaveData(data: Dictionary) -> void:
	_generation += 1
	_next_event = clampi(int(data.get("next_event", 0)), 0, 3)
	_line_index = clampi(int(data.get("line_index", 0)), 0, maxi(opening_lines.size() - 1, 0))
	if _next_event == 0:
		SignalBus.PlayerOpeningHoldRequested.emit()
	else:
		SignalBus.PlayerOpeningReleaseRequested.emit()
	if _running:
		_dialog_box.Dismiss()
		_running = false
	if is_node_ready():
		if _next_event == 0:
			_run_opening()
		else:
			_try_leave_if_overlapping()

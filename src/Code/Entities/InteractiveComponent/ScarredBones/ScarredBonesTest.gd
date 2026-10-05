extends Node2D
## F6 测试入口：ScarredBonesTest.tscn。A/D 移动，F 取得，顶部按钮测试状态恢复。
## 按钮只在内存保存本实体数据，不写正式存档；停止运行后样本丢失。
## 玩家和镜头直接实例化队友现有场景，本测试不覆盖其参数。

@onready var _bones: Node2D = $ScarredBones
@onready var _status: Label = $TestUI/Panel/Margin/Rows/Status
@onready var _save_status: Label = $TestUI/Panel/Margin/Rows/SaveStatus
@onready var _load_button: Button = $TestUI/Panel/Margin/Rows/Buttons/Load
var _saved_data: Dictionary = {}
var _collected_events: int = 0
var _finished_events: int = 0
var _inspection_events: int = 0


func _ready() -> void:
	SignalBus.InteractionRequested.connect(_on_interaction_requested)
	SignalBus.ScarredBonesCollected.connect(_on_collected)
	SignalBus.ScarredBonesPresentationFinished.connect(_on_finished)
	SignalBus.ScarredBonesStateRestored.connect(_on_restored)
	$TestUI/Panel/Margin/Rows/Buttons/Save.pressed.connect(_save_sample)
	_load_button.pressed.connect(_load_sample)
	$TestUI/Panel/Margin/Rows/Buttons/Reset.pressed.connect(_reset_bones)
	_update_status("走近枯骨，出现提示后按 F。")


func _on_interaction_requested(target: Node2D, _player: Node2D) -> void:
	if target == $InspectionExample:
		_inspection_events += 1
		$TestUI/Panel/Margin/Rows/InspectionStatus.text = "调查 %d 次：%s" % [_inspection_events, ExportSettings.inspection_example_description]


func _on_collected(bones: Node2D, _player: Node2D) -> void:
	if bones == _bones:
		_collected_events += 1
		_update_status("已取得：正在播放占位展示。")


func _on_finished(bones: Node2D) -> void:
	if bones == _bones:
		_finished_events += 1
		_update_status("展示完成：再次按 F 不应重复取得。")


func _on_restored(bones: Node2D, collected: bool) -> void:
	if bones == _bones:
		_update_status("状态恢复：%s；不会重播取得通知。" % ("已取得" if collected else "未取得"))


func _update_status(message: String) -> void:
	_status.text = "%s\n取得通知：%d 次　展示完成通知：%d 次" % [message, _collected_events, _finished_events]


func _save_sample() -> void:
	_saved_data = _bones.ExportSaveData().duplicate(true)
	_load_button.disabled = false
	_save_status.text = "内存样本：%s（停止运行后清除）" % ("已取得" if _saved_data.collected else "未取得")


func _load_sample() -> void:
	if not _saved_data.is_empty():
		_bones.LoadSaveData(_saved_data)


func _reset_bones() -> void:
	_bones.LoadSaveData({"collected": false})

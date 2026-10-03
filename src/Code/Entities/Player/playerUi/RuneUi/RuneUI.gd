extends Control
class_name RuneUI

## =============================================================================
## RuneUI.gd - 流水符文冷却与就绪状态显示 UI
## 位于 playerUi/RuneUi/RuneUI.tscn，负责展示流水符文 [E] 的冷却进度与就绪状态
## =============================================================================

@onready var cd_progress_bar: ProgressBar = $VBoxContainer/ProgressBar
@onready var status_label: Label = $VBoxContainer/ProgressBar/StatusLabel
@onready var name_label: Label = $VBoxContainer/NameLabel

var _current_cd: float = 0.0
var _max_cd: float = 2.0

func _ready() -> void:
	if ExportSettings:
		_max_cd = ExportSettings.water_rune_cooldown
	
	if SignalBus:
		SignalBus.WaterRuneCooldownChanged.connect(_on_water_rune_cooldown_changed)
	
	UpdateCooldown(0.0, _max_cd)

## 更新流水符文冷却显示
## @param current_cd 当前剩余冷却秒数 (0.0 为就绪)
## @param max_cd 最大冷却秒数
func UpdateCooldown(current_cd: float, max_cd: float) -> void:
	_current_cd = max(0.0, current_cd)
	_max_cd = max(0.01, max_cd)
	
	if not is_inside_tree() or not cd_progress_bar:
		return
		
	cd_progress_bar.max_value = _max_cd
	# 冷却条设计：cd为0时进度条填满（100%），进入cd时按比例变为空并随时间恢复填满
	cd_progress_bar.value = _max_cd - _current_cd
	
	if _current_cd <= 0.001:
		status_label.text = "[E] 流水符文 (就绪)"
		status_label.modulate = Color(1.0, 1.0, 1.0, 1.0)
	else:
		status_label.text = "[E] 冷却中 %.1fs" % _current_cd
		status_label.modulate = Color(0.9, 0.9, 0.9, 0.8)

func _on_water_rune_cooldown_changed(current_cd: float, max_cd: float) -> void:
	UpdateCooldown(current_cd, max_cd)

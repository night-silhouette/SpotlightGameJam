class_name StartMenu
extends Control

## =============================================================================
## StartMenu.gd - 游戏开始界面控制器
## 提供主菜单选项：开始游戏、设置、制作人名单、退出游戏
## 包含存档选择弹窗：支持选择已有存档载入或点击空白槽位创建新存档进入 World 主场景
## =============================================================================

const SaveManagerRef = preload("res://Code/Entities/Setting/SaveManager.gd")
const SettingScene = preload("res://Code/Entities/Setting/Setting.tscn")

@onready var btn_start: Button = %BtnStart
@onready var btn_setting: Button = %BtnSetting
@onready var btn_credits: Button = %BtnCredits
@onready var btn_quit: Button = %BtnQuit

@onready var saves_modal: Control = %SavesModal
@onready var saves_list: VBoxContainer = %SavesList
@onready var btn_close_saves: Button = %BtnCloseSaves

@onready var credits_modal: Control = %CreditsModal
@onready var btn_close_credits: Button = %BtnCloseCredits

@onready var quit_confirm_dialog: ConfirmationDialog = %QuitConfirmDialog

var _setting_instance: SettingUI = null

func _ready() -> void:
	_setup_signals()
	_instantiate_setting()
	saves_modal.visible = false
	credits_modal.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if saves_modal.visible:
			saves_modal.visible = false
			get_viewport().set_input_as_handled()
		elif credits_modal.visible:
			credits_modal.visible = false
			get_viewport().set_input_as_handled()

## 实例化系统设置节点以便菜单内随时唤起
func _instantiate_setting() -> void:
	if not _setting_instance:
		_setting_instance = SettingScene.instantiate() as SettingUI
		add_child(_setting_instance)
		_setting_instance.HideSetting()

func _setup_signals() -> void:
	if btn_start:
		btn_start.pressed.connect(_on_start_pressed)
	if btn_setting:
		btn_setting.pressed.connect(_on_setting_pressed)
	if btn_credits:
		btn_credits.pressed.connect(_on_credits_pressed)
	if btn_quit:
		btn_quit.pressed.connect(_on_quit_pressed)

	if btn_close_saves:
		btn_close_saves.pressed.connect(func(): saves_modal.visible = false)
	if btn_close_credits:
		btn_close_credits.pressed.connect(func(): credits_modal.visible = false)

	if quit_confirm_dialog:
		quit_confirm_dialog.confirmed.connect(func(): get_tree().quit())

func _on_start_pressed() -> void:
	_refresh_saves_ui()
	saves_modal.visible = true

func _on_setting_pressed() -> void:
	if _setting_instance:
		_setting_instance.ShowSetting()

func _on_credits_pressed() -> void:
	credits_modal.visible = true

func _on_quit_pressed() -> void:
	if quit_confirm_dialog:
		quit_confirm_dialog.popup_centered()

## 刷新开始界面的存档槽位列表
func _refresh_saves_ui() -> void:
	if not saves_list:
		return
	for child in saves_list.get_children():
		child.queue_free()

	var slots = SaveManagerRef.GetAllSlotsInfo()
	for slot in slots:
		var slot_idx: int = slot["slot_index"]
		var exists: bool = slot["exists"]
		var player_hp: float = slot.get("player_hp", 0.0)
		var player_max_hp: float = slot.get("player_max_hp", 200.0)

		var card = PanelContainer.new()
		card.custom_minimum_size = Vector2(0, 68)
		card.mouse_filter = Control.MOUSE_FILTER_PASS

		# 如果是空白槽位，允许点击整张卡片任意空白区域直接新建存档
		if not exists:
			card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			card.gui_input.connect(func(event: InputEvent):
				if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
					_on_slot_new_game_pressed(slot_idx)
			)

		var card_style = StyleBoxFlat.new()
		if exists:
			card_style.bg_color = Color(0.12, 0.18, 0.26, 0.95)
			card_style.border_color = Color(0.35, 0.65, 0.9, 0.9)
		else:
			card_style.bg_color = Color(0.08, 0.12, 0.16, 0.8)
			card_style.border_color = Color(0.25, 0.35, 0.45, 0.5)
		card_style.set_border_width_all(1)
		card_style.set_corner_radius_all(6)
		card.add_theme_stylebox_override("panel", card_style)

		var margin = MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 16)
		margin.add_theme_constant_override("margin_right", 16)
		margin.add_theme_constant_override("margin_top", 10)
		margin.add_theme_constant_override("margin_bottom", 10)
		card.add_child(margin)

		var hbox = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 14)
		margin.add_child(hbox)

		var info_vbox = VBoxContainer.new()
		info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		info_vbox.mouse_filter = Control.MOUSE_FILTER_PASS
		hbox.add_child(info_vbox)

		var title_label = Label.new()
		title_label.text = "存档槽位 %d" % slot_idx
		title_label.add_theme_font_size_override("font_size", 16)
		title_label.mouse_filter = Control.MOUSE_FILTER_PASS
		if exists:
			title_label.add_theme_color_override("font_color", Color(0.4, 0.85, 1.0))
		else:
			title_label.add_theme_color_override("font_color", Color(0.7, 0.75, 0.8))
		info_vbox.add_child(title_label)

		var detail_label = Label.new()
		detail_label.add_theme_font_size_override("font_size", 12)
		detail_label.mouse_filter = Control.MOUSE_FILTER_PASS
		if exists:
			detail_label.text = "记录时间: %s  |  生命值: %d/%d" % [slot["timestamp"], int(player_hp), int(player_max_hp)]
			detail_label.add_theme_color_override("font_color", Color(0.85, 0.9, 0.95))
		else:
			detail_label.text = "【空白槽位】点击开启新游戏探索"
			detail_label.add_theme_color_override("font_color", Color(0.5, 0.55, 0.6))
		info_vbox.add_child(detail_label)

		# 操作按钮
		var btn_action = Button.new()
		btn_action.custom_minimum_size = Vector2(110, 38)
		btn_action.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		btn_action.focus_mode = Control.FOCUS_NONE

		if exists:
			btn_action.text = "载入进度"
			btn_action.pressed.connect(_on_slot_load_pressed.bind(slot_idx))
		else:
			btn_action.text = "开启新存档"
			btn_action.pressed.connect(_on_slot_new_game_pressed.bind(slot_idx))
		hbox.add_child(btn_action)

		# 已有存档提供重开/覆盖按钮
		if exists:
			var btn_restart = Button.new()
			btn_restart.text = "覆写新开"
			btn_restart.custom_minimum_size = Vector2(80, 38)
			btn_restart.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			btn_restart.focus_mode = Control.FOCUS_NONE
			btn_restart.pressed.connect(_on_slot_new_game_pressed.bind(slot_idx))
			hbox.add_child(btn_restart)

		saves_list.add_child(card)

## 载入已有存档进入游戏
func _on_slot_load_pressed(slot_idx: int) -> void:
	saves_modal.visible = false
	SaveManagerRef.LoadFromSlot(get_tree(), slot_idx)

## 空白处或指定槽位开启新存档并进入 World.tscn
func _on_slot_new_game_pressed(slot_idx: int) -> void:
	saves_modal.visible = false
	SaveManagerRef.StartNewGameInSlot(get_tree(), slot_idx)

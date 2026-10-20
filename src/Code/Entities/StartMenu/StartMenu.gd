class_name StartMenu
extends Control

## =============================================================================
## StartMenu.gd - 游戏开始界面控制器
## 提供主菜单选项：开始游戏、设置、制作人名单、退出游戏
## 包含存档选择弹窗：支持选择已有存档载入或点击空白槽位创建新存档进入 World 主场景
## =============================================================================

const SettingsSkin = preload("res://Code/Entities/Setting/SettingsSkin.gd")
const SettingsFrame = preload("res://Code/Entities/Setting/SettingsFrame.gd")
const SaveManagerRef = preload("res://Code/Entities/Setting/SaveManager.gd")
const SettingScene = preload("res://Code/Entities/Setting/Setting.tscn")
const CONFIRM_SFX = preload("res://Music/SFX/UI/Confirm.wav")
const MENU_REVEAL_SFX = preload("res://Music/SFX/InteractiveLV3/UIClick.wav")

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
@onready var _new_game_intro: CanvasLayer = $NewGameIntro
@onready var _intro_text: Label = $NewGameIntro/Black/Text

var _setting_instance: SettingUI = null
var _starting_new_game := false
var _awaiting_menu_input := true
var _revealing_menu := false
var _menu_rain_time := 0.0
@onready var _menu_rain: ColorRect = $CompletedWeather/Rain
@onready var _ordinary_background: Texture2D = $BackgroundLayers/Sky.texture

func _ready() -> void:
	saves_modal.theme = SettingsSkin.CreateTheme()
	SettingsSkin.ApplyToTree(saves_modal)
	var save_panel: PanelContainer = $SavesModal/PanelContainer
	SettingsFrame.Mount(save_panel, btn_close_saves)
	credits_modal.theme = SettingsSkin.CreateTheme()
	SettingsSkin.ApplyToTree(credits_modal)
	var thanks_detail: Label = $CreditsModal/PanelContainer/Margin/VBox/CreditsScroll/CreditsContent/ThanksSection/Sec3Detail
	thanks_detail.text = "Spotlight Game Jam 2026"
	if not ExportSettings.credits_early_playtesters.is_empty():
		thanks_detail.text += "\n测试游玩早期版本：" + "、".join(ExportSettings.credits_early_playtesters)
	var credits_panel: PanelContainer = $CreditsModal/PanelContainer
	SettingsFrame.Mount(credits_panel, btn_close_credits)
	_setup_signals()
	_instantiate_setting()
	saves_modal.visibility_changed.connect(_sync_setting_shortcut)
	credits_modal.visibility_changed.connect(_sync_setting_shortcut)
	saves_modal.visible = false
	credits_modal.visible = false
	_intro_text.text = ExportSettings.new_game_intro_text
	_intro_text.add_theme_color_override("font_color", ExportSettings.new_game_intro_text_color)
	get_viewport().size_changed.connect(_resize_intro_text)
	_resize_intro_text()
	_sync_setting_shortcut()
	SignalBus.SaveSlotSaved.connect(_refresh_completed_background)
	SignalBus.SaveSlotDeleted.connect(_refresh_completed_background)
	_refresh_completed_background()

func _refresh_completed_background(_slot: int = 0) -> void:
	var completed := SaveManagerRef.HasCompletedSlot()
	$BackgroundLayers/Sky.texture = $BackgroundLayers/CompletedBackground.texture if completed else _ordinary_background
	_menu_rain.visible = completed
	_menu_rain.material.set_shader_parameter("intensity", 1.0)
	_menu_rain.material.set_shader_parameter("rain_color", ExportSettings.chapter5_rain_color)
	_menu_rain.material.set_shader_parameter("drop_count", float(ExportSettings.chapter5_rain_count))

func _process(delta: float) -> void:
	if _menu_rain.visible:
		_menu_rain_time += delta
		_menu_rain.material.set_shader_parameter("elapsed", _menu_rain_time)

func _input(event: InputEvent) -> void:
	if not _awaiting_menu_input and not _revealing_menu:
		return
	get_viewport().set_input_as_handled()
	if _revealing_menu:
		return
	var pressed := false
	if event is InputEventKey:
		pressed = event.pressed and not event.echo
	elif event is InputEventMouseButton:
		pressed = event.pressed
	elif event is InputEventJoypadButton:
		pressed = event.pressed
	elif event is InputEventScreenTouch:
		pressed = event.pressed
	if pressed:
		_reveal_menu()

func _reveal_menu() -> void:
	_awaiting_menu_input = false
	_revealing_menu = true
	Util.PlaySFX(MENU_REVEAL_SFX)
	$BackgroundLayers/Sky.hide()
	$BackgroundLayers/CleanBackground.show()
	$MainUI.modulate.a = 0.0
	$SettingsGear.modulate.a = 0.0
	$MainUI.show()
	$SettingsGear.show()
	var tween := create_tween().set_parallel(true)
	tween.tween_property($MainUI, "modulate:a", 1.0, ExportSettings.start_menu_ui_fade_duration)
	tween.tween_property($SettingsGear, "modulate:a", 1.0, ExportSettings.start_menu_ui_fade_duration)
	await tween.finished
	_revealing_menu = false
	_sync_setting_shortcut()

func _resize_intro_text() -> void:
	var viewport_size := get_viewport_rect().size
	var text_scale := minf(1.0, minf(viewport_size.x / 1280.0, viewport_size.y / 720.0))
	_intro_text.add_theme_font_size_override("font_size", maxi(1, roundi(ExportSettings.new_game_intro_font_size * text_scale)))

func _sync_setting_shortcut() -> void:
	_setting_instance.set_process_input(not _awaiting_menu_input and not _revealing_menu and not _starting_new_game and not saves_modal.visible and not credits_modal.visible)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if saves_modal.visible:
			if not _starting_new_game:
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
	for button in [btn_start, btn_credits, btn_quit, btn_close_saves, btn_close_credits]:
		button.pressed.connect(_play_confirm)
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
		quit_confirm_dialog.confirmed.connect(func(): SignalBus.GameQuitRequested.emit())

func _play_confirm() -> void:
	Util.PlaySFX(CONFIRM_SFX)

func _on_start_pressed() -> void:
	$SavesModal/PanelContainer/Margin/VBox/HeaderHBox/ModalTitle.text = "选择游戏存档"
	_refresh_saves_ui()
	saves_modal.visible = true

func _on_setting_pressed() -> void:
	SignalBus.SettingVisibilityRequested.emit(true)

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

		card.add_theme_stylebox_override("panel", SettingsSkin.SaveStyle())
		card.theme = SettingsSkin.CardTheme()

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
		title_label.add_theme_color_override("font_color", SettingsSkin.INK)
		info_vbox.add_child(title_label)

		var detail_label = Label.new()
		detail_label.add_theme_font_size_override("font_size", 12)
		detail_label.mouse_filter = Control.MOUSE_FILTER_PASS
		if exists:
			detail_label.text = "记录时间: %s  |  生命值: %d/%d" % [slot["timestamp"], int(player_hp), int(player_max_hp)]
			detail_label.add_theme_color_override("font_color", SettingsSkin.INK)
		else:
			detail_label.text = "【空白槽位】点击开启新游戏探索"
			detail_label.add_theme_color_override("font_color", Color("555347"))
		info_vbox.add_child(detail_label)

		# 操作按钮
		var btn_action = Button.new()
		btn_action.custom_minimum_size = Vector2(110, 38)
		btn_action.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		btn_action.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		btn_action.focus_mode = Control.FOCUS_NONE

		if exists:
			btn_action.text = "载入进度"
			btn_action.pressed.connect(_play_confirm)
			btn_action.pressed.connect(_on_slot_load_pressed.bind(slot_idx))
		else:
			btn_action.text = "开启新存档"
			btn_action.pressed.connect(_play_confirm)
			btn_action.pressed.connect(_on_slot_new_game_pressed.bind(slot_idx))
		hbox.add_child(btn_action)

		# 已有存档提供重开/覆盖按钮
		if exists:
			var btn_restart = Button.new()
			btn_restart.text = "覆写新开"
			btn_restart.custom_minimum_size = Vector2(80, 38)
			btn_restart.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			btn_restart.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			btn_restart.focus_mode = Control.FOCUS_NONE
			btn_restart.pressed.connect(_play_confirm)
			btn_restart.pressed.connect(_on_slot_new_game_pressed.bind(slot_idx))
			hbox.add_child(btn_restart)

		saves_list.add_child(card)

## 载入已有存档进入游戏
func _on_slot_load_pressed(slot_idx: int) -> void:
	if _starting_new_game:
		return
	_starting_new_game = true
	btn_close_saves.disabled = true
	saves_list.visible = false
	_sync_setting_shortcut()
	$SavesModal/PanelContainer/Margin/VBox/HeaderHBox/ModalTitle.text = "正在载入存档…"
	var loaded: bool = await SaveManagerRef.LoadFromSlot(get_tree(), slot_idx)
	if not loaded and is_instance_valid(self):
		_starting_new_game = false
		btn_close_saves.disabled = false
		saves_list.visible = true
		_sync_setting_shortcut()
		$SavesModal/PanelContainer/Margin/VBox/HeaderHBox/ModalTitle.text = "载入失败，请覆写或选择其他存档"

## 空白处或指定槽位开启新存档并进入 World.tscn
func _on_slot_new_game_pressed(slot_idx: int) -> void:
	if _starting_new_game:
		return
	_starting_new_game = true
	$SavesModal/PanelContainer/Margin/VBox/HeaderHBox/ModalTitle.text = "正在加载世界…"
	btn_close_saves.disabled = true
	saves_list.visible = false
	_sync_setting_shortcut()
	_new_game_intro.show()
	_intro_text.modulate.a = 0.0
	var intro_tween := create_tween()
	intro_tween.tween_property(_intro_text, "modulate:a", 1.0, ExportSettings.new_game_intro_fade_in_duration)
	intro_tween.tween_interval(ExportSettings.new_game_intro_hold_duration)
	intro_tween.tween_property(_intro_text, "modulate:a", 0.0, ExportSettings.new_game_intro_fade_out_duration)
	var started: bool = await SaveManagerRef.StartNewGameInSlot(get_tree(), slot_idx, "", intro_tween)
	if not started and is_instance_valid(self):
		intro_tween.kill()
		_new_game_intro.hide()
		_starting_new_game = false
		_sync_setting_shortcut()
		$SavesModal/PanelContainer/Margin/VBox/HeaderHBox/ModalTitle.text = "加载失败，请重试"
		btn_close_saves.disabled = false
		saves_list.visible = true

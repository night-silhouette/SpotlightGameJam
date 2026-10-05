extends CanvasLayer
class_name SettingUI

## =============================================================================
## Setting.gd - 设置页面实体控制器
## 包含选项：
## 1. 退出游戏 (确认弹窗与平稳退出)
## 2. 改变按键绑定 (捕获按键并独立持久化至 user://，不随存档改变)
## 3. 改变存档 (最多5个独立槽位：新建/覆盖、载入、删除)
## 提供打开/关闭动画、快捷键 ESC 呼出与关闭，支持鼠标交互。
## =============================================================================

const KeybindManagerRef = preload("res://Code/Entities/Setting/KeybindManager.gd")
const SaveManagerRef = preload("res://Code/Entities/Setting/SaveManager.gd")

@onready var root_control: Control = $RootControl
@onready var background_dim: ColorRect = $RootControl/BackgroundDim
@onready var panel_container: PanelContainer = $RootControl/PanelContainer
@onready var close_button: Button = $RootControl/PanelContainer/MarginContainer/MainVBox/HeaderHBox/CloseButton
@onready var tab_btn_keybinds: Button = $RootControl/PanelContainer/MarginContainer/MainVBox/TabHBox/TabBtnKeybinds
@onready var tab_btn_saves: Button = $RootControl/PanelContainer/MarginContainer/MainVBox/TabHBox/TabBtnSaves
@onready var keybinds_container: ScrollContainer = $RootControl/PanelContainer/MarginContainer/MainVBox/ContentPanel/KeybindsScroll
@onready var keybinds_list: VBoxContainer = $RootControl/PanelContainer/MarginContainer/MainVBox/ContentPanel/KeybindsScroll/KeybindsList
@onready var saves_container: ScrollContainer = $RootControl/PanelContainer/MarginContainer/MainVBox/ContentPanel/SavesScroll
@onready var saves_list: VBoxContainer = $RootControl/PanelContainer/MarginContainer/MainVBox/ContentPanel/SavesScroll/SavesList
@onready var quit_button: Button = $RootControl/PanelContainer/MarginContainer/MainVBox/BottomHBox/QuitButton
@onready var status_toast: Label = $RootControl/PanelContainer/MarginContainer/MainVBox/BottomHBox/StatusToast

## 绑定按键等待遮罩
@onready var rebind_overlay: ColorRect = $RootControl/RebindOverlay
@onready var rebind_prompt_label: Label = $RootControl/RebindOverlay/PromptVBox/PromptLabel

## 退出确认弹窗
@onready var quit_confirm_dialog: ConfirmationDialog = $QuitConfirmDialog

var _is_waiting_for_input: bool = false
var _rebinding_action: StringName = &""
var _rebind_button_ref: Button = null

func _ready() -> void:
	# 启动时自动读取并应用持久化的独立按键绑定
	KeybindManagerRef.LoadAndApplyKeybinds()
	
	_connect_signals()
	_build_keybind_rows()
	_refresh_save_slots_ui()
	_switch_tab(0)
	
	# 默认隐藏，通过按 ESC 或 UI 齿轮打开
	HideSetting()

func _input(event: InputEvent) -> void:
	# 如果正在监听新按键输入
	if _is_waiting_for_input:
		if (event is InputEventKey and event.pressed and not event.is_echo()) or (event is InputEventMouseButton and event.pressed):
			get_viewport().set_input_as_handled()
			_apply_new_keybind(event)
			return

	# ESC 键唤出/收起设置菜单 (仅在非改键等待状态时生效)
	if event.is_action_pressed("ui_cancel") and not _is_waiting_for_input:
		if quit_confirm_dialog and quit_confirm_dialog.visible:
			return
		get_viewport().set_input_as_handled()
		ToggleSetting()

func _connect_signals() -> void:
	if close_button:
		close_button.pressed.connect(HideSetting)
	if tab_btn_keybinds:
		tab_btn_keybinds.pressed.connect(func(): _switch_tab(0))
	if tab_btn_saves:
		tab_btn_saves.pressed.connect(func(): _switch_tab(1))
	if quit_button:
		quit_button.pressed.connect(_on_quit_button_pressed)
	if quit_confirm_dialog:
		quit_confirm_dialog.confirmed.connect(_on_quit_confirmed)
	if SignalBus:
		SignalBus.SettingVisibilityRequested.connect(func(open: bool):
			if open:
				ShowSetting()
			else:
				HideSetting()
		)

## 显示设置面板
func ShowSetting() -> void:
	root_control.visible = true
	_refresh_save_slots_ui()
	_refresh_keybind_labels()
	_show_status("")

## 隐藏设置面板
func HideSetting() -> void:
	_cancel_rebinding()
	root_control.visible = false

## 切换设置面板开关状态
func ToggleSetting() -> void:
	if root_control.visible:
		HideSetting()
	else:
		ShowSetting()

## 切换 Tab 栏
func _switch_tab(tab_idx: int) -> void:
	if tab_idx == 0:
		keybinds_container.visible = true
		saves_container.visible = false
		tab_btn_keybinds.disabled = true
		tab_btn_saves.disabled = false
	else:
		keybinds_container.visible = false
		saves_container.visible = true
		tab_btn_keybinds.disabled = false
		tab_btn_saves.disabled = true
		_refresh_save_slots_ui()

#region 按键绑定 UI 构建与事件

func _build_keybind_rows() -> void:
	for child in keybinds_list.get_children():
		child.queue_free()

	for action in KeybindManagerRef.CONFIGURABLE_ACTIONS:
		var row = HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_theme_constant_override("separation", 12)

		var action_label = Label.new()
		action_label.text = KeybindManagerRef.GetActionDisplayName(action)
		action_label.custom_minimum_size = Vector2(160, 36)
		action_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		action_label.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0))
		row.add_child(action_label)


		var ev = KeybindManagerRef.GetPrimaryEventForAction(action)
		var btn = Button.new()
		btn.text = KeybindManagerRef.GetEventText(ev)
		btn.custom_minimum_size = Vector2(180, 34)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		btn.focus_mode = Control.FOCUS_NONE
		btn.set_meta("action_name", action)
		btn.pressed.connect(_on_keybind_button_pressed.bind(action, btn))
		row.add_child(btn)

		keybinds_list.add_child(row)

func _refresh_keybind_labels() -> void:
	for row in keybinds_list.get_children():
		for child in row.get_children():
			if child is Button and child.has_meta("action_name"):
				var action = child.get_meta("action_name")
				var ev = KeybindManagerRef.GetPrimaryEventForAction(action)
				child.text = KeybindManagerRef.GetEventText(ev)

func _on_keybind_button_pressed(action: StringName, btn: Button) -> void:
	_rebinding_action = action
	_rebind_button_ref = btn
	_is_waiting_for_input = true
	rebind_overlay.visible = true
	var name_cn = KeybindManagerRef.GetActionDisplayName(action)
	rebind_prompt_label.text = "请按下要绑定到【%s】的新按键或鼠标键\n(按 ESC 取消)" % name_cn

func _apply_new_keybind(event: InputEvent) -> void:
	if event is InputEventKey and event.keycode == KEY_ESCAPE:
		_cancel_rebinding()
		return

	KeybindManagerRef.RebindAction(_rebinding_action, event, true)
	if is_instance_valid(_rebind_button_ref):
		_rebind_button_ref.text = KeybindManagerRef.GetEventText(event)

	_show_status("【%s】已重新绑定为: %s" % [KeybindManagerRef.GetActionDisplayName(_rebinding_action), KeybindManagerRef.GetEventText(event)])
	_cancel_rebinding()

func _cancel_rebinding() -> void:
	_is_waiting_for_input = false
	_rebinding_action = &""
	_rebind_button_ref = null
	if rebind_overlay:
		rebind_overlay.visible = false

#endregion

#region 存档系统 UI 构建与槽位操作

func _refresh_save_slots_ui() -> void:
	for child in saves_list.get_children():
		child.queue_free()

	var all_slots = SaveManagerRef.GetAllSlotsInfo()
	for slot in all_slots:
		var slot_idx: int = slot["slot_index"]
		var exists: bool = slot["exists"]
		var desc: String = slot["desc"]
		var player_hp: float = slot["player_hp"]
		var player_max_hp: float = slot["player_max_hp"]

		var row_panel = PanelContainer.new()
		row_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.12, 0.16, 0.22, 0.8)
		style.border_width_left = 1
		style.border_width_top = 1
		style.border_width_right = 1
		style.border_width_bottom = 1
		style.border_color = Color(0.3, 0.5, 0.7, 0.6)
		style.corner_radius_top_left = 4
		style.corner_radius_top_right = 4
		style.corner_radius_bottom_right = 4
		style.corner_radius_bottom_left = 4
		style.content_margin_left = 14.0
		style.content_margin_right = 14.0
		style.content_margin_top = 10.0
		style.content_margin_bottom = 10.0
		row_panel.add_theme_stylebox_override("panel", style)

		var hbox = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 12)
		row_panel.add_child(hbox)

		var info_vbox = VBoxContainer.new()
		info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(info_vbox)

		var title_label = Label.new()
		title_label.text = "存档槽位 %d" % slot_idx
		title_label.add_theme_color_override("font_color", Color(0.4, 0.85, 1.0))
		title_label.add_theme_font_size_override("font_size", 14)
		info_vbox.add_child(title_label)

		var detail_label = Label.new()
		if exists:
			detail_label.text = "时间: %s | 生命: %d/%d" % [slot["timestamp"], int(player_hp), int(player_max_hp)]
			detail_label.add_theme_color_override("font_color", Color(0.85, 0.9, 0.95))
		else:
			detail_label.text = "【空存档位】点击新建存档进行保存"
			detail_label.add_theme_color_override("font_color", Color(0.55, 0.6, 0.65))
		detail_label.add_theme_font_size_override("font_size", 12)
		info_vbox.add_child(detail_label)

		# 按钮群
		var btn_box = HBoxContainer.new()
		btn_box.add_theme_constant_override("separation", 8)
		hbox.add_child(btn_box)

		# 新建/覆盖保存按钮
		var btn_save = Button.new()
		btn_save.text = "覆盖保存" if exists else "新建存档"
		btn_save.custom_minimum_size = Vector2(88, 34)
		btn_save.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		btn_save.focus_mode = Control.FOCUS_NONE
		btn_save.pressed.connect(_on_save_slot_pressed.bind(slot_idx))
		btn_box.add_child(btn_save)

		# 载入按钮
		var btn_load = Button.new()
		btn_load.text = "载入"
		btn_load.custom_minimum_size = Vector2(70, 34)
		btn_load.disabled = not exists
		btn_load.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if exists else Control.CURSOR_ARROW
		btn_load.focus_mode = Control.FOCUS_NONE
		btn_load.pressed.connect(_on_load_slot_pressed.bind(slot_idx))
		btn_box.add_child(btn_load)

		# 删除按钮
		var btn_del = Button.new()
		btn_del.text = "删除"
		btn_del.custom_minimum_size = Vector2(70, 34)
		btn_del.disabled = not exists
		btn_del.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if exists else Control.CURSOR_ARROW
		btn_del.focus_mode = Control.FOCUS_NONE
		btn_del.pressed.connect(_on_delete_slot_pressed.bind(slot_idx))
		btn_box.add_child(btn_del)

		saves_list.add_child(row_panel)

func _on_save_slot_pressed(slot_idx: int) -> void:
	var success = SaveManagerRef.SaveToSlot(get_tree(), slot_idx)
	if success:
		_refresh_save_slots_ui()
		_show_status("已成功保存至 存档槽位 %d" % slot_idx)
	else:
		_show_status("保存至 存档槽位 %d 失败！" % slot_idx, true)

func _on_load_slot_pressed(slot_idx: int) -> void:
	var success = SaveManagerRef.LoadFromSlot(get_tree(), slot_idx)
	if success:
		_show_status("成功载入 存档槽位 %d" % slot_idx)
		# 载入成功后关闭设置菜单，返回游戏
		HideSetting()
	else:
		_show_status("载入 存档槽位 %d 失败！" % slot_idx, true)

func _on_delete_slot_pressed(slot_idx: int) -> void:
	var success = SaveManagerRef.DeleteSlot(slot_idx)
	if success:
		_refresh_save_slots_ui()
		_show_status("已删除 存档槽位 %d" % slot_idx)
	else:
		_show_status("删除 存档槽位 %d 失败！" % slot_idx, true)

#endregion

#region 退出游戏与反馈提示

func _on_quit_button_pressed() -> void:
	if quit_confirm_dialog:
		quit_confirm_dialog.popup_centered()

func _on_quit_confirmed() -> void:
	get_tree().quit()

func _show_status(text: String, is_error: bool = false) -> void:
	if not status_toast:
		return
	status_toast.text = text
	status_toast.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4) if is_error else Color(0.4, 0.9, 0.6))
	if text != "":

		var t = get_tree().create_timer(3.0)
		t.timeout.connect(func():
			if status_toast and status_toast.text == text:
				status_toast.text = ""
		)

#endregion

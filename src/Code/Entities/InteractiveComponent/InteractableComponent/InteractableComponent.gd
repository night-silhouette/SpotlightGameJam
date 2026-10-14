extends Area2D
class_name InteractableComponent

## 每次成功交互时触发；interactor 为处于此交互区域内的玩家节点。
signal Interacted(interactor: Node2D)
## 首次交互时触发，按展示顺序传递物体描述文本数组。
signal DescriptionRequested(lines: Array[String])
## 后续重复交互时触发，按展示顺序传递内心独白文本数组。
signal MonologueRequested(lines: Array[String])

## 首次交互时通过 [signal DescriptionRequested] 及全局信号发出的描述文本数组；为空且启用 [member use_export_settings] 时使用全局默认值。此数组不会自动显示在对话框中。
@export var description_lines: Array[String] = []
## 后续交互时通过 [signal MonologueRequested] 及全局信号发出的独白文本数组；为空且启用 [member use_export_settings] 时使用全局默认值。此数组不会自动显示在对话框中。
@export var monologue_lines: Array[String] = []
## 触发交互的输入动作名；启用 [member use_export_settings] 时会被全局设置覆盖。
@export var interaction_action: StringName = &"interact"
## 是否读取 ExportSettings 中的交互动作及默认描述／独白数组；仅在对应数组为空时才填入默认文本。
@export var use_export_settings: bool = true
## 是否允许按键或提示按钮交互；关闭后隐藏提示，但仍会检测玩家进入区域并按配置显示进入区域对话。
@export var enable_interaction: bool = true

@export_group("进入区域对话")
## 玩家每次进入交互区域时，是否立即显示旁白对话框；不受 [member enable_interaction] 影响。
@export var show_enter_dialog: bool = false
## 进入区域时显示的旁白文字；仅在 [member show_enter_dialog] 开启时使用。
@export_multiline var enter_dialog_text: String = ""

@export_group("首次交互对话")
## 第一次成功交互时是否显示旁白对话框；首次状态可随组件存档恢复。
@export var show_first_dialog: bool = false
## 首次交互时显示的旁白文字；仅在 [member show_first_dialog] 开启时使用。
@export_multiline var first_dialog_text: String = ""

@export_group("后续交互对话")
## 第二次及以后成功交互时是否显示独白对话框。
@export var show_repeat_dialog: bool = false
## 后续交互时显示的独白文字；仅在 [member show_repeat_dialog] 开启时使用。
@export_multiline var repeat_dialog_text: String = ""
@export_group("剧情对话")
## 供关卡剧情脚本逐句展示的旁白／独白；按数组顺序排列，每句的类型和文字可在检查器中编辑。
@export var story_lines: Array[PlotDialogLine] = []
@export_group("")

@onready var _prompt: Control = $PromptContainer
@onready var _button: Button = $PromptContainer/PromptButton
@onready var _key_badge: Label = $PromptContainer/HBox/KeyBadge
@onready var _collision_shape: CollisionShape2D = $CollisionShape2D

var _players: Array[Node2D] = []
var _description_requested: bool = false
var _dispatching: bool = false

func _ready() -> void:
	if use_export_settings:
		interaction_action = ExportSettings.interactable_action
		if description_lines.is_empty():
			description_lines.assign(ExportSettings.interactable_description_lines)
		if monologue_lines.is_empty():
			monologue_lines.assign(ExportSettings.interactable_monologue_lines)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_button.pressed.connect(_on_prompt_pressed)
	_refresh_prompt()

func _physics_process(_delta: float) -> void:
	_players = _players.filter(func(player: Node2D) -> bool: return is_instance_valid(player))
	_refresh_prompt()

func _unhandled_input(event: InputEvent) -> void:
	if not enable_interaction or not event.is_action_pressed(interaction_action) or _players.is_empty():
		return
	if event is InputEventMouseButton:
		var shape := _collision_shape.shape as RectangleShape2D
		var point := _collision_shape.to_local(get_global_mouse_position())
		if not shape or not Rect2(-shape.size * 0.5, shape.size).has_point(point):
			return
	if Interact(_players[0]):
		get_viewport().set_input_as_handled()

## 执行交互逻辑：首次交互请求描述文本，后续交互请求内心独白文本。
## @param interactor 必须为当前重叠区域内有效的玩家节点。
## @return 交互成功返回 true，否则返回 false。
func Interact(interactor: Node2D) -> bool:
	if not enable_interaction or _dispatching or not is_instance_valid(interactor) or interactor not in _players:
		return false
	_dispatching = true
	var is_description: bool = not _description_requested
	_description_requested = true
	Interacted.emit(interactor)
	SignalBus.ComponentInteracted.emit(self, interactor)
	var lines: Array[String] = []
	if is_description:
		lines.assign(description_lines)
		DescriptionRequested.emit(lines)
		SignalBus.ComponentDescriptionRequested.emit(self, lines)
		if show_first_dialog:
			SignalBus.DialogBox.emit(&"旁白", first_dialog_text)
	else:
		lines.assign(monologue_lines)
		MonologueRequested.emit(lines)
		SignalBus.ComponentMonologueRequested.emit(self, lines)
		if show_repeat_dialog:
			SignalBus.DialogBox.emit(&"独白", repeat_dialog_text)
	_dispatching = false
	return true

## 导出交互组件持久化存档数据。
func ExportSaveData() -> Dictionary:
	return {"description_requested": _description_requested}

## 加载并恢复交互组件存档数据。
## @param data 包含 description_requested 状态的字典。
func LoadSaveData(data: Dictionary) -> void:
	_description_requested = bool(data.get("description_requested", false))

func _on_body_entered(body: Node2D) -> void:
	if (body.is_in_group("player") or body is CharacterBody2D) and body not in _players:
		_players.append(body)
		if show_enter_dialog:
			SignalBus.DialogBox.emit(&"旁白", enter_dialog_text)
	_refresh_prompt()

func _on_body_exited(body: Node2D) -> void:
	_players.erase(body)
	_refresh_prompt()

func _on_prompt_pressed() -> void:
	if not _players.is_empty():
		Interact(_players[0])

func _refresh_prompt() -> void:
	_prompt.visible = enable_interaction and not _players.is_empty()
	if not enable_interaction:
		return
	var bound_event := KeybindManager.GetPrimaryEventForAction(interaction_action)
	_button.button_mask = MOUSE_BUTTON_MASK_RIGHT
	if bound_event is InputEventMouseButton:
		_button.button_mask |= 1 << (bound_event.button_index - 1)
	_key_badge.text = KeybindManager.GetActionKeyBadgeText(interaction_action, "右键")

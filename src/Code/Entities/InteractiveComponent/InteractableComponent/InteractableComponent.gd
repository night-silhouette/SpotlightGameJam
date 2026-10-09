extends Area2D
class_name InteractableComponent

## 每次成功交互时触发；interactor 为处于此交互区域内的玩家节点。
signal Interacted(interactor: Node2D)
## 首次交互时触发，按展示顺序传递物体描述文本数组。
signal DescriptionRequested(lines: Array[String])
## 后续重复交互时触发，按展示顺序传递内心独白文本数组。
signal MonologueRequested(lines: Array[String])

@export var description_lines: Array[String] = []
@export var monologue_lines: Array[String] = []
@export var interaction_action: StringName = &"interact"
@export var use_export_settings: bool = true

const KEYBIND_MANAGER = preload("res://Code/Entities/Setting/KeybindManager.gd")

@onready var _prompt: Control = $PromptContainer
@onready var _button: Button = $PromptContainer/PromptButton
@onready var _key_badge: Label = $PromptContainer/HBox/KeyBadge

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
	SignalBus.KeybindChanged.connect(_on_keybind_changed)
	_refresh_prompt()

func _physics_process(_delta: float) -> void:
	_players = _players.filter(func(player: Node2D) -> bool: return is_instance_valid(player))
	_refresh_prompt()

func _unhandled_input(event: InputEvent) -> void:
	if not InputMap.has_action(interaction_action):
		return
	if event.is_action_pressed(interaction_action) and not _players.is_empty():
		Interact(_players[0])
		get_viewport().set_input_as_handled()

## 执行交互逻辑：首次交互请求描述文本，后续交互请求内心独白文本。
## @param interactor 必须为当前重叠区域内有效的玩家节点。
## @return 交互成功返回 true，否则返回 false。
func Interact(interactor: Node2D) -> bool:
	if _dispatching or not is_instance_valid(interactor) or interactor not in _players:
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
	else:
		lines.assign(monologue_lines)
		MonologueRequested.emit(lines)
		SignalBus.ComponentMonologueRequested.emit(self, lines)
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
	_refresh_prompt()

func _on_body_exited(body: Node2D) -> void:
	_players.erase(body)
	_refresh_prompt()

func _on_prompt_pressed() -> void:
	if not _players.is_empty():
		Interact(_players[0])

func _on_keybind_changed(_action: StringName, _description: String) -> void:
	_refresh_prompt()

func _refresh_prompt() -> void:
	_prompt.visible = not _players.is_empty()
	_key_badge.text = KEYBIND_MANAGER.GetActionKeyBadgeText(interaction_action, "F")

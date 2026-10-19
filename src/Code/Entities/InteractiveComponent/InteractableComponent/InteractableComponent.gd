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
## 是否允许通过交互键或点击碰撞区域交互。
@export var enable_interaction: bool = true
## 本组件触发的对话框显示期间是否禁止玩家输入；关闭对话后恢复，玩家动画与物理仍继续运行。
@export var disable_movement_during_dialog: bool = false

@export_group("进入区域对话")
## 玩家每次进入交互区域时，是否立即显示进入区域对话；不受 [member enable_interaction] 影响。
@export var show_enter_dialog: bool = false
## 进入区域对话是否要求玩家当前持有刻痕枯骨。
@export var enter_dialog_requires_scarred_bones: bool = false
## 进入区域时按顺序显示的对话；仅在 [member show_enter_dialog] 开启时使用。
@export var enter_dialog_lines: Array[PlotDialogLine] = []
## 进入区域对话是否仅触发一次；开启后首次进入时显示并存档标记，之后（含读档后）不再显示。仅在 [member show_enter_dialog] 开启时生效。
@export var enter_dialog_once: bool = false

@export_group("首次交互对话")
## 第一次成功交互时是否显示对话；首次状态可随组件存档恢复。
@export var show_first_dialog: bool = false
## 首次交互时按顺序显示的对话；仅在 [member show_first_dialog] 开启时使用。
@export var first_dialog_lines: Array[PlotDialogLine] = []

@export_group("后续交互对话")
## 第二次及以后成功交互时是否显示对话。
@export var show_repeat_dialog: bool = false
## 后续交互时按顺序显示的对话；仅在 [member show_repeat_dialog] 开启时使用。
@export var repeat_dialog_lines: Array[PlotDialogLine] = []
@export_group("剧情对话")
## 供关卡剧情脚本逐句展示的旁白／独白；按数组顺序排列，每句的类型和文字可在检查器中编辑。
@export var story_lines: Array[PlotDialogLine] = []
@export_group("")

@onready var _collision_shape: CollisionShape2D = $CollisionShape2D

var _players: Array[Node2D] = []
var _description_requested: bool = false
var _enter_dialog_triggered: bool = false
var _dispatching: bool = false
var _dialog_box: Node
var _locked_players: Dictionary = {}

func _ready() -> void:
	_fit_collision_to_art()
	add_to_group("touch_interactables")
	var ancestor: Node = self
	while ancestor != null and _dialog_box == null:
		_dialog_box = ancestor.get_node_or_null("DialogBox")
		ancestor = ancestor.get_parent()
	if _dialog_box != null:
		_dialog_box.Finished.connect(_unlock_players)
	if use_export_settings:
		interaction_action = ExportSettings.interactable_action
		if description_lines.is_empty():
			description_lines.assign(ExportSettings.interactable_description_lines)
		if monologue_lines.is_empty():
			monologue_lines.assign(ExportSettings.interactable_monologue_lines)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _fit_collision_to_art() -> void:
	# 纯进入区域剧情沿用手工触发范围，不按装饰图改变区域。
	if not enable_interaction:
		return
	var bounds := Rect2()
	var has_art := false
	for child in get_children():
		var sprite := child as Sprite2D
		if sprite == null or sprite.texture == null or not sprite.visible:
			continue
		var rect := sprite.get_rect()
		for corner in [rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)]:
			var point: Vector2 = sprite.transform * corner
			if not has_art:
				bounds = Rect2(point, Vector2.ZERO)
				has_art = true
			else:
				bounds = bounds.expand(point)
	if not has_art or not bounds.has_area():
		return
	# 每个实体独享形状，避免修改共享场景资源影响其他交互物。
	var shape := RectangleShape2D.new()
	shape.size = bounds.size
	_collision_shape.transform = Transform2D(0.0, bounds.get_center())
	_collision_shape.shape = shape

func _physics_process(_delta: float) -> void:
	_players = _players.filter(func(player: Node2D) -> bool: return is_instance_valid(player))
	for input_control in _locked_players:
		if not is_instance_valid(input_control):
			continue
		var player := input_control.get_parent() as Player
		if player != null and player.is_on_floor() and player.move_state_machine.cur_state_name == "fall":
			input_control.set("is_idle", true)

func _unhandled_input(event: InputEvent) -> void:
	if not enable_interaction or not is_visible_in_tree() or not event.is_action_pressed(interaction_action):
		return
	if event is InputEventMouseButton:
		var mouse_position := get_global_mouse_position()
		if not _contains_world_point(mouse_position):
			return
		# 重叠时优先前景交互物，避免雕塑先于其上的王冠消耗点击。
		for candidate in get_tree().get_nodes_in_group("touch_interactables"):
			var other := candidate as InteractableComponent
			if other == null or other == self or not other.enable_interaction or not other.is_visible_in_tree() or not other.is_processing_unhandled_input():
				continue
			if other._get_interaction_z_index() > _get_interaction_z_index() and other._contains_world_point(mouse_position):
				return
	for candidate in get_tree().get_nodes_in_group("player"):
		var player := candidate as Node2D
		if player != null and Interact(player):
			get_viewport().set_input_as_handled()
			return

func _contains_world_point(world_pos: Vector2) -> bool:
	var shape := _collision_shape.shape as RectangleShape2D
	return shape != null and not _collision_shape.disabled and Rect2(-shape.size * 0.5, shape.size).has_point(_collision_shape.to_local(world_pos))

func _get_interaction_z_index() -> int:
	var result := z_index
	var item: CanvasItem = self
	while item.z_as_relative:
		item = item.get_parent() as CanvasItem
		if item == null:
			break
		result += item.z_index
	return result

func TryTouchInteract(world_pos: Vector2, interactor: Node2D) -> bool:
	var shape := _collision_shape.shape as RectangleShape2D
	if shape == null or not Rect2(-shape.size * 0.5, shape.size).has_point(_collision_shape.to_local(world_pos)):
		return false
	return Interact(interactor)

## 执行交互逻辑：首次交互请求描述文本，后续交互请求内心独白文本；不限制玩家距离。
## @param interactor 必须为有效的玩家节点，无需与区域重叠。
## @return 交互成功返回 true，否则返回 false。
func Interact(interactor: Node2D) -> bool:
	if not enable_interaction or _dispatching or not is_instance_valid(interactor):
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
			_show_dialog_lines(first_dialog_lines)
	else:
		lines.assign(monologue_lines)
		MonologueRequested.emit(lines)
		SignalBus.ComponentMonologueRequested.emit(self, lines)
		if show_repeat_dialog:
			_show_dialog_lines(repeat_dialog_lines)
	_dispatching = false
	return true

## 导出交互组件持久化存档数据。
func ExportSaveData() -> Dictionary:
	return {"description_requested": _description_requested, "enter_dialog_triggered": _enter_dialog_triggered}

## 加载并恢复交互组件存档数据。
## @param data 包含 description_requested 与 enter_dialog_triggered 状态的字典。
func LoadSaveData(data: Dictionary) -> void:
	_description_requested = bool(data.get("description_requested", false))
	_enter_dialog_triggered = bool(data.get("enter_dialog_triggered", false))

func _on_body_entered(body: Node2D) -> void:
	if (body.is_in_group("player") or body is CharacterBody2D) and body not in _players:
		_players.append(body)
		if show_enter_dialog and (not enter_dialog_once or not _enter_dialog_triggered) and (not enter_dialog_requires_scarred_bones or (body is Player and body.has_scarred_bones)):
			_enter_dialog_triggered = true
			_show_dialog_lines(enter_dialog_lines)

func ShowStoryDialogLine(line: PlotDialogLine) -> void:
	if line != null:
		var lines: Array[PlotDialogLine] = [line]
		_show_dialog_lines(lines)

func _show_dialog_lines(lines: Array[PlotDialogLine]) -> void:
	for line in lines:
		if line != null:
			var dialog_type := StringName(line.dialog_type)
			if disable_movement_during_dialog and _dialog_box != null and dialog_type in [&"旁白", &"独白"]:
				_lock_players()
			SignalBus.DialogBox.emit(dialog_type, line.text)

func _lock_players() -> void:
	for candidate in get_tree().get_nodes_in_group("player"):
		var player := candidate as Node2D
		if player == null:
			continue
		var input_control := player.get_node_or_null("GameInputControl")
		if input_control == null or _locked_players.has(input_control):
			continue
		_locked_players[input_control] = input_control.is_physics_processing()
		input_control.set_physics_process(false)
		input_control.set("row_dir", 0.0)
		input_control.set("column_dir", 0.0)
		input_control.set("is_jump", false)
		input_control.set("is_double_jump", false)
		input_control.set("is_dash", false)
		input_control.set("is_run", false)
		var wait_for_run: bool = player is Player and player.move_state_machine.cur_state_name == "run"
		input_control.set("is_idle", player is CharacterBody2D and player.is_on_floor() and not wait_for_run)
		if wait_for_run:
			_finish_running_cycle(player as Player, input_control)

func _finish_running_cycle(player: Player, input_control: Node) -> void:
	var animation := player.ani_move.get_animation("run")
	var remaining := (animation.length - player.ani_move.current_animation_position) / absf(player.ani_move.get_playing_speed())
	await get_tree().create_timer(maxf(remaining, 0.0)).timeout
	if not is_inside_tree() or not is_instance_valid(player) or not _locked_players.has(input_control):
		return
	if player.move_state_machine.cur_state_name == "run":
		if player.is_on_floor():
			input_control.set("is_idle", true)
			player.move_state_machine.change_state("idle")
		else:
			player.move_state_machine.change_state("fall")

func _unlock_players() -> void:
	for input_control in _locked_players:
		if is_instance_valid(input_control):
			input_control.set_physics_process(_locked_players[input_control])
	_locked_players.clear()

func _exit_tree() -> void:
	_unlock_players()

func _on_body_exited(body: Node2D) -> void:
	_players.erase(body)

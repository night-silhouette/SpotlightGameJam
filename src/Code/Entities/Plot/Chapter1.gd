extends Node2D

const NARRATION: StringName = &"旁白"
const MONOLOGUE: StringName = &"独白"

@onready var _dialog_box = get_node("../../DialogBox")

var _next_event: int = 0
var _line_index: int = 0
var _running: bool = false
var _generation: int = 0

func _ready() -> void:
	for trigger in get_children():
		if trigger is InteractableComponent:
			trigger.enable_interaction = false
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
	var event_index := int(trigger.get_meta("chapter_event", -1))
	if event_index != _next_event:
		return
	_run_event(event_index)

func _run_event(event_index: int) -> void:
	if _running:
		return
	_running = true
	var generation := _generation
	var lines: Array[Dictionary] = _event_lines(event_index)
	while _line_index < lines.size():
		var line: Dictionary = lines[_line_index]
		SignalBus.DialogBox.emit(line["type"], line["text"])
		await _dialog_box.Closed
		if generation != _generation or not is_inside_tree():
			return
		_line_index += 1
	_next_event = event_index + 1
	_line_index = 0
	_running = false
	_try_next_if_overlapping()

func _try_next_if_overlapping() -> void:
	if _running or _next_event < 1 or _next_event > 6:
		return
	for trigger in get_children():
		if trigger is InteractableComponent and int(trigger.get_meta("chapter_event", -1)) == _next_event:
			for body in trigger.get_overlapping_bodies():
				if body.is_in_group("player"):
					_run_event(_next_event)
					return

func _event_lines(event_index: int) -> Array[Dictionary]:
	match event_index:
		0:
			return _lines([[NARRATION, "这是哪里……"], [MONOLOGUE, "好痛……身体像被火烧过一样……水，我需要水！"]])
		1:
			return _lines([[NARRATION, "【靠近水源可快速补充水分】"], [NARRATION, "冰凉舒缓的水滑入喉管。"], [MONOLOGUE, "慢慢找回呼吸的节奏了，刚刚那种心脏快要干涸的感觉消失了……"], [MONOLOGUE, "虽然不知道为什么，但看来得一直保持身体里的水分才行，一旦缺水，恐怕行动都会成问题。"]])
		2:
			return _lines([[NARRATION, "水面的涟漪倒映出一张完全陌生的脸。"], [MONOLOGUE, "这，这是我吗……脸上是什么……"]])
		3:
			return _lines([[MONOLOGUE, "这帐篷……是用无数片颜色各异的碎布料拼凑缝补的。有人在这里生活过？"]])
		4:
			return _lines([[NARRATION, "帐篷外的沙地上放着一件斗篷，有别致的纹路。"]])
		5:
			return _lines([[NARRATION, "残破的石碑，上方一行字，下方有刻痕形成的图案，经历了风吹日晒，还附着着很多沙土，均已有些模糊不清。图案是几个火柴人影，看起来像是高举手臂，整个身体向上延伸（其实是幻化成云的过程）；天上的云；短而粗劣的竖向线条（其实是雨）。"], [MONOLOGUE, "这上面有字，“寻找，直到最后XXXXX。”好难辨认，后面几个字几乎看不清了啊。\n还有……这是一幅画吗？画上的人在干什么，好像在朝着远处挥手？这些竖道又是什么……"], [MONOLOGUE, "这是谁留下的，为什么偏偏出现在这里？他似乎知道些什么……难道他也曾像我一样，不知何去何从……"]])
		6:
			return _lines([[MONOLOGUE, "不管怎样，看来我只能沿着这些线索继续走下去了。那么，先去画上人挥手的方向看看吧。"]])
	return []

func _lines(raw: Array) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for item in raw:
		result.append({"type": item[0], "text": item[1]})
	return result

func ExportSaveData() -> Dictionary:
	return {"next_event": _next_event, "line_index": _line_index}

func LoadSaveData(data: Dictionary) -> void:
	_generation += 1
	_next_event = clampi(int(data.get("next_event", 0)), 0, 7)
	_line_index = clampi(int(data.get("line_index", 0)), 0, _event_lines(_next_event).size() - 1) if _next_event < 7 else 0
	if _running:
		_dialog_box.Dismiss()
		_running = false
	if is_node_ready() and _next_event == 0:
		_run_event(0)

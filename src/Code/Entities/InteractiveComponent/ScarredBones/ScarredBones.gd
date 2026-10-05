extends Node2D
## 枯骨本体通过通用靠近交互组件接收请求。正式文字、玩家拔取动作、镜头与追逐由后续模块接入。
## 调参入口：ExportSettings 的 Interactive - Scarred Bones 分组。
## 持久化由关卡按稳定节点路径保存 ExportSaveData()，本实体不写存档文件。

@onready var _detection: Area2D = $DetectionArea
@onready var _interaction: ProximityInteraction = $Interaction
@onready var _visual: Node2D = $VisualRoot
@onready var _prompt: Control = $PromptAnchor/Prompt

var _collected: bool = false
var _presentation: Tween
var _visual_start: Vector2
var _restore_pending: bool = false


func _ready() -> void:
	_visual_start = _visual.position
	_interaction.Configure(self, _detection, _prompt, ExportSettings.scarred_bones_interact_radius, ExportSettings.scarred_bones_prompt_text, ExportSettings.scarred_bones_prompt_font_size)
	SignalBus.InteractionRequested.connect(_on_interaction_requested)
	_apply_stable_state()
	if _restore_pending:
		_restore_pending = false
		SignalBus.ScarredBonesStateRestored.emit(self, _collected)


func _on_interaction_requested(target: Node2D, player: Node2D) -> void:
	if target == self:
		TryCollect(player)


## 尝试取得枯骨，供当前输入或后续公共交互系统调用。
## @param player 原玩家节点，必须位于检测区、属于 player 组、未死亡且可处理输入。
## @return 成功时返回 true 并广播一次取得事件；重复、越界或无效请求返回 false。
func TryCollect(player: Node2D) -> bool:
	if not is_node_ready() or _collected or not _interaction.CanInteract(player):
		return false
	# 先提交状态，再启动表现并广播，防止连续输入或监听方回调导致重复领取。
	_collected = true
	_interaction.SetEnabled(false)
	_presentation = create_tween()
	_presentation.tween_property(_visual, "position", _visual_start + Vector2.UP * ExportSettings.scarred_bones_lift_height, maxf(0.01, ExportSettings.scarred_bones_lift_duration)).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_presentation.tween_interval(maxf(0.0, ExportSettings.scarred_bones_display_duration))
	_presentation.tween_property(_visual, "modulate:a", 0.0, maxf(0.01, ExportSettings.scarred_bones_fade_duration))
	_presentation.tween_callback(_on_presentation_finished)
	SignalBus.ScarredBonesCollected.emit(self, player)
	return true


## 查询是否已经取得信物；展示进行中也算已取得。
## @return true 表示不可再次拾取。
func IsCollected() -> bool:
	return _collected


## 导出稳定拾取状态，不保存播放到一半的占位动画。
## @return 可序列化字典；由关卡或存档系统负责关联实体标识与写入磁盘。
func ExportSaveData() -> Dictionary:
	return {"collected": _collected}


## 恢复稳定拾取状态，可在加入场景树之前调用；不会重播取得事件。
## @param data ExportSaveData 返回的字典。缺少 collected 时视为未取得；非布尔值忽略。
func LoadSaveData(data: Dictionary) -> void:
	var value: Variant = data.get("collected", false)
	if not value is bool:
		return
	_collected = value
	if not is_node_ready():
		_restore_pending = true
		return
	_apply_stable_state()
	SignalBus.ScarredBonesStateRestored.emit(self, _collected)


func _apply_stable_state() -> void:
	if _presentation != null and _presentation.is_valid():
		_presentation.kill()
	_presentation = null
	_visual.position = _visual_start
	_visual.modulate.a = 1.0
	_visual.visible = not _collected
	_prompt.hide()
	_interaction.SetEnabled(not _collected)


func _on_presentation_finished() -> void:
	_visual.hide()
	SignalBus.ScarredBonesPresentationFinished.emit(self)

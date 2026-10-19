extends Node2D

const CHANNEL: StringName = &"chapter5_after_enemy_definition"

@export_node_path("Node2D") var lake_anchor: NodePath
@export_node_path("Sprite2D") var stele_path: NodePath
@export var stele_material: ShaderMaterial
@onready var _rain: Control = $Presentation/Rain
@onready var _inscription: Label = $Presentation/Layout/Inscription
@onready var _resume: Button = $Presentation/Layout/Resume
@onready var _menu: Button = $Presentation/Layout/Menu
@onready var _phantom: Sprite2D = $Phantom
var _player: Node2D
var _active := false
var _pending := false
var _completed := false
var _loaded := false
var _step := -1
var _elapsed := 0.0
var _dialog_wait := false
var _origin: Vector2
var _direction := 1
var _steps: Array[Dictionary] = []
var _overflow := 0.0
var _rain_time := 0.0
var _phantom_time := -1.0
var _finishing := false
var _turn_wait := false
var _stele: Sprite2D
var _stele_texture: Texture2D
var _stele_original_material: Material
var _stele_effect: ShaderMaterial
var _stele_drying := false
var _stele_wetness := 0.0
@onready var _surge: ColorRect = $Presentation/Surge
@onready var _black: ColorRect = $Presentation/Black
@onready var _thunder: AudioStreamPlayer = $Thunder
@onready var _rain_audio: AudioStreamPlayer = $RainAudio
var _audio_tweens: Array[Tween] = []
@onready var _surge_audio: AudioStreamPlayer = $SurgeAudio
var _wet_time := -1.0
var _lake_wait := false
var _ending_stage := ""
var _ending_time := 0.0
const STELE_CLEAR = preload("res://Art/New/component/game0/残碑_左.png")

func _ready() -> void:
	SignalBus.ChapterCardFinished.connect(_on_chapter_finished)
	SignalBus.Chapter5PlayerAcknowledged.connect(_on_player_acknowledged)
	SignalBus.Chapter5Cancelled.connect(_on_cancelled)
	SignalBus.Chapter5PoseFinished.connect(_on_pose_finished)
	SignalBus.SaveSlotLoaded.connect(_on_save_loaded)
	SignalBus.DialogPresentationFinished.connect(_on_dialog_finished)
	SignalBus.CameraShotReady.connect(_on_camera_ready)
	_thunder.finished.connect(_loop_audio.bind(_thunder))
	_rain_audio.finished.connect(_loop_audio.bind(_rain_audio))
	_resume.pressed.connect(_on_resume_pressed)
	_surge_audio.stream = _surge_audio.stream.duplicate()
	if _surge_audio.stream is AudioStreamWAV:
		(_surge_audio.stream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_DISABLED
	_menu.pressed.connect(_on_menu_pressed)
	_inscription.add_theme_font_size_override("font_size", ExportSettings.chapter5_text_size)
	_rain.material.set_shader_parameter("rain_color", ExportSettings.chapter5_rain_color)
	_rain.material.set_shader_parameter("drop_count", float(ExportSettings.chapter5_rain_count))

func _on_chapter_finished(channel: StringName) -> void:
	if channel == CHANNEL and not _active and not _completed and not _pending and not _loaded:
		_pending = true
		_try_start()

func _process(delta: float) -> void:
	if _pending and not _active and not _loaded:
		_try_start()
	if not _active:
		return
	if not is_instance_valid(_player) or _player.get("chapter5_locked") != true:
		_on_cancelled(self)
		return
	if _wet_time >= 0.0:
		_wet_time += delta
		_stele_wetness = move_toward(_stele_wetness, 0.0 if _stele_drying else 1.0, delta / maxf(ExportSettings.chapter5_stele_wet_duration, 0.01))
		_stele_effect.set_shader_parameter("elapsed", _wet_time)
		_stele_effect.set_shader_parameter("wetness", smoothstep(0.0, 1.0, _stele_wetness))
		if _stele_drying and _stele_wetness <= 0.0:
			_wet_time = -1.0
	if not _ending_stage.is_empty():
		_process_ending(delta)
	_elapsed += delta
	if _phantom_time >= 0.0:
		_phantom_time += delta
		var cycle := fmod(_phantom_time, 3.0) / 3.0
		_phantom.position = Vector2(sin(floor(_phantom_time / 3.0) * 2.4) * 42.0, -cycle * 100.0)
		_phantom.modulate.a = sin(cycle * PI) * 0.38
	if _rain.visible:
		_rain_time += delta
		_rain.material.set_shader_parameter("elapsed", _rain_time)
		var rain_progress := smoothstep(0.0, 1.0, minf(_rain_time / maxf(ExportSettings.chapter5_rain_build_duration, 0.01), 1.0))
		_rain.material.set_shader_parameter("intensity", lerpf(ExportSettings.chapter5_rain_initial_intensity, 1.0, rain_progress))
		_rain_audio.volume_db = lerpf(ExportSettings.chapter5_rain_volume_db - 35.0, ExportSettings.chapter5_rain_volume_db, rain_progress)
		if _overflow > 0.0:
			_overflow = move_toward(_overflow, 1.0, delta / maxf(ExportSettings.chapter5_rain_duration, 0.01))
		queue_redraw()
	if _turn_wait and _elapsed > float(_steps[_step].duration) + 2.0:
		_on_cancelled(self)
		return
	if _completed or _dialog_wait or _turn_wait or not _ending_stage.is_empty():
		return
	if _step >= 0 and _elapsed >= float(_steps[_step].get("duration", ExportSettings.chapter5_beat_duration)):
		_next_step()

func _try_start() -> void:
	_player = get_tree().get_first_node_in_group("player") as Node2D
	var anchor := get_node_or_null(lake_anchor) as Node2D
	if not is_instance_valid(_player) or anchor == null:
		_pending = false
		_resume.show()
		return
	if _player.get("offering_locked") == true or not _player.can_process() or SignalBus.IsGradualTextActive():
		return
	if _player is CharacterBody2D and not _player.is_on_floor():
		return
	global_position = anchor.global_position
	if not _prepare_stele():
		_pending = false
		return
	_origin = _player.global_position
	_direction = 1 if global_position.x >= _origin.x else -1
	SignalBus.Chapter5PlayerRequested.emit(_player, self, &"begin", {})

func _on_player_acknowledged(player: Node2D, source: Node, accepted: bool) -> void:
	if source != self or player != _player:
		return
	if not accepted:
		return
	_active = true
	SignalBus.CameraFixedRequested.emit(_player, self, "", "", Rect2())
	_pending = false
	_resume.hide()
	_steps = _build_steps()
	_step = -1
	_next_step()

func _build_steps() -> Array[Dictionary]:
	# 文案10.18 最终版(3).xlsx / Sheet1 / 97—121行；5-1已由章节卡显示。
	# 5-7、5-15括号内为演出备注；5-8、5-25仅演出，不作为台词播放。
	return [
		{"op": "approach", "text": "沙丘的尽头，那片熟悉的水面再次出现在眼前，仍旧安静地嵌在沙地之间。"},
		{"text": "信物立刻沉入水中，水面荡开一圈涟漪。片刻之后，水底隐约浮现出了幽微的光，那光并不激烈，只在水中缓缓流动。"},
		{"op": "change", "text": "指尖忽然传来一阵异样的感觉，这才猛然发觉，自己的身体边缘正变得模糊，细小的水汽不断从身上缓缓升起，悬浮在周围。"},
		{"type": &"独白", "text": "怎么回事，是错觉吗？"},
		{"op": "fear", "type": &"独白", "text": "不，不对，指尖已经没有感觉了，手掌的轮廓也快要看不清了！"},
		{"op": "retreat", "duration": ExportSettings.chapter5_step_duration, "type": &"独白", "text": "奇怪，变化停止了，不过水汽没有散去。"},
		{"duration": ExportSettings.chapter5_beat_duration},
		{"op": "phantom", "text": "水池边忽然浮现出一道模糊的身影。那身影低头看着水面，随后缓缓抬起头。主角看不清它的面容，只看见它的身体逐渐消散，升向天空。"},
		{"text": "幻影在水池周围不断闪现。有的久久凝望水面，有的席地而坐，有的回望身后的沙漠。一个身影消失，另一个又出现。"},
		{"type": &"独白", "text": "我能感觉到……他们和我一样……我们都是那本笔记里提到的……"},
		{"op": "stele", "text": "水汽掠过残碑，附着在冰冷的石面上，凝成了细密的水珠。水珠沿着凹陷的刻痕缓缓滑落，模糊的线条逐渐变得清晰。"},
		{"text": "原本不成意义的图案，连成了一幅完整的画。画中既有日族，也有月族，他们的身影似乎正缓缓升向天空，最终与云层融为一体。"},
		{"text": "水珠顺着石刻的纹路缓缓滑落，汇成一道细流，顺着水流看去，自己的双脚已悄然浮起。石碑上那些渐渐淡去的身影，与眼前正在发生的一切，终于重叠在了一起。"},
		{"type": &"独白", "text": "那是……雨……那些竖线，是雨！这就是使者的归宿……直到……直到最后一场雨落下。"},
		{"type": &"独白", "text": "难怪……蓄水池里的水，地下的水脉，还有那片湖，都没有在那次极昼灾难中干涸。\n幻化成云，留在这片天空里，又一次次化作雨，落回这片土地。这就是使者的归宿。\n他们都走过相似的道路，又都在这里作出了自己的选择，尽管永远都无法知道，自己的选择究竟会带来什么，甚至不确定这场雨会落在何处。"},
		{"type": &"独白", "text": "一滴雨或许微不足道，可千万滴雨落下，就足以让一个世界重新生长。"},
		{"type": &"独白", "text": "我一直都弄错了，我不是一个等待被找到的答案，我是曾经存在过的、即将要消失的、仍在未来等待的，所有的选择交织在一起，我是这些痕迹的一部分。我是我们。"},
		{"op": "choose", "duration": ExportSettings.chapter5_step_duration, "text": "想到这便不再试图抓住正在消散的身体，最后一缕犹豫随着叹气散去。向前迈出一步，水汽从脚下升起，托起越来越轻的身躯，向上飘去。"},
		{"op": "turn", "duration": 0.6},
		{"op": "ascend", "duration": ExportSettings.chapter5_ascent_duration},
		{"text": "身体——如果还能称为身体的话——融入了云雾之中。他们现下只是彼此交融的云雾，没有名字，也不再区分彼此来自白昼还是黑夜。他听到了从很久以前传来的低语，那声音很柔和。他闭上眼，任由风将他推向远方。"},
		{"op": "thunder", "text": "云层不断向远方延伸。高空中传来一阵低沉的雷声，细小的水珠沿着云雾迅速聚集。"},
		{"op": "rain", "text": "一滴雨穿过云层，落向沉默的沙地。随后，第二滴、第三滴接连落下。雨打湿了帐篷，也落入水池，刚才落入池中的斗篷也随之沉没，再也看不见了。"},
		{"text": "雨水越织越密，落在宫殿和图书馆的残垣上，暗淡的石壁重新显出了深沉的颜色。雨水落在那片埋葬着无数骸骨的绿洲里，渗入泥土，沿着草木的根须，一寸寸流向更深的地底。而那些从骸骨之间生长出来的植物，在雨中自由而欢快地舒展、摇曳着。"},
		{"op": "fill", "text": "水位还在缓缓上涨，浓云低垂，映在水面，绵密的雨丝也落进倒影之中。云与水，天与地，同色同影，同流同归，四野朦胧，浑然一体，一切都在这场似乎无边无际的雨中慢慢化开。"},
		{"op": "end", "duration": ExportSettings.chapter5_rain_duration}
	]

func _next_step() -> void:
	_step += 1
	_elapsed = 0.0
	if _step >= _steps.size():
		_start_ending()
		return
	var beat := _steps[_step]
	var op: String = beat.get("op", "")
	var pose: Dictionary = {}
	var step_duration: float = maxf(ExportSettings.chapter5_step_duration, 0.01)
	match op:
		"approach", "choose":
			pose = {"animation": &"run", "face": _direction, "target": _player.global_position + Vector2(_direction * ExportSettings.chapter5_approach_distance, 0), "duration": step_duration}
		"change":
			pose = {"vfx": &"tail_fade", "vapor": true}
		"retreat":
			pose = {"animation": &"run", "backwards": true, "pause_vfx": true, "face": _direction, "target": _player.global_position - Vector2(_direction * ExportSettings.chapter5_retreat_distance, 0), "duration": step_duration}
		"fear":
			pose = {"pause_vfx": true}
		"stele":
			_wet_time = 0.0
		"phantom":
			_phantom_time = 0.0
			_phantom.show()
		"turn":
			pose = {"animation": &"turn_back"}
			_turn_wait = true
		"ascend":
			_phantom.hide()
			_phantom_time = -1.0
			_inscription.hide()
			pose = {"animation": &"up_fly", "vfx": &"powder_dissolve", "airborne": true, "target": _player.global_position - Vector2(0, ExportSettings.chapter5_ascent_height), "duration": maxf(ExportSettings.chapter5_ascent_duration, 0.01)}
		"thunder":
			_start_audio(_thunder, ExportSettings.chapter5_thunder_volume_db, ExportSettings.chapter5_thunder_fade_duration)
			_rain_time = 0.0
			_rain.material.set_shader_parameter("intensity", ExportSettings.chapter5_rain_initial_intensity)
			_rain.show()
			_rain_audio.volume_db = ExportSettings.chapter5_rain_volume_db - 35.0
			_rain_audio.play()
		"fill":
			_overflow = 0.2
		"end":
			_overflow = maxf(_overflow, 0.2)
	if not pose.is_empty():
		SignalBus.Chapter5PlayerRequested.emit(_player, self, &"pose", pose)
	if beat.has("text"):
		_dialog_wait = true
		SignalBus.DialogBox.emit(beat.get("type", &"旁白"), beat.text)

func _on_pose_finished(player: Node2D, source: Node, animation: StringName) -> void:
	if _active and player == _player and source == self and animation == &"turn_back":
		_turn_wait = false

func _on_dialog_finished() -> void:
	if _active and _dialog_wait:
		_dialog_wait = false
		if _step >= 0 and _step < _steps.size() and _steps[_step].get("op", "") == "stele":
			_stele.texture = STELE_CLEAR
			_stele_effect.set_shader_parameter("texture_scale", _stele_texture.get_size() / STELE_CLEAR.get_size())
			_stele_drying = true

func _on_cancelled(source: Node) -> void:
	if source == self and not _finishing:
		_cancel()
		_pending = true
		_loaded = true
		_resume.show()

func _cancel() -> void:
	_finishing = true
	for tween in _audio_tweens:
		if tween.is_valid():
			tween.kill()
	_audio_tweens.clear()
	_thunder.stop()
	_rain_audio.stop()
	_ending_stage = ""
	_lake_wait = false
	_surge_audio.stop()
	_surge.material.set_shader_parameter("progress", 0.0)
	_surge.material.set_shader_parameter("elapsed", 0.0)
	_black.color.a = 0.0
	_surge.hide()
	_active = false
	_restore_stele()
	_wet_time = -1.0
	if _dialog_wait:
		SignalBus.Chapter5DialogueCancelled.emit()
	_dialog_wait = false
	_turn_wait = false
	_active = false
	if is_instance_valid(_player):
		SignalBus.Chapter5PlayerRequested.emit(_player, self, &"release", {})
		SignalBus.CameraNormalRequested.emit(_player)
	_pending = false
	_rain.hide()
	_phantom.hide()
	_inscription.hide()
	_menu.hide()
	_overflow = 0.0
	_rain_time = 0.0
	_rain.material.set_shader_parameter("elapsed", 0.0)
	_rain.material.set_shader_parameter("intensity", 0.0)
	_phantom_time = -1.0
	queue_redraw()
	_finishing = false

func _on_resume_pressed() -> void:
	_loaded = false
	_completed = false
	_pending = true
	_resume.hide()

func _on_menu_pressed() -> void:
	# 沿用已有显式返回菜单操作：仅此按钮点击后由既有流程决定保存与切场景。
	SignalBus.ReturnToMainMenuRequested.emit()

func _on_save_loaded(_slot: int) -> void:
	_loaded = _pending or _completed
	if _pending or _completed:
		_resume.text = "重看第五章" if _completed else "继续第五章"
		_resume.show()

func _exit_tree() -> void:
	_cancel()

## 导出第五章完成/待续标记；不自动保存，不保存演出瞬间或改写玩家位置。
func ExportSaveData() -> Dictionary:
	return {"pending": _pending or _active, "completed": _completed}

## 读取中断/完成状态后等待显式继续；尚未开始时保留正常章节卡自动衔接。
func LoadSaveData(data: Dictionary) -> void:
	_cancel()
	_pending = bool(data.get("pending", false))
	_completed = bool(data.get("completed", false))
	_loaded = _pending or _completed

func _draw() -> void:
	if _overflow <= 0.0:
		return
	var color: Color = ExportSettings.chapter5_overflow_color
	var radius: float = ExportSettings.chapter5_overflow_radius * (0.65 + _overflow * 0.7)
	draw_set_transform(Vector2.ZERO, 0, Vector2(1, 0.24))
	color.a *= _overflow * 0.28
	draw_circle(Vector2.ZERO, radius, color)
	for index in range(4):
		var ripple := fmod(_rain_time * 0.22 + float(index) * 0.25, 1.0)
		color.a = (1.0 - ripple) * _overflow * 0.5
		draw_arc(Vector2.ZERO, radius * (0.4 + ripple * 0.7), 0, TAU, 72, color, 2.0, true)

func _start_audio(audio: AudioStreamPlayer, volume: float, duration: float) -> void:
	audio.volume_db = -80.0
	audio.play()
	var tween := create_tween()
	tween.tween_property(audio, "volume_db", volume, maxf(duration, 0.01))
	_audio_tweens.append(tween)

func _loop_audio(audio: AudioStreamPlayer) -> void:
	if _active:
		audio.play()

func _start_ending() -> void:
	_ending_stage = "surge"
	_ending_time = 0.0
	_surge.material.set_shader_parameter("water_color", ExportSettings.chapter5_overflow_color)
	_surge.material.set_shader_parameter("progress", 0.0)
	_surge.material.set_shader_parameter("elapsed", 0.0)
	_surge.show()
	_surge_audio.volume_db = ExportSettings.chapter5_surge_volume_db
	_surge_audio.play()

func _on_camera_ready(player: Node2D, mode: StringName) -> void:
	if _active and player == _player and mode == &"fixed" and _ending_stage == "lake":
		_lake_wait = false

func _prepare_stele() -> bool:
	if is_instance_valid(_stele):
		return true
	_stele = get_node_or_null(stele_path) as Sprite2D
	if _stele == null or stele_material == null:
		return false
	_stele_texture = _stele.texture
	_stele_original_material = _stele.material
	_stele_effect = stele_material.duplicate() as ShaderMaterial
	_stele.material = _stele_effect
	return true

func _restore_stele() -> void:
	if is_instance_valid(_stele):
		_stele.texture = _stele_texture
		_stele.material = _stele_original_material
	_stele = null
	_stele_effect = null
	_stele_texture = null
	_stele_original_material = null
	_stele_drying = false
	_stele_wetness = 0.0

func _process_ending(delta: float) -> void:
	_ending_time += delta
	var fade: float = maxf(ExportSettings.chapter5_black_fade_duration, 0.01)
	match _ending_stage:
		"surge":
			var progress := minf(_ending_time / maxf(ExportSettings.chapter5_surge_duration, 0.01), 1.0)
			_surge.material.set_shader_parameter("progress", progress)
			_surge.material.set_shader_parameter("elapsed", minf(_ending_time, maxf(ExportSettings.chapter5_surge_duration, 0.01)))
			if progress >= 1.0:
				_ending_stage = "black"
				_ending_time = 0.0
		"black":
			_black.color.a = minf(_ending_time / fade, 1.0)
			if _black.color.a >= 1.0:
				_ending_stage = "lake"
				_ending_time = 0.0
				_lake_wait = true
				_surge.hide()
				SignalBus.Chapter5PlayerRequested.emit(_player, self, &"conceal", {})
				SignalBus.CameraFixedRequested.emit(_player, get_node(lake_anchor), "", "", Rect2())
		"lake":
			if not _lake_wait and _ending_time >= ExportSettings.chapter5_black_hold_duration:
				_ending_stage = "reveal"
				_ending_time = 0.0
		"reveal":
			_black.color.a = maxf(1.0 - _ending_time / fade, 0.0)
			if _black.color.a <= 0.0:
				_ending_stage = ""
				_completed = true
				# 保持剧情锁和湖泊固定镜头；设置菜单已有返回入口，不抢焦点。

extends Node

const GAME_BGMS = [
	preload("res://Music/bgm/MainMenu.wav"),
	preload("res://Music/bgm/GrowMaintheme.wav"),
]

const LEVEL3_BGM: AudioStreamWAV = preload("res://Music/bgm/MUSLv3.wav")
const BGM_CROSSFADE_DURATION: float = 2.5

# 仅保存本次运行的接近骸骨解锁；死亡及场景重载不清除，不写入存档。
var level3_bgm_unlocked: bool = false

var _bgm_player: AudioStreamPlayer
var _bgm_index: int = 0
var _bgm_mode: StringName = &"normal"
var _bgm_tracks: Dictionary = {}
var _bgm_tweens: Dictionary = {}

var _audio_initialized: bool = false
var _audio_volumes: Dictionary = {}
var _audio_buses: Dictionary = {}
var _audio_base_db: Dictionary = {}

func _ready() -> void:
	var cursor_image: Image = preload("res://Art/New/component/移动端/IMG_9839_切割/04_指针.png").get_image()
	for y in range(cursor_image.get_height()):
		for x in range(cursor_image.get_width()):
			cursor_image.set_pixel(x, y, Color(1.0, 1.0, 1.0, cursor_image.get_pixel(x, y).a))
	var cursor_texture: ImageTexture = ImageTexture.create_from_image(cursor_image)
	Input.set_custom_mouse_cursor(cursor_texture, Input.CURSOR_ARROW, Vector2.ZERO)
	Input.set_custom_mouse_cursor(cursor_texture, Input.CURSOR_POINTING_HAND, Vector2.ZERO)
	call_deferred("_start_game_audio")

func _start_game_audio() -> void:
	_initialize_audio_settings()
	_start_game_bgm()

func _start_game_bgm() -> void:
	if not is_instance_valid(_bgm_player):
		SetBgmMode(_bgm_mode)

func SetBgmMode(mode: StringName) -> void:
	if mode != &"normal" and mode != &"level3" and mode != &"camp":
		return
	if mode == _bgm_mode and is_instance_valid(_bgm_player):
		return
	_initialize_audio_settings()
	_bgm_mode = mode
	if mode == &"normal":
		_play_next_bgm()
	elif mode == &"level3":
		_switch_bgm(LEVEL3_BGM, true)
	else:
		_switch_bgm(GAME_BGMS[0], true)

func _play_next_bgm() -> void:
	var music: AudioStreamWAV = GAME_BGMS[_bgm_index]
	_bgm_index = (_bgm_index + 1) % GAME_BGMS.size()
	_switch_bgm(music, false)

func _switch_bgm(music: AudioStreamWAV, loop: bool) -> void:
	var next_player: AudioStreamPlayer = null
	for track_player: AudioStreamPlayer in _bgm_tracks:
		if _bgm_tracks[track_player] == music and track_player.playing:
			next_player = track_player
			break
	if next_player == null:
		next_player = AudioStreamPlayer.new()
		next_player.process_mode = Node.PROCESS_MODE_ALWAYS
		next_player.bus = ExportSettings.audio_music_bus
		next_player.volume_linear = 0.0
		next_player.stream = music.duplicate() as AudioStreamWAV
		next_player.finished.connect(_on_bgm_finished.bind(next_player))
		add_child(next_player)
		_bgm_tracks[next_player] = music
	var stream := next_player.stream as AudioStreamWAV
	if loop:
		stream.loop_begin = 0
		stream.loop_end = int(round(stream.get_length() * stream.mix_rate))
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD if loop else AudioStreamWAV.LOOP_DISABLED
	_bgm_player = next_player
	if not next_player.playing:
		next_player.play()
	for track_player: AudioStreamPlayer in _bgm_tracks:
		var target_volume: float = db_to_linear(ExportSettings.audio_bgm_volume_db) if track_player == next_player else 0.0
		_fade_bgm(track_player, target_volume)

func _fade_bgm(player: AudioStreamPlayer, target_volume: float) -> void:
	if _bgm_tweens.has(player):
		var previous_tween: Tween = _bgm_tweens[player]
		previous_tween.kill()
	var tween: Tween = player.create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_bgm_tweens[player] = tween
	tween.tween_property(player, "volume_linear", target_volume, BGM_CROSSFADE_DURATION)
	tween.tween_callback(_on_bgm_faded.bind(player))

func _on_bgm_faded(player: AudioStreamPlayer) -> void:
	_bgm_tweens.erase(player)
	if player != _bgm_player:
		_release_bgm(player)

func _on_bgm_finished(player: AudioStreamPlayer) -> void:
	var was_current: bool = player == _bgm_player
	if was_current:
		_bgm_player = null
	_release_bgm(player)
	if was_current and _bgm_mode == &"normal":
		_play_next_bgm()

func _release_bgm(player: AudioStreamPlayer) -> void:
	if _bgm_tweens.has(player):
		var tween: Tween = _bgm_tweens[player]
		tween.kill()
		_bgm_tweens.erase(player)
	_bgm_tracks.erase(player)
	player.stop()
	player.queue_free()

## 初始化并恢复独立音量设置；无参数，可重复调用且不会重置总线基准音量。
func InitializeAudioSettings() -> void:
	_initialize_audio_settings()

## 读取音量比例。
## @param channel 类别为 master 总音量、music 音乐、sfx 音效、dialogue 对白或 ambience 环境。
## @return 0.0-1.0 的线性音量比例；未知类别返回 1.0。
func GetAudioVolume(channel: StringName) -> float:
	_initialize_audio_settings()
	return float(_audio_volumes.get(channel, 1.0))

## 调整音量、应用音频总线并独立持久化，同时发送音量变化通知。
## @param channel 类别为 master 总音量、music 音乐、sfx 音效、dialogue 对白或 ambience 环境，未知类别忽略。
## @param volume 有限的线性音量比例，限制到 0.0-1.0，0 表示静音。
func SetAudioVolume(channel: StringName, volume: float) -> void:
	_initialize_audio_settings()
	if not _audio_volumes.has(channel) or not is_finite(volume):
		return
	_audio_volumes[channel] = clampf(volume, 0.0, 1.0)
	_apply_audio_volume(channel)
	var config := ConfigFile.new()
	for audio_channel in _audio_volumes:
		config.set_value("volume", String(audio_channel), _audio_volumes[audio_channel])
	var error := config.save(ExportSettings.audio_settings_path)
	if error != OK:
		push_warning("音量设置保存失败，错误码：%d" % error)
	SignalBus.AudioVolumeChanged.emit(channel, _audio_volumes[channel])

func _initialize_audio_settings() -> void:
	if _audio_initialized:
		return
	_audio_initialized = true
	_audio_volumes = {
		&"master": ExportSettings.audio_master_volume,
		&"music": ExportSettings.audio_music_volume,
		&"sfx": ExportSettings.audio_sfx_volume,
		&"dialogue": ExportSettings.audio_dialogue_volume,
		&"ambience": ExportSettings.audio_ambience_volume,
	}
	_audio_buses = {
		&"master": ExportSettings.audio_master_bus,
		&"music": ExportSettings.audio_music_bus,
		&"sfx": ExportSettings.audio_sfx_bus,
		&"dialogue": ExportSettings.audio_dialogue_bus,
		&"ambience": ExportSettings.audio_ambience_bus,
	}
	SignalBus.AudioVolumeChangeRequested.connect(SetAudioVolume)
	var config := ConfigFile.new()
	var loaded := config.load(ExportSettings.audio_settings_path) == OK
	for channel in _audio_volumes:
		var bus_index := AudioServer.get_bus_index(_audio_buses[channel])
		if bus_index >= 0:
			_audio_base_db[channel] = AudioServer.get_bus_volume_db(bus_index)
		else:
			push_warning("音量设置找不到音频总线：%s" % _audio_buses[channel])
		if loaded:
			var saved_volume: Variant = config.get_value("volume", String(channel), _audio_volumes[channel])
			if (saved_volume is float or saved_volume is int) and is_finite(float(saved_volume)):
				_audio_volumes[channel] = clampf(float(saved_volume), 0.0, 1.0)
		_apply_audio_volume(channel)
		SignalBus.AudioVolumeChanged.emit(channel, _audio_volumes[channel])

func _apply_audio_volume(channel: StringName) -> void:
	var bus_index := AudioServer.get_bus_index(_audio_buses[channel])
	if bus_index < 0 or not _audio_base_db.has(channel):
		return
	var volume: float = _audio_volumes[channel]
	AudioServer.set_bus_mute(bus_index, volume == 0.0)
	if volume > 0.0:
		AudioServer.set_bus_volume_db(bus_index, float(_audio_base_db[channel]) + linear_to_db(volume))


#时间到了,触发回调函数
func setTime(time,callback)->SceneTreeTimer:
	var temp=get_tree().create_timer(time)
	temp.timeout.connect(callback,CONNECT_ONE_SHOT)
	return temp
	#输出定时器本身,输出出来,以便于.stop()

## 兼容小写 set_time 调用
func set_time(time, callback) -> SceneTreeTimer:
	return setTime(time, callback)

	
	
#点击area2D,触发回调
func Area2dConnectClick(area2d:Area2D,callback:Callable)->void:
	area2d.input_event.connect(func(obj,event,id):
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
				callback.call()
		)
	
#松开鼠标
func Area2dConnectRelease(area2d: Area2D, callback: Callable) -> void:
	area2d.input_event.connect(func(_viewport, event, _shape_idx):
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
				callback.call()
	)
	
#改变节点的texture
func SetNodeTexture(node: Node, new_texture: Texture2D) -> void:
	if node and "texture" in node:
		node.texture = new_texture


	
#tween_fast_to_slow($Sprite2D, "modulate:a", 0.0, 1.0(时间), func():
	#print("淡出动画播完了！")
#)

#callback是补间动画结束触发的回调	
func TweenFastToSlow(obj,prop:String,value,time,callback=func():pass):
	var tween=create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)	
	tween.tween_property(obj,prop, value,time)
	tween.finished.connect(callback)
	return tween#tween的引用没有了之后,tween.finished.connect(callback)这个的信号也会随之free,所以可以大胆的对这个tween.kill()

# callback是补间动画结束触发的回调	
func TweenSlowToFast(obj, prop:String, value, time, callback = func(): pass):
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_CUBIC)	
	tween.tween_property(obj, prop, value, time)
	tween.finished.connect(callback)
	return tween
	
	
# 大数字简洁格式化
# 小于 1K 显示普通数字；从 K 开始缩写，输出 1K、1M、1B、1T 这种干净形式
func FormatNumber(num: float) -> String:
	# 从 K(10^3) 开始；之后每 1000 倍进一位：K M B T Qa Qi Sx Sp ...
	var suffixes := ["K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp"]
	var value := num
	var divisor := 1_000.0

	# K 之前直接显示普通数字
	if value < divisor:
		# 整数就不带小数点
		if value == floor(value):
			return str(int(value))
		return str(value)

	var idx := 0
	while value >= divisor * 1000.0 and idx < suffixes.size() - 1:
		divisor *= 1000.0
		idx += 1

	var result := value / divisor

	# 干净显示：整除就不带小数，否则最多保留一位小数并去掉末尾的 .0
	if result == floor(result):
		return "%d%s" % [int(result), suffixes[idx]]
	else:
		var s := "%.1f" % result
		if s.ends_with(".0"):
			s = s.left(s.length() - 2)
		return s + suffixes[idx]	
	


class AreaHoldHelper extends Node:
	var area: Area2D
	var press_callback: Callable
	var release_callback: Callable
	var is_inside := false
	var is_holding := false
	
	func _init(p_area: Area2D, p_press_cb: Callable, p_release_cb: Callable) -> void:
		area = p_area
		press_callback = p_press_cb
		release_callback = p_release_cb
		
	func _ready() -> void:
		area.mouse_entered.connect(func(): is_inside = true)
		area.mouse_exited.connect(func(): is_inside = false)
		
	func _input(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed and is_inside:
				is_holding = true
				if press_callback.is_valid():
					press_callback.call()
			elif not event.pressed and is_holding:
				is_holding = false
				if release_callback.is_valid():
					release_callback.call()

func Area2dConnectHold(area2d: Area2D, press_callback: Callable, release_callback: Callable = Callable()) -> void:
	var helper = AreaHoldHelper.new(area2d, press_callback, release_callback)
	area2d.add_child(helper)

## 播放音效辅助函数（自动挂接到对应总线并在播放完毕后释放）
## @param stream 要播放的音频资源 (AudioStream)
## @param bus_name 总线名称 (如 "SFX_Interact", "SFX_Move_Dry", "SFX_Footstep_Dry" 等)
## @param volume_db 音量分贝调节
## @param pitch 音调缩放
## @return 生成的 AudioStreamPlayer 实例
func PlaySFX(stream: AudioStream, bus_name: StringName = &"SFX_Interact", volume_db: float = 0.0, pitch: float = 1.0) -> AudioStreamPlayer:
	if not stream:
		return null
	var player = AudioStreamPlayer.new()
	player.stream = stream
	player.bus = bus_name
	player.volume_db = volume_db
	player.pitch_scale = pitch
	get_tree().root.add_child(player)
	player.play()
	player.finished.connect(player.queue_free)
	return player

## 2D空间位置播放音效辅助函数（自动挂接到对应总线并在播放完毕后释放）
## @param stream 要播放的音频资源 (AudioStream)
## @param global_pos 播放的世界坐标
## @param bus_name 总线名称 (如 "SFX_Interact", "SFX_Move_Dry" 等)
## @param volume_db 音量分贝调节
## @param pitch 音调缩放
## @return 生成的 AudioStreamPlayer2D 实例
func PlaySFX2D(stream: AudioStream, global_pos: Vector2, bus_name: StringName = &"SFX_Interact", volume_db: float = 0.0, pitch: float = 1.0) -> AudioStreamPlayer2D:
	if not stream:
		return null
	var player = AudioStreamPlayer2D.new()
	player.stream = stream
	player.bus = bus_name
	player.volume_db = volume_db
	player.pitch_scale = pitch
	player.global_position = global_pos
	get_tree().root.add_child(player)
	player.play()
	player.finished.connect(player.queue_free)
	return player

	
	

	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
#region Napori
func FakeDeath(target_node: Node) -> void:
	if not is_instance_valid(target_node):
		return
		
	# 1. 掐断逻辑心跳：全面禁用该节点及其所有子节点的 _process, _physics_process 和 Timer
	target_node.process_mode = Node.PROCESS_MODE_DISABLED
	
	# 2. 掐断画面渲染：如果是 UI 节点或 2D 节点，直接隐藏
	if target_node is CanvasItem:
		target_node.visible = false
		
	# 3. 拦截鼠标与输入输入：
	# 如果是 UI 控件，让它彻底对鼠标透明（无法被点击）
	if target_node is Control:
		target_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# 4. 强行关闭碰撞体（防止假死物体还能挡住网络弹道或卡牌拖拽判定）
	_set_all_collisions(target_node, false)
	
func _set_all_collisions(root_node: Node, enabled: bool) -> void:
	# 遍历目标节点下的所有子节点，把碰撞体全部禁用/启用
	for child in root_node.get_children():
		if child is CollisionShape2D or child is CollisionPolygon2D:
			child.set_deferred("disabled", !enabled)
		# 递归向下查找（比如卡牌内部嵌套的复合节点）
		if child.get_child_count() > 0:
			_set_all_collisions(child, enabled)
			
func Revive(target_node: Node) -> void:
	if not is_instance_valid(target_node):
		return
		
	# 1. 恢复画面显示
	if target_node is CanvasItem:
		target_node.visible = true
		
	# 2. 恢复鼠标接收
	if target_node is Control:
		target_node.mouse_filter = Control.MOUSE_FILTER_STOP # 或者是 MOUSE_FILTER_PASS，取决于你原厂设置
		
	# 3. 恢复物理碰撞
	_set_all_collisions(target_node, true)
	
	# 4. 最后一步：接回逻辑心跳。强制恢复和父节点一样的处理模式（通常是 INHERIT 恢复正常）
	target_node.process_mode = Node.PROCESS_MODE_INHERIT
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	

























#endregion

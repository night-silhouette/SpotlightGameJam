extends Node2D
## 仅为 Hub 追加局部光照，不负责机关、碰撞或存档。
@onready var _fountain: PointLight2D = $FountainLight
@onready var _fountain_source: PointLight2D = $FountainSourceLight
@onready var _desk: PointLight2D = $DeskLight
@onready var _descent: PointLight2D = $DescentMoonlight
@onready var _descent_beams: Node2D = $DescentBeams
@onready var _beams: Node2D = $Beams
@onready var _signals: Node = get_node("/root/SignalBus")
@onready var _settings: Node = get_node("/root/ExportSettings")
@onready var _ambient: CanvasModulate = $Ambient
var _level: Node2D
var _player: Node2D
var _active: bool = false
var _activation: float = 0.0
var _darkness: float = 0.0

func _ready() -> void:
	var ancestor := get_parent()
	while ancestor != null:
		if ancestor.has_method("GetCityConnections") and ancestor.has_method("GetRoomAt"):
			_level = ancestor as Node2D
			break
		ancestor = ancestor.get_parent()
	_signals.Level2StateChanged.connect(_on_level_state_changed)
	_signals.SaveSlotLoaded.connect(_on_save_loaded)
	_sync_state()
	_activation = 1.0 if _active else 0.0
	_apply_settings()

func _on_level_state_changed(level: Node2D) -> void:
	if level == _level:
		_sync_state()

func _on_save_loaded(_slot: int) -> void:
	_sync_state()

func _sync_state() -> void:
	_active = is_instance_valid(_level) and bool(_level.get("fountain_active"))

func _process(delta: float) -> void:
	var duration: float = _settings.level2_hub_light_transition_time
	_activation = move_toward(_activation, 1.0 if _active else 0.0, delta / maxf(duration, 0.001))
	if not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player") as Node2D
	var inside: bool = is_instance_valid(_player) and is_instance_valid(_level) and _level.GetRoomAt(_player.global_position) != null
	_darkness = move_toward(_darkness, 1.0 if inside and _settings.level2_hub_light_enabled else 0.0, delta / maxf(_settings.level2_hub_light_ambient_transition_time, 0.001))
	_apply_settings()

func _apply_settings() -> void:
	# 同一 Canvas 只让当前关卡的 CanvasModulate 生效，避免第一关与第二关互相覆盖色调。
	_ambient.visible = _darkness > 0.001 and _settings.level2_hub_light_enabled
	_ambient.color = Color.WHITE.lerp(_settings.level2_hub_light_ambient_color, _darkness)
	visible = _settings.level2_hub_light_enabled
	_fountain.enabled = visible
	_fountain_source.enabled = visible
	_desk.enabled = visible
	_descent.enabled = visible
	_fountain.color = _settings.level2_hub_light_fountain_color
	_fountain.energy = lerpf(_settings.level2_hub_light_fountain_idle_energy, _settings.level2_hub_light_fountain_active_energy, _activation)
	_fountain.texture_scale = _settings.level2_hub_light_fountain_radius / 128.0
	_fountain_source.color = _fountain.color
	_fountain_source.energy = lerpf(_settings.level2_hub_light_fountain_source_idle_energy, _settings.level2_hub_light_fountain_source_energy, _activation)
	_fountain_source.texture_scale = _settings.level2_hub_light_fountain_source_radius / 128.0
	_desk.color = _settings.level2_hub_light_desk_color
	_desk.energy = _settings.level2_hub_light_desk_energy
	_desk.texture_scale = _settings.level2_hub_light_desk_radius / 128.0
	_descent.color = _settings.level2_hub_light_beam_color
	_descent.energy = _settings.level2_hub_light_descent_energy
	_descent.texture_scale = _settings.level2_hub_light_descent_radius / 128.0
	for light: PointLight2D in [_fountain, _fountain_source, _desk]:
		light.shadow_enabled = visible and _settings.level2_hub_light_shadows_enabled and light != _desk
		light.shadow_color = Color(0.0, 0.0, 0.0, _settings.level2_hub_light_shadow_opacity)
		light.shadow_filter_smooth = _settings.level2_hub_light_shadow_smooth
	var beam_color: Color = _settings.level2_hub_light_beam_color
	beam_color.a = _settings.level2_hub_light_beam_opacity
	_beams.modulate = beam_color
	_descent_beams.modulate = Color(_descent.color, _settings.level2_hub_light_descent_beam_opacity)
	$DescentBeams/DescentOpeningGlow.modulate = Color(_descent.color, minf(_settings.level2_hub_light_descent_beam_opacity * 2.0, 1.0))
	$Glows/FountainGlow.modulate = Color(_fountain.color, _settings.level2_hub_light_glow_opacity * lerpf(0.65, 1.0, _activation))
	$Glows/DeskGlow.modulate = Color(_desk.color, _settings.level2_hub_light_glow_opacity)

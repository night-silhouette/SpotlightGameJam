extends Node

@export_group("Level 2 - Blockout", "level2_")
## 物品提示出现距离，像素。
@export var level2_interact_radius: float = 85.0
## 第二关镜头的目标世界宽度；沿用正式镜头系统，窗口变化时自动适配。
@export var level2_view_width: float = 1000.0
## 第二关水道移动平台速度，像素/秒。
@export var level2_platform_speed: float = 85.0
## 机关顺序：日、月、交织。
@export var level2_rune_order: PackedStringArray = ["sun", "moon", "weave"]
## 逆流水柱上升速度（像素/秒），沿实体水井推动玩家。
@export var level2_fountain_speed: float = 720.0
## 井口喷流水平速度；保持物理移动离开井口。
@export var level2_fountain_exit_speed: float = 320.0

@export_group("Level 2 - Scenery", "level2_scenery_")
## 第二关独立前后景开关；关闭后继续显示原灰盒背景。
@export var level2_scenery_enabled: bool = true
## 横向分层原画在世界中的显示高度；保持每张图片原始宽高比。
@export var level2_scenery_artwork_height: float = 800.0
## 远景相对镜头的移动比例。
@export_range(0.0, 1.0) var level2_scenery_far_speed: float = 0.25
## 窗格、拱廊等中景移动比例，同组保持原图对齐。
@export_range(0.0, 1.0) var level2_scenery_middle_speed: float = 0.65
## 前景柱移动比例。
@export_range(1.0, 1.5) var level2_scenery_foreground_speed: float = 1.08
## 前景透明度，避免遮住跳台和玩家。
@export_range(0.0, 1.0) var level2_scenery_foreground_opacity: float = 0.35
## 玩家附近前景进一步淡出的半径，世界像素。
@export var level2_scenery_player_clear_radius: float = 100.0
## 竖井右侧前景柱透明度，默认保留美术原图的深色。
@export_range(0.0, 1.0) var level2_scenery_vertical_foreground_opacity: float = 1.0
## 竖井玩家附近前景淡出半径，避免窄井中的柱子遮住玩家。
@export var level2_scenery_vertical_clear_radius: float = 32.0
## 竖井柱子纵向循环的重叠淡化比例，避免原图首尾硬切。
@export_range(0.01, 0.15) var level2_scenery_vertical_loop_blend: float = 0.06
## 下层竖井雕花柱相对原位置的最大视差位移（像素）；不循环，雕花保持在下部。
@export_range(0.0, 128.0) var level2_scenery_vertical_architecture_travel: float = 128.0
## 竖井浅色远柱的纵向移动比例；独立于横向背景。
@export_range(0.0, 1.0) var level2_scenery_vertical_far_speed: float = 0.12
## 上层竖井左侧暗柱的纵向移动比例。
@export_range(0.0, 1.0) var level2_scenery_vertical_middle_speed: float = 0.35
## 竖井右侧阴影柱的纵向移动比例；大于 1 时比地形滚动更快。
@export_range(1.0, 2.0) var level2_scenery_vertical_foreground_speed: float = 1.6

@export_group("Level 2 - Camera", "level2_camera_")
## 窄屏时限制可见高度，避免露出上下相邻房间；不改项目全局分辨率。
@export var level2_camera_max_view_height: float = 800.0
## 第二关普通跟随偏移，负 Y 在人物上方留白。
@export var level2_camera_offset: Vector2 = Vector2(0, -80)
## 普通跟随沿用项目默认阻尼风格。
@export var level2_camera_damping: Vector2 = Vector2(0.12, 0.18)
## 竖井跟随阻尼，减少高速落下和上升时的滞后。
@export var level2_camera_shaft_damping: Vector2 = Vector2(0.10, 0.12)
## 下落时人物位于画面高度的比例，为下方落脚点留出视野。
@export_range(0.2, 0.8) var level2_camera_descent_frame_y: float = 0.42
## 上升时人物位于画面高度的比例，为上方出口留出视野。
@export_range(0.2, 0.8) var level2_camera_ascent_frame_y: float = 0.62
## 第二关模式切换时间。
@export var level2_camera_transition_time: float = 0.45
## 竖井侧面遮挡，防止看到平行水井；不改变物理路线。
@export var level2_camera_shaft_occlusion: bool = true
## 竖井两侧显示的墙体余量。
@export var level2_camera_wall_margin: float = 24.0
## 竖井口附近遮挡淡入淡出的距离。
@export var level2_camera_occlusion_fade: float = 160.0

## 玩家与全局导出配置项 (ExportSettings)
## 供设计人员与开发者统一调整角色移动、跳跃、冲刺、受击、绳索等各项数值

@export_category("Player Settings")

@export_group("Movement & Physics", "player_")
## 角色水平移动最大速度
@export var player_speed: float = 230.0
## 角色地面/空中水平移动加速度
@export var player_acceleration: float = 2500.0
## 角色水平停止摩擦力/减速度
@export var player_friction: float = 3000.0
## 角色自动跨越的小坡最大高度（像素；不超过脚部与下身探针间距）
@export_range(0.0, 11.0, 0.5) var player_step_height: float = 11.0
## 自动上坡时每次额外水平推进的最大距离（像素；不含正常行走）
@export_range(0.0, 11.0, 0.5) var player_step_horizontal_distance: float = 1.0
## 跳跃初速度
@export var player_jump_speed: float = 380.0
## 长按跳跃滞空调节能力系数 (影响跳跃手感曲线)
@export var player_jump_ability: float = 0.85
## 二段跳初速度
@export var player_double_jump_speed: float = 380.0
## 二段跳最大可用次数 (通常为 1)
@export var player_max_double_jumps: int = 1
## 是否开启二段跳功能
@export var player_enable_double_jump: bool = false
## 是否默认解锁钩索功能
@export var player_enable_rope: bool = false
## 调试飞行四向移动速度（像素/秒）；仅开关开启时使用
@export_range(1.0, 2000.0, 1.0) var player_debug_flight_speed: float = 700.0

@export_group("Relics & Lake")
## The Sunken Crown 贴图；留空时使用程序生成的临时图标。
@export var sunken_crown_texture: Texture2D
## The Starseeker's Codex 贴图；留空时使用程序生成的临时图标。
@export var starseekers_codex_texture: Texture2D
## The Scarred Bones 贴图；留空时使用程序生成的临时图标。
@export var scarred_bones_texture: Texture2D
## 湖第一次交互后的水量比例。
@export_range(0.0, 1.0, 0.01) var lake_first_fill_ratio: float = 0.5
## 遗物飞入湖泊的动画时长（秒）。
@export_range(0.1, 3.0, 0.05) var lake_relic_flight_duration: float = 0.65

func _ready() -> void:
	if sunken_crown_texture == null:
		sunken_crown_texture = _make_relic_icon("<path d='M7 16 L14 22 L24 11 L34 22 L41 16 L38 35 L10 35 Z' fill='#f4c857' stroke='#583d71' stroke-width='2'/><path d='M10 35 H38 V40 H10 Z' fill='#fff0a8'/><circle cx='24' cy='28' r='4' fill='#45ccdc'/>")
	if starseekers_codex_texture == null:
		starseekers_codex_texture = _make_relic_icon("<path d='M8 10 Q18 7 24 13 Q30 7 40 10 V38 Q30 35 24 41 Q18 35 8 38 Z' fill='#574b98' stroke='#eddba7' stroke-width='2'/><path d='M24 13 V40' stroke='#eddba7' stroke-width='2'/><path d='M31 15 L32 20 L37 21 L32 22 L31 27 L30 22 L25 21 L30 20 Z' fill='#ffec93'/>")
	if scarred_bones_texture == null:
		scarred_bones_texture = _make_relic_icon("<path d='M14 12 L35 33 M35 12 L14 33' stroke='#e8dac2' stroke-width='7' stroke-linecap='round'/><path d='M16 19 L22 22 L19 27 M29 20 L26 26 L32 29' fill='none' stroke='#9c4c56' stroke-width='2'/>")

func _make_relic_icon(shapes: String) -> Texture2D:
	var svg := "<svg xmlns='http://www.w3.org/2000/svg' width='48' height='48' viewBox='0 0 48 48'>%s</svg>" % shapes
	var image := Image.new()
	image.load_svg_from_buffer(svg.to_utf8_buffer())
	return ImageTexture.create_from_image(image)

@export_group("Movement & Physics", "player_")
## 蹬墙跳垂直弹跳力与水平反冲基数
@export var player_climb_ability: float = 480.0
## 贴墙滑落时的最大下落速度限制
@export var player_max_fall_speed: float = 120.0

@export_group("Double Jump Ring", "player_double_jump_ring_")
## 二段跳脚下光环颜色（透明度决定初始亮度）
@export var player_double_jump_ring_color: Color = Color(1.0, 0.92, 0.58, 0.42)
## 光环扩散并淡出的持续时间（秒）
@export_range(0.05, 2.0, 0.01) var player_double_jump_ring_duration: float = 0.32
## 光环最终的水平半径（像素）
@export_range(1.0, 100.0, 1.0) var player_double_jump_ring_radius: float = 25.0
## 光环从起跳位置向下移动的距离（像素）
@export_range(0.0, 150.0, 1.0) var player_double_jump_ring_drop_distance: float = 35.0

@export_group("Dash", "player_dash_")
## 冲刺持续时间 (秒)
@export var player_dash_time: float = 0.15
## 冲刺位移速度
@export var player_dash_speed: float = 650.0
## 冲刺冷却间隔 (秒)
@export var player_dash_span: float = 0.65
## 冲刺残影采样间隔（秒）
@export_range(0.01, 0.2, 0.01) var player_dash_afterimage_interval: float = 0.04
## 单个冲刺残影的淡出时长（秒）
@export_range(0.05, 1.0, 0.01) var player_dash_afterimage_duration: float = 0.22
## 冲刺残影的黄白色及初始透明度
@export var player_dash_afterimage_color: Color = Color(1.0, 0.94, 0.65, 0.65)

@export_group("Combat & Health", "player_")
## 玩家最大生命值
@export var player_max_hp: float = 200.0
## 受到伤害时的硬直顿挫时间 (秒)
@export var player_hurt_time: float = 0.15
## 受伤后的无敌免伤时间 (秒)
@export var player_unbeatable_time: float = 0.3
## 随时间自然掉血速率 (每秒掉血量)
@export var player_hp_drain_rate: float = 200.0 / 300.0
## 触发缺水视觉效果的水量比例 (0.15 即低于 15%)
@export_range(0.0, 1.0, 0.01) var player_low_water_threshold: float = 0.15
## 缺水时主角最终呈现的沙土色
@export var player_low_water_color: Color = Color("f8f4ed")
## 缺水时主角边缘的描线颜色
@export var player_low_water_outline_color: Color = Color.BLACK
## 缺水时主角描线宽度（纹理像素）
@export_range(1.0, 8.0, 0.5) var player_low_water_outline_width: float = 3.0
## 缺水时边缘缺口的密度
@export_range(0.0, 0.5, 0.01) var player_low_water_edge_damage: float = 0.16
## 主角颜色与描线向缺水状态渐变的速度
@export_range(0.1, 10.0, 0.1) var player_low_water_color_fade_speed: float = 2.0
## 缺水时持续掉落的沙粒数量
@export_range(1, 128, 1) var player_low_water_sand_amount: int = 12
## 沙粒存活时间 (秒)
@export_range(0.1, 5.0, 0.1) var player_low_water_sand_lifetime: float = 1.0

@export_group("Water Droplets", "player_water_droplet_")
## 离开最后一个流水区域后持续发射水滴的时间 (秒)
@export_range(0.1, 10.0, 0.1) var player_water_droplet_duration: float = 2.0
## 同时参与发射的水滴粒子数量
@export_range(1, 128, 1) var player_water_droplet_amount: int = 18
## 单颗水滴存活时间 (秒)
@export_range(0.1, 5.0, 0.1) var player_water_droplet_lifetime: float = 1.2
## 水滴在人物身上的矩形发射范围半径
@export var player_water_droplet_emission_extents: Vector2 = Vector2(10.0, 20.0)
## 水滴下落重力
@export var player_water_droplet_gravity: Vector2 = Vector2(0.0, 420.0)
## 水滴初始速度下限
@export_range(0.0, 500.0, 1.0) var player_water_droplet_velocity_min: float = 25.0
## 水滴初始速度上限
@export_range(0.0, 500.0, 1.0) var player_water_droplet_velocity_max: float = 70.0
## 水滴尺寸下限
@export_range(0.1, 10.0, 0.1) var player_water_droplet_size_min: float = 1.2
## 水滴尺寸上限
@export_range(0.1, 10.0, 0.1) var player_water_droplet_size_max: float = 2.4
## 水滴颜色（生命周期末尾自动淡出）
@export var player_water_droplet_color: Color = Color(0.18, 0.72, 1.0, 0.9)

@export_group("Audio & Footsteps", "player_footstep_")
## 脚步材质：砖块或沙地
@export_enum("Brick", "Sand") var player_footstep_surface: String = "Sand"
## 脚步声使用的音频总线名称 (Audio Bus)
@export var player_footstep_bus: StringName = &"SFX_Footstep_Wet"
## 行走/奔跑时脚步声播放间隔时长 (秒)
@export var player_footstep_interval: float = 0.22
## 起步迈出第一步时的前置延迟 (秒)
@export var player_footstep_initial_delay: float = 0.05
## 脚步声公共基准音量 (dB)；实际音量 = 此值 + 对应材质/样本的补偿值。
@export var player_footstep_volume_db: float = -2.0
## 脚步声音调微机随机变化范围 (pitch_scale: 1.0 ± 变化值，0 为固定音调)
@export var player_footstep_pitch_randomness: float = 0.08

@export_group("Sand Footstep Volume Offsets (dB)", "player_footstep_sand_")
## Sand_01 相对 player_footstep_volume_db 的音量偏移 (dB)，按原音源 RMS 与 Brick_01 对齐。
@export var player_footstep_sand_01_volume_offset_db: float = 10
## Sand_02 相对脚步声公共基准音量的偏移 (dB)。
@export var player_footstep_sand_02_volume_offset_db: float = 10
## Sand_03 相对脚步声公共基准音量的偏移 (dB)。
@export var player_footstep_sand_03_volume_offset_db: float = 10
## Sand_04 相对脚步声公共基准音量的偏移 (dB)。
@export var player_footstep_sand_04_volume_offset_db: float = 10
## Sand_05 相对脚步声公共基准音量的偏移 (dB)。
@export var player_footstep_sand_05_volume_offset_db: float = 10
## SandLand 相对脚步声公共基准音量的偏移 (dB)。
@export var player_footstep_sand_land_volume_offset_db: float = 10
## SandTurn 相对脚步声公共基准音量的偏移 (dB)。
@export var player_footstep_sand_turn_volume_offset_db: float = 10

@export_group("Brick Footstep Volume Offsets (dB)", "player_footstep_brick_")
## Brick_01 相对 player_footstep_volume_db 的音量偏移 (dB)，0 不改变原音量。
@export var player_footstep_brick_01_volume_offset_db: float = 0.0
## Brick_02 相对脚步声公共基准音量的偏移 (dB)。
@export var player_footstep_brick_02_volume_offset_db: float = 0.0
## Brick_03 相对脚步声公共基准音量的偏移 (dB)。
@export var player_footstep_brick_03_volume_offset_db: float = 0.0
## Brick_04 相对脚步声公共基准音量的偏移 (dB)。
@export var player_footstep_brick_04_volume_offset_db: float = 0.0
## Brick_05 相对脚步声公共基准音量的偏移 (dB)。
@export var player_footstep_brick_05_volume_offset_db: float = 0.0
## BrickLand 相对脚步声公共基准音量的偏移 (dB)。
@export var player_footstep_brick_land_volume_offset_db: float = 0.0
## BrickTurn 相对脚步声公共基准音量的偏移 (dB)。
@export var player_footstep_brick_turn_volume_offset_db: float = 0.0

@export_group("Footstep Surface Area", "footstep_surface_area_")
## 区域左侧音源类别与两条音频总线；实例可逐项覆盖。
@export_enum("Brick", "Sand") var footstep_surface_area_left_surface: String = "Brick"
@export var footstep_surface_area_left_footstep_bus: StringName = &"SFX_Footstep_Dry"
@export var footstep_surface_area_left_move_bus: StringName = &"SFX_Move_Dry"
## 区域右侧音源类别与两条音频总线；实例可逐项覆盖。
@export_enum("Brick", "Sand") var footstep_surface_area_right_surface: String = "Sand"
@export var footstep_surface_area_right_footstep_bus: StringName = &"SFX_Footstep_Wet"
@export var footstep_surface_area_right_move_bus: StringName = &"SFX_Move_Wet"

@export_group("Audio & Move SFX", "sfx_move_")
## 动作音效使用的音频总线名称 (Audio Bus，如 SFX_Move_Wet 或 SFX_Move_Dry)
@export var sfx_move_bus: StringName = &"SFX_Move_Wet"
## 动作音效音量分贝 (dB)
@export var sfx_move_volume_db: float = 0.0
## 冲刺音效音量分贝 (dB)
@export var sfx_move_dash_volume_db: float = 0.0
## 一段跳起跳音效音量分贝 (dB)
@export var sfx_move_jump_first_volume_db: float = 0.0
## 二段跳音效音量分贝 (dB)
@export var sfx_move_jump_second_volume_db: float = 0.0
## 蹬墙跳音效音量分贝 (dB)
@export var sfx_move_wall_jump_volume_db: float = 0.0
## 贴墙滑落音效音量分贝 (dB)
@export var sfx_move_wall_sliding_volume_db: float = -2.0
## 下落/滞空起落呼啸音效音量分贝 (dB)
@export var sfx_move_rising_falling_volume_db: float = -4.0
## 钩索发射音效音量分贝 (dB)
@export var sfx_move_shoot_hook_volume_db: float = 10.0
## 钩索拉拽飞行音效音量分贝 (dB)
@export var sfx_move_pulling_hook_volume_db: float = 10.0
## 受伤音效音量分贝 (dB)
@export var sfx_move_hurt_volume_db: float = 0.0
## 死亡音效音量分贝 (dB)
@export var sfx_move_death_volume_db: float = 0.0
## 动作音效音调随机浮动范围 (0 为固定音调)
@export var sfx_move_pitch_randomness: float = 0.05
## 触发下落呼啸音效的垂直下落速度阈值
@export var sfx_move_falling_speed_threshold: float = 260.0

@export_group("Rope & Grapple", "rope_")
## 使用绳索每次消耗的生命值
@export var rope_hp_cost: float = 10.0
## 绳索最大有效射程距离
@export var rope_max_length: float = 450.0
## 绳索发射向前飞行的速度 (像素/秒，高速弹射感)
@export var rope_projectile_speed: float = 2200.0
## 命中目标后处于待命决策窗口期的持续时间 (秒)
@export var rope_window_duration: float = 0.6
## 再次按下射击键将自身高速拉向命中点的飞行速度
@export var rope_pull_speed: float = 850.0
## 拉拽判定为已到达挂钩点的阈值距离
@export var rope_pull_arrive_distance: float = 35.0
## 摆动受重力影响缩放因子
@export var rope_swing_gravity_scale: float = 1.0
## 摆动时玩家通过左右移动输入所施加的切向角加速度
@export var rope_swing_input_accel: float = 1800.0
## 摆动阻尼衰减系数
@export var rope_swing_damping: float = 0.15
## 绳索脱钩后水平动量保留比例
@export var rope_pull_momentum_ratio: float = 0.95
## 绳索脱钩后地面高速滑行减速摩擦力 (替代普通地面高摩擦，给予平滑滑行与跳跃窗口)
@export var rope_ground_slide_friction: float = 900.0
## 绳索脱钩后空中保留超速动量时的轻微空气阻尼 (替代普通2500高额阻尼，实现超远跳跃)
@export var rope_air_drag: float = 250.0
## 绳索脱钩后地面动量滑行保护时间 (秒)
@export var rope_momentum_duration: float = 0.4
## 绳索射线检测碰撞层级掩码 (默认层1 world + 层3 entity = 5)
@export_flags_2d_physics var rope_collision_mask: int = 5

@export_group("Grapple Visuals", "rope_visual_")
## ani_move 发射人物两帧动画的帧率，播完转入持绳飞行动画。
@export_range(1.0, 30.0, 0.5) var rope_visual_deploy_fps: float = 12.0
## ani_move 持绳飞行两帧循环动画的帧率。
@export_range(1.0, 30.0, 0.5) var rope_visual_fly_fps: float = 12.0
## 发射人物相对角色原点的偏移。
@export var rope_visual_player_offset: Vector2 = Vector2(-7.0, 0.0)
## 发射人物图的统一缩放。
@export_range(0.1, 2.0, 0.01) var rope_visual_player_scale: float = 0.36
## 绳身显示宽度，不影响碰撞和绳长。
@export_range(1.0, 12.0, 0.5) var rope_visual_width: float = 1.5
## 钩头图的统一缩放。
@export_range(0.1, 3.0, 0.05) var rope_visual_hook_scale: float = 0.4

@export_group("Interactive - Water Flow", "water_flow_")
## 流水区域加速系数 (进入速度 * 该倍数)
@export var water_flow_speed_multiplier: float = 1.9
## 保证进入流体时的最低喷射加速值
@export var water_flow_min_speed: float = 600.0
## 流水区域内方向输入的加速度（像素/秒²）
@export_range(0.0, 5000.0, 10.0) var water_flow_swim_acceleration: float = 1600.0
## 流水区域内无输入时的二维减速（像素/秒²）
@export_range(0.0, 3000.0, 10.0) var water_flow_swim_drag: float = 180.0
## 流水区域内主动游泳的目标速度；入水爆发速度会逐渐回落而非直接截断
@export_range(0.0, 2000.0, 10.0) var water_flow_swim_max_speed: float = 360.0
## 水符文石交互激活有效距离
@export var water_flow_interact_distance: float = 130.0
## 水符文激活技能冷却时间 (秒)
@export var water_rune_cooldown: float = 2.0
## 穿过流水区域时划水音效音量分贝 (dB)
@export var water_flow_pass_volume_db: float = 0.0
## 穿过流水区域音效所使用的音频总线
@export var water_flow_audio_bus: StringName = &"SFX_Interact"

@export_group("Interactive - Spikes", "spikes_")
## 通用地刺基础伤害值
@export var spikes_damage: float = 40.0
## 尖刺命中击退力度标量
@export var spikes_knockback_force: float = 650.0

@export_group("Interactive - Rising Spikes", "rising_spikes_")
## 时序突刺基础伤害值
@export var rising_spikes_damage: float = 50.0
## 时序突刺击退力度标量
@export var rising_spikes_knockback_force: float = 700.0
## 突刺缩回安全等待时长 (秒)
@export var rising_spikes_retracted_duration: float = 2.0
## 突刺伸出危险保持时长 (秒)
@export var rising_spikes_extended_duration: float = 1.5
## 突刺伸出/缩回过渡动画时长 (秒)
@export var rising_spikes_transition_time: float = 0.2

@export_group("Interactive - Chalice Station", "chalice_")
## 小圣杯站重置刷新时间 (秒，<= 0 表示单次使用不刷新)
@export var chalice_reset_time: float = 10.0
## 小圣杯补水百分比 (1.0 即 100% 满水)
@export var chalice_heal_ratio: float = 1.0

@export_group("Interactive - Tent", "tent_")
## 帐篷重生延迟时长 (秒，玩家死亡后多久在帐篷重生)
@export var tent_respawn_delay: float = 1.0
## 重生时相对帐篷中心的原点偏移 (Vector2)
@export var tent_respawn_offset: Vector2 = Vector2(0, 0)
## 帐篷交互检测交互范围宽度/高度
@export var tent_interaction_size: Vector2 = Vector2(48.0, 40.0)

@export_group("Interactive - Crumbling Platform", "crumble_")
## 踩踏后震颤延迟坍塌时间 (秒)
@export var crumble_delay: float = 0.6
## 坍塌碎裂后在原地重生的等待时长 (秒)
@export var crumble_respawn_time: float = 3.0
## 震颤剧烈程度幅度 (像素)
@export var crumble_shake_offset: float = 2.5

@export_group("Interactive - Moving Platform", "moving_platform_")
## 移动平台默认尺寸 (宽, 高)
@export var moving_platform_size: Vector2 = Vector2(112.0, 20.0)
## 移动平台默认移动速度 (像素/秒)
@export var moving_platform_speed: float = 90.0
## 移动平台抵达路径端点后的默认停顿时间 (秒)
@export var moving_platform_endpoint_wait_time: float = 0.45
## 移动平台抵达另一端后是否默认反向循环
@export var moving_platform_loop: bool = true

@export_group("Interactive - Directional Chase Mover", "chase_mover_")
## 第一阶段持续时间，作为玩家熟悉追逐节奏的热身段。
@export var chase_mover_stage_1_duration: float = 28.0
## 第二阶段持续时间，进入连续跳跃和障碍压力段。
@export var chase_mover_stage_2_duration: float = 32.0
## 第一阶段基础速度。
@export var chase_mover_stage_1_speed: float = 190.0
## 第二阶段基础速度。
@export var chase_mover_stage_2_speed: float = 230.0
## 第三阶段基础速度，持续到钩锁逃脱终点。
@export var chase_mover_stage_3_speed: float = 275.0
## 分阶段切速时的加速度，避免速度瞬间跳变。
@export var chase_mover_acceleration: float = 125.0
## 追逐体希望与玩家维持的前向距离。
@export var chase_mover_follow_distance: float = 520.0
## 玩家领先超过此距离时进入追赶速度。
@export var chase_mover_max_follow_distance: float = 900.0
## 靠近玩家时的速度倍率；保持接近 1，避免减速表现过于明显。
@export_range(0.5, 1.0, 0.01) var chase_mover_near_speed_multiplier: float = 0.9
## 玩家领先较远时的速度倍率；保持轻微提升，避免突兀追赶。
@export_range(1.0, 1.5, 0.01) var chase_mover_far_speed_multiplier: float = 1.16

@export_group("Interactive - Slick Wall", "slick_wall_")
## 光滑滑石墙摩擦系数 (极度光滑)
@export var slick_wall_friction: float = 0.0

@export_group("Player Camera", "player_camera_")
## 玩家跟随镜头的优先级；后续关卡镜头可使用更高优先级接管。
@export var player_camera_priority: int = 10
## 镜头统一缩放，1.0 保持素材原始比例。
@export_range(0.1, 4.0, 0.05) var player_camera_zoom: float = 1.0
## 镜头中心相对玩家的偏移；负 Y 为人物上方留出更多视野。
@export var player_camera_offset: Vector2 = Vector2(0, -120)
## 是否使用插件平滑跟随；不叠加 Camera2D 自带平滑。
@export var player_camera_smoothing: bool = true
## 横向/纵向跟随阻尼，数值越大跟随越慢；重新运行后生效。
@export var player_camera_damping: Vector2 = Vector2(0.12, 0.18)
## 防抖方框大小（占视口的比例，1.0=整个视口宽/高）。角色在框内移动不推动镜头，顶到框边才推动镜头。
@export var player_camera_box_fraction: Vector2 = Vector2(0.05, 0.25)

@export_group("Camera Gate", "camera_gate_")
## 镜头门边界沿禁止露出方向向内收缩的距离（世界像素）。
@export_range(0.0, 1000.0, 1.0) var camera_gate_margin: float = 0.0
## 非一次性镜头门允许画面移动一个视口宽/高所需的秒数。
@export_range(0.05, 5.0, 0.05) var camera_gate_transition_duration: float = 0.25

@export_group("Camera Director", "camera_")
## 镜头间的平滑切换秒数，由 Phantom Camera 执行。
@export var camera_transition_duration: float = 1.2
## 归一化构图位置：0 为左/上，1 为右/下。Zoom 只改镜头，不改美术 Scale。
@export var camera_desert_frame: Vector2 = Vector2(0.25, 0.7)
@export var camera_desert_zoom: float = 0.85
@export var camera_desert_damping: Vector2 = Vector2(0.25, 0.3)
@export var camera_descent_frame: Vector2 = Vector2(0.5, 0.7)
@export var camera_descent_zoom: float = 1.0
@export var camera_descent_damping: Vector2 = Vector2(0.12, 0.4)
## 补偿下落阻尼延迟，避免角色高速掉出屏幕。
@export var camera_descent_velocity_compensation: float = 1.0
@export var camera_boat_frame: Vector2 = Vector2(0.4, 0.6)
@export var camera_boat_zoom: float = 1.0
@export var camera_boat_damping: Vector2 = Vector2(0.6, 0.3)
@export var camera_fixed_zoom: float = 1.0
@export var camera_ritual_close_zoom: float = 1.35
@export var camera_ritual_wide_zoom: float = 0.85
@export var camera_ritual_close_hold: float = 0.6
@export var camera_ritual_pan_duration: float = 2.8
@export var camera_intro_duration: float = 1.8
@export var camera_blur_radius: float = 5.0
@export var camera_title_hold: float = 1.0
@export var camera_text_font_size: int = 26
@export var camera_text_interval: float = 0.12
@export var camera_text_fade: float = 0.5
@export var camera_boat_mask_fraction: float = 0.16
@export var camera_boat_mask_opacity: float = 0.85

@export_group("Camera Showcase", "camera_demo_")
## 仅用于独立验收场景，不改变正式玩家的物理参数。
@export var camera_demo_boat_speed: float = 100.0
@export var camera_demo_fall_speed: float = 420.0

@export_group("Parallax Scenery", "parallax_")
## 天空和山体共同使用的横向视差比例；保留二者的横向相对构图。
@export_range(0.0, 2.0, 0.05) var parallax_far_scroll_x: float = 0.2
## 浅色后景的横向视差比例；仍慢于人物所在的游戏世界。
@export_range(0.0, 2.0, 0.05) var parallax_near_scroll_x: float = 0.35
## 绿色地形和黑色植物共同使用的前景比例；大于 1 时比地面移动更快。
@export_range(0.0, 2.0, 0.05) var parallax_foreground_scroll_x: float = 1.2
## 原图对齐的参考取景左边界。这里保持联调出生镜头的 X=96，不移动或缩放素材。
@export var parallax_reference_view_left: float = 96.0
## 各层统一使用蓝线对应的循环周期；只裁掉原图重复尾部，不缩放素材。
@export var parallax_repeat_width: float = 4831.0
## 绿色装饰在每段开头的接缝过渡宽度；0 关闭过渡，重新运行后生效。
@export var parallax_green_seam_blend_width: float = 128.0
## 绿色原图在循环末列和首列的轮廓高差；仅在接缝过渡内补偿，整体位置不变。
@export var parallax_green_seam_y_offset: float = 14.0
## 浅黄色后景在每段开头的接缝过渡宽度；0 关闭过渡，重新运行后生效。
@export var parallax_near_seam_blend_width: float = 256.0
## 浅黄色后景末列轮廓 Y=898、首列 Y=858，仅在过渡内补偿 40 像素高差。
@export var parallax_near_seam_y_offset: float = 40.0

@export_group("Interactive - Stalactite", "stalactite_")
## 钟乳石检测射线向下最大长度 (像素)
@export var stalactite_ray_length: float = 400.0
## 钟乳石松动预警晃动时长 (秒)
@export var stalactite_shake_duration: float = 0.35
## 钟乳石下落重力加速度 (像素/秒^2)
@export var stalactite_gravity: float = 1600.0
## 钟乳石最大下落速度 (像素/秒)
@export var stalactite_max_fall_speed: float = 900.0
## 钟乳石基础伤害量
@export var stalactite_damage: float = 50.0
## 钟乳石击退力度
@export var stalactite_knockback_force: float = 600.0

@export_group("Interactive - Falling Block", "falling_block_")
## 下落方块检测射线向下最大长度 (像素)
@export var falling_block_ray_length: float = 400.0
## 下落方块松动预警晃动时长 (秒)
@export var falling_block_shake_duration: float = 0.4
## 下落方块下落重力加速度 (像素/秒^2)
@export var falling_block_gravity: float = 1400.0
## 下落方块最大下落速度 (像素/秒)
@export var falling_block_max_fall_speed: float = 800.0
## 下落方块砸中玩家时的伤害量
@export var falling_block_damage: float = 30.0
## 下落方块砸中玩家时的击退力度
@export var falling_block_knockback_force: float = 300.0

@export_group("Interactive - Pressure Button", "pressure_button_")
## 压力按钮默认宽高（像素）。
@export var pressure_button_size: Vector2 = Vector2(64.0, 14.0)
## 压力按钮完全按下时向下移动的距离（像素）。
@export_range(0.0, 32.0, 0.5) var pressure_button_press_depth: float = 8.0
## 压力按钮按下与回弹速度（像素/秒）。
@export_range(1.0, 1000.0, 1.0) var pressure_button_move_speed: float = 120.0

@export_group("Interactive - Signal Door", "signal_door_")
## 信号门默认碰撞宽高（像素）。
@export var signal_door_size: Vector2 = Vector2(32.0, 128.0)
## 信号门默认开启位移；场景实例可用导出属性覆盖方向和距离。
@export var signal_door_open_offset: Vector2 = Vector2(0.0, -128.0)
## 信号门开关移动速度（像素/秒）。
@export_range(1.0, 2000.0, 1.0) var signal_door_move_speed: float = 180.0

@export_group("Mobile & Android", "mobile_")
## 是否在非安卓环境下强制开启虚拟按键与摇杆 (方便在 PC 编辑器测试)
@export var mobile_debug_force_touch_controls: bool = false
## 触屏长按判定时间 (秒)
@export var mobile_touch_hold_threshold: float = 0.2
## 虚拟摇杆基础尺寸 (像素直径，默认 240)
@export var mobile_joystick_size: float = 240.0
## 虚拟摇杆中心手柄尺寸 (像素，默认 90)
@export var mobile_joystick_tip_size: float = 90.0
## 跳跃按钮半径 (像素，默认 52)
@export var mobile_jump_button_radius: float = 52.0
## 冲刺按钮半径 (像素，默认 44)
@export var mobile_dash_button_radius: float = 44.0

@export_group("Audio Settings", "audio_")
## 总音量默认值 (0.0-1.0)
@export_range(0.0, 1.0, 0.01) var audio_master_volume: float = 1.0
## 音乐默认音量 (0.0-1.0)
@export_range(0.0, 1.0, 0.01) var audio_music_volume: float = 1.0
## 音效默认音量 (0.0-1.0)
@export_range(0.0, 1.0, 0.01) var audio_sfx_volume: float = 1.0
## 对白默认音量 (0.0-1.0)
@export_range(0.0, 1.0, 0.01) var audio_dialogue_volume: float = 1.0
## 环境默认音量 (0.0-1.0)
@export_range(0.0, 1.0, 0.01) var audio_ambience_volume: float = 1.0
## 音量设置持久化文件路径
@export var audio_settings_path: String = "user://audio_settings.cfg"
## 总音量对应的音频总线
@export var audio_master_bus: StringName = &"Master"
## 音乐音量对应的音频总线
@export var audio_music_bus: StringName = &"Music_Master"
## 音效音量对应的音频总线
@export var audio_sfx_bus: StringName = &"SFX_Master"
## 对白音量对应的音频总线
@export var audio_dialogue_bus: StringName = &"Dialogue_Master"
## 环境音量对应的音频总线
@export var audio_ambience_bus: StringName = &"Amb_Master"

@export_group("Setting & Save System", "setting_")
## 最大允许的存档槽位数 (固定为 5)
@export var setting_max_save_slots: int = 5
## 游戏启动时是否自动载入第一个存档 (若存在)
@export var setting_auto_load_slot_1: bool = false
## 存档文件路径前缀模版 (支持 res://Saves/save_slot_ 或 user://save_slot_)
@export var setting_save_path_prefix: String = "res://Code/Entities/Setting/Saves/save_slot_"

## 按键绑定持久化文件路径 (独立于存档槽位)
@export var setting_keybinds_path: String = "res://Code/Entities/Setting/Saves/custom_keybinds.json"
## 设置界面背景透明度
@export_range(0.0, 1.0, 0.05) var setting_panel_opacity: float = 0.92

@export_group("Start Menu", "start_menu_")
## 游戏主游玩场景路径 (新开存档或载入进入的目标世界场景)
@export var start_menu_world_scene_path: String = "res://Code/Entities/World/World.tscn"
## 开始菜单背景音乐总线
@export var start_menu_music_bus: StringName = &"MUS_StartMenu"

@export_group("Oasis Decoration", "oasis_art_")
## 第三关水化外观透明度，不影响水化碰撞或加速。
@export_range(0.1, 1.0) var oasis_art_water_opacity: float = 0.78
## 第三关水纹滚动速度，只控制装饰动画。
@export_range(0.0, 5.0) var oasis_art_water_scroll_speed: float = 1.5

@export_group("Interactable Component", "interactable_")
@export var interactable_action: StringName = &"interact"
@export var interactable_description_lines: Array[String] = []
@export var interactable_monologue_lines: Array[String] = []

@export_group("Vanishing Blocker", "vanishing_blocker_")
@export var vanishing_blocker_zone_group: StringName = &"VanishZone"
@export_range(0.0, 10.0, 0.05) var vanishing_blocker_fade_duration: float = 0.5

@export_group("Oasis Boat", "oasis_boat_")
## 第三关七个停靠点的航线进度，按递增顺序配置，起点为 0、终点为 1。
@export var oasis_boat_stop_ratios: Array[float] = [0.0, 0.03338, 0.51271, 0.67568, 0.78541, 0.84054, 1.0]
## 等待障碍消失的停靠点索引；该站不要求玩家登船。
@export var oasis_boat_blocker_stop_index: int = 4

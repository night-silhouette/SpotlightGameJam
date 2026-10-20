extends Node

@export_group("Debug", "debug_")
## 是否显示玩家界面的调试能力面板。
@export var debug_panel_enabled: bool = true

@export_group("Chapter 5", "chapter5_")
## 地面位移相对当前脚下坐标和真实湖中心，单位世界像素。
@export var chapter5_approach_distance: float = 18.0
@export var chapter5_retreat_distance: float = 48.0
@export var chapter5_step_duration: float = 1.2
@export var chapter5_ascent_height: float = 460.0
@export var chapter5_ascent_duration: float = 7.5
@export var chapter5_rain_duration: float = 6.0
@export var chapter5_rain_build_duration: float = 12.0
@export_range(0.01, 0.25, 0.01) var chapter5_rain_initial_intensity: float = 0.08
@export var chapter5_rain_count: int = 180
@export var chapter5_rain_color: Color = Color(0.72, 0.86, 0.94, 0.5)
@export var chapter5_overflow_radius: float = 115.0
@export var chapter5_overflow_color: Color = Color(0.64, 0.82, 0.88, 0.5)
@export var chapter5_vapor_color: Color = Color(0.76, 0.9, 1.0, 0.8)
@export var chapter5_text_size: int = 25
@export var chapter5_beat_duration: float = 2.4
@export var chapter5_stele_wet_duration: float = 2.0
@export var chapter5_surge_duration: float = 3.0
@export var chapter5_surge_volume_db: float = -8.0
@export var chapter5_black_fade_duration: float = 1.4
@export var chapter5_black_hold_duration: float = 0.6
@export var chapter5_thunder_volume_db: float = -12.0
@export var chapter5_thunder_fade_duration: float = 3.0
@export var chapter5_rain_volume_db: float = -10.0

const TUTORIAL_SKIN = preload("res://Code/Entities/Setting/SettingsSkin.gd")

@export_group("Credits", "credits_")
## 参与早期版本测试游玩的玩家名单，可在数组中继续添加。
@export var credits_early_playtesters: PackedStringArray = ["YBBBY", "君问归期未有期", "LongDaling", "atomo_muzic"]

@export_group("Tutorial Subtitle", "tutorial_")
## 跳跃教学区域每次重新进入时请求的文案。
@export var tutorial_jump_hint_text: String = "长按跳跃以达到更高高度"
## 横木平台冲刺教学区域每次重新进入时请求的文案。
@export var tutorial_dash_hint_text: String = "Shift键冲刺"
## 绿洲骸骨植物柱顶的向下观察教学文案。
@export var tutorial_look_down_hint_text: String = "长按s键向下观察"
## 第一处水墙前的交互教学文案。
@export var tutorial_water_wall_hint_text: String = "左键交互水墙"
## 手机版第一处水墙前的交互教学文案。
@export var tutorial_mobile_water_wall_hint_text: String = "切换钩锁和交互模式，点击屏幕交互水墙"
## 字幕淡入、全显停留和淡出的时长，单位秒。
@export_range(0.0, 5.0, 0.05) var tutorial_fade_in_duration: float = 0.7
@export_range(0.0, 20.0, 0.1) var tutorial_hold_duration: float = 4.0
@export_range(0.0, 5.0, 0.05) var tutorial_fade_out_duration: float = 1.0
## 文字颜色复用设置界面的暖纸色，默认不透明度为0.8。
@export var tutorial_text_color: Color = Color(TUTORIAL_SKIN.PAPER, 0.8)
## 墨色文字阴影及暖金装饰线颜色。
@export var tutorial_shadow_color: Color = Color(TUTORIAL_SKIN.INK, 0.6)
@export var tutorial_line_color: Color = Color(TUTORIAL_SKIN.ACCENT, 0.45)
@export_range(12, 64, 1) var tutorial_font_size: int = 24
@export var tutorial_shadow_offset: Vector2i = Vector2i(0, 2)
## 字幕底边距及左右安全距离，单位为界面像素。
@export_range(0.0, 240.0, 1.0) var tutorial_bottom_margin: float = 64.0
@export_range(0.0, 120.0, 1.0) var tutorial_screen_margin: float = 24.0
## 字幕最大宽度；小窗口按左右安全距离自动收窄并换行。
@export_range(120.0, 1600.0, 1.0) var tutorial_max_width: float = 760.0
@export_range(0, 40, 1) var tutorial_line_spacing: int = 10
@export_range(0.0, 1.0, 0.01) var tutorial_line_width_ratio: float = 0.3
@export_range(1.0, 4.0, 0.5) var tutorial_line_thickness: float = 1.0

@export_group("Level 3 - Outward Scenery", "outward_scenery_")
## 第三关本地坐标的显示范围；比例及视差统一使用下方 Parallax Scenery 参数。
@export var outward_scenery_camera_bounds: Vector2 = Vector2(-512.0, 19000.0)

@export_group("Camp - Scenery", "camp_scenery_")
## Camp 独立前后景开关；不影响帐篷、湖水和碰撞。
@export var camp_scenery_enabled: bool = true
## Camp 相机裁剪边界，避免在其他关卡渲染 Camp 背景。
@export var camp_scenery_camera_bounds: Vector2 = Vector2(-2000.0, 3000.0)
## 原画统一缩放；所有图层保持同一构图，不逐张拉伸。
@export var camp_scenery_scale: float = 1.75
## 布景节点内的地面高度，原画的 1900 像素线对齐这里；完整保留线下前景。
@export var camp_scenery_ground_y: float = 1606.0
## Camp 本地横向位置偏移。
@export var camp_scenery_offset_x: float = 0.0
## 默认关闭视差，准确还原原画构图；启用后使用下面三项速度。
@export var camp_scenery_parallax_enabled: bool = true
## 天空、远景、中景、前景的横向视差比例；1 为跟地形镜头一致。
@export var camp_scenery_sky_speed: float = 0.2
@export var camp_scenery_far_speed: float = 0.5
@export var camp_scenery_middle_speed: float = 0.8
@export var camp_scenery_foreground_speed: float = 1.05
## 前景透明度及人物周围淡出半径，防止草石挡住玩家。
@export_range(0.0, 1.0) var camp_scenery_foreground_opacity: float = 1.0
@export var camp_scenery_player_clear_radius: float = 100.0

@export_group("Camp - Background Parallax", "camp_background_")
## Sprite2D2 背景相对镜头位移的跟随比例；数值越小，远景移动越慢。
@export_range(0.0, 1.0, 0.01) var camp_background_follow_x: float = 0.12
## 纵向跟随比例，默认明显低于横向，避免跳跃时背景大幅上下移动。
@export_range(0.0, 1.0, 0.01) var camp_background_follow_y: float = 0.03
## 背景相对场景中原始位置允许移动的最大像素，分别对应 X / Y。
@export var camp_background_max_offset: Vector2 = Vector2(120.0, 18.0)
## 背景跟随到目标位置的平滑速度；0 表示立即到位。
@export_range(0.0, 30.0, 0.1) var camp_background_smoothing_speed: float = 8.0
## Camp 本地边界；镜头取样和背景像素都会限制在此范围内。
@export var camp_background_local_bounds: Rect2 = Rect2(0.0, 0.0, 2160.0, 1700.0)

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
## 从地表落入喷泉井时启用离屏死亡；不影响由地下乘水柱上升。
@export var level2_fountain_return_fall_enabled: bool = true
## 从井口向下落多少像素后镜头停止跟随；随后人物继续落出画面才死亡。
@export_range(32.0, 2000.0, 32.0) var level2_fountain_return_fall_distance: float = 400.0
## 人物中心越过画面底边的额外屏幕像素，确保身体完全离屏。
@export_range(0.0, 300.0, 8.0) var level2_fountain_return_fall_screen_margin: float = 96.0

@export_group("Level 2 - Archive Gate", "level2_archive_gate_")
## 档案库闸门向上升起的距离（像素），应大于门的高度。
@export_range(1.0, 2000.0, 1.0) var level2_archive_gate_lift_distance: float = 640.0
## 解谜后闸门升起所需秒数；越大越慢。
@export_range(0.1, 10.0, 0.1) var level2_archive_gate_open_duration: float = 1.4

@export_group("Level 2 - Slow Descent", "level2_descent_")
## 仅左侧高落差竖井启用慢下落、快速背景效果。
@export var level2_descent_enabled: bool = true
## 竖井中段的下落限速，像素/秒；越小下降越慢。
@export_range(80.0, 1000.0, 10.0) var level2_descent_fall_speed: float = 260.0
## 进入竖井后的减速强度，像素/秒平方。
@export_range(1000.0, 10000.0, 100.0) var level2_descent_braking: float = 3200.0
## 井口和井底的渐变距离，像素。
@export_range(32.0, 800.0, 16.0) var level2_descent_edge_fade: float = 240.0
## 井口、井底过渡区的宽松限速，像素/秒；离开区域后取消限速。
@export_range(260.0, 3000.0, 20.0) var level2_descent_edge_speed: float = 1200.0
## 两层循环柱子额外向上滚动的基础速度，像素/秒；远柱为其 0.65 倍。
@export_range(0.0, 2400.0, 20.0) var level2_descent_background_speed: float = 900.0
## 正式世界竖井镜头中人物的纵向位置，0.5 为中央。
@export_range(0.2, 0.8) var level2_descent_frame_y: float = 0.5
## 正式世界竖井镜头跟随阻尼，越小跟随越紧。
@export var level2_descent_camera_damping: Vector2 = Vector2(0.08, 0.08)

@export_group("Level 2 - Terrain Art", "level2_terrain_art_")
## 第二关石砖外观总开关；关闭后恢复原有灰盒显示，碰撞不变。
@export var level2_terrain_art_enabled: bool = true
## 兼容旧场景的透明平台参数；新版地形统一使用蓝边黑芯，此项不再参与绘制。
@export var level2_terrain_art_glass_platforms: bool = false
## 兼容旧场景保留；新版统一砖块不再按厚度切换透明材质。
@export_range(1, 4, 1) var level2_terrain_art_glass_max_rows: int = 2
## 石墙边缘宽度占一格的比例；包含蓝色石边与向黑色内层过渡的碎石。
@export_range(0.15, 0.48, 0.01) var level2_terrain_art_border_ratio: float = 0.44
## 折返阶梯竖井左墙向外增加的美术厚度（格）；0 恢复原宽，不改变碰撞。
@export_range(0, 3, 1) var level2_terrain_art_stairwell_left_extra_columns: int = 1
## 入口右墙向左补齐到下落井右墙，让上下两段美术边缘保持一条直线。
@export var level2_terrain_art_entry_wall_aligned: bool = true
## 高落差竖井外侧填成厚实墙体，同时填两条竖井之间的灰缝；仅影响外观。
@export var level2_terrain_art_shaft_exterior_enabled: bool = true
## 竖井组合最外侧向外延伸的墙面宽度（像素），保留两条管道内部空间。
@export_range(0.0, 4096.0, 32.0) var level2_terrain_art_shaft_exterior_width: float = 2048.0
## 地图底部空白向下填充蓝黑墙体的深度（像素）；0 关闭额外填充，不改变死亡范围。
@export_range(0.0, 8192.0, 32.0) var level2_terrain_art_bottom_fill_depth: float = 2048.0
## 主层房间上方与两端外侧填墙的高度；0 关闭这部分外观，不改变通道碰撞。
@export_range(0.0, 4096.0, 32.0) var level2_terrain_art_room_exterior_height: float = 1024.0

@export_group("Level 2 - Scenery", "level2_scenery_")
## 第二关独立前后景开关；关闭后继续显示原灰盒背景。
@export var level2_scenery_enabled: bool = true
## 横向远中景的小幅收色；1 保留原图，前景柱子不受影响。
@export_range(0.5, 1.0, 0.01) var level2_scenery_background_contrast: float = 0.85
@export_range(0.5, 1.0, 0.01) var level2_scenery_background_brightness: float = 0.86
## 横向分层原画在世界中的显示高度；保持每张图片原始宽高比。
@export var level2_scenery_artwork_height: float = 800.0
## 远景相对镜头的移动比例。
@export_range(0.0, 1.0) var level2_scenery_far_speed: float = 0.25
## 窗格、拱廊等中景移动比例，同组保持原图对齐。
@export_range(0.0, 1.0) var level2_scenery_middle_speed: float = 0.85
## 前景柱移动比例。
@export_range(1.0, 1.5) var level2_scenery_foreground_speed: float = 1.03
## 横向前景实体柱透明度，默认完整显示裁切素材。
@export_range(0.0, 1.0) var level2_scenery_foreground_opacity: float = 1.0
## 玩家附近前景进一步淡出的半径，世界像素。
@export var level2_scenery_player_clear_radius: float = 100.0
## 竖井右侧前景柱透明度，默认保留美术原图的深色。
@export_range(0.0, 1.0) var level2_scenery_vertical_foreground_opacity: float = 1.0
## 竖井玩家附近前景淡出半径，避免窄井中的柱子遮住玩家。
@export var level2_scenery_vertical_clear_radius: float = 32.0
## 折返井蓝色底图水平偏移（适配后的像素），不移动柱子或圆桌。
@export var level2_scenery_lower_blue_offset_x: float = 6.0
## 横向背景向折返井内覆盖的深度；64 像素对齐入口第一级台阶，仅改变裁切。
@export_range(0.0, 180.0) var level2_scenery_lower_entry_overlap: float = 64.0
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

@export_group("Level 2 - Readability", "level2_readability_")
## 角色与可站立书本的柔和补光；离开第二关随环境光淡出。
@export var level2_readability_enabled: bool = true
@export var level2_readability_fill_color: Color = Color(0.72, 0.83, 1.0, 1.0)
@export_range(0.0, 1.0, 0.01) var level2_readability_player_energy: float = 0.50
@export_range(0.0, 1.0, 0.01) var level2_readability_book_energy: float = 0.42
## 人物左上方的局部柔光，使用原法线显出耳朵、肩部和衣服的体积。
@export_range(0.0, 1.0, 0.01) var level2_readability_rim_energy: float = 0.35
@export var level2_readability_rim_offset: Vector2 = Vector2(-25.0, -35.0)
@export_range(40.0, 240.0, 1.0) var level2_readability_rim_radius: float = 110.0
## 仅在书本透明轮廓内提亮朝上的边缘，宽度为世界像素，不增加发光外圈。
@export_range(0.0, 0.5, 0.01) var level2_readability_book_edge_strength: float = 0.38
@export_range(0.0, 2.0, 0.1) var level2_readability_book_edge_width: float = 1.2

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
## 离开平台后仍可普通起跳的宽限时间（秒）；0 表示关闭，不消耗二段跳。
@export_range(0.0, 0.3, 0.01) var player_coyote_time: float = 0.12
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
@export var sunken_crown_texture: Texture2D = preload("res://Art/New/component/game1/ancient_crown.png")
## The Starseeker's Codex 贴图；留空时使用程序生成的临时图标。
@export var starseekers_codex_texture: Texture2D = preload("res://Art/New/component/extracted/rune_circle_emblem.png")
## The Scarred Bones 贴图；留空时使用程序生成的临时图标。
@export var scarred_bones_texture: Texture2D = preload("res://Code/Entities/InteractiveComponent/Lake/OfferingBone.tres")
## 湖第一次交互后的水量比例。
@export_range(0.0, 1.0, 0.01) var lake_first_fill_ratio: float = 0.5
## 遗物飞入湖泊的动画时长（秒）。
@export_range(0.1, 3.0, 0.05) var lake_relic_flight_duration: float = 0.65
## 湖泊流水图集的循环播放帧率（帧/秒）。
@export_range(1.0, 30.0, 0.5) var lake_stream_animation_fps: float = 6.0
## 第7帧持物包围尺寸（Action 局部像素，骨头旋转前）；残卷保留交接宽度并按471×457原图等比显示。
@export var lake_relic_held_sizes: Dictionary = {"crown": Vector2(44, 22), "codex": Vector2(65, 63.06794), "bones": Vector2(13, 66)}
## 故障超时；正常时序依赖动画完成信号而非该时长。
@export_range(2.0, 30.0, 0.1) var lake_take_timeout: float = 8.0
@export_range(0.0, 5.0, 0.05) var lake_relic_hold_duration: float = 0.55
@export_range(0.1, 5.0, 0.05) var lake_relic_dissolve_duration: float = 0.7
@export_range(0.1, 1.5, 0.01) var lake_relic_height_ratio: float = 0.6667
## 人物第7帧非透明像素高度，与 Action 世界缩放相乘。
@export var lake_player_visual_height: float = 175.0
## 预置手部 Marker 的附加局部偏移；Marker 也可逐种在场景手调。
@export var lake_hand_offset: Vector2 = Vector2.ZERO


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
@export var player_hp_drain_rate: float = 200.0 / 300.0 * 1.3 * 0.9
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
## 玩家距圣杯图像边缘的最大交互距离（世界像素），不要求身体进入点击区域。
@export_range(0.0, 300.0, 1.0) var chalice_interact_distance: float = 85.0

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

@export_group("Oasis Boss Corruption", "oasis_boss_")
## 第三关 Boss 整体扭曲效果开关；只影响画面。
@export var oasis_boss_corruption_enabled: bool = true
## 整体邪化强度，0 为原始画面，1 为完整效果。
@export_range(0.0, 1.0, 0.01) var oasis_boss_corruption_strength: float = 0.65
## 蠕动扭曲的最大屏幕像素偏移，不改变碰撞轮廓。
@export_range(0.0, 8.0, 0.1) var oasis_boss_distortion_pixels: float = 3.5
## 侵蚀纹理与呼吸变化的流动速度；0 为静止。
@export_range(0.0, 3.0, 0.05) var oasis_boss_flow_speed: float = 0.65
## 暗色身体上浮现的侵蚀细纹强度。
@export_range(0.0, 1.0, 0.01) var oasis_boss_vein_strength: float = 0.2
## 身体向邪化色偏移的混色比例。
@export_range(0.0, 1.0, 0.01) var oasis_boss_tint_strength: float = 0.12
## 侵蚀细纹与身体偏色使用的颜色，默认暗紫色。
@export var oasis_boss_corruption_color: Color = Color(0.24, 0.085, 0.31, 1.0)

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
## 物理 W/S 持续同方向按住后开始观察的秒数。
@export_range(0.0, 2.0, 0.05) var player_camera_look_hold_delay: float = 0.5
## 上下观察相对原构图的距离（世界像素），仍受所有现有限位钳制。
@export_range(0.0, 800.0, 1.0) var player_camera_look_distance: float = 180.0
## 观察和松手恢复的指数平滑速率（每秒），越大越快。
@export_range(0.1, 30.0, 0.1) var player_camera_look_smooth_speed: float = 8.0

@export_group("Camera Gate", "camera_gate_")
## 设置了 scope_origin_path 的永久边界，仅在玩家处于所属关卡的此局部 Y 范围时启用。
## 当前用于第三关 CameraGate5；覆盖绿洲路线及跳跃余量，排除地下第二关。
@export var camera_gate_scope_y_range: Vector2 = Vector2(-1600.0, 2300.0)
## 镜头门边界沿禁止露出方向向内收缩的距离（世界像素）。
@export_range(0.0, 1000.0, 1.0) var camera_gate_margin: float = 0.0
## 非一次性镜头门允许画面移动一个视口宽/高所需的秒数。
@export_range(0.05, 5.0, 0.05) var camera_gate_transition_duration: float = 0.4
## 镜头门真实切换时是否播放全屏渐变黑幕，不改变镜头运动或玩家输入。
@export var camera_gate_fade_enabled: bool = true
## 镜头门黑幕的最大不透明度，0 为全透明，1 为全黑。
@export_range(0.0, 1.0, 0.01) var camera_gate_fade_opacity: float = 1.0
## 镜头门黑幕淡入秒数；淡入后保持至门过渡时长，再淡出。
@export_range(0.0, 5.0, 0.01) var camera_gate_fade_in: float = 0.12
## 镜头门黑幕淡出秒数。
@export_range(0.0, 5.0, 0.01) var camera_gate_fade_out: float = 0.25

@export_group("Level Transition Visual", "level_transition_visual_")
## 关卡接缝黑雾的颜色；该组件位于世界空间，不依赖摄像头或镜头门。
@export var level_transition_visual_black_color: Color = Color(0.19, 0.13, 0.075, 1.0)
## 关卡接缝黑雾中心的不透明度。
@export_range(0.0, 1.0, 0.01) var level_transition_visual_black_opacity: float = 0.82
## 黑雾矩形边缘的柔化比例，越大过渡越宽。
@export_range(0.01, 0.5, 0.01) var level_transition_visual_black_edge_softness: float = 0.22
## 黑雾内部明暗扰动强度，只制造雾感，不采样或模糊游戏画面。
@export_range(0.0, 0.5, 0.01) var level_transition_visual_black_fog_amount: float = 0.12
## 黑雾纹理密度。
@export_range(0.5, 16.0, 0.1) var level_transition_visual_black_fog_scale: float = 4.0
## 黑雾流动速度；0 为静止。
@export_range(0.0, 2.0, 0.01) var level_transition_visual_black_fog_speed: float = 0.08
## 关卡出口白光的主色。
@export var level_transition_visual_glow_color: Color = Color(1.0, 0.92, 0.72, 1.0)
## 白光出口中心的最大不透明度。
@export_range(0.0, 1.0, 0.01) var level_transition_visual_glow_core_opacity: float = 1.0
## 白光出口外围光晕的不透明度。
@export_range(0.0, 1.0, 0.01) var level_transition_visual_glow_halo_opacity: float = 0.72
## 白光矩形边缘的柔化比例，越大过渡越宽。
@export_range(0.01, 0.5, 0.01) var level_transition_visual_glow_edge_softness: float = 0.28
## 白光呼吸幅度；0 为稳定常亮。
@export_range(0.0, 0.5, 0.01) var level_transition_visual_glow_pulse_strength: float = 0.08
## 白光呼吸速度；0 为静止。
@export_range(0.0, 5.0, 0.05) var level_transition_visual_glow_pulse_speed: float = 0.7

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
## 虚拟摇杆基础尺寸 (像素直径，默认 190)
@export var mobile_joystick_size: float = 190.0
## 虚拟摇杆中心手柄尺寸 (像素，默认 72)
@export var mobile_joystick_tip_size: float = 72.0
## 跳跃按钮半径 (像素，默认 52)
@export var mobile_jump_button_radius: float = 52.0
## 冲刺按钮半径 (像素，默认 44)
@export var mobile_dash_button_radius: float = 44.0

@export_group("Audio Settings", "audio_")
## 总音量默认值 (0.0-1.0)
@export_range(0.0, 1.0, 0.01) var audio_master_volume: float = 0.5
## 音乐默认音量 (0.0-1.0)
@export_range(0.0, 1.0, 0.01) var audio_music_volume: float = 1.0
## 全游戏背景音乐启动渐入时长，单位为秒；0 表示立即播放。
@export_range(0.0, 10.0, 0.1) var audio_bgm_fade_in_duration: float = 2.0
## 全游戏背景音乐的基础音量，单位为分贝；叠加音乐及总音量设置。
@export_range(-40.0, 6.0, 0.01) var audio_bgm_volume_db: float = -10.0
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
## 存档文件路径前缀（仅user://可写目录；res://旧档由SaveManager只读兼容）。
@export var setting_save_path_prefix: String = "user://Saves/save_slot_"

## 按键绑定持久化文件路径 (独立于存档槽位)
@export var setting_keybinds_path: String = "user://custom_keybinds.json"
## 设置界面背景透明度
@export_range(0.0, 1.0, 0.05) var setting_panel_opacity: float = 0.92
## 设置和读档共用面板的设计尺寸；小屏等比缩小，内容最小尺寸优先。
@export var setting_panel_design_size: Vector2 = Vector2(900, 620)
## 共用面板与屏幕边缘的安全距离，屏幕像素。
@export_range(0.0, 64.0, 1.0) var setting_panel_screen_margin: float = 12.0
## 共用面板内容留白，依次为左、上、右、下，避免覆盖顶部原画纹样。
@export var setting_panel_content_margins: Vector4 = Vector4(44, 82, 44, 54)
## 补绘边缘的线宽，设计坐标像素。
@export_range(0.5, 4.0, 0.1) var setting_panel_edge_width: float = 1.6

@export_group("Dialog", "dialog_")
## 旁白自动消失的最短停留秒数。
@export_range(0.1, 10.0, 0.1) var dialog_narration_min_duration: float = 2.5
## 旁白自动消失的最长停留秒数。
@export_range(0.1, 20.0, 0.1) var dialog_narration_max_duration: float = 6.0
## 旁白每个字符对应的阅读秒数，最终时长限制在最短与最长停留时间之间。
@export_range(0.01, 1.0, 0.01) var dialog_narration_seconds_per_character: float = 0.12
## 独白与旁白继续箭头的悬停颜色；正常状态为白色。
@export var dialog_arrow_hover_color: Color = Color(1.0, 0.95, 0.70, 1.0)
## 独白每秒显示的字符数。
@export_range(1.0, 120.0, 1.0) var dialog_monologue_chars_per_second: float = 30.0
## 独白显示标点后、显示下一个字前额外停顿的秒数。
@export_range(0.0, 1.0, 0.01) var dialog_monologue_punctuation_pause: float = 0.2

@export_group("Start Menu", "start_menu_")
## 游戏主游玩场景路径 (新开存档或载入进入的目标世界场景)
@export var start_menu_world_scene_path: String = "res://Code/Entities/World/World.tscn"
## 开始菜单背景音乐总线
@export var start_menu_music_bus: StringName = &"MUS_StartMenu"
## 首次按键后主菜单界面的淡入时长，单位为秒。
@export_range(0.0, 3.0, 0.05) var start_menu_ui_fade_duration: float = 0.8

@export_group("New Game Intro", "new_game_intro_")
## 仅新开存档播放的黑幕文字；换行对应屏幕上的两行。
@export_multiline var new_game_intro_text: String = "雨水将带着所有被遗忘的名字\n回到世界的出处"
## 开场文字颜色。
@export var new_game_intro_text_color: Color = Color("eee5cf")
## 1280×720 基准下的字号，小窗口等比缩小。
@export_range(16, 64, 1) var new_game_intro_font_size: int = 28
## 文字淡入时间，单位为秒。
@export_range(0.0, 5.0, 0.1) var new_game_intro_fade_in_duration: float = 1.2
## 文字完全显示后的停留时间，单位为秒。
@export_range(0.0, 15.0, 0.1) var new_game_intro_hold_duration: float = 3.0
## 文字淡出时间，单位为秒；黑幕保留到世界载入。
@export_range(0.0, 5.0, 0.1) var new_game_intro_fade_out_duration: float = 1.0

@export_group("World Opening", "world_opening_")
## 世界就绪后等待的帧数，与开场剧情及读档初始化对齐。
@export_range(0, 10, 1) var world_opening_fade_ready_frames: int = 4
## 开场全屏黑幕淡出时长（秒）。
@export_range(0.0, 2.0, 0.05) var world_opening_fade_duration: float = 0.5

@export_group("Oasis Decoration", "oasis_art_")
## 第三关水化外观透明度，不影响水化碰撞或加速。
@export_range(0.1, 1.0) var oasis_art_water_opacity: float = 0.78
## 第三关水纹滚动速度，只控制装饰动画。
@export_range(0.0, 5.0) var oasis_art_water_scroll_speed: float = 1.5

@export_group("Oasis Phase Transition", "oasis_phase_transition_")
## 拾取枯骨后从去程切至返程时是否播放全屏黑幕。
@export var oasis_phase_transition_enabled: bool = true
## 去程画面淡入至全黑的时长，单位秒。
@export_range(0.0, 5.0, 0.05) var oasis_phase_transition_fade_in: float = 0.45
## 已切换到返程后继续保持全黑的时长，单位秒。
@export_range(0.0, 5.0, 0.05) var oasis_phase_transition_hold: float = 0.15
## 返程画面从全黑淡出的时长，单位秒；淡出完成后开始追逐。
@export_range(0.0, 5.0, 0.05) var oasis_phase_transition_fade_out: float = 0.45

@export_group("Oasis Outward Water", "oasis_outward_water_")
## 玩家进入第三关去程水体时是否立即回满水量。
@export var oasis_outward_water_full_heal_on_enter: bool = true

@export_group("Interactable Component", "interactable_")
@export var interactable_action: StringName = &"interact"
@export var interactable_description_lines: Array[String] = []
@export var interactable_monologue_lines: Array[String] = []

@export_group("Vanishing Blocker", "vanishing_blocker_")
@export var vanishing_blocker_zone_group: StringName = &"VanishZone"
@export_range(0.0, 10.0, 0.05) var vanishing_blocker_fade_duration: float = 0.5
## 区域触发的消失挡板向下沉入地形的世界坐标距离。
@export_range(0.0, 2048.0, 1.0) var vanishing_blocker_sink_distance: float = 240.0
## 信号消失挡板是否使用碎裂 shader；关闭时回退为普通透明淡出。
@export var vanishing_blocker_shatter_enabled: bool = true
## 信号挡板的石质风化消散时长（秒）。
@export_range(0.0, 10.0, 0.05) var vanishing_blocker_weathering_duration: float = 1.2
## 碎块在目标 CanvasItem 本地坐标中的尺寸；TileMap 缩放会同步缩放视觉块大小。
@export_range(16.0, 512.0, 1.0) var vanishing_blocker_shard_size: float = 180.0
## 石面松动时的轻微横向偏移尺度（本地坐标）。
@export_range(0.0, 512.0, 1.0) var vanishing_blocker_scatter_distance: float = 6.0
## 石面风化时缓慢沉降的本地坐标距离。
@export_range(0.0, 1024.0, 1.0) var vanishing_blocker_fall_distance: float = 36.0
## 不规则石缝宽度，取值范围 0 到 0.25。
@export_range(0.0, 0.25, 0.005) var vanishing_blocker_edge_width: float = 0.018
## 石缝的沙褐阴影色及混合强度（Alpha），不发光。
@export var vanishing_blocker_edge_color: Color = Color(0.19, 0.13, 0.075, 0.65)

@export_group("Oasis Boat", "oasis_boat_")
## 第三关七个停靠点的航线进度，按递增顺序配置，起点为 0、终点为 1。
@export var oasis_boat_stop_ratios: Array[float] = [0.0, 0.03338, 0.51271, 0.67568, 0.78541, 0.84054, 1.0]
## 等待障碍消失的停靠点索引；该站不要求玩家登船。
@export var oasis_boat_blocker_stop_index: int = 4

@export_group("Level 2 - Death Boundary", "level2_death_boundary_")
## 第二关可见蓝色边界与接触死亡总开关。
@export var level2_death_boundary_enabled: bool = true
## 符文档案房底部死亡区域的石边与黑色外观；关闭后仍保留死亡判定。
@export var level2_death_boundary_weave_visual_enabled: bool = false
## 日光书架房底部死亡区域的石边与黑色外观；关闭后仍保留死亡判定。
@export var level2_death_boundary_sun_visual_enabled: bool = false
## 月影水道底部死亡区域的石边与黑色外观；关闭后仍保留死亡判定。
@export var level2_death_boundary_moon_visual_enabled: bool = false
## 兼容旧场景保留；新版死亡砖边框统一使用 level2_terrain_art_border_ratio。
@export_range(32.0, 256.0, 8.0) var level2_death_boundary_texture_size: float = 96.0
## 月影水道死亡砖块向下衔接天花板的美术高度；仅合并外观，不扩大死亡碰撞。
@export_range(0.0, 64.0, 1.0) var level2_death_boundary_moon_join_depth: float = 32.0
## 调试飞行时不触发边界，方便查看与搭建地图。
@export var level2_death_boundary_ignore_debug_flight: bool = true

@export_group("Level 2 - Hub Lighting", "level2_hub_light_")
## 地下图书馆环境光与大厅局部光影总开关；离开图书馆时恢复其他关卡底色。
@export var level2_hub_light_enabled: bool = true
@export var level2_hub_light_ambient_color: Color = Color(0.38, 0.44, 0.55, 1.0)
@export_range(0.0, 3.0, 0.05) var level2_hub_light_ambient_transition_time: float = 0.8
@export var level2_hub_light_fountain_color: Color = Color(0.56, 0.76, 1.0, 1.0)
@export_range(0.0, 2.0, 0.01) var level2_hub_light_fountain_idle_energy: float = 0.72
@export_range(0.0, 2.0, 0.01) var level2_hub_light_fountain_active_energy: float = 1.05
## 圆形月光覆盖喷泉附近；位置与物件轮廓由 Lighting 场景预置。
@export_range(32.0, 650.0, 1.0) var level2_hub_light_fountain_radius: float = 510.0
## 喷泉未激活时泉口仍保留微弱冷光；激活后渐亮至下方强度。
@export_range(0.0, 2.0, 0.01) var level2_hub_light_fountain_source_idle_energy: float = 0.18
## 喷泉激活时喷泉口局部补光的强度与半径。
@export_range(0.0, 2.0, 0.01) var level2_hub_light_fountain_source_energy: float = 0.62
@export_range(32.0, 400.0, 1.0) var level2_hub_light_fountain_source_radius: float = 245.0
@export var level2_hub_light_desk_color: Color = Color(1.0, 0.76, 0.47, 1.0)
@export_range(0.0, 1.0, 0.01) var level2_hub_light_desk_energy: float = 0.46
@export_range(32.0, 260.0, 1.0) var level2_hub_light_desk_radius: float = 205.0
## 第二关可交互物的常驻冷色微光（喷泉使用独立光源）。
@export var level2_hub_light_device_color: Color = Color(0.53, 0.78, 1.0, 1.0)
@export_range(0.0, 1.0, 0.01) var level2_hub_light_device_energy: float = 0.29
@export_range(32.0, 260.0, 1.0) var level2_hub_light_device_radius: float = 110.0
## 月影水道移动平台的随行冷光，比可交互物略亮。
@export var level2_hub_light_platform_color: Color = Color(0.58, 0.80, 1.0, 1.0)
@export_range(0.0, 1.0, 0.01) var level2_hub_light_platform_energy: float = 0.46
@export_range(32.0, 260.0, 1.0) var level2_hub_light_platform_radius: float = 145.0
## 左侧下落竖井从井口洒下的月光：光源照亮井口与人物，光束向井底渐隐。
@export_range(0.0, 2.0, 0.01) var level2_hub_light_descent_energy: float = 0.9
@export_range(64.0, 600.0, 1.0) var level2_hub_light_descent_radius: float = 360.0
@export_range(0.0, 0.8, 0.01) var level2_hub_light_descent_beam_opacity: float = 0.15
@export var level2_hub_light_beam_color: Color = Color(0.70, 0.83, 1.0, 1.0)
@export_range(0.0, 0.15, 0.005) var level2_hub_light_beam_opacity: float = 0.11
@export_range(0.0, 0.15, 0.005) var level2_hub_light_glow_opacity: float = 0.075
@export var level2_hub_light_shadows_enabled: bool = true
@export_range(0.0, 1.0, 0.01) var level2_hub_light_shadow_opacity: float = 0.35
@export_range(0.0, 8.0, 0.1) var level2_hub_light_shadow_smooth: float = 2.0
@export_range(0.0, 3.0, 0.05) var level2_hub_light_transition_time: float = 0.65

@export_group("Room Camera Zone", "room_camera_zone_")
## 房间固定镜头区域总开关；关闭后恢复普通跟随。
@export var room_camera_zone_enabled: bool = false
## 进入房间时的镜头过渡时间（秒）。
@export_range(0.05, 3.0, 0.05) var room_camera_zone_transition_time: float = 0.7
## 离开区域需要额外走出的距离，避免门口来回微动反复切镜。
@export_range(0.0, 100.0, 1.0) var room_camera_zone_exit_margin: float = 24.0

@export_group("Sunken Palace - Scenery", "sunken_scenery_")
## 沉没宫殿本地 X 坐标的背景显示范围，避免第一关背景覆盖其他关卡。
@export var sunken_scenery_camera_bounds: Vector2 = Vector2(-515.0, 4500.0)
## 镜头与沉没宫殿原点在 Y 轴上的最大距离；超出后隐藏宫殿背景。
@export_range(0.0, 10000.0, 10.0, "or_greater") var sunken_scenery_camera_y_distance: float = 2000.0
## 背景纵向视差：1 固定在世界中，不跟随人物或镜头升降；0 贴住屏幕。横向视差沿用各层配置。
@export_range(0.0, 1.0, 0.05) var sunken_scenery_vertical_scroll_scale: float = 1.0
## 旧沙丘阈值参数，保留以兼容已有设置；背景已统一使用 sunken_scenery_vertical_scroll_scale。
@export_range(0.0, 3000.0, 10.0, "or_greater") var sunken_scenery_dunes_stop_follow_height: float = 320.0
## 旧沙丘跟随参数，保留以兼容已有设置；不再根据镜头高度追加背景偏移。
@export_range(0.0, 1.0, 0.05) var sunken_scenery_dunes_vertical_follow_ratio: float = 1.0
## visualplayer 宫殿墙面与下层沙漠背景交界处的水平羽化宽度，单位为屏幕像素；0 表示关闭。
@export_range(0.0, 160.0, 1.0) var sunken_scenery_visual_player_fade_width: float = 72.0
## visualplayer 宫殿墙面上、下横向切线的垂直羽化高度，单位为屏幕像素；0 表示关闭。
@export_range(0.0, 160.0, 1.0) var sunken_scenery_visual_player_fade_height: float = 56.0

@export_group("Sunken Palace - Lift Rope", "sunken_lift_rope_")
## 横绳左端固定点，使用沉没宫殿 MovePl 父空间坐标。
@export var sunken_lift_rope_left_anchor: Vector2 = Vector2(-81.75574, -920.0)
## 横绳右端固定点，与左端保持相同高度，固定于右上台阶侧面。
@export var sunken_lift_rope_right_anchor: Vector2 = Vector2(260.6, -920.0)
## 吊环相对移动平台原点的偏移，竖绳下端随此点移动。
@export var sunken_lift_rope_attachment: Vector2 = Vector2(0.0, -84.0)
## 绳子绘制宽度；纹理按此宽度等比重复，不随长度拉伸。
@export_range(1.0, 24.0, 0.5) var sunken_lift_rope_width: float = 8.0
## 拆分后的吊架平台图相对平台碰撞中心的位置。
@export var sunken_lift_rope_art_offset: Vector2 = Vector2(0.0, -38.0)
## 吊架平台图的等比缩放。
@export_range(0.05, 2.0, 0.01) var sunken_lift_rope_art_scale: float = 0.4

@export_group("Interaction Dot", "interaction_dot_")
## 是否显示可交互实体中心的普通圆点，不影响既有照明。
@export var interaction_dot_enabled: bool = true
## 圆点的暖白颜色与中心不透明度，边缘渐隐；不受环境光影响。
@export var interaction_dot_color: Color = Color(1.0, 0.96, 0.85, 0.65)
## 圆点半径，单位为世界像素，不随实体缩放。
@export_range(1.0, 32.0, 0.5) var interaction_dot_radius: float = 15.0

@export_group("Low Health Sand Overlay", "low_health_sand_")
## 屏幕边缘沙化开关；独立于人物的15%缺水表现。
@export var low_health_sand_enabled: bool = true
## 生命比例严格低于此值才进入危机状态；0 表示不触发。
@export_range(0.0, 1.0, 0.01) var low_health_sand_threshold: float = 0.3
## 边缘最大不透明度，不影响中心视野。
@export_range(0.0, 1.0, 0.01) var low_health_sand_max_opacity: float = 0.62
## 最大侵蚀宽度占屏幕短边比例，硬限制不超过18%。
@export_range(0.01, 0.18, 0.01) var low_health_sand_edge_width: float = 0.18
## 强度从0到1或从1到0所需秒数；0为立即切换，死亡始终立即清除。
@export_range(0.0, 3.0, 0.05) var low_health_sand_fade_duration: float = 0.65
## 呼吸频率（次/秒）与微弱透明度起伏幅度。
@export_range(0.0, 2.0, 0.05) var low_health_sand_pulse_speed: float = 0.32
@export_range(0.0, 0.15, 0.01) var low_health_sand_pulse_amount: float = 0.06
## 细沙尺寸（屏幕像素）及沿边缘流动速度（屏幕像素/秒）。
@export_range(0.5, 4.0, 0.1) var low_health_sand_grain_size: float = 1.4
@export_range(0.0, 60.0, 1.0) var low_health_sand_flow_speed: float = 12.0
## 沙金与暗沙颜色；颜色alpha与最大不透明度相乘。
@export var low_health_sand_color: Color = Color(0.76, 0.59, 0.32, 1.0)
@export var low_health_sand_dark_color: Color = Color(0.19, 0.13, 0.075, 1.0)

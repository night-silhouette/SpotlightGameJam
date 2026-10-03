extends Node

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
## 跳跃初速度
@export var player_jump_speed: float = 380.0
## 长按跳跃滞空调节能力系数 (影响跳跃手感曲线)
@export var player_jump_ability: float = 0.85
## 蹬墙跳垂直弹跳力与水平反冲基数
@export var player_climb_ability: float = 480.0
## 贴墙滑落时的最大下落速度限制
@export var player_max_fall_speed: float = 120.0

@export_group("Dash", "player_dash_")
## 冲刺持续时间 (秒)
@export var player_dash_time: float = 0.15
## 冲刺位移速度
@export var player_dash_speed: float = 650.0
## 冲刺冷却间隔 (秒)
@export var player_dash_span: float = 0.65

@export_group("Combat & Health", "player_")
## 玩家最大生命值
@export var player_max_hp: float = 200.0
## 受到伤害时的硬直顿挫时间 (秒)
@export var player_hurt_time: float = 0.15
## 受伤后的无敌免伤时间 (秒)
@export var player_unbeatable_time: float = 0.3
## 随时间自然掉血速率 (每秒掉血量)
@export var player_hp_drain_rate: float = 5.0

@export_group("Rope & Grapple", "rope_")
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

@export_group("Interactive - Water Flow", "water_flow_")
## 流水区域加速系数 (进入速度 * 该倍数)
@export var water_flow_speed_multiplier: float = 1.9
## 保证进入流体时的最低喷射加速值
@export var water_flow_min_speed: float = 600.0
## 水符文石交互激活有效距离
@export var water_flow_interact_distance: float = 130.0
## 水符文激活技能冷却时间 (秒)
@export var water_rune_cooldown: float = 2.0

@export_group("Interactive - Spikes", "spikes_")
## 通用地刺基础伤害值
@export var spikes_damage: float = 40.0
## 尖刺命中击退力度标量
@export var spikes_knockback_force: float = 400.0

@export_group("Interactive - Rising Spikes", "rising_spikes_")
## 时序突刺基础伤害值
@export var rising_spikes_damage: float = 50.0
## 时序突刺击退力度标量
@export var rising_spikes_knockback_force: float = 450.0
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

@export_group("Interactive - Crumbling Platform", "crumble_")
## 踩踏后震颤延迟坍塌时间 (秒)
@export var crumble_delay: float = 0.6
## 坍塌碎裂后在原地重生的等待时长 (秒)
@export var crumble_respawn_time: float = 3.0
## 震颤剧烈程度幅度 (像素)
@export var crumble_shake_offset: float = 2.5

@export_group("Interactive - Slick Wall", "slick_wall_")
## 光滑滑石墙摩擦系数 (极度光滑)
@export var slick_wall_friction: float = 0.0

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
@export var stalactite_knockback_force: float = 350.0

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

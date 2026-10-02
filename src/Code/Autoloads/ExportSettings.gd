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
@export var player_dash_speed: float = 700.0
## 冲刺冷却间隔 (秒)
@export var player_dash_span: float = 0.65

@export_group("Combat & Health", "player_")
## 玩家最大生命值
@export var player_max_hp: float = 100.0
## 受到伤害时的硬直顿挫时间 (秒)
@export var player_hurt_time: float = 0.15
## 受伤后的无敌免伤时间 (秒)
@export var player_unbeatable_time: float = 0.3

@export_group("Rope & Grapple", "rope_")
## 绳索最大有效射程距离
@export var rope_max_length: float = 350.0
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
## 绳索射线检测碰撞层级掩码 (默认层1 world + 层3 entity = 5)
@export_flags_2d_physics var rope_collision_mask: int = 5

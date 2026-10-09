extends Node

## 第二关物件请求交互。source 为关卡内设备，player 为靠近的角色。
signal Level2InteractionRequested(source: Node2D, player: Node2D)
## 第二关钥匙、谜题或出口状态改变。level 为对应关卡实例。
signal Level2StateChanged(level: Node2D)
## 第二关喷泉返程结束；世界管理器可监听并连接真正主城入口。
signal Level2Completed(level: Node2D, player: Node2D)

## 交互组件被触发时触发；component 为发起交互的组件节点，interactor 为交互主体（通常是玩家）。
signal ComponentInteracted(component: Node2D, interactor: Node2D)
## 请求展示第一阶段描述文本；lines 为按顺序展示的文本数组。
signal ComponentDescriptionRequested(component: Node2D, lines: Array[String])
## 请求展示第二阶段内心独白文本；lines 为按顺序展示的文本数组。
signal ComponentMonologueRequested(component: Node2D, lines: Array[String])
## 当障碍物开始清除碰撞并淡出时触发。
signal BlockerVanishStarted(blocker: Node2D)
## 当障碍物淡出完成、即将被释放前触发。
signal BlockerVanished(blocker: Node2D)

## 恢复普通玩家跟随。
## @param player PlayerWithCamera 内的原 Player 节点。
signal CameraNormalRequested(player: Node2D)

## 第一幕沙漠：人物左下、右上留白，正文纵排。
## @param player PlayerWithCamera 内的原 Player。
## @param title 章节标题；传 "" 跳过标题。
## @param text 纵排正文；传 "" 不显示。
## @param intro 是否播放黑幕/模糊开场。
## @param bounds 世界坐标镜头范围；传 Rect2() 沿用基础镜头边界。
signal CameraDesertRequested(player: Node2D, title: String, text: String, intro: bool, bounds: Rect2)

## 第二幕下落：锁 X，平滑跟随玩家 Y；正文显示在上方。
## @param player PlayerWithCamera 内的原 Player。
## @param title 章节标题；传 "" 跳过标题。
## @param text 上方叙事正文；传 "" 不显示。
## @param bounds 世界坐标镜头范围；传 Rect2() 沿用基础镜头边界。
signal CameraDescentRequested(player: Node2D, title: String, text: String, bounds: Rect2)

## 第三幕渡舟：锁 Y，平滑横移跟随目标；顶部遮罩，正文显示在水面区域。
## @param player PlayerWithCamera 内的原 Player。
## @param follow_target 跟随的船体节点；传 null 跟随玩家。
## @param title 章节标题；传 "" 跳过标题。
## @param text 水面区域的叙事正文；传 "" 不显示。
## @param bounds 世界坐标镜头范围；传 Rect2() 沿用基础镜头边界。
signal CameraBoatRequested(player: Node2D, follow_target: Node2D, title: String, text: String, bounds: Rect2)

## 遗物 CG：暂停玩家子树，从玩家近景过渡到 anchor 空镜；最终就位后播放文字。
## @param player PlayerWithCamera 内的原 Player。
## @param anchor 空镜中心节点（不可为空）；取请求时的世界坐标。
## @param title 空镜就位后的标题；传 "" 跳过标题。
## @param text 标题退去后的仪式正文；传 "" 不显示。
## @param bounds 世界坐标镜头范围；传 Rect2() 沿用基础镜头边界。
signal CameraRitualRequested(player: Node2D, anchor: Node2D, title: String, text: String, bounds: Rect2)

## 小室固定镜头：锁在 anchor 的请求时位置，玩家可以自由移动。
## @param player PlayerWithCamera 内的原 Player。
## @param anchor 房间镜头中心节点（不可为空）；取请求时的世界坐标。
## @param title 房间标题；传 "" 跳过标题。
## @param text 房间叙事正文；传 "" 不显示。
## @param bounds 世界坐标镜头范围；传 Rect2() 沿用基础镜头边界。
signal CameraFixedRequested(player: Node2D, anchor: Node2D, title: String, text: String, bounds: Rect2)

## 旧版通用切镜请求；新接入优先使用上方具名信号。
## @param player PlayerWithCamera 内的原 Player。
## @param mode normal 普通、desert 沙漠、descent 下落、boat 渡舟、ritual 仪式、fixed 固定。
## @param options 镜头参数字典；字段和示例见 CameraDirector_README.md 的“旧接口兼容”。
signal CameraShotRequested(player: Node2D, mode: StringName, options: Dictionary)

## 由关卡发送：结束 CG 并回到此前镜头，回镜后恢复操作；非 CG 时返回普通跟随。
## @param player PlayerWithCamera 内的原 Player。
signal CameraShotEndRequested(player: Node2D)

## 镜头就位时触发（不代表文字播完）；仪式镜头仅在最终空镜就位时触发。
## @param player 本次切镜对应的原 Player。
## @param mode normal 普通、desert 沙漠、descent 下落、boat 渡舟、ritual 仪式、fixed 固定。
signal CameraShotReady(player: Node2D, mode: StringName)

## CG 暂停/恢复玩家子树时触发；外部机关不会自动暂停。
## @param player 被暂停/恢复的原 Player。
## @param locked true 暂停玩家子树；false 恢复进入 CG 前的处理模式。
signal CameraInputLockChanged(player: Node2D, locked: bool)

## =============================================================================
## SignalBus.gd - 全局信号总线
## 依据 GameBible 设定与实体规范定义，集中管理全局事件通信与状态解耦
## =============================================================================


#region 1. 玩家钩锁与移动事件

## 玩家发射多向自瞄钩锁时触发
## @param target_pos 目标吸附点全局坐标
signal PlayerGrappleLaunched(target_pos: Vector2)

## 钩锁命中墙面或自瞄钩锁环并开始拉拽时触发
## @param hook_pos 锁定的抓取点世界坐标
signal PlayerGrappleHooked(hook_pos: Vector2)

## 钩锁断开、收回或松开时触发
signal PlayerGrappleReleased

#endregion


#region 2. 水体与符文区域交互

## 玩家施展【4向化墙为水】技能转化符文墙时触发
## @param wall_node 发生水化的符文墙节点
## @param direction 水化朝向
signal RuneWallConverted(wall_node: Node2D, direction: Vector2)

## 水符文技能冷却状态变化时触发 (供 UI 刷新冷却进度条/倒计时)
## @param current_cd 当前剩余冷却时间 (0 为就绪)
## @param max_cd 最大冷却时间
signal WaterRuneCooldownChanged(current_cd: float, max_cd: float)

## 玩家成功触发并激活/凝固流水区域符文时触发
## @param area_node 被操作的流水区域节点
## @param is_fluid 操作后的流体状态
signal WaterRuneActivated(area_node: Node2D, is_fluid: bool)

## 玩家游入水膜内部时触发 (重置冲刺/钩锁)
signal PlayerEnteredWaterWall

## 玩家破水喷射而出时触发
## @param eject_direction 弹出速度/冲刺方向
signal PlayerExitedWaterWall(eject_direction: Vector2)

#endregion


#region 3. 玩家生命值与掉血机制

## 启动玩家随时间自然流失血量 (可在特定事件或关卡开局时触发)
## @param drain_rate 每秒流失的血量数值 (默认可传 > 0，若 <= 0 则使用默认速率)
signal StartPlayerHpDrain(drain_rate: float)

## 停止玩家随时间自然流失血量
signal StopPlayerHpDrain

## 玩家生命值/当前血量变化时触发 (供 UI 等响应)
## @param current_hp 当前血量
## @param max_hp 最大血量
signal PlayerHealthChanged(current_hp: float, max_hp: float)

## 玩家进入或离开低水量状态时触发
## @param player_node 状态发生变化的玩家节点
## @param is_low_water true 表示进入低水量状态，false 表示恢复
signal PlayerLowWaterStateChanged(player_node: Node2D, is_low_water: bool)

## 玩家受到伤害/触碰陷阱扣水瞬间触发 (驱动闪白 + Hit-stop 顿帧 + 震屏)
## @param damage_amount 扣除的水量/伤害量
## @param knockback_dir 受击击退方向向量
signal PlayerHurt(damage_amount: float, knockback_dir: Vector2)

#endregion


#region 4. 场景交互组件与陷阱事件

## 通用尖刺陷阱被玩家触碰触发
## @param hazard_node 尖刺陷阱节点
## @param player_node 受到触碰的玩家节点
signal SpikesTriggered(hazard_node: Node2D, player_node: Node2D)

## 时序突刺伸出刺出瞬间触发
## @param spikes_node 尖刺机构节点
signal SpikesExtended(spikes_node: Node2D)

## 时序突刺缩回安全状态时触发
## @param spikes_node 尖刺机构节点
signal SpikesRetracted(spikes_node: Node2D)

## 关卡微光小圣杯被玩家触碰回满水量时触发
## @param station_node 圣杯站节点
signal ChaliceStationUsed(station_node: Node2D)

## 玩家激活帐篷设置重生点时触发
## @param tent_node 帐篷节点
## @param respawn_position 重生点世界坐标
signal TentActivated(tent_node: Node2D, respawn_position: Vector2)

## 玩家在重生点完成重生时触发
## @param respawn_position 重生点世界坐标
signal PlayerRespawned(respawn_position: Vector2)

## 易碎平台开始开裂震颤时触发
## @param platform_node 易碎平台节点
signal PlatformCracked(platform_node: Node2D)

## 易碎平台完全坍塌碎裂时触发
## @param platform_node 易碎平台节点
signal PlatformCollapsed(platform_node: Node2D)

## 易碎平台原地重生复原时触发
## @param platform_node 易碎平台节点
signal PlatformRespawned(platform_node: Node2D)

## 移动平台抵达路径端点并进入停顿时触发
## @param platform_node 移动平台节点
## @param endpoint_index 端点编号：0 为起点，1 为终点
signal MovingPlatformEndpointReached(platform_node: Node2D, endpoint_index: int)

## 移动平台结束端点停顿并反向启程时触发
## @param platform_node 移动平台节点
## @param direction 新移动方向：1 前往终点，-1 返回起点
signal MovingPlatformDirectionChanged(platform_node: Node2D, direction: int)

## 定向追逐移动组件进入新速度阶段时触发。
## @param mover_node 发生阶段变化的移动组件。
## @param stage_index 阶段编号，从 1 开始。
## @param base_speed 新阶段的基础速度。
signal ChaseMoverStageChanged(mover_node: Node2D, stage_index: int, base_speed: float)

## 定向追逐移动组件开始或暂停时触发。
## @param mover_node 状态发生变化的移动组件。
## @param active true 为开始或继续，false 为暂停。
signal ChaseMoverActiveChanged(mover_node: Node2D, active: bool)

## 致命追逐体接触玩家并请求立即死亡时触发。
## @param player_node 被接触的玩家节点。
## @param source_node 发出致死请求的追逐体节点。
signal PlayerInstantDeathRequested(player_node: Node2D, source_node: Node2D)

## 钟乳石检测到玩家走过开始松动下落时触发
## @param stalactite_node 钟乳石节点
signal StalactiteTriggered(stalactite_node: Node2D)

## 钟乳石砸中目标(玩家或地面)瞬间触发
## @param stalactite_node 钟乳石节点
## @param target 碰撞目标节点
signal StalactiteHit(stalactite_node: Node2D, target: Node2D)

## 钟乳石碎裂消失时触发
## @param stalactite_node 钟乳石节点
signal StalactiteShattered(stalactite_node: Node2D)

## 下落方块/落石检测到玩家走过开始掉落时触发
## @param block_node 落石节点
signal FallingBlockTriggered(block_node: Node2D)

## 下落方块下落砸中目标时触发
## @param block_node 落石节点
## @param target 碰撞目标节点
signal FallingBlockHit(block_node: Node2D, target: Node2D)

## 下落方块落到地面稳定变为可踩平台时触发
## @param block_node 落石节点
signal FallingBlockLanded(block_node: Node2D)

#endregion


#region 5. 设置与存档系统事件

## 按键绑定变更并持久化保存时触发
## @param action_name 变更的输入动作名
## @param event 绑定的输入事件描述
signal KeybindChanged(action_name: StringName, event_desc: String)

## 请求打开或关闭设置界面
## @param is_open 是否打开
signal SettingVisibilityRequested(is_open: bool)

## 存档已成功保存/新建时触发
## @param slot_index 槽位索引 (1-5)
signal SaveSlotSaved(slot_index: int)

## 存档被载入应用时触发
## @param slot_index 槽位索引 (1-5)
signal SaveSlotLoaded(slot_index: int)

## 存档槽位被删除时触发
## @param slot_index 槽位索引 (1-5)
signal SaveSlotDeleted(slot_index: int)

#endregion


 

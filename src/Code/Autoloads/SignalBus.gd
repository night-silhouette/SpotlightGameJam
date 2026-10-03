extends Node

## =============================================================================
## SignalBus.gd - 全局信号总线
## 依据 GameBible 设定与实体规范定义，集中管理全局事件通信与状态解耦
## =============================================================================


#region 1. 水资源生态核心 (Water Ecosystem Core)

## 水量发生变动时触发
## @param current_water 当前剩余水量
## @param max_water 当前最大水量上限
signal WaterChanged(current_water: float, max_water: float)

## 水量低于警戒线 (<15%) 触发，进入低水虚弱/锁钩锁状态
signal WaterCriticalEntered

## 水量脱离低水警戒恢复正常时触发
signal WaterCriticalExited

## 水量耗尽 (0%) 触发角色沙化消散死亡流程
signal WaterDepleted

## 触碰微光小圣杯或水源补水时触发
## @param amount 恢复的水量数值
signal WaterReplenished(amount: float)

## 在微光营地再生之池提交信物扩容水量上限时触发
## @param new_max 扩容后的最大水量上限
signal WaterMaxCapacityIncreased(new_max: float)

#endregion


#region 2. 玩家角色实体 (Player Character Entity)

## 玩家运动学主状态发生改变时触发 (如 IDLE, RUN, JUMP, FALL, WALL_CLING, HURT, DEAD 等)
## @param old_state 变更前的状态标识
## @param new_state 变更后的状态标识
signal PlayerStateChanged(old_state: Variant, new_state: Variant)

## 玩家起跳瞬间触发 (零前摇拉伸形变与音效)
## @param is_double_jump 是否为二段跳 (若是则配合脚底扩散水环特效)
signal PlayerJumped(is_double_jump: bool)

## 玩家落地接触地面瞬间触发 (驱动代码 Squash & Stretch 压缩回弹)
signal PlayerLanded

## 玩家进入贴墙滑行状态触发
signal PlayerWallClingStarted

## 玩家脱离贴墙状态触发
signal PlayerWallClingEnded

## 玩家触发无敌冲刺 (Dash) 时触发
## @param direction 冲刺方向向量
signal PlayerDashStarted(direction: Vector2)

## 玩家冲刺结束时触发
signal PlayerDashEnded

## 玩家发射多向自瞄钩锁时触发
## @param target_pos 目标吸附点全局坐标
signal PlayerGrappleLaunched(target_pos: Vector2)

## 钩锁命中墙面或自瞄钩锁环并开始拉拽时触发
## @param hook_pos 锁定的抓取点世界坐标
signal PlayerGrappleHooked(hook_pos: Vector2)

## 钩锁断开、收回或松开时触发
signal PlayerGrappleReleased

## 玩家施展【4向化墙为水】技能转化符文墙时触发
## @param wall_node 发生水化的符文墙节点
## @param direction 水化朝向
signal RuneWallConverted(wall_node: Node2D, direction: Vector2)

## 玩家游入水膜内部时触发 (重置冲刺/钩锁)
signal PlayerEnteredWaterWall

## 玩家破水喷射而出时触发
## @param eject_direction 弹出速度/冲刺方向
signal PlayerExitedWaterWall(eject_direction: Vector2)

## 玩家受到伤害/触碰陷阱扣水瞬间触发 (驱动闪白 + Hit-stop 顿帧 + 震屏)
## @param damage_amount 扣除的水量/伤害量
## @param knockback_dir 受击击退方向向量
signal PlayerHurt(damage_amount: float, knockback_dir: Vector2)

## 启动玩家随时间自然流失血量 (可在特定事件或关卡开局时触发)
## @param drain_rate 每秒流失的血量数值 (默认可传 > 0，若 <= 0 则使用默认速率)
signal StartPlayerHpDrain(drain_rate: float)

## 停止玩家随时间自然流失血量
signal StopPlayerHpDrain

## 玩家生命值/当前血量变化时触发 (供 UI 等响应)
## @param current_hp 当前血量
## @param max_hp 最大血量
signal PlayerHealthChanged(current_hp: float, max_hp: float)

## 玩家死亡流程启动时触发 (冻结输入、触发沙化消散)
signal PlayerDied

## 玩家在营地帐篷或复活点重生时触发
## @param spawn_point_pos 重生坐标位置
signal PlayerRespawned(spawn_point_pos: Vector2)

#endregion


#region 3. 关卡交互与功能组件 (Level Components & Hazards)

## 通用陷阱触碰触发 (尖刺、时序刺等)
## @param hazard_node 触发伤害的陷阱节点
## @param player_node 受到触碰的玩家节点
signal HazardTriggered(hazard_node: Node2D, player_node: Node2D)

## 时序突刺伸出刺出瞬间触发
## @param spikes_node 尖刺机构节点
signal SpikesExtended(spikes_node: Node2D)

## 时序突刺缩回安全状态时触发
## @param spikes_node 尖刺机构节点
signal SpikesRetracted(spikes_node: Node2D)

## 坠落巨墙受触发急速砸落时触发
## @param wall_node 坠落巨墙节点
signal FallingWallDropped(wall_node: Node2D)

## 易碎平台被踩踏开始震颤开裂时触发
## @param platform_node 平台节点
signal PlatformCracked(platform_node: Node2D)

## 易碎平台完全崩塌下坠碎裂时触发
## @param platform_node 平台节点
signal PlatformCollapsed(platform_node: Node2D)

## 易碎平台倒计时结束原地重生复原时触发
## @param platform_node 平台节点
signal PlatformRespawned(platform_node: Node2D)

## 可推动垫脚石被玩家贴靠推移时触发
## @param block_node 垫脚石节点
## @param new_position 当前位移位置
signal PushableBlockMoved(block_node: Node2D, new_position: Vector2)

## 自瞄金属钩锁环被钩爪扣住吸附时触发
## @param ring_node 钩锁环节点
signal GrappleRingLatched(ring_node: Node2D)

## 自瞄金属钩锁环脱离解除吸附时触发
## @param ring_node 钩锁环节点
signal GrappleRingUnlatched(ring_node: Node2D)

#endregion


#region 4. 机关、门禁与解密组件 (Mechanisms & Puzzles)

## 地面压力机关按钮被玩家或垫脚石踩压触发
## @param switch_node 压力开关节点
signal PressureSwitchPressed(switch_node: Node2D)

## 地面压力机关按钮重压解除释放时触发
## @param switch_node 压力开关节点
signal PressureSwitchReleased(switch_node: Node2D)

## 机关移门开启升起时触发
## @param door_node 移门节点
signal MechanismDoorOpened(door_node: Node2D)

## 机关移门落下关闭时触发
## @param door_node 移门节点
signal MechanismDoorClosed(door_node: Node2D)

## 关卡核心过关封锁铁门下砸彻底锁死时触发
## @param gate_node 铁门节点
signal ClearanceGateLocked(gate_node: Node2D)

## 飞翔古书目标在空中被跳跃或冲刺触碰命中时触发
## @param book_node 飞翔古书节点
signal FlyingBookHit(book_node: Node2D)

## 顺序解密火炬被按序点亮单根时触发
## @param torch_index 被点亮的火炬序号
## @param torch_node 火炬节点
signal TorchLit(torch_index: int, torch_node: Node2D)

## 顺序火炬全部按正确顺序点亮，解谜成功时触发
signal SequentialTorchPuzzleSolved

## 顺序火炬点亮顺序错误，解谜失败熄灭重置时触发
signal SequentialTorchPuzzleFailed

#endregion


#region 5. 收集品、叙事信物与任务推进 (Pickups & Relics)

## 关卡微光小圣杯被玩家触碰回满水量时触发
## @param station_node 圣杯站节点
signal ChaliceStationUsed(station_node: Node2D)

## 月辉图书馆古代喷泉三钥匙被拾取时触发
## @param key_id 钥匙标识 (如 "sun_gold", "moon_silver", "twin_weave")
signal AncientKeyCollected(key_id: String)

## 地底古代喷泉集齐三把钥匙插入激活，启动全城水网时触发
## @param keys_count 已插入激活的钥匙数量
signal AncientFountainActivated(keys_count: int)

## 关卡核心叙事信物拔起并收集成功时触发
## @param relic_id 信物标识 (如 "sun_crown", "stargazer_scroll", "notched_bone")
signal NarrativeRelicCollected(relic_id: String)

#endregion


#region 6. 剧情、UI与场景大事件回流 (Story, UI & Flow Events)

## 玩家贴近场景叙事调查物触发交互时触发
## @param lore_id 调查物标识 ID
## @param dialogue_data 调查物附带的叙事对话数据
signal LoreInteracted(lore_id: String, dialogue_data: Dictionary)

## 屏幕底部叙事内心独白 UI 呼出请求
## @param text 独白文本内容
## @param duration 持续时长 (秒)，<= 0 表示等待任意键或手动关闭
signal MonologueRequested(text: String, duration: float)

## 叙事内心独白 UI 关闭淡出时触发
signal MonologueClosed

## 区域全局光照或氛围模式发生切换时触发
## @param zone_name 区域标识 (如 "solarium", "library", "oasis")
## @param light_color 目标光照色温
## @param intensity 光照强度
signal ZoneAtmosphereChanged(zone_name: String, light_color: Color, intensity: float)

## 区域 01（烈阳宫殿）拔冠大决堤泄洪回流演出触发
signal Zone1FloodSequenceTriggered

## 区域 02（月辉图书馆）古代喷泉爆发逆流水梯水柱演出触发
signal Zone2WaterGeyserTriggered

## 区域 03（灵魂绿洲与古战场）拔起枯骨触发极限逃生流程时触发
signal Zone3EscapeSequenceStarted

## 区域 03 逃生流程结束时触发
## @param success 是否逃生成功回到主城
signal Zone3EscapeSequenceEnded(success: bool)

## 环境生态小动物受惊逃窜时触发
## @param wildlife_node 动物节点
signal WildlifeScared(wildlife_node: Node2D)

#endregion
 

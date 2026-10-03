extends Node

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

#endregion

 

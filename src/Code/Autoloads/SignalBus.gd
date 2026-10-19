extends Node

## 玩家应用本帧重力后、移动碰撞前发出；区域可在此限制速度，delta 为物理帧秒数。
signal PlayerBeforeMotion(player: CharacterBody2D, delta: float)
## 第二关下落背景速度更新；level 为地图实例，speed 为额外向上滚动的像素/秒，0 表示停止。
signal Level2DescentVisualChanged(level: Node2D, speed: float)

## 第二关物件请求交互。source 为关卡内设备，player 为靠近的角色。
signal Level2InteractionRequested(source: Node2D, player: Node2D)
## 第二关钥匙、谜题或出口状态改变。level 为对应关卡实例。
signal Level2StateChanged(level: Node2D)
## 请求第二关地图重新广播当前钥匙状态，供玩家 HUD 初始化时同步。
signal Level2StateRequested
## 第二关喷泉返程结束；世界管理器可监听并连接真正主城入口。
signal Level2Completed(level: Node2D, player: Node2D)

## 请求玩家在第一关开场独白期间锁定操作，并将起身动画停在第0帧。
signal PlayerOpeningHoldRequested
## 请求玩家从第0帧完整播放第一关开场起身动画。
signal PlayerOpeningStandUpRequested
## 请求玩家取消第一关开场锁定并恢复原有处理模式。
signal PlayerOpeningReleaseRequested

## 请求显示剧情对话框；type 传 &"旁白" 或 &"独白"，content 为要显示的文字。
signal DialogBox(type: StringName, content: String)

## 请求显示非模态教学字幕；text 为完整文案，空字符串清除当前字幕，不锁定玩家操作。
signal TutorialSubtitleRequested(text: String)

## 渐显文字黑幕的整体播放状态变化时触发；active 为是否至少有一张 GradualTextCard 正在播放。
signal GradualTextActiveChanged(active: bool)

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

## 镜头门约束变化；player 为唯一目标玩家，gate 为门实例，active 为是否仍限制，side 为禁止露出的边，boundary 为世界坐标边界。
signal CameraGateChanged(player: Node2D, gate: Area2D, active: bool, side: int, boundary: float)
## 非一次性镜头门切换目标侧；reset 表示出生/读档初始化，其他情况先平滑过界再落锁。
signal CameraGateSideChanged(player: Node2D, gate: Area2D, side: int, boundary: float, reset: bool)
## 非一次性镜头门退出场景；移除该门的当前及待切换约束。
signal CameraGateSideRemoved(player: Node2D, gate: Area2D)
## 目标玩家实际进入镜头门碰撞区域时请求黑幕；player 为该门配置的玩家，gate 为触发的门实例，已解锁的一次性门不发送。
signal CameraGateFadeRequested(player: Node2D, gate: Area2D)

## =============================================================================
## SignalBus.gd - 全局信号总线
## 依据 GameBible 设定与实体规范定义，集中管理全局事件通信与状态解耦
## =============================================================================


## 区域请求切换指定玩家的脚步材质及音频总线；player 为目标玩家，surface 仅 Brick/Sand，footstep_bus 与 move_bus 分别为脚步及动作音频总线。
signal PlayerFootstepSurfaceChangeRequested(player: Node2D, surface: String, footstep_bus: StringName, move_bus: StringName)

## UI 请求设置永久能力；ability 为 double_jump 或 rope，enabled 为目标解锁状态。
signal PlayerAbilityChangeRequested(ability: StringName, enabled: bool)
## UI 请求当前玩家能力状态，用于初始化或重新打开面板。
signal PlayerAbilityStateRequested
## 玩家永久能力变化或应答状态请求时触发；两个布尔值分别为二段跳与钩索解锁状态。
signal PlayerAbilitiesChanged(double_jump_enabled: bool, rope_enabled: bool)
## UI 请求切换调试飞行；enabled 为目标开关状态，不写入存档。
signal PlayerDebugFlightChangeRequested(enabled: bool)
## UI 请求当前调试飞行状态；无参数。
signal PlayerDebugFlightStateRequested
## 玩家调试飞行变化或应答查询时触发；enabled 为当前实际状态。
signal PlayerDebugFlightChanged(enabled: bool)

## 发出时角色获得 The Sunken Crown；无参数。
signal lock1
## 发出时角色获得 The Starseeker's Codex；无参数。
signal lock2
## 发出时角色获得 The Scarred Bones；无参数。
signal lock3
## 请求玩家广播三件遗物的持有状态；无参数。
signal PlayerRelicStateRequested
## 角色持有状态变化或响应查询时触发；crown、codex、bones 分别表示三件遗物是否持有。
signal PlayerRelicsChanged(crown: bool, codex: bool, bones: bool)
## 湖泊请求消耗一件遗物时触发；relic 为 crown、codex 或 bones。
signal PlayerRelicConsumeRequested(relic: StringName)
## 湖泊请求目标玩家锁定运动并播放掏物；source 为本次演出所有者，relic 为 crown/codex/bones。
signal PlayerOfferingRequested(player: Node2D, source: Node, relic: StringName)
## 掏物实际结束时应答；hand_position 为世界手部中心，held_size 为遗物世界尺寸，visual_height 为人物视觉高度。
signal PlayerOfferingPrepared(player: Node2D, source: Node, relic: StringName, hand_position: Vector2, held_size: Vector2, visual_height: float)
## 所有者结束/取消演出，只释放自身的运动锁，不改变其他剧情的处理开关。
signal PlayerOfferingReleaseRequested(player: Node2D, source: Node)
## 掏物被死亡、读档或其他动作打断；source 为需要取消的演出所有者。
signal PlayerOfferingCancelled(player: Node2D, source: Node)
## 玩家真正死亡时触发；player 为死亡的角色，而非即死请求。
signal PlayerDied(player: Node2D)
## 刻痕枯骨完整献祭并登记永久完成时触发；无参数，不直接播放结局画面。
signal LakeEndingTriggered

## 指定渐显卡淡出隐藏并 Finished 后请求章节；channel 为场景装配的匹配通道。
signal ChapterCardRequested(channel: StringName)

#region 1. 玩家钩锁与移动事件

## 玩家发射多向自瞄钩锁时触发
## @param target_pos 目标吸附点全局坐标
signal PlayerGrappleLaunched(target_pos: Vector2)

## 钩锁命中墙面或自瞄钩锁环并开始拉拽时触发
## @param hook_pos 锁定的抓取点世界坐标
signal PlayerGrappleHooked(hook_pos: Vector2)

## 钩锁断开、收回或松开时触发
signal PlayerGrappleReleased

## 绳索人物动作阶段变化时触发；player 为所属玩家，phase 为 RopeSend、fly 或空字符串（退出），target_pos 为瞄准/挂接世界坐标。
signal PlayerGrapplePhaseChanged(player: Node2D, phase: StringName, target_pos: Vector2)

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

## 湖边请求将目标玩家立即补满血；player 为进入湖边范围的 Player 节点，每次进入只请求一次。
signal PlayerFullHealRequested(player: Node2D)

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

## 物理机关通道状态发生变化时触发。
## @param channel 机关绑定通道；发送端与接收端使用相同名称即可联动。
## @param is_active true 表示通道被按下或激活，false 表示释放。
## @param source 发出状态的物理机关节点；接收端据此正确合并同通道的多个发送端。
signal MechanismChannelStateChanged(channel: StringName, is_active: bool, source: Node2D)

#endregion


#region 5. 设置与存档系统事件

## 按键绑定变更并持久化保存时触发
## @param action_name 变更的输入动作名
## @param event 绑定的输入事件描述
signal KeybindChanged(action_name: StringName, event_desc: String)

## 请求打开或关闭设置界面
## @param is_open 是否打开
signal SettingVisibilityRequested(is_open: bool)

## 手机动作按钮排版保存或恢复默认后触发，HUD 据此立即重排。
signal TouchLayoutChanged

## 设置界面请求调整音量时触发。
## @param channel 音量类别：master 总音量、music 音乐、sfx 音效、dialogue 对白、ambience 环境。
## @param volume 线性音量比例，范围 0.0-1.0，0 为静音。
signal AudioVolumeChangeRequested(channel: StringName, volume: float)

## 音量恢复或调整并应用至音频总线后触发。
## @param channel 音量类别：master 总音量、music 音乐、sfx 音效、dialogue 对白、ambience 环境。
## @param volume 应用后的线性音量比例，范围 0.0-1.0。
signal AudioVolumeChanged(channel: StringName, volume: float)

## 存档已成功保存/新建时触发
## @param slot_index 槽位索引 (1-5)
signal SaveSlotSaved(slot_index: int)

## 存档被载入应用时触发
## @param slot_index 槽位索引 (1-5)
signal SaveSlotLoaded(slot_index: int)

## 存档槽位被删除时触发
## @param slot_index 槽位索引 (1-5)
signal SaveSlotDeleted(slot_index: int)

## 菜单确认退出游戏时触发；无参数，窗口关闭同样走退出存档流程。
signal GameQuitRequested

## 游戏内设置请求返回主菜单时触发；无参数，正式世界会先自动保存当前槽位。
signal ReturnToMainMenuRequested

## 返回主菜单失败、保留当前场景时触发；message 为供设置界面显示的错误提示。
signal ReturnToMainMenuFailed(message: String)

#endregion

const SaveManagerRef = preload("res://Code/Entities/Setting/SaveManager.gd")
const START_MENU_SCENE_PATH = "res://Code/Entities/StartMenu/StartMenu.tscn"

var _returning_to_main_menu: bool = false
var _active_gradual_text_cards: Dictionary = {}


## 登记或释放渐显文字播放状态；source 为卡片自身，active 为是否播放，重复登记不会累计。
func SetGradualTextActive(source: Node, active: bool) -> void:
	var was_active := IsGradualTextActive()
	var source_id := source.get_instance_id()
	if active:
		_active_gradual_text_cards[source_id] = true
	else:
		_active_gradual_text_cards.erase(source_id)
	var is_active := IsGradualTextActive()
	if was_active != is_active:
		GradualTextActiveChanged.emit(is_active)


## 返回是否至少有一张渐显文字卡正在播放，供晚初始化的监听者查询当前状态。
func IsGradualTextActive() -> bool:
	return not _active_gradual_text_cards.is_empty()

func _ready() -> void:
	get_tree().auto_accept_quit = false
	GameQuitRequested.connect(_quit_with_auto_save)
	ReturnToMainMenuRequested.connect(_return_to_main_menu, CONNECT_DEFERRED)

func _return_to_main_menu() -> void:
	var tree = get_tree()
	var scene = tree.current_scene
	if _returning_to_main_menu or not scene or scene.scene_file_path == START_MENU_SCENE_PATH:
		return
	_returning_to_main_menu = true
	var menu = load(START_MENU_SCENE_PATH) as PackedScene
	if not menu:
		_returning_to_main_menu = false
		ReturnToMainMenuFailed.emit("主菜单加载失败，已留在当前游戏。")
		return
	if scene.scene_file_path == ExportSettings.start_menu_world_scene_path:
		var slot = SaveManagerRef.GetActiveSlot()
		if SaveManagerRef.HasSlot(slot) and not SaveManagerRef.AutoSave(tree):
			_returning_to_main_menu = false
			ReturnToMainMenuFailed.emit("自动保存失败，已取消返回主菜单，请重试或手动保存。")
			return
	var error = tree.change_scene_to_packed(menu)
	if error != OK:
		_returning_to_main_menu = false
		ReturnToMainMenuFailed.emit("返回主菜单失败，已保留当前游戏（错误码 %d）。" % error)
		return
	tree.paused = false
	for action in InputMap.get_actions():
		Input.action_release(action)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	await tree.scene_changed
	_returning_to_main_menu = false

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_quit_with_auto_save()

func _quit_with_auto_save() -> void:
	var tree = get_tree()
	var scene = tree.current_scene
	if scene and scene.scene_file_path == ExportSettings.start_menu_world_scene_path:
		var slot = SaveManagerRef.GetActiveSlot()
		if SaveManagerRef.HasSlot(slot) and not SaveManagerRef.AutoSave(tree):
			push_error("退出游戏时自动保存至存档槽位 %d 失败，已取消退出" % slot)
			return
	tree.quit()

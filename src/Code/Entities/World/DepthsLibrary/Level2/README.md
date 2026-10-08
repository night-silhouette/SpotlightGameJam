# 第二关：月辉图书馆 / 连续地图灰盒

## 如何试玩
打开 Level2Playtest.tscn，按 F6。A/D 移动，空格起跳与二段跳；靠近物品按 F 或点击物品上方提示。
本关禁用钩锁。测试场景引用正式 Player.gd 和状态机，用蓝色块替代损坏的玩家贴图；不自动读取正式菜单存档。
F5 和 World.tscn 保持原项目入口。本轮没有直接替换队友的正式世界。

## 设计依据
读取 E:/download1/策划案.md 第 4.2 节：高落差竖井、矿道、水网、机关陷阱、分批提交钥匙、逆流水柱出口。
优先采用用户与策划最新说明：第二关没有钩锁，主要围绕二段跳；三个钥匙任务并行，补给探索可选。
原策划里要求第二关用钩锁的路线取消。五分钟是首次游玩的目标，尚未真人计时。
原文主城枯井东西方位前后矛盾；这里预留出口，由世界整合者决定最终方位。

## 连续空间布局
所有房间都是同一个 Level2Map 场景里的实例，通过碰撞地面、跳台和通道直接相连。
场景实例只是编辑时的整理方式，运行时不卸载房间、不靠门传送，也没有跨房间坐标跳转。

入口断层
   ↓ 裂纹平台塌陷
约 3000 像素落差竖井
   ↓
补给阅览室 ← 隐蔽书廊 ← 日纹书库 ⇄ 废弃矿道 ⇄ 喷泉大厅 ⇄ 渗水矿道 ⇄ 月影水道
                                                     ↓↑
                                                  折返阶梯
                                                     ⇄ 交织档案室

三钥匙提交后：喷泉大厅 → 逆流水柱向上 → 另一个地表枯井出口 → 主城接口（待整合）

## 具体节点与用途
在 Level2Map / Rooms 下：
| 节点 | 内容及编辑位置 |
| --- | --- |
| EntryCollapse | Floor、UpperStep、Collapse、EntryFallReset。移除中间 Step；上方平台比出生地面高 170 像素，需要二段跳到达；断层跌落后返回检查点。入口跳台与易碎平台，位置在 Transform → Position。 |
| DescentShaft | LeftWall、RightWall、RestLedge0..5。280 宽、2700 高的井段；算上入口到大厅的距离，实际下落约 3000。 |
| Hub | Fountain 提交钥匙；HubChalice 补水；FloorWest / FloorEast 中间开口连接下层阶梯；三段 Roof 留出下落井与上升井。 |
| WestPassage / EastPassage | 左右实体矿道。EastPassage / CeilingTrap 引用队友的钟乳石组件。 |
| SunStacks | Shelf0/1/3/5/6、Crumble2/4、SunKey。右侧进入向左探索。取钥匙后 ReturnCatwalk 与 Flow 出现，沿下层栈道回程。 |
| ArchivePassage / RestArchive | 书库左侧继续走到补给房。引用圣杯，ObservatoryScroll 是叙事占位物。 |
| MoonAqueduct | FerryA、Island、FerryB、MoonKey。移动渡台过水；ReturnCatwalk 为取钥匙后的实体返程栈道。 |
| LowerStairwell | Step0..8 为实心石台，150 像素高度间隔、左右交替；Step1 向井口靠拢以避开大厅地板底部。必须从侧边跳上，不能穿过台底；二段跳可原路返回大厅。 |
| WeaveArchive | SunRune / MoonRune / WeaveRune、两组时序地刺、Gate、WeaveKey。按碑文顺序交互开闸。 |
| FountainShaft | Updraft 为物理推动区域，Stream 为水柱占位图形；不会直接设定玩家目的地坐标。 |
| SurfaceExit | Spout 为井口横向喷流，ExitFloor 为落脚地面，FinishArea 发出完成信号。 |

各房间 Spawn 是安全复活点；有 ReturnSpawn 的房间在进入时选离玩家较近的安全端点。
房间间界面已经对齐：单独挪动整间房会断开通道，需要同步调整相邻地面与井壁。
平台可以单独调整。静态平台改变大小时，同时调整 CollisionShape2D 的 Shape/Size 和 Stone、Edge 的形状。
易碎平台和移动平台用它们已有的 Platform Size 参数调整。

## 钥匙、失败与喷泉
- 携带钥匙：拿到后暂存在身上，对应钥匙隐藏，书库/水道返程栈道开放。
- 提交钥匙：返回 Hub/Fountain，F 或鼠标提交当前携带的全部钥匙；可分批提交。
- 死亡/掉入深水：回最近检查点。未提交的钥匙回到各自原位，已提交的保留。
- 三把全部提交：开启实体水柱。走进去持续上升，井口喷流把玩家推出到地表平台。
- 存档接口：ExportSaveData / LoadSaveData 包含携带、已提交、符文、喷泉和完成状态；本地图不写存档文件。
“永久保存”在此指关卡导出的状态不会因死亡回滚；跨游戏会话仍需正式存档管理器按节点路径调用上述接口。
- 正式观星者残卷收集、演出、钩锁解锁、主城池水变化尚未接入；阅览室只有占位说明。

## 复用队友的组件
CrumblingPlatform：入口塌陷、书库脆弱台。
MovingPlatform：两艘渡台。
RisingSpikes：档案室时序地刺，触碰沿用原伤害逻辑。
Stalactite：右侧矿道落石，走过下方会预警、掉落并碎裂。
MiniChaliceStation：大厅和阅览室补水。
本轮没有修改这些组件的脚本，也没有修改第三关、World、原玩家脚本、原镜头或美术。

## 参数
Autoloads/ExportSettings.tscn 的 Level 2 - Blockout：
Interact Radius = 85，View Width = 1000，Platform Speed = 85。
Rune Order = sun,moon,weave（必须三种各一次）。
Fountain Speed = 720 像素/秒，Fountain Exit Speed = 320 像素/秒。
陷阱参数沿用各组件原有的 ExportSettings 分组。房间保持人物跟随，竖井改变构图；不使用固定房间镜头。
HUD 上的文字与计时是灰盒测试辅助；策划要求的正式极简 HUD 还需统一。

## 交给队友
一并提供 Level2 目录、InteractiveComponent/Level2Device 目录，以及 ExportSettings.gd / SignalBus.gd 的新增项。
正式整合引用 Level2Map.tscn；Level2Playtest.tscn 和 Level2PreviewPlayer.tscn 只负责独立测试。
以整个地图根节点对齐正式第二关入口；调整内部节点时保留实体通道接缝。
复用现有 player 分组玩家，不要同时再放 PreviewPlayer。第二关适配已继承正式 PlayerWithCamera.gd 并复用 Phantom Camera。正式世界尚未接入；整合时引用适配脚本与 CameraDirector，并将玩家引用改为正式玩家，避免重复玩家和两台 Camera2D 同时工作。
监听 Level2Completed(level, player) 接主城流程；连接 EntryCollapse 和 SurfaceExit 的实际世界出口。
公共脚本合并保留队友已有修改；此轮没有自动提交或推送。

## 背景尺寸初步建议
横向循环单元 2048×1024，竖井纵向循环单元 1536×2048；这是重复使用的图片单元尺寸，不是整个房间或地图的尺寸。
远景、中景、前景分别导出；需循环的层单独处理相应方向无缝边缘，透明装饰层用带透明通道的 PNG。
原先 2400×1000 房间整图建议不作为这一版循环背景的交付要求。
当前视野见下方镜头说明。1:1 放置时有余量；加入视差、偏移和前景遮挡后，仍需用草图检查覆盖和接缝，不能保证一张图铺满整关。

## 验证记录
- 连续地图版实测塌陷下落到大厅、书库全部跳台及两块易碎台。入口删 Step 后再次验证：普通跳最高抬升约 104 像素，够不到高差 170 的 UpperStep；二段跳成功落到 UpperStep。
- 实际步行验证大厅→左矿道→书库、书库→书廊→补给房，以及右矿道→水道、下层楼梯→档案室的接缝。
- 石台改实心后重新验证：从底部逐级二段跳返回大厅，无钩锁/冲刺；正下方起跳会撞到台底，不能穿透。
- 书库返程栈道步行及出口跳台、水道返程栈道穿过中间岛下方；右矿道钟乳石触发后碎裂。
- 三种符文实际 F 交互开门，导出/还原后闸门保持开启。
- F 拿日钥匙、分批提交；模拟另带未提交钥匙后重生，已提交保留、未提交回原位。
- 水柱使用物理速度经过完整竖井，自动通过井口喷流落到出口平台，并触发完成。
- 两艘渡台的去程跳跃、圣杯补水和鼠标提示在上一版已实测；本轮保持渡台路线尺寸和原组件逻辑。
- 当前运行无新解析/运行错误。局部测试使用了定位起点和构造收集状态，不能等同于真人一次完整通关。
- 尚待真人从入口到出口完整首次试玩，确认五分钟时长、路线辨识度及机关难度。

## 第二关镜头接入
本轮仅接入 Level2Playtest，未修改 World、第三关、原 PlayerWithCamera 脚本、插件或美术。
- Level2PlayerWithCamera：继承项目镜头脚本，使用同一套 PhantomCameraHost / PhantomCamera2D、SignalBus 和演出接口。Player 子节点仍为占位外观和正式玩家逻辑。
- CameraDirector：入口、主层、下层采用连续跟随；两条竖井采用中心轴跟随。普通探索使用同一台 Phantom Camera，避免过场切镜拖慢高速下落。
- CameraDirector/ShaftFollowTarget：固定井中心横坐标，纵向跟随玩家。
- CameraDirector/ShaftOcclusion/Mask：井壁外的暗色遮挡，隐藏相邻另一条井；井口附近渐隐，不挡 HUD、不增加碰撞。后续可配合前景岩层素材替换。
- Backdrop/Fill：暗色底，避免地图边缘露出默认灰色。
- 重生立即回位，楼梯上下层留出重叠的镜头边界以避免横向跳动。大房间不使用固定镜头。
当前分区对应这版灰盒；井位置读取房间节点，入口/主层/下层整体范围在 Level2CameraDirector.gd 内。挪动或扩大房间后应复核范围，并非自动识别任意地图形状。

ExportSettings → Level 2 - Camera：
Max View Height = 800；Offset = (0,-80)；Damping = (0.12,0.18)；Shaft Damping = (0.10,0.12)。
Descent Frame Y = 0.42，Ascent Frame Y = 0.62，分别给运动方向留出视野。
Transition Time = 0.45，为构图偏移平滑参数；Shaft Occlusion = true，Wall Margin = 24，Occlusion Fade = 160。
横向仍使用 Level 2 - Blockout / View Width = 1000，不修改其他关卡的全局镜头缩放。
当前 1152×720 视口下缩放 1.152，显示约 1000×625 世界像素；16:9 下按公式约 1000×563。过窄窗口可见高度最多 800，横向相应收窄。

本轮验证：
- 新脚本通过 Godot 解析；最终启动、游戏日志和编辑器增量日志无新错误。
- 定位检查入口、左右主层、下层档案室、两条竖井；井内横移镜头中心不随之摆动，截图确认井外遮挡有效。
- 定位井中起点后释放玩家，实测高速物理下落到大厅，采样人物始终留在画面内；重生两个物理帧内镜头回到入口。
- 构造三钥匙提交状态，实测水柱上升、井口喷流、落到出口并完成关卡。
- 检查井底和楼梯分区前后，人物可见，楼梯口无横向镜头跳转。
以上是局部验证，不是从零收集钥匙的真人完整通关；不同窗口比例、正式人物素材和 World 整合仍需验收。
walk.png 既有资源错误未在本轮处理；先用蓝色占位玩家测试镜头。游戏已停止，重新打开 Level2Playtest.tscn 按 F6 可试玩。

## 入口越界视野修正与队友调用
入口和地表出口已分开计算镜头上边界：分别依据各自 Ceiling 的 y=-80 和房间位置，避免入口跳跃时露出更高的出口区域。
入口宽 860，小于约 1000 的水平视野；保持人物/平台屏幕尺寸，墙外由 CameraDirector/ShaftOcclusion/Mask 局部遮挡，不在整个画面盖黑幕，也不封闭底部井口。
修改文件：Level2CameraDirector.gd、Level2ShaftOcclusion.gd。无新全局参数，无碰撞或平台尺寸变化。
复测：物理帧输入二段跳，从入口地面落到 UpperStep（x≈494，y≈-2674）；全过程采样人物在画面内。高处取点检查入口镜头顶边不越过 y=-3080。模拟已提交钥匙后实际水柱上升，出口 completed=true。新运行无新增错误。
左右暗区仍会存在，这是房间小于视野时的墙外留黑，正式前景岩层可继续装饰。

队友独立试玩：打开本目录 Level2Playtest.tscn，按 F6；它已经包含地图、占位玩家、镜头导演与遮挡，不要再添加第二个 Player。
队友只取地图：实例化 Level2Map.tscn；这个场景不包含玩家或本轮镜头导演。
队友参考镜头组装：参照 Level2Playtest 的 Level2PlayerWithCamera 和 CameraDirector（连同 ShaftFollowTarget、ShaftOcclusion/Mask 子节点），必须保留同一父节点下的相对引用关系。
正式 World 集成不是把 Level2Playtest 整个嵌进去：需要将 CameraDirector 的地图、镜头包装、玩家引用接到正式节点，并处理进入/离开第二关时的镜头交接；第二关适配参数不能无条件作用于其他关卡。当前尚未实现这一正式世界生命周期。
通关衔接可监听现有 SignalBus.Level2Completed(level, player)；存档仍由地图的 ExportSaveData/LoadSaveData 对接正式存档管理器。
后续交接汇报需包含：队友使用哪个场景、依赖哪些节点/脚本、如何接线或调用，以及哪些正式整合步骤仍未完成。

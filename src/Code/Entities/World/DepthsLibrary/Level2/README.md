# 第二关：月辉图书馆 / 连续地图灰盒

## 2026-10-10 主城左右井口接口（当前版本）

策划确认左口下去、右口上来；截图版主城尚未上传。因此本轮只更新第二关和独立试玩，不修改 Camp.tscn 或 World.tscn，不声称已与正式主城坐标对齐。下面的接口取代旧版“封闭入口房间/右侧横向出口”的约定。

- EntryCollapse 保留为井口下的小型机关段：上方留 240 宽下行口，落脚地面从局部 y=520 移至 280，高台和塌陷平台从 y=350 移至 110，保留 170 高差的二段跳技能锁。入口跌落重生区和出生点同步上移。
- DescentShaft 顶端从地图 y=-2700 上移到 -2940，井壁延长至 2860，底端仍为 y=-80；地下大厅和支路位置不变。
- FountainShaft 顶端上移至地图 y=-3080，井壁长 3000，底端仍为 y=-80；推升区域延伸到地表上方 180，以完成喷出。SurfaceExit 改为敞口和右侧落脚台，移除原封闭顶板/上部侧墙。
- 两口的地表都在地图局部 y=-3080，连接点不能仅挪 Marker；修改开口要同时调整对应碰撞、井壁和镜头范围。

| 用途 | 节点（相对 Level2Map） | 地图局部中心 | 净宽 |
| --- | --- | --- | --- |
| 主城左口，下行 | Rooms/EntryCollapse/CityEntrance | (160, -3080) | 240 |
| 主城右口，上行 | Rooms/FountainShaft/CityExit | (990, -3080) | 140 |

两口中心水平间距 830，单位为世界坐标单位，地图 scale 保持 (1,1)。GetCityConnections() 返回这两个 Marker 的世界坐标和净宽。正式对接时先以主城左口中心减去本地图入口局部坐标确定地图平移，再检查右口；不要缩放整关来匹配间距。若两口实际间距不同，调整井口连接段并重测。入口方向向下，出口方向向上、随后向右落地。

### 队友如何调用

- 独立试玩：打开 Level2Playtest.tscn 按 F6，出生于 CityInterfacePreview 左侧地面；向右走落入左口，再二段跳和踩塌平台下井。CityInterfacePreview 只是两个接口的灰盒地表示意，不能当作正式主城。
- 正式地图：继续复用 DepthsLibrary.tscn 内的 Level2Map 实例。不要额外放 Level2Playtest 或 CityInterfacePreview，不要重复生成测试玩家。按以上 Marker 对齐主城，保留 Level2Completed 信号和存档接口。CameraDirector 当前仅接在独立试玩入口，正式世界镜头仍需整合者接线。
- SurfaceExit/ExitFloor 是右口落脚台；如果正式主城已有同位置地面，需要合并接缝，避免重复碰撞。
- 第二关仍使用 StaticBody2D 地形与已有机关组件；不为这次连接整体改为 TileMapLayer。以后可以在装饰层铺砖，须避免重复添加一套碰撞。
- 玩家继续用正式 Player.gd 的移动逻辑和蓝色占位外观。测试场景补齐公共脚本新增的粒子节点、渐变资源及动画名；空动画仅满足测试状态机接口，不是正式人物动画。

### 本轮验证

在 Godot 运行 Level2Playtest 实测：从地表示意区步行进入左口并落地；普通跳最高约 109，小于高差 170；二段跳最大抬升约 198，落在 UpperStep；继续跳到 Collapse 并触发塌陷，物理下落至大厅 (约 676,496)。
模拟已提交三钥匙状态后，从大厅喷泉经全长水柱上升、喷出右口并落至地表 (约 1208,-3104)，completed=true。排除测试定位的前五帧，上升/喷出过程镜头外帧数为 0；导出并重新载入后喷泉状态与出口水流显示保持一致。最终这一轮游戏/编辑器日志无错误。
这些是局部输入与物理路线验证，不是全钥匙任务的真人完整通关，也尚未对接未上传的主城场景。


## 如何试玩
打开 Level2Playtest.tscn，按 F6。A/D 移动，空格起跳与二段跳；靠近物品按 F 或点击物品上方提示。
本关禁用钩锁。测试场景引用正式 Player.gd 和状态机，用蓝色块替代损坏的玩家贴图；不自动读取正式菜单存档。
F5 和 World.tscn 保持原项目入口。本轮没有直接替换队友的正式世界。

## 设计依据
读取 E:/download1/策划案.md 第 4.2 节：高落差竖井、矿道、水网、机关陷阱、分批提交钥匙、逆流水柱出口。
优先采用用户与策划最新说明：第二关没有钩锁，主要围绕二段跳；三个钥匙任务并行，补给探索可选。
原策划里要求第二关用钩锁的路线取消。五分钟是首次游玩的目标，尚未真人计时。
原策划方位描述有歧义；现按用户和策划最新说明固定为左口下、右口上，见顶部接口约定。

## 连续空间布局
所有房间都是同一个 Level2Map 场景里的实例，通过碰撞地面、跳台和通道直接相连。
场景实例只是编辑时的整理方式，运行时不卸载房间、不靠门传送，也没有跨房间坐标跳转。

主城左口 → 井口二段跳挑战（EntryCollapse）
   ↓ 裂纹平台塌陷
约 3000 像素落差竖井
   ↓
补给阅览室 ← 隐蔽书廊 ← 日纹书库 ⇄ 废弃矿道 ⇄ 喷泉大厅 ⇄ 渗水矿道 ⇄ 月影水道
                                                     ↓↑
                                                  折返阶梯
                                                     ⇄ 交织档案室

三钥匙提交后：喷泉大厅 → 逆流水柱向上 → 主城右侧井口向上喷出 → 右侧落脚地面（正式主城坐标待对齐）

## 具体节点与用途
在 Level2Map / Rooms 下：
| 节点 | 内容及编辑位置 |
| --- | --- |
| EntryCollapse | Floor、UpperStep、Collapse、EntryFallReset。移除中间 Step；上方平台比出生地面高 170 像素，需要二段跳到达；死亡后按玩家当前重生点复活。入口跳台与易碎平台，位置在 Transform → Position。 |
| DescentShaft | LeftWall、RightWall、RestLedge0..5。280 宽、2940 高的井段；算上入口到大厅的距离，实际下落约 3000。 |
| Hub | Fountain 提交钥匙；HubChalice 补水；FloorWest / FloorEast 中间开口连接下层阶梯；三段 Roof 留出下落井与上升井。 |
| WestPassage / EastPassage | 左右实体矿道。EastPassage / CeilingTrap 引用队友的钟乳石组件。 |
| SunStacks | Shelf0/1/3/5/6、Crumble2/4、SunKey。右侧进入向左探索。取钥匙后 ReturnCatwalk 与 Flow 出现，沿下层栈道回程。 |
| ArchivePassage / RestArchive | 书库左侧继续走到补给房。引用圣杯，ObservatoryScroll 是叙事占位物。 |
| MoonAqueduct | FerryA、Island、FerryB、MoonKey。移动渡台过水；ReturnCatwalk 为取钥匙后的实体返程栈道。 |
| LowerStairwell | Step0..8 为实心石台，150 像素高度间隔、左右交替；Step1 向井口靠拢以避开大厅地板底部。必须从侧边跳上，不能穿过台底；二段跳可原路返回大厅。 |
| WeaveArchive | SunRune / MoonRune / WeaveRune、两组时序地刺、Gate、WeaveKey。按碑文顺序交互开闸。 |
| FountainShaft | Updraft 为物理推动区域，Stream 为水柱占位图形；不会直接设定玩家目的地坐标。 |
| SurfaceExit | Spout 为井口横向喷流，ExitFloor 为落脚地面，FinishArea 发出完成信号。 |

第二关不设置自动检查点，各房间的 Spawn 和 ReturnSpawn 标记已移除。进入房间不会覆盖玩家重生点；死亡后由玩家系统返回最近激活的帐篷，没有激活帐篷时沿用玩家初始出生点或读档恢复的重生点。独立测试场景的 CityInterfacePreview/Spawn 只用于测试初始出生。
房间间界面已经对齐：单独挪动整间房会断开通道，需要同步调整相邻地面与井壁。
平台可以单独调整。静态平台改变大小时，同时调整 CollisionShape2D 的 Shape/Size 和 Stone、Edge 的形状。
易碎平台和移动平台用它们已有的 Platform Size 参数调整。

## 钥匙、失败与喷泉
- 携带钥匙：拿到后暂存在身上，对应钥匙隐藏，书库/水道返程栈道开放。
- 提交钥匙：返回 Hub/Fountain，F 或鼠标提交当前携带的全部钥匙；可分批提交。
- 死亡：由玩家系统返回当前重生点，第二关不改写该位置。未提交的钥匙回到各自原位，已提交的保留。
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

## 第二关前后景接入（2026-10-10，按美术预览图组合）

正式引用链：DepthsLibrary.tscn → Level2Map.tscn → Scenery/Level2Scenery.tscn → HorizontalScenery.tscn → parallax_scenery2.tscn。
HorizontalScenery 是 parallax_scenery2 的继承场景，不再复制另一套图片节点。三条横向背景带共同引用它，修改原始拼图会同步到地图。

- HorizontalMain：主横向层，覆盖 x=-4300～4100、y=-80～720，多个相邻房间共用连续背景。
- HorizontalEntry：入口挑战区，位置 (0,-3080)，局部 coverage 为 Rect2(0,0,860,520)。
- HorizontalLower：下层档案室，位置 (0,1320)，局部 coverage 为 Rect2(1650,0,2200,800)。
- DescentShaft、FountainShaft、LowerStairwell：已恢复上一版 VerticalScenery.tscn 的分层竖向重复方案。

原始拼图在 Scenery/parallax_scenery2.tscn：仅使用美术 Horizontal/01、03～11，共 10 张图片，按预览图组合。Sky 是底色，FarBackground 是彩色窗片、窗格、拱窗，NearBackground 是光影、岩顶、亮点和下方桥梁，ForegroundLoop 是两根黑色柱子。窗户等左右两半对应预览图构图；原始完整循环单元是 4096×1024，图片保持 1:1，无额外素材、裁剪或透明度修改。

地图适配由 HorizontalScenery.gd 完成：显示高度取 ExportSettings 的 Artwork Height 与该区域高度中的较小值，整套图片、节点位置和 Repeat Size 一起等比缩放。默认主层/下层高度 800，缩放 0.78125，Repeat Size.x=3200；入口高度 520，缩放 0.5078125，Repeat Size.x=2080。原始拼图文件不被改写，地图物理尺寸不变。
Sky、FarBackground、NearBackground 在地图中统一使用 Middle Speed，避免构图错位；ForegroundLoop 使用 Foreground Speed。循环由原生 Parallax2D 执行。已有 HorizontalCoverage.gdshader 只裁剪整条背景带外缘并淡化角色附近的前景，防止背景穿到其他楼层；不会生成纹理或重绘图案。

队友调用和调节：
1. 直接使用 DepthsLibrary.tscn 或 Level2Map.tscn，背景已包含在里面，不要再添加第二份 Scenery，也不需要新增信号接线。
2. 独立试玩打开 Level2Playtest.tscn 按 F6；它已有测试玩家和镜头，不要把整个试玩场景嵌入 World。
3. 修改图片构图：打开 Scenery/parallax_scenery2.tscn，编辑对应 Sprite2D。这个场景可以单独运行预览原图组合。
4. 修改地图背景尺寸/速度/前景淡化：ExportSettings.tscn → Level 2 - Scenery。Enabled 控制开关，Artwork Height 默认 800；Middle Speed 默认 0.65，Foreground Speed 默认 1.08；Foreground Opacity 默认 0.35，Player Clear Radius 默认 100。Far Speed 用于当前竖井远景，横向底色与窗户保持同速。
5. 改横向覆盖范围：在 Level2Scenery.tscn 中调整三条 Horizontal 实例的位置及 coverage 元数据。同层新增房间扩展该背景带，不必逐房间重复放背景。
6. 当前竖井背景在 Scenery/VerticalScenery.tscn，对应 TextureRect 引用美术素材；详见下面回退说明。

前述横向接入仅替换背景组装和地图适配，没有修改第三关、碰撞、出入口、机关和原始美术。背景拱桥只是装饰，没有可踩踏碰撞。
验证：运行 Level2Playtest，定位检查大厅、左侧阅读室、右侧水道、入口挑战区和下层档案室；三条背景带实例和重复距离正确，原始图与右半图位置按同一比例缩放；本次游戏日志与编辑器增量日志无新增错误。这是局部背景验收，不是完整通关测试。


### 竖井背景回退（2026-10-10）

按用户反馈，正式地图已恢复为上一版 VerticalScenery.tscn：Control + TextureRect + LibraryLayer.gdshader，按井宽等比缩小图片并沿竖向重复、分层滚动。三个区域仍是 DescentShaft 280×2940、FountainShaft 180×3000、LowerStairwell 600×1450；未改变地图物理层、井口、镜头和横向背景。

调用链：DepthsLibrary → Level2Map → Scenery → 三个竖向区域（VerticalScenery.tscn）。队友使用地图即可，不需要额外添加节点。试玩用 Level2Playtest.tscn 按 F6。

原图组合 VerticalComposition.tscn 和纵向拉伸适配脚本 VerticalScenery.gd 暂留供对照，但正式地图已不再引用这套拉伸组合；Vertical Foreground Opacity / Vertical Clear Radius 两个参数也不作用于当前旧版竖井。当前竖井继续使用 Far/Middle/Foreground Speed、Foreground Opacity 和 Player Clear Radius。

1536×4168 是源图片画布像素，并非地图井口要求。旧版缩放到宽 280 后，一段画面高约 760；若保持图像比例又一张铺满 2940 高，宽度需要约 1083。调整玩法井宽必须连同跳台、墙体、水流、镜头、主城接口一起考虑，不能只按图片宽度扩大。

本轮仅恢复背景方案；改井宽仍在讨论，未实施。未提交、未推送。


## 横向背景编辑器预览修正（2026-10-11）

HorizontalScenery.gd 现在同时在编辑器与运行时执行等比适配和范围裁剪。三条背景带仍位于 Level2Map/Scenery：HorizontalEntry（860×520）、HorizontalMain（8400×800）、HorizontalLower（2200×800）；编辑器里不会再把入口和下层的循环背景铺到整张地图外面。循环继续由原生 Parallax2D 执行，不增加新的背景图片或按房间拆分。

调节方法：在 Level2Scenery.tscn 中选择对应 Horizontal 实例，修改位置和 Metadata → coverage 即可预览覆盖范围。图片高度、视差速度和前景透明度仍使用 ExportSettings；编辑器读取已保存的 ExportSettings.tscn 覆盖值和脚本默认值，游戏读取实际单例。缩放始终依据 parallax_scenery2.tscn 的原始位置、尺寸和 Repeat Size，避免重复初始化后累积缩放。

验证：编辑器中确认下层裁剪边界；试玩检查入口、主层和交织档案，三条背景的范围、缩放和循环间距正确，重复初始化尺寸不变；游戏日志和编辑器增量日志无新增错误。按用户确认恢复 Level2Playtest/Level2Map 的 Visible=true。没有改变美术源文件、房间位置、碰撞、竖井或主城接口，未进行完整通关测试。

队友继续直接使用 DepthsLibrary.tscn / Level2Map.tscn；不需要额外实例化背景。独立试玩仍打开 Level2Playtest.tscn 按 F6。

## 横向背景与竖井交界裁剪（2026-10-11）

HorizontalScenery.gd 读取同级 DescentShaft、LowerStairwell、FountainShaft 三个竖向背景区域的实际全局矩形，传给 HorizontalCoverage.gdshader。横向底色、窗户、桥梁和前景在这些矩形内不绘制，保留竖井背景，避免透明图层相互叠加。Parallax2D 的循环和视差照常运行，缺口固定在地图对应位置。

节点仍位于 Level2Map/Scenery。调整竖向背景区域的位置或尺寸时，横向缺口自动跟随；这只是背景覆盖范围，不会调整墙体或碰撞。独立打开 parallax_scenery2.tscn 时不裁竖井缺口，可以继续查看完整美术构图。不要通过改 Repeat Size 来挖井口。

验证：编辑器入口预览、试玩入口竖井与下层阶梯井交界均已检查，横向桥梁不再穿过井内；脚本与着色器验证通过，本轮游戏日志及编辑器增量日志无新增错误。当前是边界裁剪，尚未增加井口专用装饰过渡；没有完整通关测试。

队友仍直接使用 DepthsLibrary.tscn / Level2Map.tscn，背景随地图自动加载，不需要额外调用。试玩打开 Level2Playtest.tscn 按 F6。本轮只修改横向背景适配脚本、裁剪着色器和本文档；未改变井宽、碰撞、落脚点、主城接口及美术源图，未提交、未推送。

### 喷泉水流占位图的初始显示（2026-10-11）

Hub/FountainStream 和 FountainShaft/Stream 默认 Visible=false，与 SurfaceExit/SprayStream 及喷泉未激活状态一致。它们是半透明水流占位图，不是竖井背景；默认显示时会覆盖大厅窗户，容易误认为背景叠加。Level2Map 的原有激活逻辑仍控制三段水流：未激活全部隐藏，激活全部显示。验证了这两个状态的可见性切换，本轮无新增日志错误。井底背景仍有直接衔接的直线边界，尚未添加装饰过渡。

队友使用地图的方式不变，不要手动常驻显示水流占位图；正式水柱美术以后接到对应水流节点。没有修改水流区域、推动人物的逻辑、碰撞或井宽。

### 移除旧占位背景（2026-10-11）

按用户要求，从 12 个地下房间删除了 180 个旧占位背景节点：Background 及其 Base/Pillar/Window/WindowLight 子节点、DarkShaft、DepthLine。SurfaceExit 原本没有这类背景，因此没有改动。地面、墙体、天花板、平台的 Stone/Edge、碰撞、机关、交互提示和出生点保留；美术前后景仍统一位于 Level2Map/Scenery。

三个竖向房间把原底板尺寸保存在不绘制的 metadata/scenery_bounds 中，Level2Scenery.gd 直接读取这些数据，不再依赖已删除的背景节点。三个区域仍为 280×2940、600×1450、180×3000。关闭美术背景后不再回退到旧占位背景；单独打开房间场景只显示地形和玩法节点，整体美术请在 Level2Map 或 Level2Playtest 查看。

核对：所有保留的非根节点和资源段与修改前逐字一致；试玩中旧背景节点数量为零；定位静谧阅览室检查美术背景、地面和平台，竖井范围未变，游戏及编辑器增量日志无新增错误。同步清理了已打开的地图与试玩场景里的旧节点缓存。没有进行完整通关测试。

队友继续实例化 DepthsLibrary.tscn / Level2Map.tscn，无需添加背景或调用新接口。只运行独立房间时没有整体前后景是正常的。未提交、未推送。

### 全地图占位背景复查（2026-10-11）

再次检查全部 13 个房间、Level2Map、DepthsLibrary、CityInterfacePreview 和 Level2Playtest。补删试玩场景的纯色 Backdrop/Fill 底幕；井外遮挡是镜头边界功能，保留。已打开的 DepthsLibrary 和 World 的第二关实例仍缓存旧背景，各同步移除 14 个旧背景根节点；只处理第二关子树，没有修改主城或其他关卡。

运行时逐房间核对：13 个房间的 Background/DarkShaft/DepthLine 残留均为零，试玩 Backdrop 不存在，美术 Scenery 保留，场景加载无新增报错。水流与 DeepWater 是玩法显示，玩家 VisualPlaceholder 是试玩人物外观，TerrainArt 是尚未启用的地形美术层，均保留。外层空 TileMapLayer 没有图块，不会绘制背景，未作无关清理。队友仍使用原地图场景，无需新增调用。

### 编辑器旧背景反复出现的修正（2026-10-11）

后续截图证实，前次只检查磁盘、运行时和当时显示的实例仍不充分：部分房间 PackedScene 在编辑器资源缓存中保留旧内容，切换场景后旧节点再次出现。本次从已清理的磁盘文件刷新 12 个房间的缓存资源，逐项确认缓存中的旧背景数量为零，再清理地图和试玩场景中各 14 个残留背景根节点。DepthsLibrary 和 World 的第二关实例复查均无旧背景。地图与试玩场景来回切换两轮，节点检查仍为零；编辑器截图核对月影水道、交织档案的旧窗框和装饰柱已消失。此次没有修改地形、美术和碰撞，临时刷新工具已删除。

## 第二关 32×32 可编辑地形（2026-10-11）

本节取代此前“只准备外观、保留固定 StaticBody2D 碰撞”的方案。用户已确认把固定地形转换为第三关同类的紫色 32×32 占位砖块，后续在 TileMap 中手动修改。

### 当前结构与范围

13 个房间各有一个 Terrain（TileMapLayer），包含 86 处原固定地形、共 1965 格；试玩专用 CityInterfacePreview 另有一个 Terrain，包含 2 处接缝地面、20 格。固定地面、墙、天花板、台阶原有 StaticBody2D / CollisionShape2D / Stone / Edge 和隐藏的 TerrainArt 已移除；砖块本身同时负责显示和碰撞，不存在旧固定碰撞留在下面的问题。

使用第二关独立资源 Terrain/Level2CollisionTileSet.tres：Tile Size 为 32×32，Source 0 / Atlas (0,0) 是普通实心格，物理层 1、完整正方形碰撞。紫色来自 Godot 自带 PlaceholderTexture2D，与第三关的占位方式相同；没有制作新美术，也没有修改第三关 TileSet 或美术源文件。

塌陷平台 Collapse / Crumble2 / Crumble4、移动平台 FerryA / FerryB、符文门 Gate、取得钥匙才出现的 ReturnCatwalk 仍是功能组件，保留原行为。返程栈道旧的隐藏 TerrainArt 也已移除。前后景仍由 Scenery 管理，和 Terrain 分开。

### 手动修改方法

1. 在 Level2Map 的 Rooms 下找到要改的房间，通过房间的场景图标打开源场景，例如 Rooms/Hub.tscn；也可以从文件系统直接打开。
2. 选中该房间的 Terrain。在底部 TileMap 面板中选择紫色砖块，使用绘制或矩形工具铺地面、墙壁、台阶，用橡皮擦删除格子。删除格子会同时删除对应碰撞。
3. 保持 Terrain 的 Position 和 Scale 不变；每个 Terrain 的少量偏移用于让所有房间拼起来时共用同一张 32 格网。改地形时刷格子，不要缩放整个 Terrain。
4. 保存房间，打开 Level2Playtest.tscn 按 F6 检查。不要单独运行房间来判断整张地图的背景、玩家或机关流程。

移动平台、塌陷平台、机关门和返程栈道仍在自己的组件节点里修改。正式地形美术交付后接入第二关独立 TileSet；目前紫色仅是便于搭建的占位外观。

### 网格对齐与对接尺寸

全图固定地形按地图坐标 x=0、y=-3080 为网格基准对齐。房间实例位置不变；主城地表 y=-3080、主层地面 y=520 保持不变。原非整格边缘发生小幅调整；薄台阶至少一格厚，最大单侧边缘调整为 28 像素，不能将此次转换当成碰撞尺寸完全不变。

| 部位 | 原净宽 | 当前净宽 |
| --- | ---: | ---: |
| 主城左侧入口 | 240 | 256 |
| DescentShaft 下落井 | 280 | 256 |
| LowerStairwell 折返阶梯通道 | 600 | 608 |
| FountainShaft 喷泉井及地表出口 | 140 | 128 |

以上均为游戏像素的物理净宽，不是背景原图分辨率。主城接口在地图局部坐标：左入口中心 (160,-3080)，净宽 256；右出口中心 (992,-3080)，净宽 128。右出口中心因砖块对齐向右移动 2 像素。CityEntrance / CityExit 的 opening_width 已同步；GetCityConnections() 会返回平移后的世界坐标。背景原图及其覆盖配置没有随此转换重新拉伸。

### 核对与交付

Godot 已载入全部 14 个 Terrain 并核对 1985 格；88 处转换区域均检测到物理碰撞。测试了城市测试地面、入口、大厅、阅览室、月影水道和交织档案的落脚；下落井和喷泉井中心射线通路无遮挡；验证符文门开关及两侧返程栈道启停；实际启用喷泉后，人物从大厅经竖井上升并穿过地表出口。未完成整关逐跳通关，手动调整地形后仍需复测跳跃距离。

已同步刷新打开的房间、地图、试玩、DepthsLibrary 和 World 中的第二关实例；切换地图与试玩再次核对，每个房间只有一个 Terrain，旧固定地形没有重新出现。运行测试和修正后的编辑器增量日志无新增错误。临时转换、刷新工具已移除。

队友继续使用 DepthsLibrary.tscn / Level2Map.tscn，不需要添加或调用新组件；对接主城时使用上述更新后的接口净宽。提交时需要包含房间场景、CityInterfacePreview.tscn、Terrain/Level2CollisionTileSet.tres 和本说明，避免只提交场景漏掉 TileSet。本轮未提交、未推送。

### 下落井与大厅背景接缝（2026-10-11）

DescentShaft 背景原下边界 Y=0，和 HorizontalMain 从 Y=-80 开始的范围重叠 80 像素。现将 Level2Scenery/DescentShaft 的 offset_bottom 调为 -80，并将 Rooms/DescentShaft 的 metadata/scenery_bounds 高度从 2940 改为 2860，避免运行时恢复旧尺寸。横向背景裁剪自动读取更新后的范围，井下端由大厅背景接续。只缩短背景覆盖区域，房间高度、地形砖块、碰撞、美术原图及横向背景位置不变。

已同步打开的编辑器实例。试玩实测竖井下边界与大厅上边界均为 -80，横向着色器读取的下落井裁剪下边界也是 -80；编辑器与游戏截图确认露进大厅的一截已消失，本轮试玩无新增运行错误。队友使用方式不变，不需要新增节点或调用。未提交、未推送。

### 喷泉竖井隐藏装饰柱（2026-10-11）

Level2Scenery.tscn 仅对 FountainShaft 实例隐藏 Backdrop/LeftColumns、Backdrop/RightColumns、Foreground/NearColumn。保留 ShaftDepth 底色、DarkEdges 边缘和原水流玩法；另外两条竖井仍显示原柱子。没有修改公用 VerticalScenery 或美术原图。以后需要恢复时，在 Scenery/FountainShaft 对应节点打开 Visible 即可。

已核对编辑器实例和试玩：喷泉三个柱子节点均隐藏，另外两条竖井保持显示，试玩无新增运行错误。队友使用地图方式不变，未提交、未推送。

### 折返阶梯改用完整竖井构图（2026-10-11）

仅 Scenery/LowerStairwell 改为 FittedVerticalComposition.tscn，内部 Composition 直接实例化美术分层组合 VerticalComposition.tscn，沿用 VerticalScenery.gd 适配。保留用户调整的背景左上角 (1055,730)，显示尺寸为 600×1246，下边界 Y=1976 对齐当前井底砖块顶面。整套原画按宽、高分别缩放铺满该范围，不是原比例缩放；原图与原始组合节点未修改，不新增绘制素材。

该实例通过 metadata/use_authored_bounds 保留编辑器里设置的范围，运行时不再被旧房间 scenery_bounds 覆盖。其他两条竖井沿用旧背景，喷泉装饰柱继续隐藏。砖块、碰撞和平台均未修改。要调整整体覆盖范围，打开 Level2Scenery.tscn，选 LowerStairwell 修改 Position/Size 并保存；修改分层内容则打开 VerticalComposition.tscn。Level2Map 和 Level2Playtest 自动引用保存后的背景场景。

已核对编辑器、试玩实例与运行时的位置 (1055,730)、尺寸 (600,1246) 一致；折返阶梯仍为 150 块砖，喷泉三个装饰柱仍隐藏。试玩截图及本轮增量日志检查通过，无新增错误。未提交、未推送。

### 折返阶梯恢复纵向视差并对齐井口（2026-10-11）

本条更新上一条的背景覆盖范围：LowerStairwell 现在为 Position=(1056,536)、Size=(608,1440)，左右对齐砖块内沿、顶部对齐现有紫色砖块上沿，底部仍为 Y=1976。HorizontalMain 自动读取这块范围并裁掉内部所有横向装饰，蓝色拱桥不再横穿井口。地图砖块和碰撞保持原样。

VerticalScenery.gd 保留完整美术组合，运行时由原生 Parallax2D 驱动纵向滚动：DistantColumn 使用 Far Speed（默认0.25）、LeftArchitecture 使用 Middle Speed（0.65）、Foreground 使用 Foreground Speed（1.08）；X轴均为1，避免柱子左右漂出窄井。BlueDepth 与 FrameEdges 固定覆盖井区。移动层通过 repeat_size.y 循环、repeat_times=2，并用 Vertical Loop Blend（默认0.06）重叠淡化首尾；可在 ExportSettings 的 Level 2 - Scenery 中调节。编辑器中保留静态原画排列，视差需运行 Level2Playtest 并移动镜头查看。

已用两个镜头高度核对各层位移差异，横向裁剪范围实测为 (1056,536,1664,1976)，试玩和编辑器覆盖范围一致，折返阶梯仍为150块砖。修改期间修复了脚本热重载引发的临时字典初始化错误，修正后的编辑器增量日志与最后一轮运行均无新增错误。未提交、未推送。

### 去除黑边并固定底部建筑装饰（2026-10-11）

VerticalComposition/FrameEdges 已隐藏，移除 Vertical/01.png 的黑色边框显示；Foreground 的 Z Index 从10改为-5，仍在其他背景柱前方，但处于地形和角色后方，不再盖住紫色砖块。美术原文件未改。

VerticalScenery 中 LeftArchitecture 保持 scroll_scale=(1,1)、repeat_size=(0,0)，使 SilverColumn 和 LowerLedge 按原构图固定在下部，避免整幅图循环把雕花和托台带回井口。DistantColumn 与 Foreground 继续保留0.25和1.08的纵向视差及淡化循环。井口范围 (1056,536,608,1440) 不变。

已分别在井口和井底查看试玩截图，黑边移除、砖块正常覆盖右柱、底部雕花和托台位置固定；两个高度实测 LeftArchitecture 世界Y均为536，而远近柱的位置随镜头变化。试玩编辑实例已同步；折返阶梯仍为150块砖，本轮编辑器增量与运行日志无新增错误。未提交、未推送。

### 下落井入口镜头过渡遮挡（2026-10-11）

Level2CameraDirector.GetUpperRoomOpening 在刚进入 descent、井壁遮挡仍淡入或镜头顶部仍能看到井口上方时，继续使用 EntryCollapse 的墙外遮挡。待镜头完整进入井区且竖井遮挡达到不透明后再撤下入口遮挡，避免切换瞬间露出右侧喷泉。原有跟随、阻尼、井底出口淡出和地图数据不变。

已在 Y=-2920 复现并对照修正后截图：原竖井遮挡强度仅0.125时，右侧喷泉由入口遮挡覆盖；继续下落到Y=-2200时入口遮挡正常释放，Y=0进入大厅时所有竖井遮挡退出。本轮编辑器增量与运行日志无新增错误。未提交、未推送。


### 2026-10-11：竖井柱子分层视差调整

- 下层 `Scenery/LowerStairwell/Composition/LeftArchitecture` 改为有限视差：雕花柱、柱身和托台一起小幅移动，不进行首尾循环，保留原图下部构图。`ExportSettings` 的 `Level 2 - Scenery / Vertical Architecture Travel` 控制最大偏移，默认 64 像素，0 为固定；实际值还限制为井高的 10%。
- 上层 `Scenery/DescentShaft` 三根柱子从左到右分别使用中景 0.65、远景 0.25、前景 1.08 的移动比例。旧节点 `NearColumn` 实为浅色远柱，仅修正移动映射，保留原透明度和绘制层级。
- 试玩验证：下层两个高度的左柱偏移约 -63.9 / +61.6 像素，repeat_size 为零；上层镜头移动约 600 像素时三层滚动量分别变化约 -210 / -450 / +48 像素。检查井口与下部画面，雕花和托台未循环到井口；本轮无新增脚本或运行错误。


### 2026-10-11：增强竖井视差（替代上节速度参数）

- 竖井独立使用 Vertical Far Speed = 0.12、Vertical Middle Speed = 0.35、Vertical Foreground Speed = 1.6；横向背景保留原参数。上层三根柱子从左到右分别使用 0.35 / 0.12 / 1.6，下层浅色后柱和右侧阴影柱使用 0.12 / 1.6。
- 旧右柱 1.08 仅比地形快 8%，现为快 60%。上层镜头下移约 600 像素时，左/浅色/右柱相对地形的偏移约 +390 / +528 / -360 像素，已在运行中测量。
- 下层 LeftArchitecture 的最大位移改为 128 像素，在整个井高范围内线性分配；取消原先迅速饱和的 tanh 曲线，避免两端看似停住。依然不重复，雕花与托台保持在下部。试玩人物 Y=700/1000/1400/1700 时实际偏移约 -113/-60/+11/+65 像素，持续变化。
- 已查看井口和下部画面，检查雕花位置、平台遮挡及本次运行日志，无新增错误。


### 2026-10-11：底部圆桌装饰固定

- 将 `VerticalComposition/LeftArchitecture/LowerLedge` 移至固定层 `BlueDepth/LowerLedge`，独立于雕花柱视差；保持原绘制层级，并在原图坐标下下移 256 像素，贴近井底。
- 下层地图对应节点为 `Scenery/LowerStairwell/Composition/BlueDepth/LowerLedge`。圆桌无重复、无视差偏移，仍为纯装饰，不新增碰撞；各柱子的速度保持不变。
- 已试玩核对两个镜头高度，圆桌世界位置不变、左柱位置继续变化，井底截图确认，无新增错误。

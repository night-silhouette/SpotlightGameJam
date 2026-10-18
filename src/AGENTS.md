# 代码组开发规范

本文件适用于仓库内的 Godot 项目 `src/`。下文的 `res://` 指 `src/`，因此 `res://Code/` 对应 `src/Code/`。
ai在分析代码之前，先看看代码索引，按需了解代码的组织结构和文件关系。

## 一、权限边界与文件操作

- 开发者和 AI 编码助手仅可修改 `res://Code/` 下的代码与场景文件。维护本文件及仓库级 AI 指令文件是此规则的明确例外；其他例外须由任务明确授权。
- `res://Code/` 外的文件（包括美术、音频和第三方插件）只可查看和引用，不得修改原始内容。程序不得引用 `res://Assets/WIP/` 中的内容；若实际素材目录名称不同，也不得引用对应的 WIP 美术目录。
- 未经明确授权，不得修改 `project.godot`、`.godot/` 缓存及全局物理、渲染等底层配置。
- 提交 `.tscn` 或 `.gd` 前，核对外部依赖、资源路径与导入状态，避免缺失依赖或断链。

## 二、架构与目录

`res://Code/` 按树状实体自治组织：

```text
Code/
├── Autoloads/          # 全局单例、常量、信号总线和数据
├── Common/             # 可复用类、基类和组件
└── Entities/           # 业务场景与功能模块
    └── Player/         # 每个实体或功能独立成目录
        ├── Player.tscn
        ├── Player.gd
        └── PlayerState.gd
```

- `Entities/` 自顶向下嵌套；每个实体或功能拥有独立目录，并尽量在各自目录内开发。目录使用 PascalCase。
- 开发组件或功能前，先检索 `Autoloads/` 和 `Common/` 中已有的常量、数据、工具和组件，优先复用。
- 原则上不删除或破坏 `Autoloads/`、`Common/` 的既有接口。需要通用能力时以兼容的增量扩展为主，并检查现有调用方。

## 三、GDScript 命名与文档

- 可供脚本外部调用的公共方法使用 PascalCase，如 `ApplyDamage`；每个公共方法上方须有 `##` 文档注释，说明用途、参数含义与传参规范，有返回值时说明返回值。
- 仅供脚本内部调用的方法使用下划线加 snake_case，如 `_update_internal_state`。Godot 引擎回调（如 `_ready`、`_process`）遵循引擎名称。
- 常量使用全大写下划线，如 `MAX_SPEED`；定义前先检查 `Autoloads/` 中是否已有相同含义的常量或数据字典。
- `Autoloads/SignalBus.gd` 中的全局信号使用 PascalCase。每个信号上方须有 `##` 文档注释，说明触发时机和各参数含义。

## 四、实体生命周期与存档

- 需要持久化状态的 Entity 提供 `ExportSaveData() -> Dictionary` 和 `LoadSaveData(data: Dictionary) -> void`，并按公共方法规则写 `##` 文档注释。
- `_init()` 必须能无参安全调用，或为所有外部参数提供安全默认值；不得强制依赖非空外部上下文。
- 外部依赖和节点引用在 `@onready`、`_ready()` 或 `LoadSaveData()` 中建立，确保实体可安全实例化与还原。加载数据时注意节点就绪时机。

## 五、场景、UI 与输入

- 尽量在 `.tscn` 场景树中预置节点，并通过 `@onready` 引用；不要在脚本中用大量 `new()` 动态构造复杂节点树。
- 鼠标点击区域使用无纹理 `TextureButton` 或透明遮罩 `Button`。Sprite2D 的悬停或进入检测使用其下的 `Area2D`，并正确配置 `CollisionShape2D`。
- Control UI 配置锚点预设与容器布局，验证不同窗口分辨率；避免任意绝对像素定位。

## 六、类别
- 在 `Common/`中声明通用类别的时候,用class_name关键词命名



## 八、参数
- 实体参数都要导出到ExportSettings.gd中,方便我修改调整

## 九、通信
- 实体之间的通信要使用信号总线(signalbus),来达到解耦的目的,实体状态变化的时候,都最好通过信号总线发送信号来通知其他实体,而不是直接调用其他实体的方法.


- C:\Users\jixiegm\Desktop\Godot_v4.7.2-stable_win64.exe"
这是godot路径

## 十、代码索引（AI 按需阅读入口）

> 基线：2026-10-15，基于当前源码与场景静态核对，未运行游戏或测试。此节描述现有实现，不代表既有代码已全部符合上面的开发规范。

### 10.1 阅读方法与维护规则

- 先按功能查下面的表，再只读对应方法、调用方和关联场景；不要默认全仓扫描，也不要从第三方插件、美术或 `.godot/` 开始阅读。
- 定位格式为 `路径:起始行-结束行`，行号从 1 开始；逗号分隔多个片段。**行号是快照，方法名/信号名是复查锚点**。若行号偏移，先搜索锚点，再读取实际实现；源码优先于索引和旧注释。
- 表中路径相对 `res://`；缩写：`A/` = `Code/Autoloads/`，`C/` = `Code/Common/`，`E/` = `Code/Entities/`，`P/` = `Code/Entities/Player/`，`IC/` = `Code/Entities/InteractiveComponent/`，`W/` = `Code/Entities/World/`，`L2/` = `Code/Entities/World/DepthsLibrary/Level2/`。其余路径不缩写。
- 同目录同名 `.tscn` 通常负责节点、碰撞、资源和序列化参数；涉及布局、节点路径、默认参数、信号连接时必须同时核对场景。大小写以实际文件为准，例如 `Player/playerUi/`、`Plot/chapter/`。
- 后续新增、删除、移动功能或修改关键调用链时，同步维护本节对应条目的路径、符号、行号及注意事项；仅核对本次影响范围，不需每次重建全部索引。未核实的功能标明“待核实”，不得推测行号或把计划当成已实现功能。
- 本节只索引业务入口与关键实现，不穷举素材、UID、每个房间节点或全部 shader uniform。未经授权不得为符合索引描述而修改业务逻辑。

### 10.2 启动、全局基础与参数

| 功能 | 文件与关键行号 | 实现锚点 / 阅读注意 |
| --- | --- | --- |
| 启动与 Autoload | `project.godot:11-29,50-99` | 主场景为 `E/StartMenu/StartMenu.tscn`；单例为 Util、SignalBus、GlobalValue、PhantomCameraManager、ExportSettings、_mcp_game_helper。此处输入是默认值，会被改键文件覆盖。配置及插件只读。 |
| 开始菜单与槽位选择 | `E/StartMenu/StartMenu.gd:35-62,218-241`；`E/StartMenu/StartMenu.tscn:483-504`；`A/ExportSettings.gd:744-756` | 已有槽直接载入；空槽/覆写新开先播放 NewGameIntro 黑幕，两行文字“雨水将带着所有被遗忘的名字 / 回到世界的出处”淡入1.2秒、停留3秒、淡出1秒，黑幕保持至 `StartNewGameInSlot` 切换世界，避免世界开场对白提前播放。`SaveManager.gd:100-173` 接收可选 intro_tween，后台资源加载与文字过场同时开始，两者均完成才写新档并切场景；资源加载慢时保持纯黑等待，失败停止过场并恢复菜单。过场拦鼠标、禁设置快捷键及重复新开，加载失败隐藏黑幕并恢复弹窗；字号随小窗口缩小，文字/颜色/字号/时长取 `new_game_intro_*`。存档和制作人弹窗打开时由菜单接管取消键。本次仅静态核对，未运行游戏或写存档。 |
| 全游戏背景音乐 | `A/Util.gd:3-43`；`A/ExportSettings.gd:642-645` | Util 单例延迟初始化音量设置后，经现有音乐总线播放 `Music/bgm/MainMenu.wav` 和 `Music/bgm/GrowMaintheme.wav`：从第一首开始，各播完一次后交替；流副本关闭自身循环，播放器 finished 切换下一首，场景切换不中断。仅初次启动默认2秒渐入，使用统一的背景音乐基础分贝，不改变音量设置默认值及原音频导入设置；实际听感及衔接待验收。 |
| 制作人名单 | `E/StartMenu/StartMenu.gd:36-39,50-57,78-79,91-92`；`E/StartMenu/StartMenu.tscn:358-543` | 沿用现有 CreditsModal 入口与关闭/Esc链路，复用 SettingsSkin 和 SettingsFrame 的墨色暖纸配色、手绘边框及三角关闭区域；TeamGrid 两列展示去重后的8人，特别鸣谢原文保留，纵向滚动及外框等比缩放适配小窗口。2026-10-16 Godot 4.7.2 headless 单独装配该弹窗，名单/鸣谢内容、资源加载、关闭按钮及1280×720、800×600、480×320面板边界与等比缩放断言通过；未启动正式 World，未做视觉验收。 |
| 正式世界装配 | `W/World.tscn:347-427` | 同时装配 DialogBox、PlayerWithCamera、Camp、SunkenPalace、DepthsLibrary、OasisBattlefield；不是在此逐关切场景。交互实例有剧情和锁输入覆盖值。 |
| 开场全屏黑幕淡出 | `W/World.tscn:349-361`；`W/OpeningFade.gd:1-10`；`A/ExportSettings.gd:686-690` | 预置不透明黑色 ColorRect，CanvasLayer 128 覆盖世界UI、忽略鼠标；默认等待4帧后用0.5秒 Tween 淡出并释放，不参与 Chapter1 独白锁定及起身流程。 |
| 玩家、能力及镜头参数 | `A/ExportSettings.gd:128-239,349-411,489-541`；`A/ExportSettings.tscn:5-16` | 移动/生命/钩索/水符文/镜头参数。先读脚本，再查场景覆盖；玩家包装器还会二次写入部分值。 |
| 移动端、音量与存档配置 | `A/ExportSettings.gd:607-668`；`A/GlobalValue.gd:1-4` | 触屏、音频、存档配置在 ExportSettings；重力在 GlobalValue，实际是可变变量。部分实体仍有本地参数，不可假定已全部集中。 |
| 全局信号定义 | `A/SignalBus.gd:6-13,29-97,105-209,233-240,275-278,310-413` | 第二关、镜头、玩家能力/生命/遗物/重生、通用机关通道、设置、返回主菜单和退出事件。改通信前先搜索信号的发送者和接收者。 |
| 音量、计时与音效工具 | `A/Util.gd:8-92,206-244` | `SetAudioVolume`、`setTime`/`set_time`、`PlaySFX`/`PlaySFX2D`；音量独立持久化，计时函数返回 SceneTreeTimer，不是可 stop 的 Timer 节点。 |
| 假死与区域辅助 | `A/Util.gd:96-139,175-204,386-431` | `FakeDeath`/`Revive` 递归改显示、处理和碰撞，复活不是逐项还原旧状态；AreaHoldHelper 构造要求外部参数。 |
| 通用状态框架 | `C/GameInputControl.gd:1-8`；`C/State.gd:1-57`；`C/StateMachine.gd:18-100` | `init`、`change_state`、`finished`、`state_map`；递归以小写节点名注册。仍有旧 snake_case 公共接口，不可按新命名规范猜调用名。 |

### 10.3 玩家、能力、输入与 HUD

| 功能 | 文件与关键行号 | 实现锚点 / 阅读注意 |
| --- | --- | --- |
| 玩家初始化与节点依赖 | `P/Player.gd:4-36,197-346`；`P/Player.tscn:1464-1696` | `_ready` 同步参数、音效、计时器、状态机和信号；固定路径引用场景内控制器、HUD、粒子与音频节点。状态节点中两个 `fall` 重名，后登记项覆盖前项。 |
| 人物动画法线 | `P/Player.tscn:11-12,15,23-29,31-34,36`；`P/NormalMaps/*.tres:1-8` | 15个 Texture2D 外部资源改引同名 CanvasTexture，保留资源 id、移除原图 uid，动画轨道及节点引用不变；CanvasTexture 将原图与同尺寸 `*_normal.png` 配对。2026-10-16 使用 Godot 4.7.2 在 TEMP 隔离小项目导入30张图片，15/15 CanvasTexture 加载及原图/法线/资源尺寸一致检查通过，退出码0；未启动正式 World，未验证实际光照渲染。 |
| 移动输入与冲刺冷却 | `P/PlayerInputControl.gd:15-92`；`P/States/JumpState.gd:20-47`；`A/ExportSettings.gd:192-193` | `InterruptDash`、`ConsumeGroundJump`；轮询移动/跳跃/冲刺，冲刺复用要求冷却及落地；`player_coyote_time` 默认0.12秒，走出边缘后宽限内优先普通跳，沿用普通速度/音效、不扣二段次数或播放二段环，实际起跳即消耗宽限。主动下穿、上升及特殊运动清除宽限；下+跳抑制跳跃，平台穿透由独立组件实现。2026-10-18 Godot 4.7.2 TEMP 隔离真实脚本及平台物理测试128项通过、退出0；未启动正式World或写原存档，完整手感待试玩。 |
| 永久能力与遗物 | `P/Player.gd:348-414` | `SetAbilityEnabled`、遗物事件、调试飞行；永久解锁与临时可用次数分开，禁钩索主动释放，死亡清未献祭遗物。 |
| 生命、受伤、死亡与重生 | `P/Player.gd:69-89,416-429,860-956`；`P/States/DiedState.gd:1-35` | `now_HP`、`ApplyDamage`、`Heal`、`Respawn`；归零转 died，广播死亡并延迟重生；重生恢复血量、能力次数与 idle。死亡状态未显式停输入控制器。 |
| 主运动与水中运动 | `P/Player.gd:504-591,958-985` | `_physics_process` 处理飞行/重力/游泳/惯性/受伤阻尼；`PlayerBeforeMotion` 后调用 `move_and_slide`。水区采用进入计数，最后一次离开才结束水中状态。 |
| 小台阶、墙与朝向 | `P/Player.gd:593-653,848-858`；`P/Player.tscn:1529-1570` | 脚部/上身射线和 `test_move` 校验台阶；指定地面状态才启用。`slick_wall`、`no_climb` 等参与禁止攀爬判定。 |
| 低水量表现、残影与动作音效 | `P/Player.gd:431-502,654-846` | 缺水提示、颜色/材质、沙粒、残影、脚步/落地/转身音效；脚步结合材质和总线；残影节点动态创建。 |
| 玩家存档 | `P/Player.gd:992-1033` | `ExportSaveData`/`LoadSaveData` 保存位置、HP、出生/重生点、永久能力、遗物与脚步信息，不保存全部瞬态；加载依赖 ready 后的节点引用。 |
| 玩家状态选择与钩索动画抢占 | `P/PlayerStateMachine.gd:5-112` | 初始化复制动画；按玩家身份处理 `PlayerGrapplePhaseChanged`，rope_send/fly 抢占普通动作，伤亡优先；依赖现有动画轨道。 |
| 跳跃、攀爬、冲刺与受伤状态 | `P/States/JumpState.gd:1-86`；`ClimbState.gd:1-55`；`DashState.gd:1-29`；`HurtState.gd:1-32`；`RopeState.gd:1-30`（后四者同属 `P/States/`） | 地面/二段/蹬墙跳，攀爬滑落与宽限，定向冲刺，受伤 generation 防旧回调；RopeState 当帧推进动画。Idle/Run/Fall/Turn 状态也在同目录，修改切换规则需检查相关状态。 |
| 钩索发射与输入 | `P/RopeController.gd:81-201,242-342` | `ShootRope`、`TriggerPull`、`TriggerSwing`、`ReleaseRope`；检查生命/解锁/输入，发射即扣血、落空不退款；先广播阶段更新动作与发射点。返回成功表示发射而非命中。 |
| 钩索命中、拉拽与摆动 | `P/RopeController.gd:344-419,440-633`；`P/GrappleVisual.gd:1-39` | FLYING 命中时，若飞行期间已松手或当前未按住则直接 PULLING，否则 LATCHED 再转 PULLING/SWINGING；逐段射线、移动挂点、长度约束和脱钩惯性；摆动路径另有 `move_and_slide`，不能忽略主玩家运动循环。视觉单独读取绳段数据。 |
| 水符文与旧符文 UI | `P/WaterRuneController.gd:1-36`；`P/playerUi/RuneUi/RuneUI.gd:1-47` | `_unhandled_input` 在 `interact` 映射按下时遍历 water_flow 并检查鼠标指向命中，随设置改键生效；`TryActivateTargetArea` 对传入的有效区域调用 `ToggleRuneFluid`，再发 `WaterRuneActivated`；当前无冷却/距离检查。旧 RuneUI 的 E 键及冷却显示不是当前行为，正式 HUD 未挂载它。 |
| HUD 与触屏动作 | `P/playerUi/HpUi/PlayerUI.gd:39-190`；`C/TouchActionButton.gd:11-111`；`P/playerUi/HpUi/PlayerUI.tscn:191-243` | 六档血量/数字、能力请求与回显、设置入口；触屏用 `Input.action_press/release`，支持拖出/回入，隐藏时释放输入。布局来自移动端设置。 |
| 掉血按钮与伤害假人 | `P/playerUi/StartLoseHpButton/StartLoseHpButton.gd:1-19`；`E/Dummy/TestDummy.gd:1-37` | 按钮发 `StartPlayerHpDrain`，未挂在当前 HUD；假人区域直接调用玩家 `ApplyDamage`，未走总线。两者仍有本地参数。 |

### 10.4 镜头系统

以下前三行的脚本位于 `E/PlayerWithCamera/`，表中省略此公共前缀。

| 功能 | 文件与关键行号 | 实现锚点 / 阅读注意 |
| --- | --- | --- |
| 包装器与相机装配 | `PlayerWithCamera.gd:5-164`；`PlayerWithCamera.tscn:3-59` | Player、PhantomCameraHost、基础镜头、双 Shot、CameraGateFade；`_enter_tree` 配镜头，父 ready 再同步玩家参数，会覆盖玩家已读取的 ExportSettings 值。 |
| 模式请求、限位与切镜 | `PlayerWithCamera.gd:182-487` | 六模式和旧 `CameraShotRequested` 兼容；按玩家过滤，双 Shot 交替；ritual/fixed 要有效 anchor。`_process` 每帧重算门限位，`_gate_overlaps_view` 按真实 Camera2D 中心/zoom 计算视野，与门有效碰撞形状的世界范围只比较正交轴（左右门比较 y，上下门比较 x）；不重叠时跳过稳定及过渡限位但保留登记，重新重叠可恢复，禁用形状不参与。门限位仍与原边界合并，重生复位，失败/被抢占会清理并解锁。 |
| CG、字幕与输入锁 | `PlayerWithCamera.gd:494-526`；`CameraPresentation.gd:1-64`；`CameraNarration.gd:1-50` | ritual 近景转远景，generation 防旧回调，最终到位发 `CameraShotReady`；只禁玩家子树处理，不暂停全世界；文字横/竖逐字显示，不解析 BBCode。 |
| 镜头门与固定镜头区 | `IC/CameraGate/CameraGate.gd:14-86`；`IC/CameraFocusArea/CameraFocusArea.gd:1-26` | 门发 `CameraGateChanged` 或 `CameraGateSideChanged/Removed`；FocusArea 进入发 `CameraFixedRequested`、退出发 `CameraNormalRequested`。门存档仅一次性 unlocked。 |
| 镜头门渐变黑幕 | `E/PlayerWithCamera/CameraGateFade.gd:1-70`；同目录 `CameraGateFade.tscn:1-16`；`E/PlayerWithCamera/PlayerWithCamera.tscn:9,55`；`A/ExportSettings.gd:549-561` | 独立 CanvasLayer 129 全屏透明黑色 ColorRect，忽略鼠标，按同级 Player 过滤门事件；非一次性仅 reset=false 播放，一次性先登记 active=true 再收到 false 后延迟复核门仍在树中且未排队删除，避免初始化和移除误触发。默认0.12秒淡入、保持至 camera_gate_transition_duration、0.25秒淡出，最大不透明度1，可禁用；重入杀旧 Tween 并从当前透明度续播，SaveSlotLoaded/PlayerRespawned 清除遮罩及待播放回调。不改原镜头运动、不锁输入、不存档。2026-10-18 Godot 4.7.2 TEMP 最小项目隔离运行退出0，22项断言通过，覆盖真实 CameraGate 登记/进入/退出树、目标过滤、reset/初始false忽略、淡入/保持/淡出、重入、读档/重生清理、开关及零时长；未启动正式World、未写原存档及原 .godot，完整视觉待人工验收。 |
| 第二关导演与井遮挡 | `L2/Level2CameraDirector.gd:19-119`；`L2/Level2ShaftOcclusion.gd:1-39`；`L2/Level2PlayerWithCamera.gd:1-90` | 按地图局部坐标选区、配置 bounds/follow_target，让位于慢降/回落；遮挡只绘制、不增加碰撞。专用包装器不覆盖玩家物理参数，`SnapToPlayer` 用于出生/复活。 |

### 10.5 关卡流程与交互机关

| 功能 | 文件与关键行号 | 实现锚点 / 阅读注意 |
| --- | --- | --- |
| 通用交互、描述与输入锁 | `IC/InteractableComponent/InteractableComponent.gd:61-214` | `Interact` 检查启用/距离/防重入，发 `ComponentInteracted` 和描述/独白事件；距离按矩形最近边计算，点击另检查命中。对话请求走 `DialogBox`，锁输入而非物理。 |
| 帐篷与圣杯 | `IC/Tent/Tent.gd:24-60,79-104`；`IC/MiniChaliceStation/MiniChaliceStation.gd:35-89,132-200` | 帐篷 `ActivateTent→TentActivated→Player.SetRespawnPosition`，自身不 AutoSave；读档激活帐篷会重发事件；已移除“重生点已设置”文字节点及显示逻辑，保留交互圆点和原激活光照。圣杯按最大HP比例 Heal，发 `ChaliceStationUsed`，保存可用性/冷却；靠近判定按玩家到 Sprite2D 图像边缘的世界距离（`A/ExportSettings.gd:455-456`，默认85），不再要求进入旧28×36 Area；鼠标和触屏均按图像矩形命中。Godot 4.7.2 TEMP 回归8项通过：旧矩形外图像点击、回血、充能拒绝、图像外拒绝、远距拒绝及恢复后再次饮用；未启动正式World或写存档。 |
| 湖泊治疗、献祭与结局 | `IC/Lake/Lake.gd:30-156` | 进入治疗并请求遗物状态；`PlayerRelicConsumeRequested` 献祭王冠/残卷解锁 double_jump/rope，枯骨触发 `LakeEndingTriggered`。出生/读档已在湖中只治疗，需离开再入才献祭。 |
| 第一关王冠与按钮绑定 | `W/SunkenPalace/SunkenPalace.gd:10-70`；`W/SunkenPalace/SunkenPalace.tscn:92-97,179-182` | Crown 的 `ComponentInteracted` 隐藏物件并发 `lock1`；未献祭死亡可恢复。平台绑定按钮1，门绑定按钮2/3/4；不是第二关专用机关事件。 |
| 第二关设备、钥匙与符文序列 | `IC/Level2Device/Level2Device.gd:8-54`；`L2/Level2Map.gd:187-238,311-341`；`L2/Rooms/Hub.tscn:43-100` | 鼠标与触屏靠近并点击可见 Sprite2D 图像（或无贴图设备的 Visual 多边形）发 `Level2InteractionRequested`；`_on_requested` 按 kind 处理 key/rune/lore/fountain/codex。符文顺序取配置、错误归零，weave 钥匙需解谜；喷泉提交三钥匙后独立启动水泵；左侧残卷从进入关卡起即可点击拾取，不依赖喷泉激活，首次拾取发 `lock2` 和原旁白/独白，重复点击不生效；刷新发 `Level2StateChanged`。 |
| 第二关升降、回落与完成 | `L2/Level2Map.gd:51-170,270-280` | `PlayerBeforeMotion` 驱动喷泉上升/刷新二跳；慢降发镜头和 `Level2DescentVisualChanged`；回落链为 descent→fixed→`PlayerInstantDeathRequested`；喷泉激活后出口发 `Level2Completed`。 |
| 第二关回退与存档 | `L2/Level2Map.gd:240-274,343-365`：`_on_player_died`、`_on_relic_consumed`、`_on_save_loaded`、`ExportSaveData`、`LoadSaveData` | 未献祭死亡清领取态并即时恢复残卷，献祭后永久隐藏；复活 keys 回退 submitted_keys；保存首次拾取剧情标记。读档过滤非法钥匙、约束喷泉及通关状态，`SaveSlotLoaded` 后以玩家持有/已献祭状态同步残卷；残卷状态不反向激活喷泉或补齐钥匙。房间装配见 `L2/Rooms/`。 |
| 第二关档案库升门 | `L2/Level2Map.gd:291-327,346-370`；`A/ExportSettings.gd:46-50` | `_refresh → _update_archive_gate` 在符文解谜后用物理帧 Tween 将 `Rooms/WeaveArchive/Gate` 整体向上移动，贴图与碰撞同步且保持启用；重复刷新不重启动画，初始化和读档直接定位。上移距离与时长由 `level2_archive_gate_*` 配置。 |
| 绿洲取骨与去返程切换 | `W/OasisBattlefield/OasisBattlefield.gd:29-182` | 枯骨交互延迟等对话结束及存活确认，再设重生点、发 `lock3`、`SwitchToReturnPhase→ResetChase→StartChase→AutoSave`；切阶段同时改显示、处理、TileMap及碰撞。读档等待 `SaveSlotLoaded`。 |
| 绿洲船谜题、死亡与终点 | `W/OasisBattlefield/OasisBattlefield.gd:169-253` | `BlockerVanished`/get_boat 区解船谜题，`ResumeJourney` 续航；TheEnd 延迟 `EndChase`；复活重置去程/追逐/船，献祭 bones 后永久记录。 |
| 船与停靠资源 | `IC/OasisBoat/OasisBoat.gd:68-182,190-307,327-404`；`IC/OasisBoat/OasisBoatStopPoint.gd:1-32` | 初漂→等待→航行→终点；`SolvePuzzle` 解站点，`ResumeJourney` 强制跳过等待条件。船体 top_level，沿航线限超前、射线防挤压，提供平台速度；无独立存档接口。 |
| 追逐器与结束处理 | `IC/DirectionalChaseMover/DirectionalChaseMover.gd:24-140`；`E/OasisBattlefieldChaser/OasisBattlefieldChaser.gd:15-64` | 三阶段速度/加速度及距离倍率，KillArea 发 `PlayerInstantDeathRequested`；包装器 `EndChase` 额外关碰撞/监测/显示/处理，不能以 Stop 代替；存档未覆盖包装器全部状态。 |
| 压力按钮 | `IC/PressureButton/PressureButton.gd:50-69,115-211` | 进入/离开按压，`stay_pressed` 锁存；本地信号 `pressed_state_changed`，全局 `MechanismChannelStateChanged(channel,is_active,source)`；退出树释放通道，`ResetState` 解除锁存。 |
| 信号门与移动平台 | `IC/SignalDoor/SignalDoor.gd:25-112`；`IC/MovingPlatform/MovingPlatform.gd:44-79,181-205`；`L2/Rooms/MoonAqueduct.tscn:9-110` | 都优先直接绑定按钮，否则监听通道；门多按钮为 AND、通道多来源为 OR，`IsOpenRequested` 为目标态非到位态；门导出空字典、加载重算。平台保存进度/方向/等待/位置，支持锁存/单程/往返。月影水道两座带美术的移动平台预置随行冷光，光源随平台移动，强度高于设备微光；只有实例含 PlatformLight 节点时才由 MovingPlatform 读取 ExportSettings 的平台光参数，不影响其他平台。 |
| 两类消失挡板 | `IC/SignalVanishBlocker/SignalVanishBlocker.gd:39-110`；`IC/VanishingBlockerComponent/VanishingBlockerComponent.gd:16-83` | 前者监听 lock1 等信号或通道、递归关碰撞；后者监听 Area/VanishZone、只关直接子碰撞，淡出后释放；都可发 `BlockerVanished`。加载消失结果不等于完整双向重置。 |
| 下穿与易碎平台 | `IC/OneWayDropPlatformComponent/OneWayDropPlatformComponent.gd:35-93`；`IC/CrumblingPlatform/CrumblingPlatform.gd:101-206` | 下+跳临时加碰撞例外，离开/超时恢复，无独立存档；易碎 INTACT→CRUMBLING→COLLAPSED→重生，广播裂开/塌陷/恢复。塌陷读档分支需核对 `_collapse` 的前置状态，不能假定所有状态已完整恢复。 |
| 落块与钟乳石 | `IC/FallingBlock/FallingBlock.gd:102-244`；`IC/Stalactite/Stalactite.gd:94-222` | 射线探测→预警→下落；落块处理防夹/伤害并落地保留平台，钟乳石击中后碎裂释放；有存档但不完整恢复预警剩余时间。 |
| 固定刺与伸缩刺 | `IC/Spikes/Spikes.gd:61-118`；`IC/RisingSpikes/RisingSpikes.gd`（`_setup_solid_base`、`_update_needle_regions`、`_physics_process`、`_start_cycle`、`LoadSaveData`）；同目录 `RisingSpikes.tscn`；`L2/Rooms/WeaveArchive.tscn`、`L2/Level2Map.tscn` | 按世界法线击退并发 `SpikesTriggered`。金色 TimingSpikesA/A2/B 启用 `solid_base_enabled`：BaseVisualRoot 使用原图底座分区，BaseBody 按整排底座范围生成固定实体碰撞；SpikeMovingRoot 仅显示针身分区，缩回时裁掉埋入部分，伤害区域跟随露出高度，站在底座上也会在出针时受伤。其他实例默认关闭固定底座。周期使用预置 CycleTimer；读档停止旧 Tween 并从恢复状态重新计时，不保存剩余秒数。2026-10-17 Godot 4.7.2 隔离物理测试覆盖三组底座站立、出针伤害、缩回安全与重复周期；正式 Level2Map 实例化检查通过，完整关卡手动游玩待验收。 |
| 水墙切换与能力刷新 | `IC/WaterFlowArea/WaterFlowArea.gd:73-200` | `ContainsWorldPoint`/`TryTouchInteract`、`SetFluidState`/`ToggleRuneFluid`；发 `RuneWallConverted`。入水中断冲刺、切 fall、`ResetDashAndRope`、更新水区计数；发 `PlayerEnteredWaterWall/PlayerExitedWaterWall`。 |
| 减速水与水面视觉 | `IC/SlowWaterArea/SlowWaterArea2D.gd:21-101`；`IC/WaterSurface/WaterSurface.gd:24-46` | 减速水记录/恢复原速度，去程限制实际依赖祖先名 OutwardPhase；WaterSurface 只管纹理尺寸/UV，接口为 `set_speed`，不负责物理。 |
| 光滑墙、即死区、脚步材质 | `IC/SlickWall/SlickWall.gd:19-77`；`IC/InstantKillArea/InstantKillArea.gd:19-58`；`IC/FootstepSurfaceArea/FootstepSurfaceArea.gd:18-73` | 墙加 slick_wall/no_climb/no_hook 组，由消费者判断；即死区直接伤害并后备归零HP，不走即死请求信号；脚步区只跟踪指定玩家，跨局部x中线才发材质切换请求。 |

### 10.6 存档、设置与剧情

| 功能 | 文件与关键行号 | 实现锚点 / 阅读注意 |
| --- | --- | --- |
| 槽位路径、新开与写盘 | `E/Setting/SaveManager.gd:11-49,100-230` | 默认 `res://Code/Entities/Setting/Saves/save_slot_<1..5>.json`，不是 user://；实际槽数固定5，未采用场景配置6。`SaveToSlot` 先写同目录临时文件并检查 flush 错误，再替换原槽位，失败返回 false；`StartNewGameInSlot` 后台加载 World 资源，加载成功才写空 entities、激活槽位并通过 PackedScene 切换，场景就绪后广播 `SaveSlotLoaded`；实例化仍在主线程。 |
| 实体发现与读档匹配 | `E/Setting/SaveManager.gd:154-166,217-368` | 递归当前场景，凭 `ExportSaveData`/`LoadSaveData` 方法发现实体，以相对节点路径存键；切场景后等两帧恢复。路径失败用同名/玩家字段兜底，可能复用已匹配条目；改节点名/层级要核对旧存档。 |
| 设置面板与改键输入 | `E/Setting/Setting.gd:61-240,286-311,397-420,426-444`；`E/Setting/Setting.tscn:537-562` | ui_cancel 切显隐，改键先捕获键/鼠标，Esc取消；`SettingVisibilityRequested` 控制显示，仅显示UI、不暂停树；默认不自动载入槽1。`ShowSetting` 仅在正式 World 或含 player 的非主菜单场景显示预置 ReturnMenuButton；按钮发 `ReturnToMainMenuRequested`，失败由 `ReturnToMainMenuFailed` 显示提示。 |
| 改键与触屏布局持久化 | `E/Setting/KeybindManager.gd:10-23,40-79,129-203`；`E/Setting/TouchLayoutManager.gd:3-41` | 改键实际写 `res://Code/Entities/Setting/Saves/custom_keybinds.json`，不是旧注释的 user://；每动作保存首事件，重绑清原绑定、无冲突检查。触屏位置/缩放另存 `user://touch_button_layout.cfg`。 |
| 设置主题、外框与音量 | `E/Setting/SettingsSkin.gd:3-140`；`E/Setting/SettingsFrame.gd:14-75`；`A/Util.gd:25-80` | 主题缓存使用 `Art/New/ui/Settings9761/` 长/短条九宫格，固定装饰端头；默认 HSlider 为通用滑块，Setting 的五通道声音控件使用 AudioSlider 音乐旋钮变体。外框 `Mount` 重挂关闭按钮并适配窗口；音量请求→`SetAudioVolume`→反馈，独立存 `user://audio_settings.cfg`。 |
| 退出与返回主菜单自动保存 | `A/SignalBus.gd:351-413` | `GameQuitRequested`/窗口关闭统一 `_quit_with_auto_save`；`ReturnToMainMenuRequested` 延迟调用 `_return_to_main_menu` 并防重入。两者仅正式 World 且活跃槽存在才自动保存；返回菜单保存/加载失败则留在当前场景并发 `ReturnToMainMenuFailed`，成功切到 StartMenu 后清暂停、释放输入动作并显示鼠标，不退出程序。 |
| 剧情资源、推进与恢复 | `E/Plot/PlotDialogLine.gd:1-7`；`E/Plot/Chapter1.gd:8-99`；`W/Camp/Camp.tscn:155-169`；`P/Player.gd:423-461`；`A/SignalBus.gd:15-21,28` | 开场等待四帧，逐句发 `DialogBox` 并等待 `../../DialogBox.Closed`；完成后发 `PlayerOpeningStandUpRequested`。Camp 石碑成功交互通过 `ComponentInteracted` 将 Chapter1 的 next_event 从1推到2；LeaveStory 不再自行进入即播，只有在 next_event=2 且玩家进入/已在区域内时由 Chapter1 播放其 enter_dialog_lines，再推到3。World 下额外的 lake 剧情区域仍独立于此门控。Chapter1 就绪即发 `PlayerOpeningHoldRequested`：玩家禁用处理，ani_move 独立保留处理并暂停在 stand_up 首帧；起身动画结束恢复处理与 idle。保存 next_event/line_index，加载更新 generation；未完成开场重新锁定，已完成发 `PlayerOpeningReleaseRequested`。 |
| 对话队列与结束信号 | `E/Plot/dialogbox/DialogBox.gd:25-129`；`E/Plot/dialogbox/DialogBox.tscn:21-102`；`E/Plot/dialogbox/NarrationPanel.tscn:1-73`；`E/Plot/dialogbox/DialogFrameEdge.gd:11-58`；`A/ExportSettings.gd:686-692` | 旁白/独白排队；旁白仍默认3秒关闭；独白按 `dialog_monologue_chars_per_second` 逐字显示，非标点、非空白字符逐字播放 `Music/SFX/UI/TalkBeep.wav`（SFX_Interact 总线），标点静音并额外停顿 `dialog_monologue_punctuation_pause`，全显后1秒自动关闭，skip_story 首次全显、再次关闭；按钮仍可立即关闭。每句发 `Closed`，队列空先发 `Finished`，交互组件借此解锁；`Dismiss` 不发 Closed，不能替代普通推进。底框使用同目录 `Art9766/` 裁图，装饰镂空已在派生 PNG 内按参考色 `#4D4D4D` 填为不透明，外部透明轮廓保留；AspectRatioContainer 保持原比例与顶部对齐；Close 位于 Margin 下，无纹理按钮的 Hint 为等比铺满的 TextureRect。`_setup_continue_arrows` 从设置底图提取镂空 alpha 并翻向右侧生成白色箭头，悬停色取 `dialog_arrow_hover_color`；独白左侧28%预留。两个 Background 下预置 FrameEdge，复用设置 PAPER 色与 setting_panel_edge_width，双道手绘描边按底图墨面定位、透明处断笔，resize 重绘且忽略鼠标，不改变正文及关闭逻辑。 |
| 章节卡与渐显文字触发 | `E/Plot/chapter/ChapterTrigger.gd:11-18`；`ChapterCard.gd:5-53`；`GradualTextTrigger.gd:11-32`；`GradualTextCard.gd:19-34`（后三者同属 `E/Plot/chapter/`） | 玩家进入/遗物献祭触发一次；章节卡4秒，`ChapterCard.tscn:7-76` 使用章节标题.PNG 的有效透明区域作为等比装饰，Layout 容器排列幕名/装饰/标题，配色复用 SettingsSkin.PAPER/ACCENT；渐显按25%/50%/25%分段；触发器无存档接口。 |
| 绘本 | `W/PictureBook.gd:35-104`；`W/PictureBook.tscn:1-90` | 父 Interacted 开书、锁输入/禁交互；每页每次打开一次独白，等 `DialogBox.Finished` 显示书页，关闭恢复；不持久化阅读进度。残缺的绘本与学者的笔记共用此场景。外观复用 SettingsSkin 主题与 SettingsFrame 外框（底图、手绘边、右上三角关闭），Book 面板由 `Mount` 统一适配窗口；节点路径含 `Root/Book/Margin/Pages` 层级。 |

### 10.7 视觉装饰与现有测试入口

水墙教学补充：`SunkenPalace.tscn:461-464` 在第一道水墙左侧地面本地 `(2490,350)` 预置 `WaterWallHint`，`hint_kind="water_wall"`，沿用240×200区域与底部字幕。`IC/TutorialHintArea/TutorialHintArea.gd:15-21` 按类型选择文案；`A/ExportSettings.gd:10-11` 的 `tutorial_water_wall_hint_text` 默认“左键交互水墙”。只新增提示，不改变水墙输入绑定；正式关卡位置待试玩确认。

冲刺教学补充：`SunkenPalace.tscn:456-459` 在横木平台上方本地 `(1666.6,220)` 预置 `DashHint`，`hint_kind="dash"`；`IC/TutorialHintArea/TutorialHintArea.gd:3-19` 按类型选择跳跃/冲刺文案，经同一总线复用底部字幕，原跳跃区域默认类型不变。冲刺文案 `A/ExportSettings.gd:8-9` 为“Shift键冲刺”。本次平台内实际触发位置仍待试玩确认。

跳跃教学字幕：`E/TutorialSubtitle/TutorialSubtitle.gd:10-49`、同名 `.tscn`，`IC/TutorialHintArea/TutorialHintArea.gd:5-16`、同名 `.tscn`；`A/ExportSettings.gd:3-26` 集中配置文案、纸色/墨色/暖金配色、字号、布局和0.7秒淡入/4秒停留/1秒淡出。`SignalBus.TutorialSubtitleRequested(text)` 驱动独立 CanvasLayer 底部居中字幕，不锁输入、不拦鼠标；空文字清除，重复请求取消旧Tween。`World.tscn` 预置字幕；`SunkenPalace.tscn` 的 `JumpHeightHint` 位于本地 `(1240,350)`，240×200区域在三格竖木板 x=1453.8 前（右上平台 x=1613.4..1719.8），只接受 player 组，每次离开再进入可重播，不存档。2026-10-18 Godot 4.7.2 headless 独立组件95项检查通过，覆盖物理进入/重入、渐变采样、替换/清空、1280×720/800×600/480×320缩放与不缩放布局；未启动正式World或写存档，完整关卡触发位置及画风仍待人工验收。定位木板时正式宫殿资源曾报告既有TileSet越界错误，未在此任务修改。

| 功能 | 文件与关键行号 | 实现锚点 / 阅读注意 |
| --- | --- | --- |
| 普通交互提示圆点 | `C/InteractionDot.gd:1-86`；`A/ExportSettings.gd:804-810`；`IC/InteractableComponent/InteractableComponent.tscn:17-18`；`IC/Level2Device/Level2Device.tscn:71-72`；`IC/MiniChaliceStation/MiniChaliceStation.tscn:76-77`；`IC/Tent/Tent.tscn:26-27` | 四个场景预置同一 Node2D（帐篷只继承脚本、不继承基础场景，故单独预置）；流水区域 WaterFlowArea 已移除提示节点，固态/流水态均不显示交互圆点；暖白半径15、动态居中的普通圆点，中心不透明度0.65，径向渐变至透明边缘，无额外光晕；本次柔边及尺寸位置调整未运行视觉验收。CanvasItemMaterial 使用 unshaded，不新增光源、光晕或粒子，不改既有照明。每帧依父实体可见/处理及 enable_interaction、is_available、available 隐藏或恢复，不依赖距离或首次交互标记；设备按点击美术选择规则，通用实体支持直接 Sprite2D 子节点（含任意名字的绘本/笔记美术），无图时用碰撞，水墙两态均按 area_size。每帧通过 source.to_global(bounds.get_center()) 计算所选图像/多边形/碰撞矩形的世界中心并定位，已移除顶部偏移参数；top_level 和单位世界变换保持圆点大小不受实体缩放/旋转影响，不扫描世界或UI。2026-10-18 Godot 4.7.2 TEMP 隔离导入及运行均退出0，75项断言通过：四类基础场景及帐篷加载、默认/隐藏/停用/恢复、可交互开关、重复交互、圣杯真实冷却计时恢复、设备 available/美术隐藏/旋转包围盒、绘本命名美术、世界大小恒定与移动跟随、全局开关。隔离环境未装原音频总线，有4条缺总线警告及退出时2个 ObjectDB 实例泄漏警告；未启动正式World、未写原存档，完整关卡视觉待人工验收。 |
| 通用视差与测试相机 | `E/ParallaxScenery/ParallaxScenery.gd:6-48`；`E/ParallaxScenery/ParallaxTestCamera.gd:1-27` | 各层周期/速度/接缝，复制材质隔离实例；top_level 避免关卡位移叠加，scroll_offset 包含世界位置。预览场景在同目录，测试相机左右移动/R复位。 |
| 第一关沙漠背景 | `W/SunkenPalace/DesertScenery.gd:1-79`；`W/SunkenPalace/DesertScenery.tscn:10-85`；`W/SunkenPalace/SunkenPalace.tscn:423-427,669-703`；`A/ExportSettings.gd:786-788` | SunkenPalace 的沙漠景物不属于 Camp 或全局背景。BaseSky、SunBokeh、MesaRocks、RockPillars、CactusFar 保留在 `DesertScenery` 子场景内作为 Parallax2D；DunesMid、DesertSilhouette 已直接放进 `SunkenPalace.tscn`，是普通 Node2D 子节点，编辑器中的 position/scale 会直接生效，控制器不改写其变换。两层前景不设 top_level，因此纵向随宫殿世界离开镜头；各自仍以原图+水平镜像衔接。控制器运行时读取当前 Camera2D 的真实画面中心并换算为 SunkenPalace 本地 X，统一控制五层背景和两层前景；默认起点 -515 对齐 World 中世界 X=2120 的 Camp/宫殿 CameraGate，因此 Camp 中整套隐藏、镜头进入宫殿后整套显示，并避免覆盖第三关。2026-10-18 Godot 4.7.2 headless 验证新场景结构可加载、七层统一显隐、直接摆放的前景变换保持不变、随世界纵向移动及宫殿整体平移保持构图；完整视觉仍待人工验收。 |
| 第一关升降平台 T 字悬绳 | `W/SunkenPalace/LiftVisual.gd:1-28`；`W/SunkenPalace/LiftVisual.tscn:1-31`；`W/SunkenPalace/SunkenPalace.tscn:255-269`；`A/ExportSettings.gd:790-803` | 仅纵向平台 MovePl/1 使用；原始 swing 图只读，拆分 PNG 存于同目录 LiftPlatform.png / LiftRope.png。横绳固定左墙及右上台阶，竖绳下端跟随吊环，Line2D TILE 重复纹理而非拉伸；节点坐标换算保持整关平移和读档位置同步。2026-10-18 Godot 4.7.2 TEMP 隔离验证 PNG/场景加载、46/596/1146 绳长、往返、固定端点、整体平移及踏板对齐通过，正式关卡视觉待验收；不改平台碰撞或触发逻辑。 |
| 营地、绿洲装饰 | `W/Camp/Scenery/CampScenery.gd:11-80`；`W/OasisBattlefield/Decoration/OutwardScenery.gd:1-14`；`OasisComponentArt.gd:22-143`；`OasisTerrainTile.gd:1-44`（后两者同属绿洲 Decoration） | 营地覆盖/有限视差；营地及第二关前景均不再按人物位置局部透明，保留整体透明度；绿洲按相机位置控制可见，按组件状态绘美术，TileMap邻接选边；不负责生成碰撞。 |
| 第二关房间与井内视差 | `L2/Scenery/Level2Scenery.gd:11-105`；`L2/Scenery/HorizontalScenery.gd:20-124`；`L2/Scenery/VerticalScenery.gd:15-122`；`L2/Scenery/parallax_scenery2.tscn:146-163` | 房间范围/视口裁剪、左井慢降只滚指定柱层；横向从原始 PackedScene 取变换防累计缩放，竖向按井高适配、分层漂移/循环。横向前景使用同目录 LibraryPillar.png（从只读 Horizontal/12.png 的 Rect2(394,0,624,1151) 裁出保留两侧拱形柱顶的完整单柱），两根柱子按4096宽单元循环，保持原比例并铺满构图高度；ExportSettings 的 level2_scenery_foreground_opacity 默认1，无新增碰撞。 |
| 第二关地形美术与黑幕 | `L2/Terrain/TerrainArt.gd:19-259`；`W/视觉装饰组件/BlackCurtain.gd:1-8`；`W/视觉装饰组件/ShaftOcclusion/ShaftOcclusion.gd:1-31`；`W/视觉装饰组件/ShaftOcclusion/ShaftOcclusionMask.gd:1-31`；`W/视觉装饰组件/ShaftOcclusion/ShaftOcclusion.tscn:11-35` | 跨房间汇总真实占用绘石框/玻璃，RenderingServer 隐藏灰盒，不改碰撞；黑幕检测 player 后释放；ShaftOcclusion 使用两个可在编辑器直接调整的 Polygon2D 区域，进入一侧时只遮住另一侧。 |
| Hub 地下图书馆环境光与局部月光 | `L2/Lighting/HubLighting.gd:1-78`；`L2/Lighting/HubLighting.tscn:40-154`；`L2/Lighting/HubBeam.gdshader:1-8`；`L2/Rooms/FountainStream.gdshader:1-13`；`L2/Rooms/Hub.tscn:151`；`IC/Level2Device/Level2Device.gd:6-34`；`IC/Level2Device/Level2Device.tscn:1-85`；`A/ExportSettings.gd:740-776` | Hub 预置 CanvasModulate，根据玩家是否位于 Level2Map 的任一房间平滑调暗共享世界 canvas，离开恢复白色；HUD 的 CanvasLayer 不受影响。冷色喷泉月光未激活时仍有基础能量，泉口补光激活后渐亮；左侧 DescentShaft 井口（地图局部 x≈700、y≈-2940）有常亮冷色 PointLight2D、井口光晕及贯穿全井、越过下方出口后渐隐的两道长条光束（主束 y=-2940..520）；两束均绑定场景内1×1纯白 BeamUVTexture，确保 Polygon2D 实际传递0..1 UV；无贴图时 UV 为零会使散射全透明。Godot OpenGL 实际离屏渲染对照平均红通道：无贴图0，使用场景贴图约0.73（不代表正式场景亮度）。两束均使用 `L2/Lighting/DescentMoonbeam.gdshader:1-28` 的加色散射，横向噪声分束、纵向雾尘缓慢漂移模拟丁达尔光路，不影响其他房间光束，光源可照亮人物，参数由 `level2_hub_light_descent_*` 控制。第二关钥匙、符文、残卷等 Level2Device 自带冷色微光；喷泉不叠加通用设备灯。灯光颜色、强度、半径由 `level2_hub_light_*` 调整，水柱 shader 接受环境光及局部光；灯只影响世界 Canvas 层0、z=-30..10。`level2_hub_light_enabled` 可对比并恢复环境光，不写机关/存档。Godot 4.7.2 headless 装配 Level2Playtest.tscn 运行2帧退出码0；实际月光视觉效果仍待人工验收。 |
| 钩索回归脚本 | `P/GrappleAnimationTest.gd:1-158` | SceneTree `_initialize` 入口，检查同帧动作/发射点/方向/脱钩/伤亡/事件隔离，退出码0/1；需要项目单例。本次未执行。 |
| 镜头演示与检查 | `E/PlayerWithCamera/CameraShowcase.gd:1-116`；`E/PlayerWithCamera/CameraDirectorChecks.gd:1-86` | 演示用同目录 CameraShowcase.tscn；Checks 是 RefCounted，需对已就绪场景显式调用异步 `Run(scene)`，非独立启动场景。检查锁定/字幕/取消/优先级/过滤。 |
| 玩家及第二关测试场景 | `E/PlayerWithCamera/PlayerWithCameraTest.gd:1-13`；`L2/Level2Playtest.gd:1-15` | 同目录对应 .tscn；前者默认禁二跳/钩索，另有 PlayerCameraTest.tscn 基础跟随场景；后者对齐 Spawn/城市预览并换灰盒外观，不能当作正式能力配置。 |
| 压力按钮回归入口 | `Code/PressureButtonTestRunner.gd:1-15`；`Code/PressureButtonRuntimeTest.gd:3-123` | Runner 以当前引擎启动 headless 的 PressureButtonRuntimeTest.tscn；检查按压/释放/锁存/Reset/旧档恢复/门同步，退出0/1；直接调用 `_apply_save_data_smart`，不覆盖磁盘存取。本次未执行。 |

### 10.8 跨模块主链与修改前检查

- **移动**：输入控制器 → 玩家状态机/状态脚本 → Player 主物理循环 → `PlayerBeforeMotion`（第二关等可响应）→ 实际位移。钩索摆动另含位移调用，改运动时要一起核对。
- **能力/HUD**：HUD 发能力请求 → Player 更新永久解锁/可用状态 → 广播反馈 → HUD 回显；钩索阶段事件另驱动状态机动画及发射点更新。
- **遗物**：关卡领取发 `lock1/lock2/lock3` → 玩家遗物状态 → 湖泊请求状态并发献祭事件 → 能力解锁/结局。领取、献祭、保存不是同一操作。
- **机关**：压力按钮 → `MechanismChannelStateChanged` → 门/平台/挡板；直接按钮绑定优先。第二关是独立 `Level2InteractionRequested → Level2Map → Level2StateChanged`，不要混用两条链。
- **存档**：菜单/设置/特定流程调用 SaveManager → 按场景节点路径收集实体字典 → 读档匹配实体 → `SaveSlotLoaded` 后部分关卡再恢复流程。帐篷只设重生点，绿洲取骨另有 AutoSave。
- **死亡/重生/镜头**：HP归零 → died/`PlayerDied` → 清未献祭遗物与关卡临时态 → Respawn/`PlayerRespawned` → 镜头和关卡复位。检查异步回调是否仍属于当前代次。
- **参数与输入的真实值**：脚本默认 → `.tscn` 覆盖 → ready 同步/包装器再次赋值；输入还会加载 custom_keybinds。不能只改 ExportSettings 默认或 project.godot 默认便认定运行值已变。
- **兼容现状而非扩大改动**：仍有直接跨实体调用、旧 snake_case、局部硬编码、自绘触屏控件及不完整瞬态存档。索引记录差异，不授权顺手重构；新增通信仍遵循总线规范。
- **验证边界**：上述为静态分析，存档路径写权限、场景资源导入、镜头/物理实际效果及测试是否通过，均需任务需要时另行验证。不要因存在测试文件就宣称测试通过，也不要为索引任务运行可能写入已有槽位的游戏。





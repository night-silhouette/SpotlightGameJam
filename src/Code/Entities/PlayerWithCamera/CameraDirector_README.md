# 玩家镜头与演出接入

本组件使用项目已有的 Phantom Camera 0.11.0.3，引用原 Player 场景。本文是随组件一起提交的团队接入说明，不参与游戏运行，也不设置 AI 协作规则。

## 封装范围与当前状态

- `PlayerWithCamera.tscn` 包含原玩家实例、实际 Camera2D、插件 Host、普通镜头、交替使用的 ShotA/ShotB、内部位置标记，以及 CameraPresentation 演出层。
- 演出层提供黑幕、模糊、顶部遮罩、标题和逐字正文。具体文案由关卡传入；它不是带交互、选项或分页的完整文本实体。
- 地图、沙漠背景、平台、船、河流和房子不包含在组件里。CameraShowcase 的船、水面和小室是测试占位内容。
- 镜头组件和演示已实现；正式关卡的触发、锚点、边界、独立文本实体及机关配合仍需接入和验收。

运行流程：关卡发出 SignalBus 请求 → PlayerWithCamera 读取 ExportSettings → Phantom Camera 运镜 → 发送就位通知并启动配套演出。CG 结束请求使镜头返回，并在回镜完成后恢复玩家操作。

## 验收入口

在 Godot 文件系统搜索 `CameraShowcase.tscn`，打开后 F6 运行当前场景。顶部按钮和数字键 0–5 对应普通、沙漠、下落、渡舟、遗物 CG、固定镜头。R 重播，Esc 或“结束 CG”返回 CG 前的镜头。录屏可按 1→2→3→4→Esc→5 展示。

沙漠引用当前视差美术。蓝色方块是原玩家占位形象。船、水面、小室、下落轨迹和文本均为验收占位，不能视为已完成正式关卡、船体玩法或最终剧情。下落/渡舟演示临时暂停玩家自己的物理，用匀速轨迹测试镜头；其他模式可 A/D 移动、空格跳跃。

`ParallaxIntegrationTest.tscn` 仍用于实际角色与背景联调，`PlayerCameraTest.tscn` 仍用于普通跟随。它们不自动播放五幕演出；F5 仍运行项目原先的主场景。

## 文件与节点

| 文件 | 用途 |
| --- | --- |
| `PlayerWithCamera.gd/.tscn` | 在原组件内新增两台交替接管的插件镜头 ShotA/ShotB、两个固定锚点 AnchorA/AnchorB，以及 CameraPresentation。原 Player、Camera2D/PhantomCameraHost、PhantomCamera2D 路径保留。 |
| `../../Autoloads/ExportSettings.gd` | 新增 Camera Director 和 Camera Showcase 参数，旧普通跟随参数不变。 |
| `../../Autoloads/SignalBus.gd` | 六个具名切镜请求信号，参数名与类型直接写在声明中；保留旧通用请求、结束请求、就位和锁输入通知，不改队友既有信号。 |
| `CameraPresentation.gd/.tscn` | 全屏模糊、黑幕、上部遮罩、标题及字幕播放顺序，切镜清理旧演出。 |
| `CameraBlur.gdshader` | 5×5 高斯核屏幕采样，退幕结束隐藏节点，避免持续全屏采样。 |
| `CameraNarration.gd` | 按字渐显；纵排右起换列，横排自动换行，完成后停止刷新。 |
| `CameraShowcase.gd/.tscn` | 独立五镜头验收场景。 |
| `CameraDirectorChecks.gd` | 检查构图、锁轴、CG 输入冻结/恢复、提前取消、连续切镜和优先级恢复。 |

Godot 为新增脚本和着色器生成的 `.uid` 应与对应文件一起提交。

## 默认参数

普通镜头原来的 Zoom=1、Offset=(0,-120)、Damping=(0.12,0.18) 保留。新模式参数独立：

| 模式 | Zoom | 人物/目标屏幕位置 | 阻尼 X/Y | 行为 |
| --- | --- | --- | --- | --- |
| desert | 0.85 | (25%,70%) | 0.25 / 0.30 | 右上留白；黑幕/模糊 1.8 秒退去后纵排字幕 |
| descent | 1 | (50%,70%)，移动时有短暂偏差 | 0.12 / 0.40 | 锁 X；Y 阻尼与速度前馈补偿；标题淡出后上方字幕 |
| boat | 1 | (40%,60%)，水平有跟随延迟 | 0.60 / 0.30 | 锁 Y；跟随传入的船体目标；顶部 16% 遮罩，下方字幕 |
| ritual | 1.35→0.85 | 玩家近景→传入的空镜中心 | 关闭跟随阻尼 | 近景过渡后停留 0.6 秒，再用插件 2.8 秒过渡到空镜；到位后播放标题/正文 |
| fixed | 1 | 传入的房间中心 | 关闭跟随阻尼 | 固定位置，不追随角色 |

普通模式切换时间 1.2 秒。文字每字间隔 0.12 秒、渐显 0.5 秒。Zoom 小于 1 表示更宽的视野，美术节点的 Scale 没有改变。若策划要求镜头也保持原始视野，将 camera_desert_zoom 改为 1。

上述全局数值在 ExportSettings 的相应分组调整，停止后重新运行验证；最新值以该文件为准。沙漠构图 Y 已由 0.76 调为 0.70，以增加底部前景可见空间。房间边界优先于人物构图：边界过小可能改变人物屏幕位置；不能同时强制单屏房间边界与广角远景。

日常调整入口：

| 想调整什么 | 去哪里改 |
| --- | --- |
| 视野远近 | ExportSettings 中对应模式的 `camera_*_zoom`；数值减小看得更广，增大看得更近。普通跟随用 `player_camera_zoom`。 |
| 人物在画面里的位置 | `camera_*_frame`；X/Y 从左上角按 0–1 计算，Y 越大人物越靠下。普通跟随用 `player_camera_offset`。 |
| 跟随快慢 | `camera_*_damping`；X 横向、Y 纵向，数值越大跟随越慢。普通跟随用 `player_camera_damping`。 |
| 切镜或演出速度 | `camera_transition_duration`、`camera_ritual_pan_duration`、`camera_intro_duration` 等。 |
| 正文字号与逐字速度 | `camera_text_font_size`、`camera_text_interval`、`camera_text_fade`。 |
| 这一关何时切镜、显示什么、看向哪里 | 关卡的信号调用、传入的船体或 Marker2D，以及 `bounds`。 |
| 文字显示区域和演出顺序 | `CameraPresentation.gd/.tscn`；交互文本由独立文本模块负责。 |

组件会在运行时设置插件镜头属性，直接修改 ShotA/ShotB 检查器中的 Zoom 等值可能被覆盖。全局配置会影响所有使用对应模式的关卡；`camera_demo_*` 只控制演示移动速度。每次只改一项，保存后重新 F6 对比。

## 正式关卡调用

关卡保留一个 PlayerWithCamera 实例及一套实际 Camera2D/Host，等组件完成 `_ready` 后发送请求。以下 `player` 指组件内的原 Player（CharacterBody2D），不是外层 Node2D。

已有玩家的地图应检查是否需要用组件替换原玩家，并更新相关节点引用，避免出现两个玩家。当前 World 已引用该组件，无需重复添加。原 Player 场景和脚本更新会传递到实例；实例已覆盖的属性仍优先使用自己的值。

新调用不用填写 `mode` 或字典键。直接选择信号，按声明顺序填写参数；所有参数都必须传入。不需要标题/正文时传 `""`，沿用边界时传 `Rect2()`。信号声明和每个参数的用途均在 SignalBus 顶部。

| 信号 | 参数顺序 | 就位通知 mode |
| --- | --- | --- |
| `CameraNormalRequested` | player | normal |
| `CameraDesertRequested` | player, title, text, intro, bounds | desert |
| `CameraDescentRequested` | player, title, text, bounds | descent |
| `CameraBoatRequested` | player, follow_target, title, text, bounds | boat |
| `CameraRitualRequested` | player, anchor, title, text, bounds | ritual |
| `CameraFixedRequested` | player, anchor, title, text, bounds | fixed |

```gdscript
# player 是 $PlayerWithCamera/Player；以下代码在关卡/剧情节点里调用。
# 第一幕：玩家、标题、纵排正文、是否播放黑幕/模糊开场、边界。
SignalBus.CameraDesertRequested.emit(player, "", "第一列文案\n第二列文案", true, Rect2())

# 第二幕：玩家、标题、上方正文、边界。
SignalBus.CameraDescentRequested.emit(player, "第二幕 · 深渊", "这里填写正式叙事。", Rect2())

# 渡舟：玩家、船体、标题、水面正文、边界。传 null 船体时跟随玩家。
SignalBus.CameraBoatRequested.emit(player, boat_node, "", "水面叙事文案", Rect2())

# 遗物：玩家、空镜中心 Marker2D、标题、仪式正文、边界。anchor 不可为空。
SignalBus.CameraRitualRequested.emit(player, ritual_marker, "", "仪式文案", Rect2())

# 剧情结束/跳过后回到进入 CG 前的镜头；回镜完成才恢复操作。
SignalBus.CameraShotEndRequested.emit(player)

# 小室：玩家、房间中心 Marker2D、标题、正文、边界。anchor 不可为空。
SignalBus.CameraFixedRequested.emit(player, room_center, "", "", Rect2())
# 离开小室时恢复普通跟随，也可以直接请求下一幕镜头。
SignalBus.CameraNormalRequested.emit(player)
```

`bounds: Rect2` 是世界坐标的镜头范围；传 `Rect2()` 沿用组件原 PhantomCamera2D 的边界。例如 `Rect2(0, 0, 4000, 2000)` 指左上角 (0,0)、宽 4000、高 2000。范围宽高应大于当前视野大小（视口尺寸 / Zoom）。固定/仪式锚点取请求瞬间的位置快照。跟随目标被移除时退回普通玩家跟随。字幕区域有限，正式长文案请拆成短段；本次不包含对话分页系统。

兼容旧代码：`CameraShotRequested(player, mode, options)` 仍可调用，原字典字段与行为保留；新接入优先使用上方具名信号。`CameraShotReady` 的 mode 仍使用表中的 StringName，以免破坏已有监听。镜头内部继续共用原切换流程，本次接口调整没有改变 Zoom、阻尼、场景节点或美术比例。

可监听 `CameraShotReady(player, mode)` 对接后续剧情；ritual 只在最终空镜就位后触发。`CameraInputLockChanged(player, locked)` 通知关卡是否处于 CG 冻结。不要通过更改 ShotA/ShotB 优先级触发剧情，使用信号接口。

就位通知不代表黑幕、标题或正文已经播完。结束 CG 的逻辑应放在关卡/剧情节点中，不能依赖被暂停的玩家子树。回镜不会重播此前文字；此前固定镜头的锚点已移除时，改回普通跟随。

## 与独立交互文本配合

正式文案可以全部由关卡的文本实体管理。此时切镜请求的 `title` 和 `text` 都传 `""`，相机不显示自己的文字。独立文本实体的启动和完成通知尚未接入，不会自动随镜头播放。

- 空文字不会关闭其他效果：沙漠仍由 `intro` 控制黑幕/模糊；渡舟仍显示顶部遮罩。若外部系统负责沙漠开场，传 `intro = false`；当前没有统一的“关闭全部配套演出”参数。
- CameraPresentation 使用 CanvasLayer 40，其可见字幕、遮罩和模糊可能覆盖较低层的 UI。需要文字显示在其上方时，将文本放在更高的独立 CanvasLayer，并与团队现有 UI 层级协调；提高文字节点的 Z Index 不等于跨 CanvasLayer 提升层级。
- 相机演出 Control 均忽略鼠标，不会由这些界面节点拦截点击；但 CG 仍会暂停 Player 子树，因此交互文本的播放和推进逻辑应放在其外部。
- `CameraShotReady` 仅表示镜头过渡完成。沙漠黑幕在此时才开始退去；当前没有“黑幕已退完”或“相机正文播放结束”的公共信号，不能把就位通知当作演出结束。

建议对接流程（待文本模块实现后接通）：交互成功 → 请求仪式镜头且传空文字 → 收到对应 player、mode 的就位通知 → 启动文本实体 → 文本结束 → 发送 CameraShotEndRequested。监听应在请求前建立，并过滤玩家与模式；等待退幕的流程需要另行接入效果完成通知。

## 旧接口兼容

旧接口 `CameraShotRequested(player, mode, options)` 为已有调用保留。新关卡使用前面的具名信号即可。

`mode` 接受 `&"normal"`（普通）、`&"desert"`（沙漠）、`&"descent"`（下落）、`&"boat"`（渡舟）、`&"ritual"`（仪式）、`&"fixed"`（固定）；其他值会被拒绝。

`options` 必须传字典，不需要额外内容时传 `{}`。字段如下：

| 字段 | 类型 / 默认值 | 用途 |
| --- | --- | --- |
| `title` | String / `""` | 章节标题；为空则跳过标题。 |
| `text` | String / `""` | 标题淡出后逐字显示的正文；为空则不显示。 |
| `intro` | bool / `true` | 仅控制沙漠黑幕/模糊开场；false 不关闭文字。 |
| `follow_target` | Node2D / 玩家 | 跟随目标，渡舟可传船体；仪式近景始终看玩家，固定镜头使用 anchor。 |
| `anchor` | Node2D / 无 | 仪式和固定镜头必填，推荐 Marker2D；取请求瞬间的世界坐标，缺失时拒绝请求。 |
| `bounds` | Rect2 / `Rect2()` | 世界坐标镜头范围；默认沿用基础镜头边界，普通模式不读取。 |

```gdscript
SignalBus.CameraShotRequested.emit(player, &"descent", {
	"title": "第二幕 · 深渊",
	"text": "光在身后远去。",
})
SignalBus.CameraShotRequested.emit(player, &"fixed", {"anchor": room_center})
```

这些字段是本项目约定，不是 Godot 内置参数。字典不提供逐字段静态类型检查，键名拼错可能被忽略。缩放、构图、阻尼和时长仍在 ExportSettings 中调整。

## 与其他模块的关系

- ExportSettings 和 SignalBus 是共享文件；队友若同时编辑相邻位置，后续 Git 合并可能需要处理冲突。原有玩家和机关信号保留。
- 已引用 PlayerWithCamera 的场景（包括 World）会加载新版组件；未请求特殊镜头时使用普通跟随参数。
- CG 暂停整个 Player 子树，包括移动、跳跃、绳索、动画和玩家自己 `_process` 内的自然掉血；回镜后恢复进入前的 process_mode。场景树计时器、外部信号和外部危险机关不会一起暂停，CG 不等于无敌。关卡若有危险，必须用 CameraInputLockChanged 协调机关/战斗模块。
- 使用默认 Host layer 的单玩家、单实际 Camera2D。多人/分屏需要单独分配插件 Host layers，当前不提供分屏管理。
- 普通镜头恢复原优先级 10；特殊模式使用原优先级+20。更高优先级的外部镜头接管时清字幕、解除本组件的 CG 锁，不与它抢夺控制。
- 演出 CanvasLayer=40，可见演出元素可能遮挡较低层的 HUD；验收按钮在 50。正式 HUD 的显隐需由关卡统筹。
- 不改变角色存档数据，镜头属于瞬时演出状态。读档/换场景后由关卡重新请求对应模式，不恢复播放到一半的 CG。

## 行为检查

此前版本的 16 项运行检查已通过；之后手动修改了沙漠构图 Y。本文更新只核对文档与代码，不代表已对该构图重新完成视觉验收；请重新 F6 比较普通/沙漠模式，再在正式地图检查。

CameraShowcase 运行时，可在调试工具中执行以下 GDScript 启动约 25 秒的检查（不要一边测试一边按演示按钮）：

```gdscript
var scene = get_tree().current_scene
var checks = load("res://Code/Entities/PlayerWithCamera/CameraDirectorChecks.gd").new()
scene.set_meta("camera_checks", checks)
checks.Run(scene)
# 稍后读取 scene.get_meta("camera_checks")._results，应有 16 项 true。
```

测试以默认参数为基准。正式地图还应检查：最快下落速度、房间出入口、不同窗口宽高比、CG 期间敌人和机关、长文本布局、保存/读档入口，以及美术背景是否足够覆盖广角镜头的可见范围。

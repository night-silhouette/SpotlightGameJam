# PlayerWithCamera：AI 接入速查

> 用途：供 AI 快速定位本项目的玩家镜头调用链。本文只描述现有实现；详细接入示例见同目录 `CameraDirector_README.md`，行为以代码为准。

## 核心结论

- `SignalBus.gd` **仅声明、转发镜头请求和状态通知，不执行视觉效果**。
- 关卡发请求 → `PlayerWithCamera.gd` 校验玩家、配置 Phantom Camera 和切镜 → 镜头就位后调用 `CameraPresentation.gd` 播放画面效果，并发出 `CameraShotReady`。
- 请求中的 `player` 必须是 `$PlayerWithCamera/Player`，而不是外层 `$PlayerWithCamera`；不匹配的请求会被忽略。
- 镜头缩放、构图、阻尼、过渡和演出时长主要从 `ExportSettings.gd` 读取。

## 文件与角色（均相对 `res://Code/`）

| 路径 | 职责 |
| --- | --- |
| `Autoloads/SignalBus.gd` | 镜头请求、结束请求、就位和输入锁通知的信号声明，主要在第 21–82 行。 |
| `Autoloads/ExportSettings.gd` | 各模式的镜头与演出参数。 |
| `Entities/PlayerWithCamera/PlayerWithCamera.tscn` | 内含原 Player、Camera2D/PhantomCameraHost、普通 PhantomCamera2D、ShotA/ShotB、AnchorA/AnchorB 和 CameraPresentation。 |
| `Entities/PlayerWithCamera/PlayerWithCamera.gd` | 第 57–75 行订阅信号；第 152–182 行校验并处理请求；第 199–264 行配置镜头；第 306–338 行处理就位、播演出、锁/解锁玩家。 |
| `Entities/PlayerWithCamera/CameraPresentation.gd` | 黑幕、模糊、渡舟遮罩、标题和正文演出。 |
| `Entities/World/DepthsLibrary/Level2/Level2CameraDirector.gd` | 第二关按区域发出旧通用镜头请求的实际例子。 |

## SignalBus 接口

所有参数按声明顺序传入；不用标题/正文传 `""`，不用自定义世界坐标边界传 `Rect2()`。

| 信号 | 参数顺序 | 结果 |
| --- | --- | --- |
| `CameraNormalRequested` | `player` | 恢复普通玩家跟随。 |
| `CameraDesertRequested` | `player, title, text, intro, bounds` | 沙漠构图；`intro=true` 时黑幕、模糊开场；正文纵排。 |
| `CameraDescentRequested` | `player, title, text, bounds` | 锁 X、纵向跟随，并补偿高速下落构图。 |
| `CameraBoatRequested` | `player, follow_target, title, text, bounds` | 锁 Y、横向跟随目标，顶部遮罩；`follow_target=null` 时跟随玩家。 |
| `CameraRitualRequested` | `player, anchor, title, text, bounds` | 暂停 Player 子树；玩家近景 → 锚点空镜，到最终空镜后播放文字。 |
| `CameraFixedRequested` | `player, anchor, title, text, bounds` | 固定锚点镜头；玩家可以移动。 |
| `CameraShotRequested` | `player, mode, options` | 旧通用接口，仍用于第二关；模式为 `normal/desert/descent/boat/ritual/fixed`。 |
| `CameraShotEndRequested` | `player` | 仪式 CG 返回此前镜头；非仪式模式返回普通跟随。 |
| `CameraShotReady` | `player, mode` | 镜头就位通知，**不是**黑幕或字幕播完通知。 |
| `CameraInputLockChanged` | `player, locked` | 仪式 CG 暂停/恢复玩家子树时通知外部。 |

## 最简调用

以下示例位于关卡节点脚本中，假设其子节点为 `PlayerWithCamera`：

```gdscript
var player: Node2D = $PlayerWithCamera/Player
SignalBus.CameraDesertRequested.emit(player, "", "沙漠叙事", true, Rect2())
SignalBus.CameraNormalRequested.emit(player)
```

仪式与固定镜头的 `anchor` 必须是存活的 `Node2D`（通常为 `Marker2D`）；空镜位置取请求时的世界坐标。镜头 `bounds` 用世界坐标；空 `Rect2()` 沿用基础镜头边界。

## 时序和边界

1. `PlayerWithCamera` 在 `_ready()` 连接请求信号，使用同一组件内部的 Player 实例过滤请求。
2. 普通模式使用基础镜头；特殊镜头交替使用 ShotA/ShotB，通过优先级切换。下落锁 X；渡舟锁 Y；固定和仪式空镜借助内部 Marker2D 定位。
3. 特殊镜头到位后才调用 `CameraPresentation.Present(...)`，随后发出 `CameraShotReady`；沙漠黑幕在此时才开始退去。仪式模式先近景停留，再切空镜，仅最终空镜就位时通知 Ready。
4. 仪式 CG 只暂停该组件的 **Player 子树**，外部机关、敌人和计时器不会自动暂停；结束请求返回镜头，回镜就位后恢复 Player 处理模式。
5. `CameraPresentation` 使用 CanvasLayer 40；其他较低层 UI 可能被遮挡。镜头状态不会自动随角色存档恢复。
6. 第二关使用 `Level2PlayerWithCamera.gd` 特化普通/下落模式；分析第二关实际表现时要同时查看该脚本，不能只按基础组件推断。

## AI 修改前检查

- 先确认是在改具名接口还是第二关现用的 `CameraShotRequested(player, mode, options)`；不要只改一种入口而遗漏另一种。
- 先检查 `SignalBus.gd` 的声明、实际调用处、`PlayerWithCamera.gd` 的处理分支和 `ExportSettings.gd` 的可调参数。
- 不要将 `CameraShotReady` 当成字幕完成信号；目前没有对外的演出结束信号。
- 遵守仓库 `AGENTS.md`：代码与场景仅改 `res://Code/`；不得改插件或无授权的 `project.godot`。

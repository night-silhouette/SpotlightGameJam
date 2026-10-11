# 代码组开发规范

本文件适用于仓库内的 Godot 项目 `src/`。下文的 `res://` 指 `src/`，因此 `res://Code/` 对应 `src/Code/`。

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

## 杂项
- 关于可交互物,InteractiveComponent 在这个文件夹里做一些可交互物,每一个都单独在这里开一个文件夹,与 WaterFlowArea 这个文件夹并行
- 关于可交互物,如果他是那种需要f键交互的,那同时增加一个可用鼠标点击的ui,来触发交互,ui样式与Mini圣水杯的ui样式一致



## 现有项目分析

### 角色场景与存档流程
- 正式世界场景是`c:\Users\jixiegm\Desktop\SpotlightGameJam\src\Code\Entities\World\World.tscn` ：第 56–62 行的结构为`World/PlayerWithCamera/Player` 。相机包装场景在`c:\Users\jixiegm\Desktop\SpotlightGameJam\src\Code\Entities\PlayerWithCamera\PlayerWithCamera.tscn` 第 19–23 行实例化`Player.tscn` ；角色本体及其输入、状态机、钩索控制器、HUD 节点见`c:\Users\jixiegm\Desktop\SpotlightGameJam\src\Code\Entities\Player\Player.tscn` 第 1583、1603、1645、1705、1718 行。
- 存档服务是`c:\Users\jixiegm\Desktop\SpotlightGameJam\src\Code\Entities\Setting\SaveManager.gd` 。`SaveToSlot` （136–178 行）从当前场景递归收集具有`ExportSaveData` 的节点，以 相对节点路径 作`entities` 键（323–334 行），连同场景路径写入槽位 JSON。`LoadFromSlot` （185–244 行）必要时先切换场景、等待两帧，再还原；优先按路径匹配，未匹配时才按节点名或玩家特征兜底（248–290 行）。因此新交互物若需保存“已领取”，应有稳定的场景节点名和层级，避免多个实例在结构变更后仅靠同名兜底误配。
- 角色的`ExportSaveData` /`LoadSaveData` 位于`c:\Users\jixiegm\Desktop\SpotlightGameJam\src\Code\Entities\Player\Player.gd` 第 826–855 行：保存位置、血量、出生/重生点，以及永久二段跳和钩索状态；加载时通过`SetAbilityEnabled` 恢复。旧存档缺少能力字段时，当前实现会按`false` 恢复（854–855 行）。
- 新游戏及默认载入目标是`World.tscn` ，见`SaveManager.gd` 第 84–129、211–218 行；配置入口是`c:\Users\jixiegm\Desktop\SpotlightGameJam\src\Code\Autoloads\ExportSettings.gd` 第 458、467 行。项目启动先进入开始菜单，而不是直接进入世界：`c:\Users\jixiegm\Desktop\SpotlightGameJam\src\project.godot` 第 14 行。
### 2. SignalBus、配置与现有解锁方式
- `c:\Users\jixiegm\Desktop\SpotlightGameJam\src\Code\Autoloads\SignalBus.gd` 第 90–95 行已经定义了完整的能力请求／回报链：`PlayerAbilityChangeRequested(ability, enabled)` 、`PlayerAbilityStateRequested` 、`PlayerAbilitiesChanged(double_jump_enabled, rope_enabled)` 。同文件第 10–15 行是通用交互事件，第 187 行是圣水杯使用事件，第 288–296 行是存档槽位事件。`project.godot` 第 25、28 行注册了`SignalBus` 和`ExportSettings` 自动加载。
- 默认值不是领取状态 ：`ExportSettings.gd` 第 59–66 行提供二段跳速度、次数和两项能力的初始开关，二段跳与钩索默认均为`false` ；实际场景配置还应核对`c:\Users\jixiegm\Desktop\SpotlightGameJam\src\Code\Autoloads\ExportSettings.tscn` 。角色`_ready` 时从配置初始化并订阅总线（`Player.gd` 第 184–196、273–300 行）。`SetAbilityEnabled` （302–320 行）接受`&"double_jump"` 或`&"rope"` ，更新永久状态并广播结果。
- 现成的 调试解锁入口 在`c:\Users\jixiegm\Desktop\SpotlightGameJam\src\Code\Entities\Player\playerUi\HpUi\PlayerUI.gd` 第 27–62 行：面板开关经`PlayerAbilityChangeRequested` 请求角色改变能力，再用`PlayerAbilitiesChanged` 同步显示。若做关卡领取物，可复用同一请求信号，不必让交互物直接找玩家调用方法。
- 二段跳运行判定在`c:\Users\jixiegm\Desktop\SpotlightGameJam\src\Code\Entities\Player\PlayerInputControl.gd` 第 53–65 行，检查的是当前`enable_double_jump` 与剩余次数；消耗发生在`c:\Users\jixiegm\Desktop\SpotlightGameJam\src\Code\Entities\Player\States\JumpState.gd` 第 31 行。钩索控制器在`c:\Users\jixiegm\Desktop\SpotlightGameJam\src\Code\Entities\Player\RopeController.gd` 第 133、290 行检查`enable_rope` 。
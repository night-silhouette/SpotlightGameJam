extends Node2D
## 通用交互复用样例：只供调查，具体描述由测试界面响应 InteractionRequested 展示。
## 不代表策划中的正式实体，没有拾取状态，不写存档。

@onready var _interaction: ProximityInteraction = $Interaction


func _ready() -> void:
	_interaction.Configure(self, $DetectionArea, $PromptAnchor/Prompt, ExportSettings.inspection_example_interact_radius, ExportSettings.inspection_example_prompt_text, ExportSettings.inspection_example_prompt_font_size)

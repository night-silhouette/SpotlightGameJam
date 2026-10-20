@tool
extends Resource
class_name PlotDialogLine

## 在检查器中选择旁白或独白。
@export_enum("旁白", "独白") var dialog_type: String = "旁白":
	set(value):
		dialog_type = value
		notify_property_list_changed()
## 独白左侧的人物表情；旁白不显示此选项。
@export_enum("正常", "惊讶", "平静") var monologue_expression: String = "正常"
## 对话框中展示的一句文案。
@export_multiline var text: String = ""

func _validate_property(property: Dictionary) -> void:
	if property.name == "monologue_expression" and dialog_type != "独白":
		property.usage = PROPERTY_USAGE_NO_EDITOR

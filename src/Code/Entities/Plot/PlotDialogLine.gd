extends Resource
class_name PlotDialogLine

## 在检查器中选择旁白或独白。
@export_enum("旁白", "独白") var dialog_type: String = "旁白"
## 对话框中展示的一句文案。
@export_multiline var text: String = ""

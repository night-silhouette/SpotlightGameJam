extends Node2D
## 组合原玩家场景与 Phantom Camera；不修改玩家内部行为。
## 将本场景放到关卡出生点，参数统一在 ExportSettings 的 Player Camera 分组调整。
## 场景需由关卡提供地面；独立验证使用 PlayerCameraTest.tscn。


func _enter_tree() -> void:
	# 在插件子节点进入场景树前应用配置，避免开场先使用另一套镜头参数。
	var phantom: PhantomCamera2D = $PhantomCamera2D
	phantom.priority = ExportSettings.player_camera_priority
	phantom.zoom = Vector2.ONE * maxf(0.01, ExportSettings.player_camera_zoom)
	phantom.follow_offset = ExportSettings.player_camera_offset
	phantom.follow_damping = ExportSettings.player_camera_smoothing
	phantom.follow_damping_value = ExportSettings.player_camera_damping


func _ready() -> void:
	# 直接从出生点开始取景，后续移动由插件提供平滑的双轴跟随。
	$PhantomCamera2D.teleport_position()

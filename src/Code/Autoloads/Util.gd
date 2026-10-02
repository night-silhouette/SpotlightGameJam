extends Node


#时间到了,触发回调函数
func setTime(time,callback)->SceneTreeTimer:
	var temp=get_tree().create_timer(time)
	temp.timeout.connect(callback,CONNECT_ONE_SHOT)
	return temp
	#输出定时器本身,输出出来,以便于.stop()

## 兼容小写 set_time 调用
func set_time(time, callback) -> SceneTreeTimer:
	return setTime(time, callback)

	
	
#点击area2D,触发回调
func Area2dConnectClick(area2d:Area2D,callback:Callable)->void:
	area2d.input_event.connect(func(obj,event,id):
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
				callback.call()
		)
	
#松开鼠标
func Area2dConnectRelease(area2d: Area2D, callback: Callable) -> void:
	area2d.input_event.connect(func(_viewport, event, _shape_idx):
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
				callback.call()
	)
	
#改变节点的texture
func SetNodeTexture(node: Node, new_texture: Texture2D) -> void:
	if node and "texture" in node:
		node.texture = new_texture


	
#tween_fast_to_slow($Sprite2D, "modulate:a", 0.0, 1.0(时间), func():
	#print("淡出动画播完了！")
#)

#callback是补间动画结束触发的回调	
func TweenFastToSlow(obj,prop:String,value,time,callback=func():pass):
	var tween=create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)	
	tween.tween_property(obj,prop, value,time)
	tween.finished.connect(callback)
	return tween#tween的引用没有了之后,tween.finished.connect(callback)这个的信号也会随之free,所以可以大胆的对这个tween.kill()

# callback是补间动画结束触发的回调	
func TweenSlowToFast(obj, prop:String, value, time, callback = func(): pass):
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_CUBIC)	
	tween.tween_property(obj, prop, value, time)
	tween.finished.connect(callback)
	return tween
	
	
# 大数字简洁格式化
# 小于 1K 显示普通数字；从 K 开始缩写，输出 1K、1M、1B、1T 这种干净形式
func FormatNumber(num: float) -> String:
	# 从 K(10^3) 开始；之后每 1000 倍进一位：K M B T Qa Qi Sx Sp ...
	var suffixes := ["K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp"]
	var value := num
	var divisor := 1_000.0

	# K 之前直接显示普通数字
	if value < divisor:
		# 整数就不带小数点
		if value == floor(value):
			return str(int(value))
		return str(value)

	var idx := 0
	while value >= divisor * 1000.0 and idx < suffixes.size() - 1:
		divisor *= 1000.0
		idx += 1

	var result := value / divisor

	# 干净显示：整除就不带小数，否则最多保留一位小数并去掉末尾的 .0
	if result == floor(result):
		return "%d%s" % [int(result), suffixes[idx]]
	else:
		var s := "%.1f" % result
		if s.ends_with(".0"):
			s = s.left(s.length() - 2)
		return s + suffixes[idx]	
	


class AreaHoldHelper extends Node:
	var area: Area2D
	var press_callback: Callable
	var release_callback: Callable
	var is_inside := false
	var is_holding := false
	
	func _init(p_area: Area2D, p_press_cb: Callable, p_release_cb: Callable) -> void:
		area = p_area
		press_callback = p_press_cb
		release_callback = p_release_cb
		
	func _ready() -> void:
		area.mouse_entered.connect(func(): is_inside = true)
		area.mouse_exited.connect(func(): is_inside = false)
		
	func _input(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed and is_inside:
				is_holding = true
				if press_callback.is_valid():
					press_callback.call()
			elif not event.pressed and is_holding:
				is_holding = false
				if release_callback.is_valid():
					release_callback.call()

func Area2dConnectHold(area2d: Area2D, press_callback: Callable, release_callback: Callable = Callable()) -> void:
	var helper = AreaHoldHelper.new(area2d, press_callback, release_callback)
	area2d.add_child(helper)
	
	

	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
#region Napori
func FakeDeath(target_node: Node) -> void:
	if not is_instance_valid(target_node):
		return
		
	# 1. 掐断逻辑心跳：全面禁用该节点及其所有子节点的 _process, _physics_process 和 Timer
	target_node.process_mode = Node.PROCESS_MODE_DISABLED
	
	# 2. 掐断画面渲染：如果是 UI 节点或 2D 节点，直接隐藏
	if target_node is CanvasItem:
		target_node.visible = false
		
	# 3. 拦截鼠标与输入输入：
	# 如果是 UI 控件，让它彻底对鼠标透明（无法被点击）
	if target_node is Control:
		target_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# 4. 强行关闭碰撞体（防止假死物体还能挡住网络弹道或卡牌拖拽判定）
	_set_all_collisions(target_node, false)
	
func _set_all_collisions(root_node: Node, enabled: bool) -> void:
	# 遍历目标节点下的所有子节点，把碰撞体全部禁用/启用
	for child in root_node.get_children():
		if child is CollisionShape2D or child is CollisionPolygon2D:
			child.set_deferred("disabled", !enabled)
		# 递归向下查找（比如卡牌内部嵌套的复合节点）
		if child.get_child_count() > 0:
			_set_all_collisions(child, enabled)
			
func Revive(target_node: Node) -> void:
	if not is_instance_valid(target_node):
		return
		
	# 1. 恢复画面显示
	if target_node is CanvasItem:
		target_node.visible = true
		
	# 2. 恢复鼠标接收
	if target_node is Control:
		target_node.mouse_filter = Control.MOUSE_FILTER_STOP # 或者是 MOUSE_FILTER_PASS，取决于你原厂设置
		
	# 3. 恢复物理碰撞
	_set_all_collisions(target_node, true)
	
	# 4. 最后一步：接回逻辑心跳。强制恢复和父节点一样的处理模式（通常是 INHERIT 恢复正常）
	target_node.process_mode = Node.PROCESS_MODE_INHERIT
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	

























#endregion

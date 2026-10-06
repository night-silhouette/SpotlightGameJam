class_name SaveManager
extends RefCounted

## =============================================================================
## SaveManager.gd - 5槽位游戏存档管理服务
## 提供最多 5 个独立存档槽位的新建、载入、删除及元数据查询。
## 严格只收集与还原实体对象（具备 ExportSaveData / LoadSaveData）的数据，
## 绝不保存、改动或重置按键绑定。
## =============================================================================

const MAX_SLOTS: int = 5
const DEFAULT_PATH_PREFIX: String = "res://Code/Entities/Setting/Saves/save_slot_"

## 获取指定槽位的保存路径
## @param slot_index 槽位编号 (1 到 5)
static func GetSlotPath(slot_index: int) -> String:
	var prefix = DEFAULT_PATH_PREFIX
	var export_settings = Engine.get_singleton("ExportSettings") if Engine.has_singleton("ExportSettings") else null
	if not export_settings and Engine.get_main_loop() is SceneTree:
		var root = (Engine.get_main_loop() as SceneTree).root
		if root and root.has_node("ExportSettings"):
			export_settings = root.get_node("ExportSettings")
	if export_settings and "setting_save_path_prefix" in export_settings:
		prefix = export_settings.setting_save_path_prefix
	return "%s%d.json" % [prefix, slot_index]


## 检查指定槽位是否存在有效存档
## @param slot_index 槽位编号 (1 到 5)
static func HasSlot(slot_index: int) -> bool:
	if slot_index < 1 or slot_index > MAX_SLOTS:
		return false
	return FileAccess.file_exists(GetSlotPath(slot_index))

## 获取槽位简要信息
## @param slot_index 槽位编号 (1 到 5)
## @return 字典包含 exists, timestamp, player_hp, player_max_hp, desc 等信息
static func GetSlotInfo(slot_index: int) -> Dictionary:
	var res: Dictionary = {
		"slot_index": slot_index,
		"exists": false,
		"timestamp": "",
		"player_hp": 0.0,
		"player_max_hp": 0.0,
		"desc": "空存档位"
	}
	if not HasSlot(slot_index):
		return res
		
	var path = GetSlotPath(slot_index)
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		return res
	var content = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	if json.parse(content) != OK:
		return res
	var data = json.get_data()
	if not (data is Dictionary):
		return res
		
	res["exists"] = true
	res["timestamp"] = data.get("timestamp", "未知时间")
	var entities = data.get("entities", {})
	if entities is Dictionary:
		for node_path_str in entities.keys():
			var entity_data = entities[node_path_str]
			if entity_data is Dictionary and entity_data.has("now_hp"):
				res["player_hp"] = entity_data.get("now_hp", 0.0)
				res["player_max_hp"] = entity_data.get("max_hp", 200.0)
				break
	res["desc"] = "存档 %d - %s" % [slot_index, res["timestamp"]]
	return res

## 获取所有5个槽位的概要列表
static func GetAllSlotsInfo() -> Array[Dictionary]:
	var list: Array[Dictionary] = []
	for i in range(1, MAX_SLOTS + 1):
		list.append(GetSlotInfo(i))
	return list

## 创建新存档并直接切换载入至目标场景（如 World.tscn）
## @param tree 场景树 SceneTree
## @param slot_index 槽位编号 (1 到 5)
## @param target_scene_path 目标场景路径 (留空时取 ExportSettings.start_menu_world_scene_path)
static func StartNewGameInSlot(tree: SceneTree, slot_index: int, target_scene_path: String = "") -> bool:
	if slot_index < 1 or slot_index > MAX_SLOTS or not tree:
		return false
	
	var world_path = target_scene_path
	if world_path == "":
		world_path = "res://Code/Entities/World/World.tscn"
		if ExportSettings and "start_menu_world_scene_path" in ExportSettings:
			world_path = ExportSettings.start_menu_world_scene_path
	
	if not ResourceLoader.exists(world_path):
		push_error("StartNewGameInSlot 目标场景不存在: %s" % world_path)
		return false

	var current_datetime = Time.get_datetime_dict_from_system()
	var time_str = "%04d-%02d-%02d %02d:%02d:%02d" % [
		current_datetime.year, current_datetime.month, current_datetime.day,
		current_datetime.hour, current_datetime.minute, current_datetime.second
	]

	var save_dict: Dictionary = {
		"slot_index": slot_index,
		"timestamp": time_str,
		"scene_path": world_path,
		"entities": {}
	}

	var path = GetSlotPath(slot_index)
	var base_dir = path.get_base_dir()
	if not DirAccess.dir_exists_absolute(base_dir):
		DirAccess.make_dir_recursive_absolute(base_dir)

	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_dict, "\t"))
		file.close()
		_emit_signal_bus("SaveSlotSaved", [slot_index])

	var err = tree.change_scene_to_file(world_path)
	if err == OK:
		_emit_signal_bus("SaveSlotLoaded", [slot_index])
		return true
	return false

## 保存/新建存档到指定槽位
## 递归查找场景树中所有实现了 ExportSaveData 的节点，收集其状态并写入
## @param tree 场景树 SceneTree
## @param slot_index 槽位编号 (1 到 5)
static func SaveToSlot(tree: SceneTree, slot_index: int) -> bool:
	if slot_index < 1 or slot_index > MAX_SLOTS or not tree:
		return false
		
	var root = tree.current_scene
	if not root:
		root = tree.root
		
	var entities_data: Dictionary = {}
	if root:
		_collect_save_data_recursive(root, root, entities_data)
	
	var current_datetime = Time.get_datetime_dict_from_system()
	var time_str = "%04d-%02d-%02d %02d:%02d:%02d" % [
		current_datetime.year, current_datetime.month, current_datetime.day,
		current_datetime.hour, current_datetime.minute, current_datetime.second
	]
	
	var scene_path = root.scene_file_path if (root and "scene_file_path" in root) else ""
	var save_dict: Dictionary = {
		"slot_index": slot_index,
		"timestamp": time_str,
		"scene_path": scene_path,
		"entities": entities_data
	}
	
	var path = GetSlotPath(slot_index)
	var base_dir = path.get_base_dir()
	if not DirAccess.dir_exists_absolute(base_dir):
		DirAccess.make_dir_recursive_absolute(base_dir)

	var file = FileAccess.open(path, FileAccess.WRITE)
	if not file:
		var err = FileAccess.get_open_error()
		push_error("SaveToSlot 无法写入文件 %s, 错误码: %d" % [path, err])
		return false


	file.store_string(JSON.stringify(save_dict, "\t"))
	file.close()
	
	_emit_signal_bus("SaveSlotSaved", [slot_index])
	return true



## 从指定槽位载入游戏状态
## @param tree 场景树 SceneTree
## @param slot_index 槽位编号 (1 到 5)
static func LoadFromSlot(tree: SceneTree, slot_index: int) -> bool:
	if not HasSlot(slot_index) or not tree:
		return false
		
	var path = GetSlotPath(slot_index)
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		return false
	var content = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	if json.parse(content) != OK:
		return false
	var data = json.get_data()
	if not (data is Dictionary):
		return false
		
	var entities_data = data.get("entities", {})
	if not (entities_data is Dictionary):
		return false
		
	var root = tree.current_scene
	if not root:
		root = tree.root

	# 1. 检查存档所记录的原始场景路径
	var saved_scene_path: String = data.get("scene_path", "")
	# 如果存档里的 scene_path 为空或指向已被废弃场景，兜底为 World.tscn
	var default_world_path = "res://Code/Entities/World/World.tscn"
	if ExportSettings and "start_menu_world_scene_path" in ExportSettings:
		default_world_path = ExportSettings.start_menu_world_scene_path
	if saved_scene_path == "" or not ResourceLoader.exists(saved_scene_path):
		saved_scene_path = default_world_path

	var current_scene_path: String = root.scene_file_path if (root and "scene_file_path" in root) else ""

	# 2. 如果当前场景与存档保存的场景不一致，且存档场景文件有效，则先切换场景
	if saved_scene_path != "" and saved_scene_path != current_scene_path and ResourceLoader.exists(saved_scene_path):
		var err = tree.change_scene_to_file(saved_scene_path)
		if err == OK:
			# 等待新场景实例化就绪后，恢复数据
			_wait_and_apply_scene(tree, entities_data, slot_index)
			return true

	# 3. 若同场景或直接在当前场景恢复，执行双重匹配（相对路径 + 实体全局/类型兜底）
	_apply_save_data_smart(root, entities_data)
	
	_emit_signal_bus("SaveSlotLoaded", [slot_index])
	return true

## 延迟等待新场景就绪并还原
static func _wait_and_apply_scene(tree: SceneTree, entities_data: Dictionary, slot_index: int) -> void:
	await tree.process_frame
	await tree.process_frame
	var new_root = tree.current_scene
	if not new_root:
		new_root = tree.root
	_apply_save_data_smart(new_root, entities_data)
	_emit_signal_bus("SaveSlotLoaded", [slot_index])

## 智能实体匹配与数据应用
## 优先使用相对节点路径精准匹配；若场景结构变化（如放入了 PlayerWithCamera 或别的父节点），自动使用节点名/实体类别/特征进行兜底匹配
static func _apply_save_data_smart(root: Node, entities_data: Dictionary) -> void:
	if not root or entities_data.is_empty():
		return

	# 先收集当前场景树中所有具备 LoadSaveData 的节点
	var current_entities: Array[Node] = []
	_gather_entities_recursive(root, current_entities)

	var applied_nodes: Array[Node] = []

	# 1. 第一轮：相对路径精准匹配
	for rel_path in entities_data.keys():
		var node = root.get_node_or_null(rel_path)
		if is_instance_valid(node) and node.has_method("LoadSaveData"):
			node.call("LoadSaveData", entities_data[rel_path])
			applied_nodes.append(node)

	# 2. 第二轮：对未精准匹配到的数据进行节点名/类型兜底匹配（例如 Player、Tent 等）
	for rel_path in entities_data.keys():
		var data = entities_data[rel_path]
		var path_node_name = rel_path.get_file() # 获取末级节点名称，如 "Player"

		for candidate in current_entities:
			if candidate in applied_nodes:
				continue
			
			var is_match = false
			# 规则 A: 节点名称完全相同 (例如两者都叫 Player)
			if candidate.name == path_node_name:
				is_match = true
			# 规则 B: 候选者为 Player 且存档数据包含 player 特征 (now_hp / respawn_x)
			elif (candidate is CharacterBody2D or candidate.is_in_group("player")) and data.has("now_hp") and data.has("respawn_x"):
				is_match = true
			# 规则 C: 候选者与数据具有相同位置或者帐篷特征
			elif candidate.is_in_group("tent") and data.has("is_active"):
				# 同名或者同类型帐篷
				if candidate.name == path_node_name:
					is_match = true

			if is_match:
				candidate.call("LoadSaveData", data)
				applied_nodes.append(candidate)
				break

static func _gather_entities_recursive(node: Node, out_list: Array[Node]) -> void:
	if not is_instance_valid(node):
		return
	if node.has_method("LoadSaveData"):
		out_list.append(node)
	for child in node.get_children():
		_gather_entities_recursive(child, out_list)


## 删除指定槽位存档
## @param slot_index 槽位编号 (1 到 5)
static func DeleteSlot(slot_index: int) -> bool:
	if not HasSlot(slot_index):
		return false
	var path = GetSlotPath(slot_index)
	var err = DirAccess.remove_absolute(path)
	if err == OK:
		_emit_signal_bus("SaveSlotDeleted", [slot_index])
		return true
	return false

static func _emit_signal_bus(sig_name: StringName, args: Array) -> void:
	var bus = Engine.get_singleton("SignalBus") if Engine.has_singleton("SignalBus") else null
	if not bus and Engine.get_main_loop() is SceneTree:
		var r = (Engine.get_main_loop() as SceneTree).root
		if r and r.has_node("SignalBus"):
			bus = r.get_node("SignalBus")
	if bus and bus.has_signal(sig_name):
		bus.callv("emit_signal", [sig_name] + args)


## 递归收集实现了 ExportSaveData 的节点
static func _collect_save_data_recursive(node: Node, root: Node, out_dict: Dictionary) -> void:
	if not is_instance_valid(node):
		return
	if node.has_method("ExportSaveData"):
		var rel_path = String(root.get_path_to(node))
		var data = node.call("ExportSaveData")
		if data is Dictionary:
			out_dict[rel_path] = data
			
	for child in node.get_children():
		_collect_save_data_recursive(child, root, out_dict)

## 递归根据相对路径查找并调用 LoadSaveData
static func _apply_save_data_recursive(node: Node, root: Node, in_dict: Dictionary) -> void:
	if not is_instance_valid(node):
		return
	var rel_path = String(root.get_path_to(node))
	if in_dict.has(rel_path) and node.has_method("LoadSaveData"):
		var data = in_dict[rel_path]
		if data is Dictionary:
			node.call("LoadSaveData", data)
			
	for child in node.get_children():
		_apply_save_data_recursive(child, root, in_dict)

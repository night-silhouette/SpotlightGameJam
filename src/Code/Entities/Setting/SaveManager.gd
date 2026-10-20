class_name SaveManager
extends RefCounted

## 五槽位实体存档服务；游戏状态与独立按键绑定互不影响。
const MAX_SLOTS: int = 5
const DEFAULT_PATH_PREFIX: String = "user://Saves/save_slot_"
const LEGACY_PATH_PREFIX: String = "res://Code/Entities/Setting/Saves/save_slot_"
const SCENE_TRANSITION_COVER = preload("res://Code/Entities/Setting/SceneTransitionCover.tscn")

static var active_slot: int = 1
static var _changing_scene: bool = false
static var _world_scene_path: String = ""
static var _world_scene: PackedScene = null
static var _scene_requests: Dictionary = {}

## 返回当前活跃槽位编号，未设置时返回1。
static func GetActiveSlot() -> int:
	return active_slot if active_slot > 0 else 1

## 设置活跃槽位；slot_index 必须在1至5之间。
static func SetActiveSlot(slot_index: int) -> void:
	if slot_index >= 1 and slot_index <= MAX_SLOTS:
		active_slot = slot_index

## 保存当前场景至活跃槽位；tree 为场景树，返回写盘是否成功。
static func AutoSave(tree: SceneTree) -> bool:
	return SaveToSlot(tree, GetActiveSlot())

## 返回slot_index（1至5）的可写路径；只接受user://前缀，旧res://配置回退默认值。
static func GetSlotPath(slot_index: int) -> String:
	var prefix = ExportSettings.setting_save_path_prefix
	if not prefix.begins_with("user://") or "/../" in prefix:
		prefix = DEFAULT_PATH_PREFIX
	return "%s%d.json" % [prefix, slot_index]

static func _get_read_path(slot_index: int) -> String:
	var path = GetSlotPath(slot_index)
	if FileAccess.file_exists(path):
		return path
	if FileAccess.file_exists(path + ".deleted"):
		return ""
	var legacy_path = "%s%d.json" % [LEGACY_PATH_PREFIX, slot_index]
	return legacy_path if FileAccess.file_exists(legacy_path) else ""

## 检查slot_index（1至5）是否有档案文件；损坏档案由载入时校验。
static func HasSlot(slot_index: int) -> bool:
	return slot_index >= 1 and slot_index <= MAX_SLOTS and _get_read_path(slot_index) != ""

static func _read_slot(slot_index: int) -> Dictionary:
	if not HasSlot(slot_index):
		return {}
	var file = FileAccess.open(_get_read_path(slot_index), FileAccess.READ)
	if not file:
		return {}
	var json = JSON.new()
	var error = json.parse(file.get_as_text())
	file.close()
	if error != OK or not json.data is Dictionary:
		return {}
	var data: Dictionary = json.data
	if not data.get("entities") is Dictionary or not data.get("scene_path", "") is String:
		return {}
	if not data.get("timestamp", "") is String:
		return {}
	for path in data.entities:
		if not path is String or path.is_empty() or path.begins_with("/") or ":" in path or ".." in path.split("/"):
			return {}
		if not data.entities[path] is Dictionary:
			return {}
	return data

## 返回slot_index（1至5）的存在状态、时间、玩家生命值及描述；损坏档保留可删除入口。
static func GetSlotInfo(slot_index: int) -> Dictionary:
	var info: Dictionary = {"slot_index": slot_index, "exists": HasSlot(slot_index), "timestamp": "", "player_hp": 0.0, "player_max_hp": 0.0, "desc": "空存档位"}
	var data = _read_slot(slot_index)
	if data.is_empty():
		if info.exists:
			info.desc = "存档损坏，请覆写或删除"
		return info
	info.timestamp = data.get("timestamp", "未知时间")
	for entity_data in data.entities.values():
		if entity_data.has("now_hp"):
			var hp = entity_data.get("now_hp", 0.0)
			var max_hp = entity_data.get("max_hp", 200.0)
			if (hp is float or hp is int) and (max_hp is float or max_hp is int):
				info.player_hp = hp
				info.player_max_hp = max_hp
			break
	info.desc = "存档 %d - %s" % [slot_index, info.timestamp]
	return info

## 返回全部五个槽位的概要列表。
static func GetAllSlotsInfo() -> Array[Dictionary]:
	var list: Array[Dictionary] = []
	for i in range(1, MAX_SLOTS + 1):
		list.append(GetSlotInfo(i))
	return list

## 检查全部有效槽位的第五章实体完成状态；遵循删除标记，不依赖活跃槽或永久全局标记。
static func HasCompletedSlot() -> bool:
	for slot_index in range(1, MAX_SLOTS + 1):
		var data := _read_slot(slot_index)
		for path in data.get("entities", {}):
			if String(path).get_file() == "Chapter5" and data.entities[path].get("completed") == true:
				return true
	return false

static func _make_save_data(slot_index: int, scene_path: String, entities: Dictionary) -> Dictionary:
	return {"slot_index": slot_index, "timestamp": Time.get_datetime_string_from_system(false, true), "scene_path": scene_path, "entities": entities}

static func _write_atomic(path: String, data: Dictionary) -> bool:
	var error = DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	if error != OK:
		return false
	var temporary_path = path + ".tmp"
	var file = FileAccess.open(temporary_path, FileAccess.WRITE)
	if not file:
		return false
	file.store_string(JSON.stringify(data, "\t"))
	file.flush()
	var write_error = file.get_error()
	file.close()
	if write_error != OK:
		DirAccess.remove_absolute(temporary_path)
		return false
	if DirAccess.rename_absolute(temporary_path, path) != OK:
		DirAccess.remove_absolute(temporary_path)
		return false
	return true

## 后台预加载配置的World及其传递依赖；不实例化场景、不触发剧情或存档。
## tree 为当前场景树，仅用于非阻塞等待资源线程完成。
static func PreloadWorld(tree: SceneTree) -> void:
	if not tree:
		return
	await _load_scene_async(tree, _get_configured_world_path())

## 新建slot_index（1至5）并进入target_scene_path（空时取配置）；可等待intro_tween。
## 必须await；返回true时场景已就绪并发出SaveSlotLoaded，失败不切换活跃槽位。
static func StartNewGameInSlot(tree: SceneTree, slot_index: int, target_scene_path: String = "", intro_tween: Tween = null) -> bool:
	if _changing_scene or not tree or slot_index < 1 or slot_index > MAX_SLOTS:
		return false
	var world_path = target_scene_path if target_scene_path != "" else _get_configured_world_path()
	_changing_scene = true
	var scene: PackedScene = await _load_scene_async(tree, world_path)
	if not scene or not scene.can_instantiate():
		_changing_scene = false
		return false
	if intro_tween != null and intro_tween.is_running():
		await intro_tween.finished
	if not _write_atomic(GetSlotPath(slot_index), _make_save_data(slot_index, world_path, {})):
		_changing_scene = false
		return false
	_emit_signal_bus("SaveSlotSaved", [slot_index])
	return await _change_and_apply(tree, scene, {}, slot_index)

## 收集tree当前场景实体并原子保存至slot_index（1至5）；写盘成功才切换活跃槽位。
static func SaveToSlot(tree: SceneTree, slot_index: int) -> bool:
	if _changing_scene or not tree or slot_index < 1 or slot_index > MAX_SLOTS:
		return false
	var root = tree.current_scene
	if not root:
		return false
	var entities: Dictionary = {}
	_collect_save_data_recursive(root, root, entities)
	if not _write_atomic(GetSlotPath(slot_index), _make_save_data(slot_index, root.scene_file_path, entities)):
		return false
	SetActiveSlot(slot_index)
	_emit_signal_bus("SaveSlotSaved", [slot_index])
	return true

## 重新实例化slot_index（1至5）的存档场景并恢复实体，避免残留已删除实体和瞬态。
## 必须await；返回true表示场景就绪、数据应用完成；失败不修改活跃槽位。
static func LoadFromSlot(tree: SceneTree, slot_index: int) -> bool:
	if _changing_scene or not tree:
		return false
	var data = _read_slot(slot_index)
	if data.is_empty():
		return false
	var scene_path: String = data.get("scene_path", "")
	if scene_path == "" or not ResourceLoader.exists(scene_path, "PackedScene"):
		scene_path = _get_configured_world_path()
	_changing_scene = true
	var scene: PackedScene = await _load_scene_async(tree, scene_path)
	if not scene or not scene.can_instantiate():
		_changing_scene = false
		return false
	return await _change_and_apply(tree, scene, data.entities, slot_index)

static func _get_configured_world_path() -> String:
	var path: String = ExportSettings.start_menu_world_scene_path
	if path != _world_scene_path:
		_world_scene_path = path
		_world_scene = null
	return path

static func _load_scene_async(tree: SceneTree, scene_path: String) -> PackedScene:
	if not tree or scene_path == "" or not ResourceLoader.exists(scene_path, "PackedScene"):
		return null
	var configured_path := _get_configured_world_path()
	if scene_path == configured_path and _world_scene:
		return _world_scene
	if _scene_requests.has(scene_path):
		var pending: Dictionary = _scene_requests[scene_path]
		while not pending.done:
			await tree.process_frame
		return pending.scene
	# 每个路径只有请求拥有者取走线程结果；等待者持有同一个结果字典。
	var request: Dictionary = {"done": false, "scene": null}
	_scene_requests[scene_path] = request
	var scene: PackedScene = await _request_scene_async(tree, scene_path)
	if scene_path == _get_configured_world_path():
		_world_scene = scene
	request.scene = scene
	request.done = true
	_scene_requests.erase(scene_path)
	return scene

static func _request_scene_async(tree: SceneTree, scene_path: String) -> PackedScene:
	var status := ResourceLoader.load_threaded_get_status(scene_path)
	if status != ResourceLoader.THREAD_LOAD_IN_PROGRESS and status != ResourceLoader.THREAD_LOAD_LOADED:
		var request_error := ResourceLoader.load_threaded_request(scene_path, "PackedScene")
		if request_error != OK:
			status = ResourceLoader.load_threaded_get_status(scene_path)
			if status != ResourceLoader.THREAD_LOAD_IN_PROGRESS and status != ResourceLoader.THREAD_LOAD_LOADED:
				return null
	while ResourceLoader.load_threaded_get_status(scene_path) == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		await tree.process_frame
	status = ResourceLoader.load_threaded_get_status(scene_path)
	if status != ResourceLoader.THREAD_LOAD_LOADED:
		if status == ResourceLoader.THREAD_LOAD_FAILED:
			ResourceLoader.load_threaded_get(scene_path)
		return null
	return ResourceLoader.load_threaded_get(scene_path) as PackedScene

static func _change_and_apply(tree: SceneTree, scene: PackedScene, entities: Dictionary, slot_index: int) -> bool:
	var cover := SCENE_TRANSITION_COVER.instantiate()
	# 不属于current_scene，旧菜单销毁时仍覆盖整个视口；先确认黑幕实际绘制。
	tree.root.add_child(cover)
	await tree.process_frame
	await RenderingServer.frame_post_draw
	if tree.change_scene_to_packed(scene) != OK:
		cover.free()
		_changing_scene = false
		return false
	# 静态服务持有协程，不依赖即将释放的菜单/设置节点继续执行。
	await tree.scene_changed
	await tree.process_frame
	await tree.process_frame
	var root = tree.current_scene
	if not is_instance_valid(root):
		cover.free()
		_changing_scene = false
		return false
	if not _apply_save_data_smart(root, entities):
		cover.free()
		_changing_scene = false
		return false
	SetActiveSlot(slot_index)
	_emit_signal_bus("SaveSlotLoaded", [slot_index])
	# 包含读档信号触发的延迟恢复，直至新场景真实绘制后才交还OpeningFade。
	await tree.process_frame
	await RenderingServer.frame_post_draw
	cover.free()
	_changing_scene = false
	return true

## 对root应用entities_data；相对路径优先、节点名/玩家特征兜底，每条数据最多消费一次。
static func _apply_save_data_smart(root: Node, entities_data: Dictionary) -> bool:
	if not is_instance_valid(root):
		return false
	var current_entities: Array[Node] = []
	_gather_entities_recursive(root, current_entities)
	var matches: Dictionary = {}
	var applied_nodes: Array[Node] = []
	for rel_path in entities_data:
		if not rel_path is String or not entities_data[rel_path] is Dictionary:
			return false
		var node = root.get_node_or_null(NodePath(rel_path))
		if node in current_entities and not node in applied_nodes:
			matches[rel_path] = node
			applied_nodes.append(node)
	for rel_path in entities_data:
		if matches.has(rel_path):
			continue
		var data: Dictionary = entities_data[rel_path]
		for candidate in current_entities:
			if candidate in applied_nodes:
				continue
			if candidate.name == rel_path.get_file() or ((candidate is CharacterBody2D or candidate.is_in_group("player")) and data.has("now_hp") and data.has("respawn_x")):
				matches[rel_path] = candidate
				applied_nodes.append(candidate)
				break
	# 在调用任何实体恢复方法前，按实体自身导出的字段类型检查，兼容JSON数字统一为float。
	for rel_path in matches:
		var node: Node = matches[rel_path]
		if node.has_method("ExportSaveData"):
			var template = node.call("ExportSaveData")
			if template is Dictionary and not _matches_types(entities_data[rel_path], template):
				return false
	for rel_path in matches:
		matches[rel_path].call("LoadSaveData", entities_data[rel_path])
	return true

static func _matches_types(data: Dictionary, template: Dictionary) -> bool:
	for key in data:
		if not template.has(key):
			continue
		var value = data[key]
		var expected = template[key]
		if (expected is int or expected is float) and (value is int or value is float):
			if not is_finite(float(value)):
				return false
		elif expected is String or expected is StringName:
			if not value is String:
				return false
		elif typeof(value) != typeof(expected):
			return false
		elif value is Dictionary and not _matches_types(value, expected):
			return false
	return true

static func _gather_entities_recursive(node: Node, out_list: Array[Node]) -> void:
	if not is_instance_valid(node) or node.is_queued_for_deletion():
		return
	if node.has_method("LoadSaveData"):
		out_list.append(node)
	for child in node.get_children():
		_gather_entities_recursive(child, out_list)

## 删除slot_index（1至5）的可写档案；先写删除标记屏蔽只读旧档，永不修改res://原档。
## 返回是否成功；之后同槽新存档优先于删除标记。
static func DeleteSlot(slot_index: int) -> bool:
	if _changing_scene or not HasSlot(slot_index):
		return false
	var path = GetSlotPath(slot_index)
	if not _write_atomic(path + ".deleted", {"deleted": true}):
		return false
	if FileAccess.file_exists(path) and DirAccess.remove_absolute(path) != OK:
		return false
	_emit_signal_bus("SaveSlotDeleted", [slot_index])
	return true

static func _emit_signal_bus(sig_name: StringName, args: Array) -> void:
	var tree = Engine.get_main_loop() as SceneTree
	var bus = tree.root.get_node_or_null("SignalBus") if tree else null
	if bus and bus.has_signal(sig_name):
		bus.callv("emit_signal", [sig_name] + args)

static func _collect_save_data_recursive(node: Node, root: Node, out_dict: Dictionary) -> void:
	if not is_instance_valid(node) or node.is_queued_for_deletion():
		return
	if node.has_method("ExportSaveData"):
		var data = node.call("ExportSaveData")
		if data is Dictionary:
			out_dict[String(root.get_path_to(node))] = data
	for child in node.get_children():
		_collect_save_data_recursive(child, root, out_dict)

## 按相对路径对root还原in_dict，保留既有测试入口；node为遍历起点。
static func _apply_save_data_recursive(node: Node, root: Node, in_dict: Dictionary) -> void:
	if not is_instance_valid(node):
		return
	var rel_path = String(root.get_path_to(node))
	if in_dict.get(rel_path) is Dictionary and node.has_method("LoadSaveData"):
		node.call("LoadSaveData", in_dict[rel_path])
	for child in node.get_children():
		_apply_save_data_recursive(child, root, in_dict)

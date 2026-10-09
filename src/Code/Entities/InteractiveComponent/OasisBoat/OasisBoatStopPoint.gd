class_name OasisBoatStopPoint
extends Resource

## 停靠点的路线进度（取值 0.0 ~ 1.0，对应 PathFollow2D 的 progress_ratio）。
@export_range(0.0, 1.0, 0.001) var progress_ratio: float = 0.0

## 该停靠点的标识名称（方便外部通过名字触发解密完成或查询）。
@export var point_id: String = ""

## 是否需要玩家在船上才允许离开此站。
@export var require_player_on_board: bool = true

## 是否需要解密/机关开启信号（puzzle_solved）才放行。
@export var require_puzzle_solved: bool = false

## 到达该停靠点后的基础等待停泊时间（秒，<=0 表示不停留直接根据上述条件放行）。
@export var wait_time: float = 0.0

## 人船分流模式标志：到达此站后是否属于“舟先到此等待玩家”的集结点。
@export var is_player_rendezvous_point: bool = false

## 运行时状态：外部机关是否已解密放行。
var is_puzzle_solved: bool = false

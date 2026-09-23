class_name StatueAttackConfig
extends Resource

enum FireMode { AIM_AT_FOX, CONFIGURED_VOLLEY }

@export_category("雕塑射击")
@export var fire_mode := FireMode.AIM_AT_FOX
@export_range(0.0, 10.0, 0.05) var first_shot_delay := 0.8
@export_range(0.1, 10.0, 0.05) var attack_interval := 1.8
@export_range(0.0, 1600.0, 10.0) var aimed_speed := 320.0
@export_range(-1200.0, 1200.0, 10.0) var aimed_acceleration := 0.0
## 编排模式的一轮齐射；所有条目在同一物理帧生成。
@export var volley: Array[StatueShotEntry] = []

class_name CorpseImpactConfig
extends Resource

@export_category("尸体冲击")
@export_range(40.0, 1600.0, 10.0) var speed := 520.0
@export_range(4.0, 64.0, 1.0) var radius := 16.0
@export_range(0.1, 10.0, 0.1) var lifetime := 2.5
@export_range(-180.0, 180.0, 1.0) var straight_angle_offset_degrees := 14.0
@export_range(0, 256, 1) var maximum_marks := 32
@export_range(0.1, 30.0, 0.1) var mark_lifetime := 6.0
## Prototype 默认碎屑色，也可改成血迹色。
@export var mark_color := Color(0.58, 0.53, 0.46, 0.72)

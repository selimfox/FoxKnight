class_name StatueShotEntry
extends Resource

## 一轮编排齐射中的单枚子弹。角度遵循 Godot 2D：0° 向右，90° 向下。
@export_category("编排子弹")
@export_range(-360.0, 360.0, 1.0) var angle_degrees := 0.0
@export_range(0.0, 1600.0, 10.0) var speed := 300.0
## 沿飞行方向加速；负值只会减速到零。
@export_range(-1200.0, 1200.0, 10.0) var acceleration := 0.0

class_name ChainLockConfig
extends Resource

@export_category("天之锁")
## InputMap 动作名，可在项目设置中改键。
@export var input_action: StringName = &"heaven_chain"
@export_range(100.0, 2000.0, 10.0) var projectile_speed := 720.0
@export_range(40.0, 1600.0, 10.0) var maximum_range := 540.0
## 重复命中刷新为完整时长，不叠加。
@export_range(0.1, 10.0, 0.1) var bind_duration := 2.0
## 从发射时开始计算。
@export_range(0.0, 20.0, 0.1) var cooldown := 4.0
@export_range(2.0, 40.0, 1.0) var projectile_radius := 8.0

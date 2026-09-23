class_name SlashChainConfig
extends Resource

@export_category("衔接斩击")
@export_range(1, 20, 1) var direct_kills_required := 1
@export_range(0.0, 1.0, 0.01) var selection_time_scale := 0.08
## 使用真实时间计时，不受时间倍率影响。
@export_range(0.1, 10.0, 0.1) var selection_duration_real_seconds := 2.0
@export_range(0.0, 1.0, 0.01) var restore_duration_real_seconds := 0.12

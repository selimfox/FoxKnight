# v0.3 关卡编辑指南（白模）

在 Godot 中打开 `scenes/prototype/v03/level_01.tscn`。新关卡可复制此场景另存于 `scenes/prototype/v03/`，保持 `V03Level`、`Terrain/Floor`、`Terrain/Walls`、`Actors/Player`、`Actors/Statues`、`Effects`、`HUD/Status` 与 `HUD/Result` 节点路径。

地形：选 `Floor` 或 `Walls`，用 Godot TileMapLayer 绘笔直接画/擦格子。Floor 有格且 Walls 无格才可走；Walls 有格便阻挡直斩与弹体。无需编辑脚本中的坐标列表。圆斩是纯半径，按 GDD 约定可以斩中隔墙目标；不要把墙当作圆斩掩体。绘制后运行关卡，确认狐狸出生点有地板、无墙，外围不会让玩家走出地图。

雕塑：将 `scenes/actors/v03/statue.tscn` 拖到 `Actors/Statues`，或复制现有雕塑并调整其位置/父节点。运行时按 `v03_statue` 分组和世界位置自动发现，增删无需登记。Inspector 的 `Attack` 可新建 `StatueAttackConfig`：AIM_AT_FOX 在发射瞬间瞄准；CONFIGURED_VOLLEY 的 `Volley` 列表中逐个新建 `StatueShotEntry`，分别配置角度、初速与加速度。StatueB 是可直接检查的双弹示例。0° 向右、90° 向下；节点旋转会作用于编排角度。

关卡根节点 Inspector 可新建/展开 `Lock Config`、`Chain Config`、`Corpse Config`，调整锁弹射程/速度/冷却/禁锢、续斩直接击杀阈值与真实时间窗口/倍率、尸体速度/半径/寿命/直斩偏角/痕迹。根节点另有圆斩半径、直斩距离与宽度、执行时长。若留空则运行时创建默认 Resource；要保存可编辑数值，务必在 Inspector 新建资源并保存场景。`heaven_chain` 动作默认 E，可在 Project Settings → Input Map 改键；R 重试。

编辑后至少检查：地面改画即时影响通行；墙即时阻挡直斩/弹体；增删雕塑更新敌数；移动 `Actors/Statues` 父节点后锁弹与命中仍对准新的世界位置；结果后 R 重试清理弹体与痕迹。命令行可运行 `godot --headless --path . --script res://tests/acceptance/v03_acceptance_runner.gd`，但它不能代替窗口可读性检查。

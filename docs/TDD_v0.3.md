# 《狐狸骑士》技术设计 v0.3

| 字段 | 内容 |
| --- | --- |
| 对应设计 | `docs/GDD.md` v0.3（2026-09-23 已确认范围） |
| 阶段 | Prototype 白模实现与功能验收 |
| 更新日期 | 2026-09-24 |

本文件只描述当前实现，不定义玩法；玩法、验收边界以 GDD 为准。v0.1、v0.2 场景与 TDD 保留为历史基线，不由新入口加载。

## 入口与结构

- `project.godot` 的主场景是 `scenes/prototype/v03/level_01.tscn`。编辑器须打开这份 v0.3 场景才能看到当前编排；同名的 `scenes/prototype/v02/level_01.tscn` 是保留的旧版场景，不由主入口运行。新场景复用既有 `PlayerController` 与狐狸素材，不依赖 v0.2 场景运行。
- `V03Level` (`scripts/prototype/v03/level.gd`) 拥有唯一的战斗状态、胜负结算、锁弹/尸体与斩断敌弹判定及地形查询。`V03Statue` (`scripts/actors/v03/statue.gd`) 只管理自身生命、禁锢计时和射击；`V03Projectile` (`scripts/combat/v03/projectile.gd`) 管理敌弹、锁弹、尸体三种投射物，碰撞由 Level 执行分段扫掠。
- `scripts/resources/v03/` 的四类配置资源与 `StatueShotEntry` 暴露锁链、续斩、尸体、雕塑弹幕参数。雕塑 `attack` 可在 Inspector 配 AIM_AT_FOX 或 CONFIGURED_VOLLEY；示例板 StatueB 已配置两枚类型化编排弹。
- 地形是 `Terrain/Floor` 与 `Terrain/Walls` 两个原生 `TileMapLayer`，共享 `assets/v03/terrain.tres`。Level 以各层实时格子读取判定地面、墙与弹体阻挡，不维护手填格子登记表。演员位置和父节点变换使用 `global_position`。

## 状态与事件顺序

`OBSERVING → AIMING → EXECUTING → CHOOSING/WAITING → EXECUTING/RESOLVED`。按住左键预览；松开执行首刀。符合本刀直接斩杀阈值时进入 CHOOSING，下一次新点击确认异刀型；未确认则真实时钟截止后退出。圆/直交替由上一刀型确定，不储存超额直杀数。CHOOSING 可为暂停倍率 0 或慢速，计时采用 `Time.get_ticks_usec()`；退出以可配置的真实时间插值恢复 `Engine.time_scale`。重试及退出场景强制复位倍率。

每次 `_start_slash` 先统一计算本刀直接击杀，再产生尸体；物理步中分段扫掠弹体，并在刀区消除敌弹，不创建友弹。直杀计数只在 `_kill_statue(..., true, ...)` 增加；尸体击杀传 `false`，消弹不调用击杀计数。尸体击中时先生成下一尸体再消耗前驱，结算用延后检查避免短暂空列表。最后一个敌人被直接杀死时，胜利推迟到本刀执行结束；结果一旦确定即不可覆盖，雕塑与投射物停止物理更新。

玩家在执行/选择期不可被敌弹杀伤，选择期禁移动与锁；连锁等待期可移动但不可普通再出刀。地形查询与直斩预览使用最终 authored 位置；直斩位移在 `slash_duration` 内补间，非瞬时传送。圆斩保持 GDD 确认的纯圆形命中，不做墙遮挡裁剪；尸体和普通弹受墙阻挡。

## 白模表现与可调项

锁弹绘制链节与箭头，雕塑禁锢绘制高亮环/链节/剩余时间环；雕塑场景使用编辑器内可见的 `Polygon2D` 人形石像部件，不再仅由运行时圆形 `_draw()` 占位。敌弹为暖色圆核及尾迹，斩断时显示短暂消弹闪光；不再绘制冷色友弹。尸体投射物复用雕塑的 `Sculpture` 人形部件作为飞行视觉，不再画灰色裂纹圆球；运动仍由尸体投射物处理。

`V03ImpactMark` 与 `V03ImpactVfx` 绘制地面/墙面的鲜红痕迹与飞溅；颜色由 `CorpseImpactConfig.mark_color` 调整，数量和寿命受既有配置约束。痕迹不参与碰撞或胜败。`V03FoxAura`、场景内 `ChoiceShade` 与 `HUD/ChoicePrompt` 共同突出 CHOOSING，保留狐狸、敌人及强制刀型预览的可见性。瞄准 HUD 以 `_point_in_area()` 共用实际刀区几何预告当前直接命中数；直斩预告同样经过墙边可位移距离计算。执行/选择 HUD 只显示本刀真实直接击杀数，不把消弹或尸体击杀计入 N。上述均为原生原型表现，尚非最终美术。关卡编辑步骤见 `docs/guides/v03_level_editing.md`。

## 验证映射与剩余风险

`tests/acceptance/v03_acceptance_runner.gd` 使用 Godot 4.7.1 运行，本轮 67 项确定性检查全通过；覆盖 AC-01~10 的核心状态、碰撞与动态编辑，包括增删雕塑、父节点位移、地块改画、锁首目标/墙/射程、直杀门槛、连续三刀、真实超时、高速扫掠消弹、模拟 E→首刀→续斩输入、迟到尸体全灭、重试清理与结果冻结，并核对预告直杀进度、选择提示/遮罩、墙面血迹节点、飞行尸体的人形节点及消弹不产生派生攻击。输入流程测试显式设置 N=1；作者场景配置的 N=3 未改。`tests/acceptance/v03_readability_capture.gd` 用图形窗口捕获普通、瞄准、尸体飞行、消弹、续斩五阶段以供目测；截图仅是局部画面证据，尸体飞行截图使用单独放置的视觉测试投射物。v0.1 历史 smoke acceptance 曾通过，不作为本轮重新执行的结论。

这些检查不等同每项 AC 的完整视觉验收或主观体验验证。尚需创作者在实际操作中核对锁链、消弹反馈、人形尸体飞行、血迹与连斩窗口的辨识和节奏；尤其在高弹量时测试分段扫掠性能，并确认编辑器 Inspector 参数工作流。每个尸体当前通过临时实例化雕塑场景并复制其视觉节点，仍属原型实现，密集连锁的开销未测。既有 v0.1 回归与 v0.2 用户改动场景不可被本版通过替代。体验是否有趣/有主动塑形感必须由试玩记录单独判断。

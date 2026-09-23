# 《狐狸骑士》技术设计 v0.3

| 字段 | 内容 |
| --- | --- |
| 对应设计 | `docs/GDD.md` v0.3（2026-09-23 已确认范围） |
| 阶段 | Prototype 白模实现与功能验收 |
| 更新日期 | 2026-09-24 |

本文件只描述当前实现，不定义玩法；玩法、验收边界以 GDD 为准。v0.1、v0.2 场景与 TDD 保留为历史基线，不由新入口加载。

## 入口与结构

- `project.godot` 的主场景是 `scenes/prototype/v03/level_01.tscn`。新场景是 v0.3 独立白模，复用既有 `PlayerController` 与狐狸素材，不依赖 v0.2 场景运行。
- `V03Level` (`scripts/prototype/v03/level.gd`) 拥有唯一的战斗状态、胜负结算、锁弹/尸体/反射派生及地形查询。`V03Statue` (`scripts/actors/v03/statue.gd`) 只管理自身生命、禁锢计时和射击；`V03Projectile` (`scripts/combat/v03/projectile.gd`) 管理四种弹体的移动和白模绘制，碰撞由 Level 执行分段扫掠。
- `scripts/resources/v03/` 的四类配置资源与 `StatueShotEntry` 暴露锁链、续斩、尸体、雕塑弹幕参数。雕塑 `attack` 可在 Inspector 配 AIM_AT_FOX 或 CONFIGURED_VOLLEY；示例板 StatueB 已配置两枚类型化编排弹。
- 地形是 `Terrain/Floor` 与 `Terrain/Walls` 两个原生 `TileMapLayer`，共享 `assets/v03/terrain.tres`。Level 以各层实时格子读取判定地面、墙与弹体阻挡，不维护手填格子登记表。演员位置和父节点变换使用 `global_position`。

## 状态与事件顺序

`OBSERVING → AIMING → EXECUTING → CHOOSING/WAITING → EXECUTING/RESOLVED`。按住左键预览；松开执行首刀。符合本刀直接斩杀阈值时进入 CHOOSING，下一次新点击确认异刀型；未确认则真实时钟截止后退出。圆/直交替由上一刀型确定，不储存超额直杀数。CHOOSING 可为暂停倍率 0 或慢速，计时采用 `Time.get_ticks_usec()`；退出以可配置的真实时间插值恢复 `Engine.time_scale`。重试及退出场景强制复位倍率。

每次 `_start_slash` 先统一计算本刀直接击杀，再产生尸体；物理步中分段扫掠弹体，并在刀区反射敌弹。直杀计数只在 `_kill_statue(..., true, ...)` 增加；弹体与尸体击杀始终传 `false`。尸体击中时先生成下一尸体再消耗前驱，结算用延后检查避免短暂空列表。最后一个敌人被直接杀死时，胜利推迟到本刀执行结束；结果一旦确定即不可覆盖，雕塑与投射物停止物理更新。

玩家在执行/选择期不可被敌弹杀伤，选择期禁移动与锁；连锁等待期可移动但不可普通再出刀。地形查询与直斩预览使用最终 authored 位置；直斩位移在 `slash_duration` 内补间，非瞬时传送。圆斩保持 GDD 确认的纯圆形命中，不做墙遮挡裁剪；尸体和普通弹受墙阻挡。

## 白模表现与可调项

锁弹绘制链节与箭头，雕塑禁锢绘制高亮环/链节/剩余时间环；敌弹圆形暖色、友弹菱形冷色、尸体灰色裂纹。命中痕迹默认碎屑/裂纹灰褐色，可在 `CorpseImpactConfig.mark_color` 改色。上述是原生代码绘制，尚非最终美术。HUD 显示敌数、刀次、锁冷却及续斩刀型/真实剩余时间。关卡编辑步骤见 `docs/guides/v03_level_editing.md`。

## 验证映射与剩余风险

`tests/acceptance/v03_acceptance_runner.gd` 使用 Godot 4.7.1 运行，当前 60 项确定性检查全通过；覆盖 AC-01~10 的核心状态、碰撞与动态编辑，包括增删雕塑、父节点位移、地块改画、锁首目标/墙/射程、直杀门槛、连续三刀、真实超时、高速扫掠、模拟 E→首刀→续斩输入、迟到友弹/尸体全灭、重试清理与结果冻结。v0.1 历史 smoke acceptance 也通过。场景编辑器导入及无窗口运行亦已通过。

这些检查不等同每项 AC 的完整视觉验收或主观体验验证。尚需窗口核对预览/锁链/弹幕/尸体痕迹的辨识与反馈；尤其在高弹量时测试分段扫掠性能，并确认编辑器 Inspector 参数工作流。既有 v0.1 回归与 v0.2 用户改动场景不可被本版通过替代。体验是否有趣/有主动塑形感必须由试玩记录单独判断。

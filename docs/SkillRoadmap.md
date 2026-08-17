# 《狐狸骑士》能力建设路线图

| 文档字段 | 内容 |
| --- | --- |
| 状态 | 已建立待验证路线条目 |
| 维护角色 | Learning Agent |
| 服务对象 | Architecture Agent 与 Coding Agent |

## 文档职责

本文件用于记录项目所需能力、知识缺口、学习顺序和验证计划。它不定义当前游戏设计，也不作为生产实现需求；学习结论需要分别交给 Architecture Agent 或 Coding Agent 判断和采用。

## 当前路线

### LR-001｜敌人、Boss 与关卡内容生产工作流

- 状态：待调研、待验证；尚未选择行为树插件，尚未授权生产实现。
- 学习主题：建立可由创作者主要通过 Godot 场景、Inspector、资源或可视化逻辑组合新敌人与遭遇的内容生产方式，并判断何时需要状态机、行为树或项目专用编辑工具。
- 来源任务：2026-08-16 关于后续新敌人、复杂敌人、Boss、Unity Behavior Tree 式制作方式，以及项目是否需要关卡/战斗编辑器的架构讨论。
- 能力缺口：
  - 尚未形成“行为原语、敌人决策、敌人定义、遭遇编排、战斗真值”之间的稳定职责边界。
  - 尚不知道本项目的可预测型敌人是否需要通用行为树，还是数据化行为序列或轻量状态机已经足够。
  - 尚未验证创作者能否在不修改 GDScript 的前提下独立制作常规敌人变体并诊断运行问题。
  - 尚未形成自定义 Inspector、路径/时序 Gizmo、调试面板或专用关卡编辑器的建设门槛。
- 需要回答的问题：
  1. 哪些敌人能力应成为只实现一次的可复用行为原语，哪些内容应由场景、`Resource`、行为树或实例参数表达？
  2. 对强调可观察与可预测的敌人，数据化行为序列、层级状态机和行为树分别适用于什么复杂度？
  3. LimboAI、Beehave 或不依赖第三方插件的轻量方案，在 Godot 4.7.1 下的编辑体验、运行时调试、版本控制、导出、升级与移除成本如何？
  4. Boss 的阶段、局部决策、严格演出时序和“一刀”胜负真值应如何分层，避免把全部逻辑塞入一棵巨型行为树？
  5. 哪些重复操作或错误已经足以证明需要项目专用编辑工具，而不是继续使用 Godot 原生场景、Inspector 和自定义 `Resource`？
  6. 内容生产合同稳定后，是否需要建立显式调用的项目 Skill，约束未来 agent 如何新增、检查和验收敌人？
- 当前已知事实与假设：
  - 项目当前 v0.1 仍以场景实例和 `@export` 参数编辑基础敌人；GDD/TDD 未授权多种敌人、Boss、关卡编辑器或通用内容生产框架。
  - Godot 可使用自定义 `Resource` 保存并在 Inspector 中编辑可复用数据，也可通过 GDScript `EditorPlugin`、自定义 Inspector 和 Dock 扩展编辑器。
  - Godot 4 核心未提供通用 VisualScript；通用行为树主要依赖社区插件。
  - LimboAI 提供行为树资源、黑板、可视化编辑与运行时调试，并提供 Godot 4.7 对应版本；当前商店发布状态和项目兼容性仍需实测。
  - Beehave 是 Godot 4.x 行为树候选，其维护者也提示简单 AI 使用行为树可能属于过度设计。
  - 假设：对《狐狸骑士》而言，未来最先产生价值的专用工具可能是路线、状态、触发条件和未来位置的可读性调试，而不是完整行为树或独立关卡编辑器；该假设尚待实际内容制作验证。
- 最小验证方式：
  1. 在不改变 v0.1 生产基线的独立测试场景中，先定义一组最小行为原语，例如移动、等待、转向、沿路径、设置速度和条件判断。
  2. 使用同一组行为原语，分别制作一个自定义 `Resource`/轻量状态方案和一个 LimboAI 行为树方案；Beehave 仅在前两者无法回答关键问题时加入比较。
  3. 两种方案都制作同样的 2～3 个可预测移动变体，不加入敌人攻击、玩家生命或尚未确认的 Boss 玩法。
  4. 由创作者在不修改 GDScript 的条件下复制一个敌人并创建新变体，记录首次完成时间、误操作、需要求助的位置和能否理解运行中的当前状态。
  5. 比较场景与资源差异的可读性、运行时分支/时序诊断、重复使用成本、Godot 4.7.1 编辑器兼容、Windows 导出、插件移除和升级风险。
  6. 只有当连续内容制作暴露出可复现的高频痛点时，才针对该痛点制作最小 `@tool`、Gizmo、Inspector 或 Editor Dock 原型。
- 学习验证通过条件：
  - 在已有行为原语范围内，创作者能够不改代码地建立并调试一个常规敌人变体。
  - 行为编辑结果仍能支持敌人的可观察性、可预测性和失败归因，而不只是提高逻辑分支数量。
  - 能清楚列出“新增配置即可完成”与“必须新增行为原语代码”的边界。
  - 候选方案可被移除或替换，不改变命中、死亡、胜败等战斗真值所有权。
  - 有足够证据决定继续使用原生 Inspector/Resource、采用行为树插件，或建设某一项窄范围编辑工具；证据不足时保留未决。
- 产出与证据：
  - 行为原语与数据所有权清单。
  - 两种方案的同题示例、制作步骤、运行截图或录屏、调试记录和耗时记录。
  - Godot 4.7.1 编辑/运行/导出兼容性记录，以及插件版本和移除步骤。
  - 方案比较结论：适用条件、失败模式、维护成本和推荐边界。
  - 若内容合同稳定，再提出 `fox-knight-enemy-authoring` 项目 Skill 草案；Skill 只规范 agent 工作流，不替代 Godot 内编辑工具。
- 适用条件与限制：
  - 本条目属于能力建设，不将多种敌人、敌人攻击、Boss、关卡组件或编辑器纳入当前版本。
  - Boss 首先是 Architecture Agent 需要解决的设计问题；在“一刀”原则下的 Boss 结构未确认前，不以 AI 工具试验反向定义玩法。
  - 行为树的可编辑性不等于玩家可读性；如果通用性使敌人行为难以预测，应优先保持更简单、确定的表达。
  - 外部插件和资料结论具有时效性，进入实现前必须重新核对版本、许可证、发布状态与平台支持。
- 外部资料（访问日期：2026-08-16）：
  - [Godot Resources](https://docs.godotengine.org/en/stable/tutorials/scripting/resources.html)
  - [Godot Editor plugins](https://docs.godotengine.org/en/stable/tutorials/plugins/editor/making_plugins.html)
  - [Godot 4 VisualScript discontinuation](https://godotengine.org/article/godot-4-will-discontinue-visual-scripting/)
  - [LimboAI repository](https://github.com/limbonaut/limboai)
  - [LimboAI Godot Asset Store page](https://store.godotengine.org/asset/limbonaut/limboai/)
  - [Beehave repository](https://github.com/bitbrain/beehave)
  - [awesome-gamedev-agent-skills](https://github.com/gamedev-skills/awesome-gamedev-agent-skills)
- 后续交接角色：Learning Agent 汇总实验与证据；Architecture Agent 决定是否符合玩家体验、设计范围与 Boss 原则；用户确认设计和目标版本后，Coding Agent 才能同步 TDD 并实施生产方案。

## 条目格式

- 学习主题：
- 来源任务：
- 需要回答的问题：
- 最小验证方式：
- 产出与证据：
- 适用条件与限制：
- 后续交接角色：

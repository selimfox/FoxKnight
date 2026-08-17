# Learning Agent

## 职责

负责识别能力缺口、安排学习与调研、设计低成本验证、整理结论和维护 `docs/SkillRoadmap.md`。学习产出用于降低后续决策与实现风险，不自动成为游戏设计或生产实现要求。

## 开始任务前

1. 阅读根目录 `AGENTS.md`。
2. 阅读 `docs/SkillRoadmap.md` 中与任务相关的条目。
3. 根据问题来源，读取 `docs/GDD.md`、`docs/TDD.md` 或 `docs/DecisionLog.md` 的相关部分。

## 工作边界

- 区分事实、推测、实验结果和建议，不把调研结论直接标为已确认设计。
- 学习实验应尽量小而可撤销；除非用户明确要求，不直接改动生产代码或当前设计基线。
- 发现玩法问题时交给 architecture agent 决策；发现实现问题时向 coding agent 提供可验证的技术建议。
- `docs/SkillRoadmap.md` 只记录能力建设与验证计划，不复制 GDD 玩法，也不替代 TDD。
- 外部资料必须记录来源和访问日期；时效性强的结论在使用前重新核实。

## 交付给其他角色

- 给 architecture agent：证据、假设、设计影响和仍未解决的问题。
- 给 coding agent：可复现步骤、最小实验结果、适用条件和已知限制。

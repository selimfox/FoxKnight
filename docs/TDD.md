# 《狐狸骑士》技术设计入口

| 文档字段 | 内容 |
| --- | --- |
| 当前技术基线 | `docs/TDD_v0.2.md`（计划，尚未实现） |
| 对应设计 | `docs/GDD.md` v0.2 横版冲击斩 Demo |
| 维护角色 | Coding Agent |
| 更新日期 | 2026-10-28 |

## 文档职责

本文件是当前技术设计的固定入口。版本化技术内容放在对应的 `TDD_vX.Y.md` 中；当前技术计划为 [TDD v0.2](TDD_v0.2.md)。Coding Agent 按 `AGENTS.md` 的上下文规则确认版本和标题，再读取本次任务相关章节；全面审查或基线升级时扩大读取范围。

TDD 说明如何实现已确认设计，不定义玩法，也不得覆盖 GDD。发生冲突时以 `docs/GDD.md` 为准，并把需要改变设计的问题交回 Architecture Agent。

## 当前状态

- v0.2 技术计划：`docs/TDD_v0.2.md`，对应当前 GDD；尚未实现或运行验收。SV-OQ-01 已确认静止敌人，SV-OQ-02～05 仍阻塞相关制作与验收；不得由代码默认选择答案。
- v0.1 Prototype 历史技术基线：[TDD v0.1](TDD_v0.1.md)，保留原文，不以其旧测试证明 v0.2 成立。
- Godot 当前默认入口仍为 `res://scenes/prototype/campaign.tscn`；sideview 目录仅有骨架，本文入口切换不表示游戏运行入口或功能已切换。

## 维护规则

- TDD 创建、更新、审查和版本切换由 Coding Agent 使用 `$fox-knight-tdd-maintainer` 执行。
- Coding Agent 不得自行决定升版；目标版本必须来自用户明确要求，或 Architecture Agent 已完成并确认的 GDD 升版。
- 新版技术正文完成并检查通过后，才能更新本文件的当前指向；旧版正文不得覆盖或删除。

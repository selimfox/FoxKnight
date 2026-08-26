# 《狐狸骑士》技术设计入口

| 文档字段 | 内容 |
| --- | --- |
| 当前技术基线 | `docs/TDD_v0.1.md` |
| 对应设计 | `docs/GDD.md` v0.1 阶段结算基线 |
| 维护角色 | Coding Agent |
| 更新日期 | 2026-08-26 |

## 文档职责

本文件是当前技术设计的固定入口。版本化技术内容放在对应的 `TDD_vX.Y.md` 中；当前 Coding Agent 应读取 `docs/TDD_v0.1.md`。

TDD 说明如何实现已确认设计，不定义玩法，也不得覆盖 GDD。发生冲突时以 `docs/GDD.md` 为准，并把需要改变设计的问题交回 Architecture Agent。

## 当前状态

- v0.1 Prototype 技术基线：`docs/TDD_v0.1.md`（阶段结算已确认，作为当前冻结基线保留）。
- 当前未建立其他版本的 TDD；在 GDD 明确升级并确认下一版本范围前，不创建或切换新的技术基线。

## 维护规则

- TDD 创建、更新、审查和版本切换由 Coding Agent 使用 `$fox-knight-tdd-maintainer` 执行。
- Coding Agent 不得自行决定升版；目标版本必须来自用户明确要求，或 Architecture Agent 已完成并确认的 GDD 升版。
- 新版技术正文完成并检查通过后，才能更新本文件的当前指向；旧版正文不得覆盖或删除。

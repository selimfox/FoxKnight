# 狐狸骑士 / 一刀狐狸

独立游戏项目。当前游戏设计与开发范围以 `docs/GDD.md` 为准。

当前为 GDD v0.3 Prototype：无战前拖格的战斗入口。玩法以 GDD 为准；v0.1/v0.2 设计、技术与测试证据保留为历史对照。本轮实现与验收状态见对应 Test Log。

## 项目结构

```text
FoxKnight/
├── AGENTS.md                  # 全体 agent 共用规则与任务路由
├── .agents/skills/            # 项目 Skills 的 canonical source
├── agents/
│   ├── architect.md           # 设计、架构、范围与设计文档治理
│   ├── coding.md              # Godot 实现、调试、测试与技术文档
│   └── learning.md            # 学习、调研、验证与能力建设
├── backups/                   # 修改前的安全备份，按原目录分类
│   ├── root/                  # 根目录文件的备份
│   └── docs/                  # docs/ 文件的备份
├── docs/
│   ├── OnePaper.md            # 创作者愿景与核心方向，不替代 GDD
│   ├── GDD.md                 # 当前设计与版本范围
│   ├── DecisionLog.md         # 重要设计变化及原因
│   ├── SkillRoadmap.md        # 能力建设与验证计划
│   ├── TDD.md                 # 当前技术设计入口
│   ├── TDD_v0.1.md            # v0.1 Prototype 冻结技术基线
│   ├── TDD_v0.2.md            # v0.2 历史技术基线
│   ├── TDD_v0.3.md            # 当前技术实现基线
│   ├── guides/v03_level_editing.md # 当前关卡编辑与参数入口
│   ├── playtest/              # 与 GDD 版本绑定的 Prototype 测试记录
│   │   ├── PrototypeTestLog_v0.1.md
│   │   ├── PrototypeTestLog_v0.2.md
│   │   └── PrototypeTestLog_v0.3.md
│   └── archive/               # 历史文档
├── scripts/                   # Godot 脚本
├── assets/
│   ├── art/                   # 美术资源
│   └── audio/                 # 音频资源
└── project.godot              # Godot 项目入口
```

`docs/GDD.docx` 当前仍为 v0.1 历史阅读副本，未同步 v0.3，请勿作为当前需求。当前设计请阅读 `docs/GDD.md`。

## 阅读与协作入口

首次了解项目时，建议依次阅读：

1. `README.md`
2. `docs/OnePaper.md`
3. `docs/GDD.md`
4. `docs/DecisionLog.md`
5. `docs/playtest/PrototypeTestLog_v0.3.md`（当前验收与试玩证据）
6. `docs/TDD.md`（进入实现、调试或技术审查时阅读）

编排关卡请阅读 `docs/guides/v03_level_editing.md`，在 Godot 编辑器中使用原生瓦片绘制和雕塑实例参数。历史场景不作为默认运行入口。

使用 agent 工作时，先阅读根目录 `AGENTS.md`，再按任务类型进入相应角色文件：

- 架构、设计与设计文档：`agents/architect.md`
- 开发、调试与测试：`agents/coding.md`
- 学习、调研与复盘：`agents/learning.md`

## 文档边界

- One Paper 表达创作者愿景与核心方向，不替代 GDD，也不作为当前版本的制作与验收依据。
- GDD 描述游戏当前是什么以及当前版本做什么。
- DecisionLog 解释重要设计为什么发生变化。
- TDD 记录如何实现已确认设计，不重新定义玩法。
- Prototype Test Log 按 GDD 版本保存逐次验收与试玩证据，不定义玩法，也不把功能通过等同于体验成立。
- SkillRoadmap 记录需要学习和验证什么，不产生实现承诺。
- backups 保存修改前的安全副本；archive 保存正式历史版本，两者不混用。
- 根 AGENTS 只维护共用规则与路由；角色细则由 `agents/` 下的文件维护。
- README 只负责项目入口、结构说明和文档索引。

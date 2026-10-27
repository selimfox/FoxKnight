# 狐狸骑士

当前设计与开发范围以 [GDD v0.2](docs/GDD.md) 为准。v0.2 已确认设计基线，仍有制作前未决项；功能尚未实现。v0.1 作为历史基线与运行参照保留。

## 当前入口与运行状态

- 设计：[docs/GDD.md](docs/GDD.md)。
- 技术：[docs/TDD.md](docs/TDD.md)，进入版本化 [TDD v0.2](docs/TDD_v0.2.md)；技术方案不表示代码已完成。
- 验证：[Prototype Test Log v0.2](docs/playtest/PrototypeTestLog_v0.2.md)，当前无新版本运行或试玩记录。
- Godot 入口：根目录 `project.godot`，默认主场景仍为旧版 `scenes/prototype/campaign.tscn`。本次没有切换启动场景或配置新输入。
- 横版隔离目录已预留，当前只含占位文件；旧版验收、云环境通过和旧包均不能作为 v0.2 验证结果。
- `docs/GDD.docx` 仍是旧版阅读副本，本轮没有同步；当前设计以 Markdown 为准。

## 项目结构

```text
FoxKnight/
├── AGENTS.md                 # 共用规则与任务路由
├── agents/                   # 各角色职责
├── .agents/skills/           # 项目 Skill 正式来源
├── .codex/agents/            # 项目 Agent 调用入口
├── docs/
│   ├── GDD.md                # 当前设计入口
│   ├── DecisionLog.md        # 重要变化及原因
│   ├── TDD.md                # 当前技术入口
│   ├── TDD_v0.2.md           # 当前技术计划，尚未实现
│   ├── TDD_v0.1.md           # 历史技术基线
│   ├── playtest/             # 按版本分开的验证证据
│   ├── archive/              # 正式历史文档
│   ├── proposals/            # 讨论过程，不替代当前入口
│   ├── art/                  # 既有美术记录与证据
│   ├── OnePaper.md           # 历史愿景材料，不能覆盖当前 GDD
│   └── SkillRoadmap.md       # 能力建设，不产生开发需求
├── scenes/sideview/          # 新 Demo 场景预留目录
├── scripts/sideview/         # 新 Demo 脚本预留目录
├── assets/sideview/          # 新 Demo 占位资源预留目录
├── tests/sideview/           # 新 Demo 验证预留目录
├── backups/                  # 修改前副本，按原目录镜像
├── build/                    # 可再生成的导出与交付包
├── export_presets.cfg        # 导出配置，仍须按新版本另行核查
└── project.godot             # Godot 工程入口
```

其他旧场景、脚本和资源保留现有路径，避免批量迁移破坏引用。目录存在不代表新 Demo 已制作。

## 历史与协作

- 历史设计：[GDD v0.1](docs/archive/GDD_v0.1.md)。
- 历史证据：[Prototype Test Log v0.1](docs/playtest/PrototypeTestLog_v0.1.md)。
- 重要变化：[DecisionLog](docs/DecisionLog.md)。
- 收束过程：[2026-10-28 设计草案](docs/proposals/SideviewDemo_20261028.md)，已由正式 GDD 替代。

开始工作先读根 `AGENTS.md`，再按任务读对应 `agents/*.md` 和正式来源。README 只维护入口与目录，不复述玩法规则。

本轮已在 `codex/sideview-impact-demo` 隔离新设计；未暂存、提交或推送。Git 写入仍遵守项目授权和 safety gate。

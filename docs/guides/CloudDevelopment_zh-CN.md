# iPhone 云端开发说明

目标：电脑关闭后通过 ChatGPT 的 Codex Cloud 开发《狐狸骑士》。本说明不定义玩法，不改变正式设计与技术基线。

## 当前状态

- GitHub：selimfox/FoxKnight，公开。
- 使用分支：codex/cloud-local-20261009，GDD/TDD v0.1 美术快照。main 是另一条 v0.3 开发线，不要默认选 main。
- scripts/cloud/setup.sh：固定官方 Godot 4.7.1 Linux x86_64 标准包，核对 SHA512 后安装至 $HOME/.local/bin/godot-4.7.1，不需 sudo。
- scripts/cloud/check.sh：导入、核心烟测、Campaign 验收；日志在忽略的 output/cloud/。
- 仓库准备与 Linux 兼容验证已完成：GitHub Actions 的 Ubuntu 22.04 实际安装 Godot 4.7.1、验证重复安装复用、导入项目，并通过核心烟测及 Campaign 验收。证据：https://github.com/selimfox/FoxKnight/actions/runs/37827205534 。这不代表 Codex Cloud 环境已经创建或发布；当前可操作网页未登录，账号侧仍需完成创建与新任务验证。

## 首次创建环境

手机 App 使用已发布的环境；创建环境使用网页或桌面端。iPhone 可在 Safari 登录同一账号，布局受限时尝试“请求桌面网站”。手机登录不会同步登录电脑网页。

1. ChatGPT 新任务：Work in → Cloud → Select environment → Create environment。也可从 Settings → Codex Cloud → Environments 创建。
2. 连接 GitHub，只选择 selimfox/FoxKnight，不要在聊天或文件中填写 GitHub token。
3. 界面可选分支时选 codex/cloud-local-20261009；没有分支选择时让环境设置任务先检出此分支，再核对 GDD/TDD v0.1 和入口 scenes/prototype/campaign.tscn。
4. 环境名 FoxKnight-v01-art，使用权限 Only me。公开仓库不要求公开环境。
5. 将下一节发送给环境设置任务。实际安装和测试全部通过后，查看报告、Save、Publish。
6. 等待 Environment published 后，在一个新任务里确认分支并重新执行检查，才能确认接入完成。

## 直接粘贴到环境设置任务

```text
为 selimfox/FoxKnight 配置 FoxKnight-v01-art 云端环境，Linux x86_64，权限 Only me。
使用 codex/cloud-local-20261009 分支，不使用 main。检出后核对 GDD/TDD v0.1、project.godot 和当前场景入口，不合并 main、不改写历史、不修改玩法。
完整读取 AGENTS.md 与 agents/coding.md，按任务读取相关正式来源。
安装 Bash、curl、unzip、GNU coreutils（timeout/sha512sum/sha256sum/install），以及官方 Godot 4.7.1 标准 Linux 二进制所需运行库。
Install script：bash scripts/cloud/setup.sh
随后实际运行：bash scripts/cloud/check.sh
Godot 路径：$HOME/.local/bin/godot-4.7.1，必要时启动环境加入 $HOME/.local/bin 到 PATH。
Start skill：新任务检查分支、版本、git status 与 Godot 路径；代码或场景修改后执行 bash scripts/cloud/check.sh，并按修改补充相关验收。
网络仅允许所需官方 GitHub 发布与下载域名 github.com、release-assets.githubusercontent.com；缺少依赖时只增加所需官方软件源，不加入私人网络或凭据。
安装失败、导入解析错误、测试失败或超时不得发布；烟测与Campaign必须退出0并输出各自精确 RESULT PASS。
保留项目 Git 授权和安全预检要求：此次配置不自动授权以后提交、推送、PR；原 gate 是 Windows PowerShell 工作流，Linux 兼容性未验证，不能静默跳过。首次配置只准备工具和测试，不提交或推送代码。
报告实际版本、分支、命令、退出码、日志和限制。headless 功能通过不代表画面、美术或手感通过。
```

## 后续用手机开发

发布后，在 iPhone ChatGPT 打开 Codex，选择 FoxKnight-v01-art。普通聊天或连接本地电脑的远程任务不能代替这个云端工作区。

一次交代一个明确目标，包含问题、修改范围和验收标准，可使用：

```text
在 FoxKnight-v01-art 中继续，确认 codex/cloud-local-20261009 与 v0.1 文档。
修复：[具体操作] 后出现的 [实际问题]；预期是 [行为]。
读取 AGENTS.md 和相关角色/正式来源，只修改直接相关文件。
完成后运行 bash scripts/cloud/check.sh 及相关验收，说明修改范围、测试结果和未验证的画面/手感。
先保留改动供我审核，不提交、不推送、不合并 main。
```

同一个任务保留其工作区；新任务是独立工作区，不自动继承上一任务的未提交修改。重要工作须按项目规则提交或保存补丁，不能只依赖任务保存状态。设计修改需先确认并维护正式来源。

## 电脑与云端交接

1. 关机前检查、提交并上传要交给云端的本地改动；未上传的文件云端看不到。
2. 手机上安排云端开发并查看证据。若要提交/PR/推送，明确授权并执行项目 gate；Linux gate 暂未验证，受阻时先保存补丁，待本地安全检查，不能声称已上传。
3. 开机后先 git status 保护本地未提交改动，再核对目标分支并拉取提交或应用补丁。不强制覆盖，不自动把 v0.1 合并进 v0.3 main。
4. 仅当确认云端提交已进入相同分支、本地干净且无独有提交时，可以运行：

```powershell
git status --short --branch
git pull --ff-only origin codex/cloud-local-20261009
```

若 fast-forward 被拒绝，停止并检查两边历史，不使用 force/reset。

5. 在本地 Godot 实际运行，检查输入、动画、画面和手感，再确认完成。

这套工作流按提交和任务交接，不是每次保存文件就自动双向同步。云端能修改脚本、场景和文档，运行无窗口功能验收；实际视觉和操控体验需另行验证。此次配置不包含自动生成 Windows 交付包。

## 依据

- https://learn.chatgpt.com/docs/cloud
- https://learn.chatgpt.com/docs/environments/cloud-environments

核实日期：2026-10-09；账号可用性、界面标签以登录后的实际页面为准。

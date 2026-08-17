# FoxKnight 手动 Git 与 GitHub Desktop 通道

## 心智模型

- 工作区：正在编辑的文件。
- 暂存区：本次准备提交的文件。
- Commit：本地保存点。
- Push / Publish：把本地历史写入远端 GitHub。

Commit 和 Push 是两次不同授权。安全检查通过也不会自动执行它们。

## 首次建立本地仓库

在 PowerShell 中执行：

```powershell
Set-Location 'D:\Godot_Project\FoxKnight'
powershell -NoProfile -ExecutionPolicy Bypass -File .agents/skills/fox-knight-git-safety-gate/scripts/preflight.ps1 -Mode Audit
git init -b main
git config --local user.name "你的 GitHub 显示名称"
git config --local user.email "GitHub 设置页提供的 noreply 地址"
git config --local push.default simple
```

不要把账号密码、Personal Access Token 或其他凭据写进命令、远端 URL、项目文件或聊天。

## 添加到 GitHub Desktop

1. 打开 GitHub Desktop。
2. 选择 `File` → `Add local repository...`。
3. 选择 `D:\Godot_Project\FoxKnight`。
4. 点击 `Add repository`。
5. 此时只注册本地仓库，不代表已经上传。

需要上传时，先运行 `Push` 模式预检，再点击 `Publish repository`。首次建议勾选私有仓库；发布是远端写入，需要单独确认。

## 每次手动提交

```powershell
git status --short
git diff
git add <明确的文件或目录>
git diff --cached --stat
git diff --cached
powershell -NoProfile -ExecutionPolicy Bypass -File .agents/skills/fox-knight-git-safety-gate/scripts/preflight.ps1 -Mode Commit
git commit -m "类型: 简短说明"
```

不要使用 `git add .` 或 `git commit -a`。暂存错文件时使用：

```powershell
git restore --staged <文件路径>
```

## 连接或发布远端

用 GitHub Desktop 发布时保持仓库为 Private。若手动连接已经创建的空仓库：

```powershell
git remote add origin https://github.com/<账号>/<仓库>.git
git remote -v
powershell -NoProfile -ExecutionPolicy Bypass -File .agents/skills/fox-knight-git-safety-gate/scripts/preflight.ps1 -Mode Push
git push -u origin main
```

## 后续提交与测试标签

```powershell
git push
git tag -a v0.1-playtest-1 -m "First external playtest build"
git push origin v0.1-playtest-1
```

把 Windows ZIP 作为 GitHub Release 附件上传，不要提交到普通 Git 历史。

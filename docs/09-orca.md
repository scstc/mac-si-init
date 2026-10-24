# Orca：安装与首次使用

Orca 可将 Claude Code、Codex 等 agent 放在多个 worktree 中工作。它是三件套安装后的可选应用，由 agent 询问用户需求后安装。[官方仓库](https://github.com/stablyai/orca)、[官网](https://www.onorca.dev/)。

## 安装

已按文档装好 Homebrew 时，使用官方仓库列出的 tap：

```zsh
brew install --cask stablyai/orca/orca
```

该命令会使用 Orca 官方 tap；用户已经选择安装 Orca 后可直接继续。不要误装同名的其他项目。安装渠道来自 [Orca 官方安装说明](https://github.com/stablyai/orca#install)。

也可以从官网下载 Mac 安装包：Apple Silicon 选择 Apple Silicon / arm64，Intel 选择 Intel / x64。打开 DMG，将 Orca 拖入 Applications 后启动；不硬编码会过期的安装包文件名。

## 首次启动引导

1. 确认在系统终端中 `claude --version`、`codex --version` 正常，至少一个 agent 已能实际登录并对话。
2. 从「应用程序」打开 Orca。若当前版本要求登录，用户在应用或跳转的浏览器完成，不把账号密码交给 agent。
3. 按当前界面选择一个用户已有的 Git 项目。不擅自创建远程仓库、推送或上传代码。
4. 在 agent 选择/设置界面选择已安装的 Claude Code 或 Codex，先启动一个会话，确认终端能运行该 CLI 并响应简单请求。
5. 如用户需要多任务，再说明独立 worktree 的用途并演示新增工作区。先确认单个会话正常，再逐步使用多 agent 功能。

界面名称随版本变化，agent 应按实际界面解释，不要求用户寻找固定位置的旧按钮。Orca 的登录不替代各 CLI 自身的授权。

## 验证与排错

Homebrew 安装可用 `brew list --cask stablyai/orca/orca` 检查；版本在应用 About 中确认。已安装不代表 agent 已能工作，需完成上面的实际会话验证。

找不到 CLI 时先完全退出 Orca 再打开。仍失败时，用 `command -v claude` / `command -v codex` 获取本机路径，并按当前版本支持的 CLI 路径设置指定它；默认官方直装入口在 `~/.local/bin`。用户从 DMG 安装 Orca 时，brew 未登记不代表未安装。

## 更新

Homebrew 渠道用 `brew upgrade --cask stablyai/orca/orca`；手动安装渠道使用应用提供的更新或官方新安装包。更新后重新确认 agent 会话可用。

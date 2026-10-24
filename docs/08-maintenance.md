# 检查、更新与状态栏

## 本机检查

```bash
# 只装三件套后
bash scripts/check.sh --bootstrap
# agent 完成其余软件安装后
bash scripts/check.sh
```

`--bootstrap` 只检查 Claude Code、Codex 与 CC Switch，不要求 Homebrew、CLT 或 Node。默认检查全套工具，不读取账号配置、不联网查询最新版本、不升级。缺少检查范围内的组件或版本命令失败时退出 1；全套检查遇到用户选择跳过的软件时，由 agent 解释。

授权单独验证：GitHub 用 `gh auth status --hostname github.com` 和 `gh api user --jq .login`；GitLab 用 `glab auth status`。CC Switch 与 AI CLI 通过实际登录/请求验证，Orca 验证见 [专篇](09-orca.md)。不要输出 Token 来证明授权。

SSH 另按 [SSH 专篇](10-ssh-github-gitlab.md) 验证各平台的公钥、SSH 问候和用户指定仓库的 `git ls-remote`。CLI 登录成功、公钥添加成功和仓库权限是不同检查项；不自动推送测试提交。

## 按来源更新

Homebrew 管理的组件：

```zsh
brew update
brew outdated
# 查看列表后，选择需要升级的包
brew upgrade git fnm gh glab jq ripgrep zsh-autosuggestions zsh-syntax-highlighting
brew upgrade --cask iterm2 visual-studio-code font-meslo-lg-nerd-font
```

只升级实际安装的包。Node.js 由 fnm 管理，`brew upgrade fnm` 不会升级 Node：

```zsh
fnm install --lts
fnm use --lts
fnm default "$(node --version)"
```

Oh My Zsh 与两款原生 AI CLI：

```zsh
omz update
claude update
curl -fsSL https://chatgpt.com/codex/install.sh | sh
```

GUI 应用按安装来源使用 Homebrew 或应用内更新。不会将 Windows 版的自动巡检钩子搬到 Mac；初始版本不添加后台计划任务。

## jq 与 Claude Code 状态栏

`jq` 已包含在 core 模块，验证：

```zsh
jq --version
```

如需状态栏，在 Claude Code 中运行 `/statusline`，让其根据当前版本生成配置。自写脚本时使用 macOS 兼容命令，从 CLI 提供的 JSON 字段读取数据，不硬编码上下文窗口大小，不依赖 Windows 的 winget 目录。状态栏可参考 [官方文档](https://code.claude.com/docs/en/statusline)。

## 恢复

配置修改前的备份位于原文件旁边，以 `.mac-si-init.` 标记。先比较内容，再恢复需要的文件或删除对应配置块；安装后新增的个人配置需要保留。卸载软件按对应包管理器处理，不批量删除账号和会话目录。

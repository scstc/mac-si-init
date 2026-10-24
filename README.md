# mac-si-init

> 先装好 agent，再让 agent 带你完成 Mac 初始化。SI = Super Intelligence。

参考 [win11-si-init](https://github.com/scstc/win11-si-init)，采用两步初始化：**脚本先装 Claude Code + CC Switch + Codex CLI，再由用户选择的 agent 按本项目文档安装其余软件、引导账号授权**。终端方案使用系统 Zsh + Oh My Zsh。

macOS 默认 Shell 已是 Zsh，无需另装 Zsh 或切换 Shell；后续只为系统 Zsh 配置 Oh My Zsh、历史建议和语法高亮。[Apple 官方说明](https://support.apple.com/zh-cn/guide/terminal/trml113/mac)。

支持 Apple Silicon / Intel，具体系统要求以当前上游为准。引导脚本兼容 macOS Bash 3.2，使用系统自带工具，**不需要提前安装 Homebrew、Node.js、jq、Python 或 Command Line Tools**。请以普通用户运行，安装需要互联网。

本仓库在 Linux 上做语法与模拟回归检查，尚未完成完整 macOS 实机验收，不沿用 Windows 版的版本号和实测结论。

## 第一步：安装三件套

将项目复制或下载到 Mac，使用系统「终端」进入项目目录：

```bash
# 先查看计划，不联网、不安装、不修改配置
bash scripts/install.sh --dry-run

# 默认只安装三件套
bash scripts/install.sh
```

| 软件 | 默认渠道 | 用途 |
|---|---|---|
| Claude Code latest | 官方 curl 安装器 | 编程 agent，可引导后续初始化 |
| Codex CLI | 官方 curl 安装器 | 另一个可选 agent，命令为 codex |
| CC Switch | 官方 Releases 的 macOS Universal ZIP | 配置、切换 CLI 供应商 |

CC Switch 安装到 `~/Applications/CC Switch.app`，无需管理员权限。已有 CLI 或 CC Switch 会保留，不自动迁移或升级。CLI 安装器先下载成功且非空后才执行。

安装后可检查三件套：

```bash
bash scripts/check.sh --bootstrap
```

此检查只验证安装；账号和供应商需要实际登录后验证。渠道说明：[Claude 官方安装文档](https://code.claude.com/docs/en/setup)、[Codex 官方 CLI 文档](https://learn.chatgpt.com/docs/codex/cli)、[CC Switch 官方发布说明](https://github.com/farion1231/cc-switch#download--installation)。

## 第二步：任选 agent，继续初始化

使用其他供应商时，先在 Finder → 前往 → 个人 → Applications 中打开 **CC Switch**，按需配置 Claude / Codex；使用官方账号则可以直接启动 CLI 并按提示登录。

```bash
# 二选一；启动后已带上本项目的初始化任务
bash scripts/start-agent.sh claude
bash scripts/start-agent.sh codex
```

首次启动时，按 CLI 提示登录、信任项目目录。没有可用账号或供应商时，需要先完成账号配置才能让 agent 工作。`codex-cli` 是工具称呼，实际命令为 `codex`；启动脚本也接受 `codex-cli` 别名。

agent 会先了解已有环境和需求，然后：

1. 安装 Homebrew、Git、fnm / Node LTS、Oh My Zsh、gh、glab、jq、ripgrep。
2. 按选择安装 iTerm2、VS Code、字体和扩展。
3. 引导 **GitHub gh 浏览器授权**：解释设备码、在哪里输入、确认账号、授权后检查；再配置 Git 提交姓名与邮箱。
4. 为所用 GitHub / GitLab 初始化 SSH：复用或生成密钥、配置钥匙串、添加公钥、验证连接；自建实例和多账号分别处理。另按需配置另一款 AI CLI 的账号与供应商。
5. 询问是否安装 **Orca**、Obsidian、DBX、GenOffice；选择 Orca 时继续引导首次启动和 agent 识别。
6. 检查环境，交代已安装、已授权、主动跳过和仍待操作的项目。

密码、Token、验证码和私钥在本机或官方页面中输入，不需要发给 agent。管理员密码、浏览器登录、系统窗口和 CLI 正常的权限确认仍由用户完成。

流程细节见 [agent 引导手册](docs/00-agent-setup.md)。也可以直接运行 `claude` / `codex`，发送 [初始化提示词](docs/agent-prompt.md)。

## 高级：直接按模块安装

有经验的用户或 agent 可以复用模块：

```bash
bash scripts/install.sh --only core     # Git / fnm + Node LTS / gh / glab / jq / rg
bash scripts/install.sh --only shell    # Oh My Zsh / 历史建议 / 语法高亮
bash scripts/install.sh --only ai       # 只装 Claude Code / Codex
bash scripts/install.sh --only apps     # iTerm2 / VS Code / Nerd Font
bash scripts/install.sh --only apps --with-obsidian
bash scripts/install.sh --only all      # 完整脚本安装，含 CC Switch
```

默认是 `bootstrap`。`bootstrap` 和 `ai` 不依赖 CLT / Homebrew。其他模块会检查 CLT / Homebrew；缺少 CLT 时打开系统安装窗口，完成后重跑。Homebrew 首次安装可能要求管理员密码。不要 sudo 整个脚本。

`core` 遇到已有 Node.js 会保留，不自动接管其版本管理器。已有 AI CLI 不覆盖。**重跑安装不是批量升级**，更新和迁移见 [AI CLI 手册](docs/05-ai-cli.md) 与 [维护手册](docs/08-maintenance.md)。

完成后续安装后，新开 Zsh 终端执行 `bash scripts/check.sh` 检查全套环境；账号授权需单独验证。只装部分模块时，检查会报告未安装组件，由 agent 区分主动跳过和缺失依赖。

已有 Node.js 22+ 时，也可使用零依赖菜单：

```bash
node cli.mjs
node cli.mjs --dry-run
node cli.mjs --check --bootstrap
node cli.mjs --agent codex
```

项目尚未发布 npm，不依赖 npx 或假设存在的远程一行安装地址。

## 与 Windows 版的对应关系

| Windows 版 | Mac 版 |
|---|---|
| PowerShell / Windows Terminal | 系统 Zsh / Terminal.app，可选 iTerm2 |
| Oh My Posh / PSReadLine | Oh My Zsh / 历史建议 / 语法高亮 |
| winget / 管理员层 | 后续由 Homebrew 管理基础工具，模块分步安装 |
| Node 系统安装 | fnm 管理 LTS，已有环境保留 |
| Windows ssh-agent | macOS OpenSSH 与钥匙串 |
| WSL / Windows Coreutils | 移除；macOS 已有 Unix 环境和 BSD 工具 |
| PowerToys | 系统功能或可选 Rectangle / Raycast |
| cc-switch | 默认三件套之一 |
| Orca / DBX / GenOffice | agent 了解需求后按手册安装 |

## 配置与恢复

首步只为 CLI PATH 在 `${ZDOTDIR:-$HOME}/.zprofile` / `.zshrc` 追加 `local-bin` 标记块；后续模块追加对应配置。同一个块不重复追加，每次实际修改前备份到原文件旁的 `*.mac-si-init.<时间>.<唯一标识>.bak`。支持符号链接，备份保存修改前的内容。

后续模块管理 `~/.mac-si-init/env.zsh` 与 `~/.mac-si-init/zshrc.zsh`，更新时也先备份。个人主题与插件写在 `.zshrc` 的 shell 加载块之前，见 [Zsh 手册](docs/02-zsh.md)。恢复时删除对应标记块，或比较后恢复需要的备份；保留安装后新增的个人内容。恢复配置不会卸载软件。

## 手册

| 文档 | 内容 |
|---|---|
| [00-agent-setup.md](docs/00-agent-setup.md) | agent 执行顺序与用户操作引导 |
| [01-homebrew.md](docs/01-homebrew.md) | CLT、Homebrew、架构与 PATH |
| [02-zsh.md](docs/02-zsh.md) | Oh My Zsh、主题、插件与字体 |
| [03-nodejs.md](docs/03-nodejs.md) | fnm 与 Node LTS |
| [04-git-and-accounts.md](docs/04-git-and-accounts.md) | GitHub gh 授权、Git 身份、SSH、GitLab |
| [05-ai-cli.md](docs/05-ai-cli.md) | 三件套安装、登录、更新和迁移 |
| [06-vscode.md](docs/06-vscode.md) | VS Code、终端与扩展 |
| [07-optional-apps.md](docs/07-optional-apps.md) | DBX、GenOffice、Obsidian 与效率工具 |
| [08-maintenance.md](docs/08-maintenance.md) | 检查、更新、jq 与状态栏 |
| [09-orca.md](docs/09-orca.md) | Orca 安装、首次启动与 agent 验证 |
| [10-ssh-github-gitlab.md](docs/10-ssh-github-gitlab.md) | SSH 密钥、钥匙串、两平台公钥配置与仓库验证 |
| [troubleshooting.md](troubleshooting.md) | 常见问题速查 |

## 开发验证

```bash
npm run check
npm test
npm pack --dry-run
```

测试使用临时目录和模拟外部命令，不执行真实安装。已配置 Linux / macOS CI，系统窗口、真实授权、GUI 启动与完整安装仍需 Mac 实机验收。

MIT，保留原项目版权声明，见 [LICENSE](LICENSE)。

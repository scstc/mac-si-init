# 三件套：Claude Code、CC Switch 与 Codex

## 安装

```bash
# 默认安装三件套
bash scripts/install.sh
# 只补装两个 CLI，不装 CC Switch
bash scripts/install.sh --only ai
```

不依赖 Node.js；脚本默认执行以下官方安装器对应的操作：

```bash
# Claude Code：明确选择 latest 渠道
curl -fsSL https://claude.ai/install.sh | bash -s -- latest

# Codex：官方独立安装器
curl -fsSL https://chatgpt.com/codex/install.sh | sh
```

项目实际实现会先将安装器下载到临时文件，下载成功且非空后再执行；失败返回非零，不继续声称安装成功。临时文件执行后删除。默认命令入口在 `~/.local/bin`，脚本已将其加入 PATH。

Claude 的原生安装器支持指定渠道，原生版本默认自动更新；Codex 官方 CLI 页面列出了独立安装与更新命令。[Claude 官方安装说明](https://code.claude.com/docs/en/setup)、[Codex 官方 CLI 说明](https://learn.chatgpt.com/docs/codex/cli)。

## 验证与登录

新开终端：

```zsh
type -a claude codex
claude --version
codex --version
```

在项目目录运行 `claude` / `codex`，按各自交互提示登录。CLI 安装成功不代表账号已授权。供应商、API Key、组织策略由用户配置，安装脚本不会修改现有 `~/.claude` / `~/.codex` 设置。

第一次登录时，解释 CLI 显示的登录选项，让用户选择已有的官方账号或按其需要使用供应商配置。需要浏览器时，让用户在浏览器完成登录、核对账号并授权；CLI 要求复制回本机的内容应在 CLI 界面处理，不发到聊天。登录结束后以一次简单的实际请求确认可用，不能仅用 `--version` 证明登录成功。

## CC Switch 安装与配置

引导脚本从官方 GitHub Releases 的 latest API 中查找 `CC-Switch-*-macOS.zip`，用 macOS 自带的 plutil 读取元数据、ditto 解压 Universal 应用，安装到 `~/Applications/CC Switch.app`。不需要预装 Homebrew / jq / Python；找不到资产或下载/解压失败时停止，不猜测文件名。

在 Finder → 前往 → 个人 → Applications 中双击 CC Switch。需要其他供应商时：

1. 在界面选择 Claude Code 或 Codex，再添加对应供应商。
2. 按用户购买/使用的服务填写地址、凭证与模型，凭证由用户在 CC Switch 本机界面输入；不从示例猜测供应商。
3. 核对将写入的配置与备份，启用供应商，然后重启对应 CLI 并验证能实际请求。
4. 官方账号用户也可以直接走 CLI 自身的登录流程，之后再按需使用 CC Switch。

安装和界面操作参考 [CC Switch 官方说明](https://github.com/farion1231/cc-switch#download--installation)。此项目不会代用户切换供应商、购买服务或填入 API Key。

三件套可用后，执行 `bash scripts/start-agent.sh claude` 或 `bash scripts/start-agent.sh codex`，按 [agent 引导手册](00-agent-setup.md) 继续安装。

## 更新

```zsh
claude update
curl -fsSL https://chatgpt.com/codex/install.sh | sh
```

Claude 的自动更新渠道可在 `/config` 中检查；已有企业策略、禁用自动更新环境变量或最低版本约束可能影响更新。

CC Switch 默认是直接下载的应用，使用应用内检查更新或官方新发布包；初始化脚本保留已有应用，重跑不会升级它。已经通过 Homebrew 安装的版本继续用 `brew upgrade --cask cc-switch`，不要混用更新渠道。

`curl` 只是获取安装器，是否最新由发布渠道决定。这里明确使用 Claude `latest`；不承诺任意 curl 脚本都比 Homebrew 新。

## 已有安装与迁移

初始化脚本发现 PATH 中已有 `claude` / `codex` 就跳过，避免自动迁移、卸载或混装。需要切换渠道时先确认来源：

```zsh
type -a claude codex
brew list --cask
npm list -g --depth=0
```

只对确认来自相应渠道的包执行卸载，例如：

```zsh
# 仅当确认装过对应 cask 时执行
brew uninstall --cask claude-code
brew uninstall --cask codex

# 仅当确认装过对应 npm 全局包时执行
npm uninstall -g @anthropic-ai/claude-code @openai/codex
```

若曾安装 `claude-code@latest`，卸载时使用该实际 cask 名。随后重跑 AI 模块，在新终端核对 `type -a`。不要删除整个 `~/.claude` / `~/.codex`，其中可能有登录、设置和会话数据。

## 常见坑

- 安装后找不到命令：新开终端，确认 `~/.local/bin` 在 PATH 中。
- 新版本未生效：优先排查多个可执行文件的 PATH 顺序，再按实际安装来源更新。
- 网络错误：修复代理或网络后重跑，不用 `sudo` 绕过。
- Homebrew 仍是可选渠道，但不要与项目默认渠道混用；用 brew 安装的版本应通过 brew 升级。

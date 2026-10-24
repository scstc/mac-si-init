# 让 agent 完成后续初始化

## 用户怎么开始

先执行 `bash scripts/install.sh` 安装三件套，然后在本项目目录任选一个：

```bash
bash scripts/start-agent.sh claude
# 或者
bash scripts/start-agent.sh codex
```

`codex-cli` 是工具称呼，安装后的实际命令为 `codex`；启动脚本也接受 `codex-cli` 别名。脚本将项目初始化任务作为初始消息传给交互会话，用户无需自己组织提示词。首次启动按 CLI 提示登录；使用其他供应商时先打开 CC Switch 配置对应工具，再启动会话。没有可用账号或供应商时，先完成账号配置才能让 agent 工作。

也可以直接在本目录运行 `claude` / `codex`，将 [agent-prompt.md](agent-prompt.md) 的内容发给它。CLI 正常的目录信任、命令批准和系统认证仍由用户操作。

## agent 的执行顺序

### 1. 了解环境与需求

只读检查系统版本、架构、现有 CLI、Shell 和配置。解释推荐组件，集中询问可选软件：iTerm2/Terminal.app、VS Code、Orca、Obsidian、DBX、GenOffice；询问使用 GitHub、GitLab 还是两者，确认对应账号、自建实例和已有密钥。浏览器授权用于 CLI 登录；SSH 初始化按所选平台继续完成，用户明确只使用 HTTPS 时再跳过。

已经存在的环境优先保留；用户确认过的安装继续执行。不要把“首次配置 Mac”理解为可以覆盖全部个人配置。

### 2. 安装开发环境

按 [Homebrew](01-homebrew.md)、[Node.js](03-nodejs.md)、[Zsh](02-zsh.md) 和 [VS Code](06-vscode.md) 手册执行。

macOS 默认已使用系统 Zsh；终端配置只需安装/配置 Oh My Zsh 与插件，不额外安装 Zsh，也不常规执行 `chsh`。用户从旧系统迁移或主动修改过默认 Shell 时，按实际需求处理。

可调用现有模块：

```bash
bash scripts/install.sh --only core
bash scripts/install.sh --only shell
# 用户选择终端/编辑器整组时：
bash scripts/install.sh --only apps
```

`apps` 整组包含 iTerm2、VS Code 与字体；用户只选其中一项时，按手册逐个安装。不要用 `--only all` 替代需求收集。

CLT 缺失时脚本会打开系统安装窗口并退出。告诉用户点「安装」、等待完成、回到对话回复完成，再继续重跑。Homebrew 要求密码时，让用户在本机终端输入；如果 agent 的终端无法交互，把准确命令交给用户在另一个终端运行，再检查安装结果。

### 3. 完成账号授权

必须执行 [Git 与账号手册](04-git-and-accounts.md) 中相应的引导，而不是只给一串登录命令：

- GitHub：先检查状态；需要时解释设备码流程，再运行/引导用户运行 `gh auth login --hostname github.com --git-protocol https --web`。交互不能转交时，让用户在自己终端执行，agent 等待用户完成后验证。
- Git 身份：向用户确认提交姓名、公开邮箱或 GitHub noreply 邮箱；解释“提交署名”与“登录账号”是两项配置。
- SSH：按 [SSH 专篇](10-ssh-github-gitlab.md) 检查/生成密钥、配置 macOS 钥匙串与 Host、添加到用户使用的 GitHub/GitLab 并验证；支持自建主机/端口、多账号及已有密钥。用户已要求配置时不再反复确认是否需要；口令由用户在本机输入，不覆盖或展示私钥。
- GitLab：只对用户使用的实例执行登录；自建实例需先确认域名与登录方式。
- AI CLI：当前使用的 agent 能正常对话后，再按用户需要验证另一个 CLI；CC Switch 装好不代表供应商已有余额或凭证。

所有密码、Token、私钥和验证码都在本机或官方页面中处理，不进入聊天、报告或仓库。无需让用户重新提供已经确认过的信息。

### 4. 可选应用与 Orca

按 [可选应用手册](07-optional-apps.md) 安装用户选中的应用。选择 Orca 时按 [Orca 专篇](09-orca.md) 完成安装、首次启动、登录（如果当前版本要求）与 CLI 识别检查；先让用户在一个已有项目中验证单个 agent，再介绍多 worktree 工作方式。

### 5. 验收与交接

新开 Zsh 终端执行 `bash scripts/check.sh`；三件套单独检查用 `--bootstrap`。脚本不检查账号授权，账号需另验。检查失败时区分用户主动跳过的组件和真正缺失的依赖，不为消除提示擅自安装用户未选的软件。

交付清单要写清：软件安装情况、GitHub/GitLab 登录结果、Git 身份是否完成、各平台公钥是否添加、SSH 是否认证、指定仓库是否可读、Orca 是否能使用选定的 CLI，以及尚待用户操作的步骤。不要在项目中落盘包含个人账号信息的验收文件，除非用户明确要求。

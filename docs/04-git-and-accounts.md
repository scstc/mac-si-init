# Git、GitHub 授权、SSH 与 GitLab

这篇不仅安装工具，还要引导用户完成授权。agent 应先说明操作目的，再执行命令；交互终端无法转交时，让用户在自己的终端执行，完成后回来验证。用户不需要向 agent 提供密码、Token 或验证码。

## 安装与验证

```zsh
bash scripts/install.sh --only core
git --version
gh --version
glab --version
```

系统 CLT 也提供 Git。新开终端后用 `type -a git` 确认当前使用的是预期版本。

## GitHub：先检查，再引导浏览器登录

先执行 `gh auth status --hostname github.com`。已经登录且账号符合用户意图时保留，不重新授权或切换账号。没有登录时，先告诉用户接下来会出现一个临时设备码，需要在 GitHub 网页输入。

```zsh
gh auth login --hostname github.com --git-protocol https --web
```

默认推荐 HTTPS：不必先生成 SSH 密钥就能使用 GitHub。按终端与网页实际提示引导：

1. 确认浏览器登录的是想使用的 GitHub 账号；没有账号时先注册。
2. 终端显示一次性设备码后，按 Enter 打开官方授权页面。浏览器未自动打开时，使用终端显示的网址，通常是 `https://github.com/login/device`。
3. 用户在网页输入**自己终端显示的设备码**，不要把它发到聊天。设备码不等于密码或 API Token。
4. 核对应用名 GitHub CLI、账号和权限，按页面提示完成授权；组织有 SSO 时按组织要求继续授权。
5. 回到终端等待登录成功，然后回到 agent 对话说明已完成。代码过期时重新运行登录命令获取新码。

如果出现“是否让 Git 使用 GitHub 凭证”的询问，需要 HTTPS Git 操作时选择 Yes。CLI 可能要求钥匙串访问权限，按系统可信提示处理。

授权后验证，并为该主机配置 Git 凭证助手：

```zsh
gh auth status --hostname github.com
gh api user --jq .login
gh auth setup-git --hostname github.com
```

确认实际账号与用户预期一致；不要用 `gh auth token` 输出 Token。若登录成功但访问组织仓库仍失败，检查组织权限和 SSO，不反复重装 gh。相关来源：[gh auth login](https://cli.github.com/manual/gh_auth_login)、[gh auth setup-git](https://cli.github.com/manual/gh_auth_setup-git)。

## Git 身份

先读取现有 `git config --global --get user.name` / `user.email`。已有正确配置时保留；缺少时向用户解释：这是提交署名，不是登录密码。询问希望显示的姓名与提交邮箱，不猜测个人信息。GitHub 可在头像 → Settings → Emails 中查看 noreply 邮箱，并启用邮箱隐私选项。

将以下占位符替换为用户确认的信息后执行：

```zsh
git config --global user.name '<你的姓名>'
git config --global user.email '<你的邮箱>'
git config --global init.defaultBranch main
```

不自动设置全局代理、换行规则或覆盖已有凭证助手。

验证时再读取上述两项配置。gh 已登录不代表 Git 提交身份已经设置。

## SSH：初始化并添加到 GitHub / GitLab

SSH 配置已纳入 agent 的初始化流程。用户使用哪个平台，就为该平台检查或创建密钥、接入 macOS 钥匙串、合并 SSH Host 配置、添加公钥并验证连接。用户明确只使用 HTTPS 时可跳过；用户已要求配置 SSH 时直接按其需求继续。

完整步骤见 [SSH 初始化与两平台配置](10-ssh-github-gitlab.md)，包括自建 GitLab 的 SSH 主机/端口、已有密钥、多账号 Host 别名和仓库 remote 验证。不要将 gh/glab 已登录视为 SSH 已可用。

## 可选：GitLab

先确认用户是否使用 GitLab，以及 gitlab.com 还是自建实例；不用则跳过。域名需要用户确认，不能照抄占位符。先用 `glab auth status` 检查是否已经登录，再进行登录：

```zsh
glab auth login --hostname '<你的GitLab域名>'
glab auth status
```

按交互流程授权，不把 PAT 写进脚本、Shell 历史或仓库。自建 GitLab 的协议、证书和所需权限遵循组织配置，见 [GitLab CLI 文档](https://docs.gitlab.com/cli/)。

支持浏览器授权时优先引导网页登录，说明浏览器的账号、设备码与授权按钮。实例要求 PAT 时，指引用户在该实例个人设置的 Access Tokens 页面按 CLI/组织要求创建令牌，并在本机隐藏输入提示中粘贴；不要让用户把令牌发给 agent。完成后再次检查登录状态，确认主机与账号。

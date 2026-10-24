请帮我按照这个项目的文档，把当前 Mac 初始化成 AI 开发工作站。我可能不熟悉命令行，请边做边解释。

先阅读 AGENTS.md、README.md 和 docs/00-agent-setup.md，检查已有环境。Claude Code、CC Switch、Codex CLI 已由引导脚本安装，请验证并保留已有配置。

请先询问我需要哪些可选软件，包括 Orca、Obsidian、DBX 和 GenOffice；然后按文档安装 Homebrew、Git、fnm/Node LTS、Oh My Zsh、gh、glab、jq、ripgrep，以及我选择的终端/编辑器和可选应用。对我已经确认的安装继续执行，不要每一步重复询问。

请特别按 docs/04-git-and-accounts.md 引导 GitHub gh 授权：先检查状态，再告诉我如何打开浏览器、在哪里输入设备验证码、如何确认账号并授权，最后验证登录和 Git 凭证。也请引导 Git 姓名/邮箱、GitLab，以及 Claude/Codex 和 Orca 的首次使用。按照 docs/10-ssh-github-gitlab.md 为我使用的 GitHub/GitLab 完成 SSH 初始化：检查或创建密钥、配置 macOS 钥匙串与 Host、添加公钥到正确账号、验证 SSH 和我指定的仓库；自建 GitLab 确认网页与 SSH 主机、端口，多账号使用独立 Host 别名。已有密钥优先复用，私钥口令让我在本机输入；除非我选择只使用 HTTPS，不要省略 SSH 配置。不要只安装软件就结束，也不要要求我把密码、Token、私钥或验证码发到对话里。

需要我操作系统安装窗口、浏览器、钥匙串、登录或输入管理员密码时，说明具体操作位置并等待我完成。完成后检查环境，列出已安装、已授权、我选择跳过和仍待处理的项目。

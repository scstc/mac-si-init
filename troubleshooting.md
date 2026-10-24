# 常见问题速查

| 症状 | 排查与处理 |
|---|---|
| core/shell/apps 运行弹出开发者工具安装后退出 | 完成 CLT 安装再重跑；默认三件套不需要 CLT |
| Homebrew 要求密码 | 使用当前 Mac 管理员授权；不 sudo 整个安装脚本 |
| Apple Silicon 下提示 Rosetta | 关闭终端的「使用 Rosetta 打开」，在原生终端重跑 |
| Homebrew 架构不匹配 | `uname -m`、`type -a brew`、`brew --prefix`；先整理迁移遗留的双份安装 |
| `brew` / `claude` / `codex` 不存在 | 新开 Zsh 终端；核对 PATH、`~/.local/bin` 和 `.zshrc` 标记块是否执行 |
| fnm 已安装但 Node 不存在 | 新开终端后检查 `fnm list`；按 Node 手册安装 LTS 并设置默认版本 |
| 已有 Node 版本管理器 | core 保留现有 Node，不自动接管其 Shell 初始化；迁移见 Node 手册 |
| Oh My Zsh 目录存在却报错 | 检查是否下载中断或 `ZSH` 指错目录；保留/备份已有目录后自行修复 |
| 主题或插件未生效 | 个人配置放在 shell 加载块前；已有 OMZ 时由原配置负责主题与插件 |
| 历史建议或高亮不出现 | 检查 Homebrew 插件是否安装，原配置是否提前 return；使用交互 Zsh |
| 图标显示方框 | 在实际显示的终端选择 Nerd Font，不能只安装字体 |
| CLI 版本不是刚安装的版本 | `type -a claude codex` 检查多个来源；默认不覆盖已有 CLI，按原渠道更新 |
| 默认装完后全套 check 报缺少 Homebrew/Node | 默认只装三件套，先用 `check.sh --bootstrap`；其余软件交给 agent 安装 |
| gh 装好却无法操作私有仓库 | 按账号手册完成浏览器授权、核对账号，检查组织权限与 SSO |
| GitHub 授权页面打不开或设备码过期 | 在用户浏览器打开 CLI 显示的官方地址；过期则重跑获取新码，不把码发给 agent |
| CC Switch 下载遇到 GitHub API 限流 | 等待限流恢复后重跑，或从官方 Releases 手动安装 Mac 应用 |
| Orca 找不到 Claude/Codex | 完全退出重开；核对 CLI 的实际路径，详见 Orca 专篇 |
| SSH 的 `UseKeychain` 不识别 | 使用 Apple `/usr/bin/ssh`，核对是否被其他 OpenSSH 覆盖 |
| SSH 测试退出 1 | GitHub 认证成功时也可能退出 1，以认证消息为准 |
| `Permission denied (publickey)` | 检查实际生效的 IdentityFile、钥匙串、公钥添加账号和密钥有效期，见 SSH 专篇 |
| gh/glab 已登录但 SSH 不通 | CLI 登录与 SSH 认证分开配置；完成密钥生成、添加公钥与 Host 配置后再测试 |
| 自建 GitLab SSH 超时 | 网页域名/端口不一定是 SSH 地址；核对项目 Clone SSH 地址和管理员提供的主机/端口 |
| SSH 问候显示错误账号 | 检查 Host 别名与对应密钥，核对 remote 使用的别名，不覆盖全局配置或删除其他密钥 |
| GUI 应用找不到新装 CLI | 完全退出应用后重新启动，确认其终端环境可看到 PATH |
| Homebrew 提示 `/Applications` 中已有应用 | 保留已有应用或自行确认后整理重复安装，不使用 `--force` 强制接管 |
| 下载失败、HTTP 错误 | 检查实际网络、代理与目标域名，修复后重跑；脚本以非零码退出 |
| GNU 参数在 Mac 报错 | macOS 默认 BSD 工具；按需安装 `coreutils` / `gnu-sed` 并使用 g 前缀命令 |
| 只装 shell 后 check 报缺少 AI/Node | 检查覆盖全套默认组件；按模块安装时，其他组件缺失属正常 |

详细说明和官方链接见 [README](README.md) 的对应手册。

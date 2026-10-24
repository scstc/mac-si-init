# SSH 初始化并连接 GitHub / GitLab

这部分由 agent 在三件套装好后的阶段引导完成，首步安装器不自动生成密钥或上传。用户已经要求配置 SSH 时，确认平台、账号和主机信息后继续执行，不再只给一个可选提示。

CLI 登录用于管理账号和上传公钥，SSH 用于 Git 的 SSH 连接，Git 姓名/邮箱用于提交署名；三者分别配置和验证。

## 1. 确认平台与已有密钥

集中确认使用 GitHub、GitLab 还是两者，以及各自账号。自建 GitLab 分别确认**网页/API 主机、SSH 主机、SSH 端口、SSH 用户**，以项目页面 Clone → SSH 地址或管理员说明为准，不能直接使用网页端口。GitHub.com / GitLab.com 通常使用 SSH 用户 `git`。

检查 `~/.ssh` 的文件名、权限、Host / Include 配置和公钥指纹，不读取、展示或上传私钥内容：

```zsh
ls -la ~/.ssh
# 对实际存在、准备复用的公钥查看指纹
/usr/bin/ssh-keygen -lf ~/.ssh/id_ed25519.pub
```

目录不存在时后续创建；已有合适密钥时优先按用户选择复用，不强制重建。只有私钥而公钥丢失时，可在本机通过 `ssh-keygen -y -f <私钥路径>` 恢复公钥到新的 `.pub` 文件，不覆盖其他文件。

## 2. 按需生成密钥

以下示例为两平台分别创建密钥，便于单独撤销；仅使用一个平台时只生成对应一对。先替换占位符，并确认私钥、公钥路径均未占用：

```zsh
mkdir -p ~/.ssh
chmod 700 ~/.ssh
# 仅在对应文件名尚未使用时执行
/usr/bin/ssh-keygen -t ed25519 -C '<你的邮箱或设备备注>' -f ~/.ssh/id_ed25519_github
/usr/bin/ssh-keygen -t ed25519 -C '<你的邮箱或设备备注>' -f ~/.ssh/id_ed25519_gitlab
```

让用户在本机终端设置私钥口令（passphrase），解释它不是平台登录密码。不要通过 `-N ""` 默认为用户创建无口令密钥，也不要在覆盖提示上替用户选择 Yes。agent 无法提供隐藏输入时，将命令交给用户在自己的终端运行，再回来检查文件与指纹。口令不发送到聊天。

## 3. 配置 macOS 钥匙串

使用系统 OpenSSH，无需额外安装 ssh-agent，只添加实际使用的密钥：

```zsh
/usr/bin/ssh-add -l
/usr/bin/ssh-add --apple-use-keychain ~/.ssh/id_ed25519_github
/usr/bin/ssh-add --apple-use-keychain ~/.ssh/id_ed25519_gitlab
```

口令和钥匙串确认由用户在本机输入。`ssh-add -l` 返回 1 可能只是没有已加载密钥；仅在无法连接 agent 时，才在当前终端执行 `eval "$(/usr/bin/ssh-agent -s)"` 后重试，不在每次开终端时新建 agent。[macOS 钥匙串官方指引](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent)。

## 4. 合并 SSH 配置

修改 `~/.ssh/config` 前先备份，保留符号链接、其他主机和 Include 文件。检查已有匹配条目和通配规则，避免重复；更具体的规则通常放在 `Host *` 前，再用 `ssh -G` 核对生效结果。不要直接覆盖整份文件或在末尾重复粘贴。

GitHub.com / GitLab.com 示例，路径按实际选择调整：

```sshconfig
Host github.com
  HostName github.com
  User git
  IdentityFile ~/.ssh/id_ed25519_github
  IdentitiesOnly yes
  AddKeysToAgent yes
  UseKeychain yes

Host gitlab.com
  HostName gitlab.com
  User git
  IdentityFile ~/.ssh/id_ed25519_gitlab
  IdentitiesOnly yes
  AddKeysToAgent yes
  UseKeychain yes
```

```zsh
chmod 600 ~/.ssh/config
/usr/bin/ssh -G github.com
/usr/bin/ssh -G gitlab.com
```

核对 HostName、User、Port、IdentityFile。自建 GitLab 配置单独条目，可用 `gitlab-work` 别名；SSH 主机和端口按实际地址填写，网页登录使用网页/API 主机。

同一平台的个人/工作账号使用不同 Host 别名和对应密钥，例如 `github-personal`、`github-work`；后续 Git remote 必须使用正确别名，避免连接到错误账号。

## 5. 添加到 GitHub

按 [账号手册](04-git-and-accounts.md) 完成 gh 登录，核对当前账号，比较已有公钥指纹；已存在就跳过，不删除重建：

```zsh
gh auth status --hostname github.com
GH_HOST=github.com gh api user --jq .login
GH_HOST=github.com gh ssh-key list
# 确认目标账号、选定公钥且尚未添加时执行
GH_HOST=github.com gh ssh-key add ~/.ssh/id_ed25519_github.pub --title 'My Mac - GitHub' --type authentication
```

用户已经要求添加到 GitHub 时，不重复索要同一项授权。权限不足则引导补充权限后重试：

```zsh
gh auth refresh --hostname github.com --scopes admin:public_key
```

也可让用户执行 `pbcopy < ~/.ssh/id_ed25519_github.pub`，再进入 GitHub 头像 → Settings → SSH and GPG keys → New SSH key，选择 Authentication Key，粘贴保存。密码和二次验证由用户在官方网页完成。参数见 [gh ssh-key add](https://cli.github.com/manual/gh_ssh-key_add)、[gh auth refresh](https://cli.github.com/manual/gh_auth_refresh)。

## 6. 添加到 GitLab

先按账号手册登录对应 GitLab 实例。以下针对 gitlab.com；自建实例把 `GITLAB_HOST` 替换为确认的**网页/API 主机**，先核对账号和已有公钥，再上传。agent 应在不属于任何 Git 仓库的临时目录执行这组命令，避免当前项目的 remote 干扰主机选择：

```zsh
glab auth status --hostname gitlab.com
GITLAB_HOST=gitlab.com glab api user | jq -r .username
GITLAB_HOST=gitlab.com glab ssh-key list
# 确认未添加时执行
GITLAB_HOST=gitlab.com glab ssh-key add ~/.ssh/id_ed25519_gitlab.pub --title 'My Mac - GitLab' --usage-type auth
```

同指纹公钥已存在时跳过；过期、撤销或组织限制时解释实际状态，再按用户/组织选择处理，不自动执行 `--replace` 或删除远端密钥。要求有效期时按组织规则设置，不硬编码未来日期。

API 授权不适用时，让用户执行 `pbcopy < ~/.ssh/id_ed25519_gitlab.pub`，打开对应 GitLab 实例 → 头像 → Edit profile → Access → SSH keys → Add new key，粘贴公钥、填设备名称，选择 Authentication 用途与所需有效期后保存。按实际版本界面引导。[glab 上传参数](https://docs.gitlab.com/cli/ssh-key/add/)、[GitLab SSH 官方说明](https://docs.gitlab.com/user/ssh/)。

## 7. 验证连接与仓库权限

先解释首次连接的主机指纹提示。GitHub 与 GitLab.com 分别核对 [GitHub 官方指纹](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/githubs-ssh-key-fingerprints)、[GitLab.com 官方指纹](https://docs.gitlab.com/user/gitlab_com/#ssh-host-keys-fingerprints)；自建实例使用帮助页实例配置或管理员提供的信息。核对后由用户确认，不使用 `StrictHostKeyChecking=no` 绕过，也不将 `ssh-keyscan` 结果当作可信依据。

```zsh
/usr/bin/ssh -T git@github.com
/usr/bin/ssh -T git@gitlab.com
# 自建实例/多账号示例，使用实际设置的 Host 别名
/usr/bin/ssh -T gitlab-work
```

GitHub 成功问候可能返回退出码 1，结合认证消息和账号判断；GitLab 应显示正确账号的欢迎信息。超时先查主机、端口和网络；`Permission denied (publickey)` 则检查有效 IdentityFile、钥匙串加载、公钥、实际账号和过期状态。

在用户指定的仓库中查看 `git remote -v`。用户要求该仓库改用 SSH 时，先记录旧地址，从仓库页面复制正确的 SSH Clone 地址，再执行：

```zsh
git remote set-url origin '<该仓库的SSH克隆地址>'
git ls-remote origin HEAD
```

有 Host 别名时替换克隆地址中的主机，保留非标准端口。不配置全局 `insteadOf` 转换所有仓库，也不执行测试 push、创建远端仓库或改动代码。

分别验收：CLI 已登录、目标账号已添加公钥、SSH 已认证、指定仓库可读。没有指定仓库时标记“SSH 已认证，仓库权限待验证”，不声称所有仓库都有权限。报告不包含私钥、口令或 Token，不将个人账号清单写进仓库。

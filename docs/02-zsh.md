# 为系统 Zsh 配置 Oh My Zsh 与终端增强

macOS 默认 Shell 已是 Zsh，通常无需安装 Zsh 或运行 `chsh`。本章只配置 Oh My Zsh、历史建议、语法高亮和字体。[Apple 官方说明](https://support.apple.com/zh-cn/guide/terminal/trml113/mac)。

## 安装

```bash
bash scripts/install.sh --only shell
bash scripts/install.sh --only apps
```

使用系统 `/bin/zsh`，不额外安装 Homebrew Zsh。Oh My Zsh 从 [官方 Git 仓库](https://github.com/ohmyzsh/ohmyzsh) 浅克隆，增强功能由 Homebrew 管理。

命令中的 `bash scripts/install.sh` 只是让 Bash 执行安装脚本，可以直接在 Zsh 终端输入，不会更改默认 Shell；日常终端仍使用 Zsh。

## 验证

新开终端后执行：

```zsh
echo "$ZSH_VERSION"
echo "$ZSH"
whence -w omz
```

输入一段用过的命令，应出现灰色历史建议，按右方向键采纳。语法高亮会标识命令。默认主题 `robbyrussell` 显示 Git 分支，开箱可用。

## 配置

如需自定义，在 `.zshrc` 的 `mac-si-init: shell` 块**之前**添加：

```zsh
ZSH_THEME="robbyrussell"
plugins=(git macos)
```

已有 Oh My Zsh 时保留原主题与插件。默认不会添加大量插件、改快捷键或强制更换主题。

只有从旧系统迁移或用户主动换过 Shell 的情况，才需要检查是否仍在使用其他 Shell。若用户希望改回系统 Zsh，再引导执行 `chsh -s /bin/zsh` 并重新登录，不将此命令列为常规安装步骤。

iTerm2 的 Profiles → Text 与 Terminal.app 的描述文件 → 文本中分别选择 Meslo Nerd Font；安装字体不会自动改变现有终端配置。

## 常见坑

- 已有 `.zshrc` 中 `return` / `exit` 会使末尾配置块无法执行，需自行将块移动到可达位置。
- 已有语法高亮插件时避免重复配置；用户自行添加的 ZLE 插件应放在语法高亮加载之前。
- 自定义 `ZDOTDIR` / `ZSH` 时，将变量导出给安装进程；仅在 `.zshrc` 内赋值的变量不会被 Bash 安装器自动读入。
- SSH 登录与 VS Code 终端中字体由显示终端决定，不由远端字体决定。
- 撤销方式和配置备份位置见 README；不需要覆盖整份 `.zshrc`。

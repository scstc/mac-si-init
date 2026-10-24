# Command Line Tools 与 Homebrew

## 安装

系统终端执行：

```bash
xcode-select --install
```

完成系统安装窗口后，再安装 Homebrew。项目的 core / shell / apps 模块会完成后一步；默认三件套不安装 Homebrew。也可以按 [Homebrew 官网](https://brew.sh/) 的命令手动安装。不要用 `sudo brew install`，也不要 `sudo bash scripts/install.sh`。

## 验证

```bash
xcode-select -p
xcrun --find clang
uname -m
brew --prefix
brew doctor
```

Apple Silicon 原生环境通常为 `arm64` + `/opt/homebrew`；历史 Intel 安装通常位于 `/usr/local`。软件及系统支持范围遵循 [Homebrew 当前安装要求](https://docs.brew.sh/Installation)，旧 Intel Mac 不保证都有预编译包。

## 配置

脚本自动写入基础 PATH 块。手动安装 Homebrew 时，按安装结束的 Next steps 配置 `brew shellenv`。登录 Zsh 读取 `.zprofile`，交互 Zsh 读取 `.zshrc`，所以项目会在两处加载同一份带防重复加载保护的环境文件。

## 常见坑

- Apple Silicon 不需要默认安装 Rosetta。若终端勾选「使用 Rosetta 打开」，先关闭再运行脚本。
- 迁移助手可能留下双份 Homebrew。先用 `type -a brew` 排查，再按 [官方常见问题](https://docs.brew.sh/Common-Issues) 处理，脚本不会删除其中任何一份。
- 已装完整 Xcode 却找不到 clang：先启动 Xcode 完成首次配置，确认 `xcode-select -p` 指向有效的开发者目录。
- 网络中断时脚本返回非零；修复网络后重跑即可，不会假报全部完成。

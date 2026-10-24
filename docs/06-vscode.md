# VS Code

## 安装与验证

```zsh
bash scripts/install.sh --only apps
code --version
```

如果原来从 DMG 手动安装过 VS Code，不要强制覆盖。保留现有应用，按 [官方 macOS 安装文档](https://code.visualstudio.com/docs/setup/mac) 在命令面板运行 `Shell Command: Install 'code' command in PATH`，或先自行整理重复安装。

## 配置

在用户设置中合并以下内容：

```json
{
  "terminal.integrated.defaultProfile.osx": "zsh"
}
```

安装自己需要的扩展，脚本不自动安装全部 AI 扩展：

```zsh
code --install-extension anthropic.claude-code
code --install-extension openai.chatgpt
# 使用 Copilot 时再装
code --install-extension GitHub.copilot
```

扩展登录按界面操作；CLI 登录不保证扩展自动完成授权。

## 常见坑

- VS Code 在安装工具前已打开：完全退出并重新打开，使新进程拿到 PATH。
- 界面启动的应用不一定继承所有 Shell 变量；项目同时为登录与交互 Zsh 配置基础 PATH。
- Nerd Font 要另外在编辑器/集成终端设置里选择，安装字体不会修改个人设置。

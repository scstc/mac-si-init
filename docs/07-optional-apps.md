# 可选应用与 macOS 替代项

这些工具由 agent 询问需求后安装。CC Switch 已是默认三件套之一，见 [三件套手册](05-ai-cli.md)。下载时根据发布页选择 Apple Silicon / arm64 或 Intel / x64 / Universal，避免硬编码会过期的 DMG 文件名。

| 工具 | 用途 | 安装入口 |
|---|---|---|
| DBX | 数据库客户端 | [官方 Releases](https://github.com/t8y2/dbx/releases) |
| Orca | 多智能体开发与 worktree 工作流 | [安装与首次使用专篇](09-orca.md)，`brew install --cask stablyai/orca/orca` |
| GenOffice | AI 文档、表格与演示编辑 | [官方 Releases](https://github.com/genspark-ai/genoffice/releases) |
| Obsidian | 本地 Markdown 笔记 | `brew install --cask obsidian` |
| Rectangle | 窗口排列 | `brew install --cask rectangle` |
| Raycast | 应用启动与效率工具 | `brew install --cask raycast` |

上游发布资产与支持架构会变化；无对应 Mac 资产时跳过，不下载 Windows 安装包。第三方 tap 需要自行评估，因此不在初始化时自动添加。

## 验证与配置

首次启动在应用内查看版本与设置。系统窗口排列、Spotlight 和快捷指令已能覆盖一部分 PowerToys 的用途，按自己的习惯选择是否额外安装。

cc-switch 首次写入供应商前先确认其备份机制与将修改的 CLI 设置。Orca 等应用如果在工具安装前已启动，应退出重开，让它发现新的 CLI。

## 常见坑

- macOS 阻止启动时，先确认下载源、签名与架构，按系统「隐私与安全性」提示处理；不把关闭 Gatekeeper 或批量清除隔离属性写进初始化脚本。
- 不安装 WSL；需要运行真正的 Linux 服务时，再按项目需求选容器或虚拟机。
- BSD `sed` / `date` / `stat` 与 GNU 参数不同。确需 GNU 命令时，可选 `brew install coreutils gnu-sed`，使用 `gdate` / `gsed`，不覆盖系统命令。

工具来源：[cc-switch](https://github.com/farion1231/cc-switch)、[DBX](https://github.com/t8y2/dbx)、[Orca](https://github.com/stablyai/orca)、[GenOffice](https://github.com/genspark-ai/genoffice)、[Rectangle](https://rectangleapp.com/)、[Raycast](https://www.raycast.com/)。

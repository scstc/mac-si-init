# fnm 与 Node.js

## 安装

```bash
bash scripts/install.sh --only core
```

基础模块安装 fnm，若当前 PATH 没有 Node.js，则解析并安装当时的 LTS。已有 Node.js 时保留，不自动卸载 nvm、mise、Volta 或系统安装包。

## 验证

新开终端：

```zsh
fnm --version
node --version
npm --version
type -a node
fnm list
```

## 配置

全新环境会追加官方建议的 Zsh 初始化形式：

```zsh
eval "$(fnm env --use-on-cd --shell zsh)"
```

已有 Node 环境不自动追加 fnm 初始化，避免影响当前版本管理器。决定迁移时，先检查 `type -a node`，清理原管理器的启动配置，再按 [fnm 官方文档](https://github.com/Schniz/fnm#shell-setup) 初始化。

手动安装、使用 LTS，并设置默认版本：

```zsh
fnm install --lts
fnm use --lts
fnm default "$(node --version)"
```

项目内提交 `.node-version` 或 `.nvmrc` 可固定 Node 版本；`--use-on-cd` 在进入目录时自动选择。不要同时启用多个版本管理器的自动切换。

## 常见坑

- Node 的具体 LTS 版本由 fnm 当时解析，不照搬 Windows 文档的版本号。
- fnm 下的全局 npm 包随 Node 版本分开管理；项目默认的两款原生 AI CLI 不依赖这类全局 npm 包。
- 切换 Node 大版本后需要重新安装该版本使用的全局 npm 包，不使用 `sudo npm install -g`。

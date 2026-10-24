#!/bin/bash
# 仅检查本机，不联网、不登录、不升级、不输出配置或 token。
set -euo pipefail
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
# shellcheck source=scripts/lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"
BOOTSTRAP=0
case "${1:-}" in
  -h|--help) printf '用法：bash scripts/check.sh [--bootstrap]（只读；默认全套，--bootstrap 只检查三件套）\n'; exit 0 ;;
  --bootstrap) [ "$#" = 1 ] || die '--bootstrap 不接受其他参数'; BOOTSTRAP=1 ;;
  '') [ "$#" = 0 ] || die '不接受空参数' ;;
  *) die "未知参数：$1" ;;
esac
[ "$(uname -s)" = Darwin ] || die '本检查脚本只支持 macOS'
missing=0
export PATH="$HOME/.local/bin:$PATH"
if [ "$BOOTSTRAP" = 1 ]; then
  for tool in claude codex; do
    if command -v "$tool" >/dev/null 2>&1; then
      printf '%s: %s\n' "$tool" "$(command -v "$tool")"
      if ! "$tool" --version; then missing=1; fi
    else
      printf '缺少 %s\n' "$tool"; missing=1
    fi
  done
  if [ -d "$HOME/Applications/CC Switch.app" ] || [ -d '/Applications/CC Switch.app' ]; then
    printf 'CC Switch: 已安装\n'
  else
    printf '缺少 CC Switch\n'; missing=1
  fi
  printf '这里只检查安装；账号/供应商是否可用需实际登录后验证。\n'
  exit "$missing"
fi
if BREW=$(find_brew); then
  brew_env=$("$BREW" shellenv)
  eval "$brew_env"
  printf 'Homebrew: %s\n' "$BREW"
else
  printf '缺少 Homebrew\n'; missing=1
fi
export PATH="$HOME/.local/bin:$PATH"
# 不加载用户 .zshrc，也不运行会创建 multishell 目录的 fnm env。
# Node 未在 PATH 中时，请先按安装提示新开 Zsh 终端再检查。
if ! xcode-select -p >/dev/null 2>&1 || ! xcrun --find clang >/dev/null 2>&1; then
  printf '缺少 Command Line Tools\n'; missing=1
fi
for tool in zsh git fnm node npm gh glab jq rg claude codex; do
  if command -v "$tool" >/dev/null 2>&1; then
    printf '\n%s: %s\n' "$tool" "$(command -v "$tool")"
    if ! "$tool" --version; then missing=1; fi
  else
    printf '\n缺少 %s\n' "$tool"; missing=1
  fi
done
if [ -r "${ZSH:-$HOME/.oh-my-zsh}/oh-my-zsh.sh" ]; then
  printf '\nOh My Zsh: 已安装\n'
else
  printf '\n缺少 Oh My Zsh\n'; missing=1
fi
printf '\n可选桌面组件：\n'
if [ -n "${BREW:-}" ]; then
  for app in iterm2 visual-studio-code font-meslo-lg-nerd-font obsidian; do
    if "$BREW" list --cask "$app" >/dev/null 2>&1; then
      printf '  %s: 已安装\n' "$app"
    else
      printf '  %s: 未由 Homebrew 安装（可选）\n' "$app"
    fi
  done
fi
printf '\n更新命令见 docs/08-maintenance.md；检查不会升级软件。\n'
exit "$missing"

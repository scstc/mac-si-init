#!/bin/bash
set -Eeuo pipefail

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
# shellcheck source=scripts/lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"
# shellcheck source=scripts/lib/cc-switch.sh
source "$SCRIPT_DIR/lib/cc-switch.sh"
DRY_RUN=0
ONLY=bootstrap
WITH_OBSIDIAN=0

usage() {
  cat <<'EOF'
mac-si-init — macOS → AI 开发工作站

用法：bash scripts/install.sh [参数]
  --only bootstrap|all|core|shell|ai|apps  默认 bootstrap（三件套）
  --dry-run                    只显示计划，不联网、不写配置、不安装
  --with-obsidian              apps/all 额外安装 Obsidian
  -h, --help                   显示帮助

bootstrap: Claude Code / CC Switch / Codex CLI，然后交给 agent 继续配置
core: Git / fnm + Node.js LTS / gh / glab / jq / ripgrep
shell: Oh My Zsh / 历史建议 / 语法高亮
ai: Claude Code latest / Codex（官方独立安装器）
apps: iTerm2 / VS Code / Meslo Nerd Font
bootstrap/ai 不需要 Homebrew、Node.js 或 Command Line Tools。
其他模块会先检查 Command Line Tools 和 Homebrew，并配置其 PATH。
请以普通用户运行；首次安装 Homebrew 时官方安装器可能要求 sudo 密码。
EOF
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --only)
      [ "$#" -ge 2 ] || die '--only 需要模块名'
      ONLY="$2"; shift 2 ;;
    --dry-run) DRY_RUN=1; shift ;;
    --with-obsidian) WITH_OBSIDIAN=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) die "未知参数：$1（使用 --help 查看帮助）" ;;
  esac
done
case "$ONLY" in bootstrap|all|core|shell|ai|apps) ;; *) die "未知模块：$ONLY" ;; esac
if [ "$WITH_OBSIDIAN" = 1 ] && [ "$ONLY" != all ] && [ "$ONLY" != apps ]; then
  die '--with-obsidian 只能配合 all 或 apps'
fi

trap 'printf "\n安装中断（第 %s 行）。修复错误后可重跑；已完成步骤会保留。\n" "$LINENO" >&2' ERR

preflight() {
  if [ "$DRY_RUN" = 1 ]; then
    log '预览模式：实际执行只支持 macOS 普通用户、原生架构终端'
    case "$ONLY" in
      bootstrap|ai) printf '[预览] 三件套/AI 安装跳过 CLT 与 Homebrew\n' ;;
      *) printf '[预览] 检查 Command Line Tools；缺失则打开系统安装窗口，装好后重跑\n' ;;
    esac
    return
  fi
  [ "$(uname -s)" = Darwin ] || die '本工具只在 macOS 安装；其他系统可以用 --dry-run 查看计划'
  [ "$(id -u)" -ne 0 ] || die '请勿 sudo 整个脚本，请以普通用户运行'
  if [ "$(sysctl -in sysctl.proc_translated 2>/dev/null || true)" = 1 ]; then
    die '当前终端运行于 Rosetta；请关闭「使用 Rosetta 打开」，在原生终端重跑'
  fi
  case "$ONLY" in bootstrap|ai) return ;; esac
  if ! xcode-select -p >/dev/null 2>&1 || ! xcrun --find clang >/dev/null 2>&1; then
    xcode-select --install || true
    die '请先完成弹出的 Command Line Tools 安装，再重新运行本脚本'
  fi
}

ensure_cli_path() {
  local line='typeset -U path; path=("$HOME/.local/bin" $path)'
  append_block "${ZDOTDIR:-$HOME}/.zprofile" local-bin "$line"
  append_block "${ZDOTDIR:-$HOME}/.zshrc" local-bin "$line"
  export PATH="$HOME/.local/bin:$PATH"
}

ensure_brew() {
  log 'Homebrew'
  if [ "$DRY_RUN" = 1 ]; then
    BREW=brew
    printf '[预览] 若未安装 Homebrew，运行其官方安装器\n'
  else
    BREW=$(find_brew || true)
    if [ -z "$BREW" ]; then
      remote_script https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh /bin/bash
      BREW=$(find_brew) || die 'Homebrew 安装未完成'
    fi
    local prefix brew_env
    prefix=$("$BREW" --prefix)
    case "$(uname -m):$prefix" in
      arm64:/usr/local|x86_64:/opt/homebrew) die 'Homebrew 架构与终端不匹配，请先处理双架构环境（见 troubleshooting.md）' ;;
    esac
    brew_env=$("$BREW" shellenv)
    eval "$brew_env"
  fi

  # .zprofile 给登录终端；.zshrc 也加载，兼容 VS Code 的非登录终端。
  local env_file="$HOME/.mac-si-init/env.zsh"
  run mkdir -p "$HOME/.mac-si-init"
  if [ "$DRY_RUN" = 1 ]; then
    printf '[预览] 创建 %s（Homebrew + ~/.local/bin PATH）\n' "$env_file"
  else
    local env_temp
    env_temp=$(mktemp "${TMPDIR:-/tmp}/mac-si-init-env.XXXXXX")
    cat > "$env_temp" <<'EOF'
# 由 mac-si-init 管理；安装时更新此文件。
if [[ -z "${_MAC_SI_ENV_LOADED:-}" ]]; then
EOF
    # 写入本次确认过的 brew 路径，避免双安装环境误加载另一架构。
    printf '  if [[ -x %q ]]; then\n    eval "$(%q shellenv)"\n  fi\n' "$BREW" "$BREW" >> "$env_temp"
    cat >> "$env_temp" <<'EOF'
  typeset -U path
  path=("$HOME/.local/bin" $path)
  _MAC_SI_ENV_LOADED=1
fi
EOF
    if ! cmp -s "$env_temp" "$env_file"; then
      backup "$env_file"
      cp "$env_temp" "$env_file"
    fi
    rm -f "$env_temp"
  fi
  local env_line='[[ -r "$HOME/.mac-si-init/env.zsh" ]] && source "$HOME/.mac-si-init/env.zsh"'
  append_block "${ZDOTDIR:-$HOME}/.zprofile" env "$env_line"
  append_block "${ZDOTDIR:-$HOME}/.zshrc" env "$env_line"
  export PATH="$HOME/.local/bin:$PATH"
}

formula() {
  local name
  for name in "$@"; do
    if [ "$DRY_RUN" = 0 ] && "$BREW" list --formula "$name" >/dev/null 2>&1; then
      printf '已安装：%s\n' "$name"
    else
      run "$BREW" install --formula "$name"
    fi
  done
}

cask() {
  local name
  for name in "$@"; do
    if [ "$DRY_RUN" = 0 ] && "$BREW" list --cask "$name" >/dev/null 2>&1; then
      printf '已安装：%s\n' "$name"
    else
      run "$BREW" install --cask "$name"
    fi
  done
}

install_core() {
  log '开发工具'
  formula git fnm gh glab jq ripgrep
  if [ "$DRY_RUN" = 1 ]; then
    printf '[预览] 若已有 Node.js，保留；否则通过 fnm 安装当前 LTS\n'
  elif command -v node >/dev/null 2>&1; then
    printf '保留已有 Node.js：%s (%s)\n' "$(node --version)" "$(command -v node)"
    printf '保留现有 Node 初始化；如需启用 fnm，见 docs/03-nodejs.md\n'
    return
  else
    local fnm_env
    fnm_env=$(fnm env --shell bash)
    eval "$fnm_env"
    fnm install --lts
  fi
  append_block "${ZDOTDIR:-$HOME}/.zshrc" fnm \
    'if command -v fnm >/dev/null 2>&1; then eval "$(fnm env --use-on-cd --shell zsh)"; fi'
}

install_shell() {
  log 'Oh My Zsh'
  formula git zsh-autosuggestions zsh-syntax-highlighting
  local zsh_dir="${ZSH:-$HOME/.oh-my-zsh}" target="$HOME/.mac-si-init/zshrc.zsh"
  if [ "$DRY_RUN" = 1 ]; then
    run git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git "$zsh_dir"
  elif [ -f "$zsh_dir/oh-my-zsh.sh" ]; then
    printf '保留已有 Oh My Zsh：%s\n' "$zsh_dir"
  elif [ -e "$zsh_dir" ]; then
    die "$zsh_dir 已存在但不是完整的 Oh My Zsh 安装，请先检查"
  else
    git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git "$zsh_dir"
  fi
  if [ "$DRY_RUN" = 1 ] || ! cmp -s "$SCRIPT_DIR/zshrc.template.zsh" "$target"; then
    backup "$target"
    run cp "$SCRIPT_DIR/zshrc.template.zsh" "$target"
  fi
  append_block "${ZDOTDIR:-$HOME}/.zshrc" shell \
    '[[ -r "$HOME/.mac-si-init/zshrc.zsh" ]] && source "$HOME/.mac-si-init/zshrc.zsh"'
}

install_ai_tool() {
  local name="$1" url="$2" interpreter="$3"
  shift 3
  # 避免官方安装器自动迁移/删除其他渠道的安装。已有工具留给用户按原渠道升级。
  if [ "$DRY_RUN" = 0 ] && command -v "$name" >/dev/null 2>&1; then
    printf '保留已有 %s：%s；更新/迁移见 docs/05-ai-cli.md\n' "$name" "$(command -v "$name")"
    return
  fi
  remote_script "$url" "$interpreter" "$@"
  if [ "$DRY_RUN" = 0 ]; then
    hash -r
    command -v "$name" >/dev/null 2>&1 || die "$name 安装器结束但找不到命令，请检查 ~/.local/bin"
    "$name" --version
  fi
}

install_ai() {
  log 'AI CLI：官方原生安装器'
  install_ai_tool claude https://claude.ai/install.sh /bin/bash latest
  install_ai_tool codex https://chatgpt.com/codex/install.sh /bin/sh
}

install_apps() {
  log '终端、编辑器与字体'
  cask iterm2 visual-studio-code font-meslo-lg-nerd-font
  if [ "$WITH_OBSIDIAN" = 1 ]; then cask obsidian; fi
}

preflight
case "$ONLY" in
  bootstrap|ai) ensure_cli_path ;;
  *) ensure_brew ;;
esac
case "$ONLY" in
  bootstrap) install_ai; install_cc_switch ;;
  all) install_core; install_shell; install_ai; install_cc_switch; install_apps ;;
  core) install_core ;;
  shell) install_shell ;;
  ai) install_ai ;;
  apps) install_apps ;;
esac
if [ "$DRY_RUN" = 1 ]; then
  log '预览结束，没有执行安装或写入配置'
else
  log '所选模块已完成'
  case "$ONLY" in
    bootstrap)
      printf '1. 打开 ~/Applications/CC Switch.app，按需配置供应商；也可直接使用 CLI 官方登录。\n'
      printf '2. 在本项目目录任选一个 agent，按提示登录后继续初始化：\n'
      printf '   bash scripts/start-agent.sh claude\n'
      printf '   bash scripts/start-agent.sh codex\n'
      printf 'agent 会带你安装其余软件，并逐步引导 GitHub/SSH/GitLab 授权。\n'
      printf '只检查三件套：bash scripts/check.sh --bootstrap\n' ;;
    *)
      printf '请新开 Zsh 终端，再运行 bash scripts/check.sh 检查。\n'
      printf '账号授权与后续引导：bash scripts/start-agent.sh claude（或 codex）\n' ;;
  esac
fi

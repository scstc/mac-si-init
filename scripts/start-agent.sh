#!/bin/bash
# 在项目根目录启动交互 agent，传入同一份初始化任务；保留正常权限与登录流程。
set -euo pipefail
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
PROJECT_DIR=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)
case "${1:-}" in
  -h|--help|'')
    printf '用法：bash scripts/start-agent.sh claude|codex|codex-cli\n'
    printf '查看交给 agent 的任务：bash scripts/start-agent.sh --print-prompt\n'
    exit 0 ;;
  --print-prompt) cat "$PROJECT_DIR/docs/agent-prompt.md"; exit 0 ;;
  claude) agent=claude ;;
  codex|codex-cli) agent=codex ;;
  *) printf '请选择 claude 或 codex\n' >&2; exit 1 ;;
esac
[ "$#" = 1 ] || { printf '请只指定一个 agent\n' >&2; exit 1; }
export PATH="$HOME/.local/bin:$PATH"
command -v "$agent" >/dev/null 2>&1 || {
  printf '找不到 %s，请先运行 bash scripts/install.sh\n' "$agent" >&2
  exit 1
}
cd "$PROJECT_DIR"
printf '启动 %s。首次使用请按 CLI 提示登录或确认供应商配置。\n' "$agent"
exec "$agent" "$(cat "$PROJECT_DIR/docs/agent-prompt.md")"

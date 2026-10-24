#!/bin/bash
# 兼容 macOS 自带 Bash 3.2。由 install.sh / check.sh 加载。

log() { printf '\n== %s ==\n' "$*"; }
die() { printf '错误：%s\n' "$*" >&2; exit 1; }

run() {
  if [ "${DRY_RUN:-0}" = 1 ]; then
    printf '[预览] '
    printf '%q ' "$@"
    printf '\n'
  else
    "$@"
  fi
}

find_brew() {
  if command -v brew >/dev/null 2>&1; then
    command -v brew
  elif [ -x /opt/homebrew/bin/brew ]; then
    printf '%s\n' /opt/homebrew/bin/brew
  elif [ -x /usr/local/bin/brew ]; then
    printf '%s\n' /usr/local/bin/brew
  else
    return 1
  fi
}

backup() {
  local target="$1" backup_file
  if [ -e "$target" ] || [ -L "$target" ]; then
    if [ "${DRY_RUN:-0}" = 1 ]; then
      printf '[预览] 为 %s 创建唯一的 .mac-si-init.*.bak 备份\n' "$target"
    else
      backup_file=$(mktemp "${target}.mac-si-init.$(date +%Y%m%d-%H%M%S).XXXXXX")
      cp -p "$target" "$backup_file"
      mv "$backup_file" "$backup_file.bak"
    fi
  fi
}

# 仅在没有对应标记时追加。保持原文件及符号链接，写入前备份。
append_block() {
  local target="$1" marker="$2" content="$3"
  if [ -f "$target" ] && grep -Fqx "# >>> mac-si-init: $marker >>>" "$target"; then
    printf '已配置：%s (%s)\n' "$target" "$marker"
    return
  fi
  if [ "${DRY_RUN:-0}" = 1 ]; then
    printf '[预览] 备份并追加 %s 到 %s\n' "$marker" "$target"
    return
  fi
  backup "$target"
  mkdir -p "$(dirname "$target")"
  printf '\n# >>> mac-si-init: %s >>>\n%s\n# <<< mac-si-init: %s <<<\n' \
    "$marker" "$content" "$marker" >> "$target"
}

# 下载必须成功且内容非空，才执行远程脚本；不使用管道掩盖 curl 失败。
remote_script() {
  local url="$1" interpreter="$2" temp status=0
  shift 2
  if [ "${DRY_RUN:-0}" = 1 ]; then
    printf '[预览] 下载 %s，成功后使用 %s 执行' "$url" "$interpreter"
    if [ "$#" -gt 0 ]; then printf ' %q' "$@"; fi
    printf '\n'
    return
  fi
  temp=$(mktemp "${TMPDIR:-/tmp}/mac-si-init.XXXXXX")
  if curl --fail --show-error --silent --location --retry 3 "$url" -o "$temp" && [ -s "$temp" ]; then
    "$interpreter" "$temp" "$@" || status=$?
  else
    status=1
  fi
  rm -f "$temp"
  return "$status"
}

#!/bin/bash
# 通过官方 Releases 安装 Universal 应用；只使用 macOS 系统自带工具。
install_cc_switch() {
  log 'CC Switch：官方 macOS Universal 发布包'
  local target="$HOME/Applications/CC Switch.app" existing
  for existing in "$target" '/Applications/CC Switch.app'; do
    if [ -e "$existing" ] || [ -L "$existing" ]; then
      printf '保留已有 CC Switch：%s\n' "$existing"
      return
    fi
  done
  if [ "$DRY_RUN" = 1 ]; then
    printf '[预览] 从 https://api.github.com/repos/farion1231/cc-switch/releases/latest 查询官方 macOS.zip\n'
    printf '[预览] 下载并解压 Universal 应用到 %s；不安装 Homebrew/Node/CLT\n' "$target"
    return
  fi
  CC_TEMP=$(mktemp -d "${TMPDIR:-/tmp}/mac-si-init-cc-switch.XXXXXX")
  CC_STAGE=''
  trap 'if [ -n "${CC_TEMP:-}" ]; then rm -rf "$CC_TEMP"; fi; if [ -n "${CC_STAGE:-}" ]; then rm -rf "$CC_STAGE"; fi' EXIT
  local metadata="$CC_TEMP/release.json" asset_name asset_url='' index=0 app='' candidate executable
  curl --fail --show-error --silent --location --retry 3 \
    https://api.github.com/repos/farion1231/cc-switch/releases/latest -o "$metadata"
  while asset_name=$(plutil -extract "assets.$index.name" raw -o - "$metadata" 2>/dev/null); do
    case "$asset_name" in
      CC-Switch-*-macOS.zip)
        asset_url=$(plutil -extract "assets.$index.browser_download_url" raw -o - "$metadata")
        break ;;
    esac
    index=$((index + 1))
  done
  case "$asset_url" in
    https://github.com/farion1231/cc-switch/releases/download/*) ;;
    *) die '官方最新发布未找到 macOS ZIP，请查看 docs/05-ai-cli.md；不猜测下载地址' ;;
  esac
  curl --fail --show-error --silent --location --retry 3 "$asset_url" -o "$CC_TEMP/app.zip"
  ditto -x -k "$CC_TEMP/app.zip" "$CC_TEMP/unpacked"
  for candidate in "$CC_TEMP"/unpacked/*.app; do
    [ -d "$candidate" ] || continue
    [ -z "$app" ] || die '发布包中包含多个应用，请检查官方发布包'
    app="$candidate"
  done
  [ -n "$app" ] || die '发布包中未找到 macOS 应用'
  executable=$(plutil -extract CFBundleExecutable raw -o - "$app/Contents/Info.plist")
  case "$executable" in ''|*/*) die 'CC Switch 应用元数据无效' ;; esac
  [ -x "$app/Contents/MacOS/$executable" ] || die 'CC Switch 发布包缺少可执行文件'
  mkdir -p "$HOME/Applications"
  CC_STAGE=$(mktemp -d "$HOME/Applications/.mac-si-init-cc-switch.XXXXXX")
  ditto "$app" "$CC_STAGE/CC Switch.app"
  [ ! -e "$target" ] && [ ! -L "$target" ] || die '安装过程中目标应用已出现，请检查后重跑'
  mv "$CC_STAGE/CC Switch.app" "$target"
  printf '已安装 CC Switch：%s\n' "$target"
  rm -rf "$CC_TEMP" "$CC_STAGE"
  CC_TEMP=''
  CC_STAGE=''
}

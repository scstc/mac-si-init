# 由 mac-si-init 管理。个人配置请写在 .zshrc 中，不要直接改此文件。
[[ -o interactive ]] || return 0
[[ -z "${_MAC_SI_SHELL_LOADED:-}" ]] || return 0
_MAC_SI_SHELL_LOADED=1

# 已有 Oh My Zsh 由原 .zshrc 加载时，保留主题和插件，不重复加载。
if (( ! $+functions[omz] )); then
  export ZSH="${ZSH:-$HOME/.oh-my-zsh}"
  if [[ -r "$ZSH/oh-my-zsh.sh" ]]; then
    ZSH_THEME="${ZSH_THEME-robbyrussell}"
    (( ${+plugins} )) || plugins=(git)
    source "$ZSH/oh-my-zsh.sh"
  fi
fi

if (( $+commands[brew] )); then
  _mac_si_prefix="${HOMEBREW_PREFIX:-$(brew --prefix)}"
  if (( ! $+functions[_zsh_autosuggest_start] )) && \
    [[ -r "$_mac_si_prefix/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ]]; then
    source "$_mac_si_prefix/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
  fi
  # 语法高亮放在本模板的最后加载。
  if (( ! $+functions[_zsh_highlight] )) && \
    [[ -r "$_mac_si_prefix/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]]; then
    source "$_mac_si_prefix/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
  fi
  unset _mac_si_prefix
fi

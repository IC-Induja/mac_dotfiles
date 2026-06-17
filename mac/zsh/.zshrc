# Source professional config — must be first so p10k instant prompt fires early
_mac_zsh_this="${${(%):-%x}:A}"
source "${_mac_zsh_this:h:h:h}/professional/zsh/.zshrc"
unset _mac_zsh_this

# ── macOS SDK paths (Rust compilation / linking) ──────────────────────────────
export PATH="/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk/usr/lib:$PATH"
export LIBRARY_PATH="$LIBRARY_PATH:/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk/usr/lib"

# ── Aliases ───────────────────────────────────────────────────────────────────
alias ll='ls -hlat'

# ── Kitty theme switcher ──────────────────────────────────────────────────────
ktheme() {
  local theme_dir="${HOME}/.config/kitty/themes"
  if [[ -z "$1" ]]; then
    echo "Usage: ktheme <theme-name>"
    echo "Available themes:"
    ls "$theme_dir"/*.conf | xargs -n1 basename | sed 's/\.conf$//' | grep -v '^current-theme$' | column
    return 1
  fi
  local target="${theme_dir}/${1}.conf"
  if [[ ! -f "$target" ]]; then
    echo "Theme not found: $1"
    return 1
  fi
  ln -sf "$target" "${theme_dir}/current-theme.conf"
  kill -SIGUSR1 $(pgrep kitty 2>/dev/null) 2>/dev/null
  echo "Theme: $1"
}

_ktheme() {
  local theme_dir="${HOME}/.config/kitty/themes"
  local -a themes
  themes=("${theme_dir}"/*.conf(:t:r))
  themes=(${themes:#current-theme})
  compadd -- "${themes[@]}"
}
compdef _ktheme ktheme

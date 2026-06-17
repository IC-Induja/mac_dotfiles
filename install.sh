#!/usr/bin/env bash
set -euo pipefail

MAC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROF="$MAC_DIR/professional"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info() { echo -e "${GREEN}  →${NC} $*"; }
warn() { echo -e "${YELLOW}  ▲${NC} $*"; }

# Back up an existing file/dir (if it's not already our symlink), then create symlink.
link() {
    local src="$1"
    local dst="$2"

    mkdir -p "$(dirname "$dst")"

    if [ -L "$dst" ]; then
        if [ "$(readlink "$dst")" = "$src" ]; then
            info "Already linked: $dst"
            return
        fi
        rm "$dst"
    elif [ -e "$dst" ]; then
        local backup
        backup="${dst}.bak.$(date +%Y%m%d%H%M%S)"
        warn "Backing up existing $dst → $backup"
        mv "$dst" "$backup"
    fi

    ln -s "$src" "$dst"
    info "Linked: $dst → $src"
}

# Non-empty directory check (ignores .gitkeep).
has_content() {
    local dir="$1"
    [ -d "$dir" ] && [ -n "$(find "$dir" -not -name '.gitkeep' -not -type d -print -quit)" ]
}

echo ""
echo "mac_dotfiles: $MAC_DIR"
echo ""

# ── Submodules ────────────────────────────────────────────────────────────────
info "Initializing submodules..."
git -C "$MAC_DIR" submodule update --init --recursive

# ── Zsh completions ───────────────────────────────────────────────────────────
if [ -x "$PROF/zsh/generate-completions.sh" ]; then
    info "Generating zsh completions..."
    "$PROF/zsh/generate-completions.sh"
fi

# ── Shell ─────────────────────────────────────────────────────────────────────
link "$PROF/bash/.bashrc"       "$HOME/.bashrc"
link "$MAC_DIR/mac/bash/.bash_profile" "$HOME/.bash_profile"
link "$MAC_DIR/mac/zsh/.zshrc"  "$HOME/.zshrc"

# ── Git ───────────────────────────────────────────────────────────────────────
link "$PROF/git/.gitconfig" "$HOME/.gitconfig"

# ── Neovim ───────────────────────────────────────────────────────────────────
link "$PROF/nvim" "$HOME/.config/nvim"

# ── Zellij ───────────────────────────────────────────────────────────────────
link "$PROF/zellij" "$HOME/.config/zellij"

# ── Lazygit ──────────────────────────────────────────────────────────────────
link "$PROF/lazygit" "$HOME/.config/lazygit"

# ── GitHub CLI ────────────────────────────────────────────────────────────────
link "$PROF/gh/config.yml" "$HOME/.config/gh/config.yml"

# ── Marimo ───────────────────────────────────────────────────────────────────
link "$PROF/marimo/marimo.toml" "$HOME/.config/marimo/marimo.toml"

# ── Claude ───────────────────────────────────────────────────────────────────
mkdir -p "$HOME/.claude"
link "$PROF/claude/CLAUDE.md"          "$HOME/.claude/CLAUDE.md"
link "$PROF/AGENTS.md"                 "$HOME/.claude/AGENTS.md"
link "$MAC_DIR/mac/claude/settings.json" "$HOME/.claude/settings.json"
link "$PROF/claude/skills"        "$HOME/.claude/skills"
link "$PROF/claude/plugins"       "$HOME/.claude/plugins"
link "$PROF/claude/commands"      "$HOME/.claude/commands"
link "$PROF/mcp/mcp.json"         "$HOME/.config/mcp/mcp.json"

# ── Mac-specific: Kitty ──────────────────────────────────────────────────────
link "$MAC_DIR/mac/kitty" "$HOME/.config/kitty"
if [ ! -e "$MAC_DIR/mac/kitty/themes/current-theme.conf" ]; then
    ln -s "$MAC_DIR/mac/kitty/themes/default.conf" "$MAC_DIR/mac/kitty/themes/current-theme.conf"
    info "Kitty theme: initialized current-theme.conf → default.conf"
fi

# ── Mac-specific: Karabiner ───────────────────────────────────────────────────
if has_content "$MAC_DIR/mac/karabiner"; then
    link "$MAC_DIR/mac/karabiner" "$HOME/.config/karabiner"
fi

# ── Mac-specific: iTerm2 ─────────────────────────────────────────────────────
link "$MAC_DIR/mac/iterm2/iterm2_shell_integration.zsh" "$HOME/.iterm2_shell_integration.zsh"

echo ""
echo "Done. To apply macOS system defaults, run: $MAC_DIR/mac/.macos"

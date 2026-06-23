#!/usr/bin/env bash
#
# install-mac.sh — Replicate this Mac's app install on another Mac.
#
# Installs via Homebrew where a cask exists, and via the official source
# (Mac App Store) where no cask is available.
#
# Apps: Chrome, Cursor, VS Code, XMind, Postman, Zotero, Slack, Miro,
#       Scrivener, reMarkable, kitty, iTerm2, Hammerspoon, sioyek
#
# Usage: bash install-mac.sh
#
set -euo pipefail

# Directory this script lives in (used to find committed lock files).
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --- Fail fast: this is macOS-only -----------------------------------------
if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "ERROR: this script only runs on macOS." >&2
  exit 1
fi

log() { printf '\n==> %s\n' "$*"; }

# --- 1. Ensure Homebrew is installed ---------------------------------------
if ! command -v brew >/dev/null 2>&1; then
  log "Homebrew not found — installing it"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Put brew on PATH for this script run (Apple Silicon vs Intel locations).
if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /usr/local/bin/brew ]]; then
  eval "$(/usr/local/bin/brew shellenv)"
else
  echo "ERROR: brew installed but not found at the expected path." >&2
  exit 1
fi

log "Updating Homebrew"
brew update

# --- 2. Install apps that have a Homebrew cask -----------------------------
# (Cask names verified to exist as of this writing.)
CASKS=(
  google-chrome
  cursor
  visual-studio-code
  xmind
  postman
  zotero
  slack
  miro
  scrivener
  kitty
  iterm2
  hammerspoon
  karabiner-elements
  docker-desktop
)

for cask in "${CASKS[@]}"; do
  if brew list --cask "$cask" >/dev/null 2>&1; then
    log "$cask already installed — skipping"
  else
    log "Installing $cask"
    brew install --cask "$cask"
  fi
done

# --- 2a. Replace the kitty icon with neue_outrun ---------------------------
# https://sw.kovidgoyal.net/kitty/faq/#i-do-not-like-the-kitty-icon
# kitty auto-applies kitty.icns from its config dir at startup. The icon repo
# ships the icon as a PNG iconset, so we build kitty.icns with iconutil.
# Pinned to a specific commit for reproducibility.
KITTY_ICON_COMMIT="7f631a61bcbdfb268cdf1c97992a5c077beec9d6"
KITTY_CONFIG_DIR="${HOME}/.config/kitty"
KITTY_ICON="${KITTY_CONFIG_DIR}/kitty.icns"
KITTY_ICON_BASE_URL="https://raw.githubusercontent.com/k0nserv/kitty-icon/${KITTY_ICON_COMMIT}/src/neue_outrun"

if [[ -f "$KITTY_ICON" ]]; then
  log "kitty icon already present ($KITTY_ICON) — skipping"
else
  log "Setting kitty icon to neue_outrun"
  mkdir -p "$KITTY_CONFIG_DIR"
  iconset_dir="$(mktemp -d)/neue_outrun.iconset"
  mkdir -p "$iconset_dir"
  for png in \
    icon_16x16.png   icon_16x16@2x.png \
    icon_32x32.png   icon_32x32@2x.png \
    icon_128x128.png icon_128x128@2x.png \
    icon_256x256.png icon_256x256@2x.png \
    icon_512x512.png icon_512x512@2x.png; do
    curl -fsSL "${KITTY_ICON_BASE_URL}/${png}" -o "${iconset_dir}/${png}"
  done
  iconutil -c icns "$iconset_dir" -o "$KITTY_ICON"
  rm -rf "$(dirname "$iconset_dir")"
  # Refresh the Dock's icon cache so the new icon shows immediately.
  rm -f /var/folders/*/*/*/com.apple.dock.iconcache 2>/dev/null || true
  killall Dock 2>/dev/null || true
  log "kitty icon installed at $KITTY_ICON (applied on next kitty launch)"
fi

# --- 2b. Install CLI tools / dev environment (Homebrew formulae) ------------
# (Formula names verified to exist as of this writing.)
FORMULAE=(
  zellij          # terminal multiplexer
  wget
  uv              # python package/project manager
  rust-analyzer
  r
  python@3.14
  pipx            # install python CLI apps in isolated envs
  node
  neovim
  mosh
  lazygit
  htop
  gh              # GitHub CLI
  fzf
)

for formula in "${FORMULAE[@]}"; do
  if brew list "$formula" >/dev/null 2>&1; then
    log "$formula already installed — skipping"
  else
    log "Installing $formula"
    brew install "$formula"
  fi
done

# --- 2c. Rust toolchain via rustup (official installer, not Homebrew) -------
# rustup manages the toolchain itself (rustc, cargo, components, updates).
if command -v rustup >/dev/null 2>&1; then
  log "rustup already installed — skipping"
else
  log "Installing rustup (official installer)"
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
fi

# --- 2d. Python CLI tools via uv (each in its own isolated environment) -----
UV_TOOLS=(
  mdformat        # markdown formatter
  ipython
  marimo
  ruff
  posting         # TUI HTTP/API client (same tool as the base AMI; no brew cask)
)

for tool in "${UV_TOOLS[@]}"; do
  if uv tool list 2>/dev/null | grep -q "^${tool} "; then
    log "$tool already installed (uv tool) — skipping"
  else
    log "Installing $tool via uv tool install"
    uv tool install "$tool"
  fi
done

# --- 2e. sioyek PDF viewer (pinned GitHub release, not Homebrew) -----------
# The Homebrew cask `sioyek` is deprecated (fails macOS Gatekeeper) and is
# scheduled to be disabled on 2026-09-01, so we install directly from the
# pinned upstream release. The mac zip ships a .dmg that contains the .app.
SIOYEK_VERSION="2.0.0"
SIOYEK_URL="https://github.com/ahrm/sioyek/releases/download/v${SIOYEK_VERSION}/sioyek-release-mac.zip"
SIOYEK_SHA256="0f81831d4fa0d57e7e7e56a40ab6fa6488950b7d6a944aa29918be42cfc46b8a"
SIOYEK_APP="${HOME}/Applications/sioyek.app"

if [[ -d "$SIOYEK_APP" ]]; then
  log "sioyek already installed ($SIOYEK_APP) — skipping"
else
  log "Installing sioyek ${SIOYEK_VERSION} from pinned release"
  sioyek_tmp="$(mktemp -d)"
  curl -fsSL "$SIOYEK_URL" -o "${sioyek_tmp}/sioyek.zip"
  echo "${SIOYEK_SHA256}  ${sioyek_tmp}/sioyek.zip" | shasum -a 256 -c -
  unzip -q "${sioyek_tmp}/sioyek.zip" -d "$sioyek_tmp"
  sioyek_mnt="${sioyek_tmp}/mnt"; mkdir -p "$sioyek_mnt"
  hdiutil attach "${sioyek_tmp}/build/sioyek.dmg" -mountpoint "$sioyek_mnt" -nobrowse -quiet
  mkdir -p "${HOME}/Applications"
  cp -R "${sioyek_mnt}/sioyek.app" "$SIOYEK_APP"
  hdiutil detach "$sioyek_mnt" -quiet
  # Clear the quarantine flag so Gatekeeper does not block the unsigned app.
  xattr -dr com.apple.quarantine "$SIOYEK_APP" 2>/dev/null || true
  rm -rf "$sioyek_tmp"
  log "sioyek installed at $SIOYEK_APP"
fi

# --- 2f. sioyek-python-tools (paper download, highlight extraction, etc.) ---
# sioyek's optional helper commands shell out to `python -m sioyek.<module>`.
# They need an interpreter (GUI apps don't inherit shell PATH) with the pinned
# package set installed. Build a dedicated venv on Python 3.12 (3.14 lacks some
# wheels) via uv, from the committed lock file, for a reproducible install.
# The `new_command` lines in prefs_user.config must point at:
#   ${SIOYEK_VENV}/bin/python
SIOYEK_VENV="${HOME}/.venvs/sioyek-tools"
SIOYEK_LOCK="${SCRIPT_DIR}/sioyek-tools-requirements.lock.txt"

if [[ ! -f "$SIOYEK_LOCK" ]]; then
  echo "ERROR: sioyek lock file not found at $SIOYEK_LOCK" >&2
  exit 1
fi

if [[ -x "${SIOYEK_VENV}/bin/python" ]] && "${SIOYEK_VENV}/bin/python" -c "import sioyek" 2>/dev/null; then
  log "sioyek-tools venv already present ($SIOYEK_VENV) — skipping"
else
  log "Creating sioyek-tools venv (Python 3.12) and installing locked deps"
  uv venv --python 3.12 "$SIOYEK_VENV"
  uv pip install --python "${SIOYEK_VENV}/bin/python" -r "$SIOYEK_LOCK"
  log "sioyek-tools venv ready at $SIOYEK_VENV"
fi

# --- 2g. TUI tools from the base AMI + yazi's preview dependency tail -------
# Mirrors packer/base.pkr.hcl: the terminal TUI apps (yazi, btop, lazysql;
# posting is handled above via uv) plus every external tool yazi shells out to
# for file previews. All are Homebrew core formulae on macOS, so we let brew
# resolve current versions (matching this file's existing unpinned convention).
#
#   yazi          terminal file manager (ships the `ya` plugin manager)
#   btop          resource monitor
#   lazysql       TUI database client
TUI_TOOLS=(
  yazi
  btop
  lazysql
)

# yazi preview helpers — yazi invokes these to render previews:
#   glow          markdown
#   duckdb        csv / parquet / json
#   ouch          archive listing/extraction
#   resvg         svg rasterization
#   ffmpeg        video thumbnails + audio metadata
#   imagemagick   heic / jpeg-xl / font / svg-fallback conversion
#   sevenzip      7z archive preview (provides 7z / 7zz)
#   mediainfo     media metadata
#   poppler       pdftoppm, for pdf previews
YAZI_PREVIEW_DEPS=(
  glow
  duckdb
  ouch
  resvg
  ffmpeg
  imagemagick
  sevenzip
  mediainfo
  poppler
)

for formula in "${TUI_TOOLS[@]}" "${YAZI_PREVIEW_DEPS[@]}"; do
  if brew list "$formula" >/dev/null 2>&1; then
    log "$formula already installed — skipping"
  else
    log "Installing $formula"
    brew install "$formula"
  fi
done

# --- 3. reMarkable: no cask, no static download URL ------------------------
# The reMarkable desktop app is not on Homebrew, and the my.remarkable.com
# download requires a logged-in session (no stable direct .dmg link). Its
# only scriptable official source is the Mac App Store.
#
# Requires `mas` (Mac App Store CLI) and that you are signed in to the App
# Store app with the same Apple ID that "purchased" (free) the app.
REMARKABLE_APPSTORE_ID=1276493162

log "Installing mas (Mac App Store CLI) for the reMarkable app"
if ! brew list mas >/dev/null 2>&1; then
  brew install mas
fi

if mas list 2>/dev/null | grep -q "^${REMARKABLE_APPSTORE_ID}"; then
  log "reMarkable already installed via Mac App Store — skipping"
elif mas account >/dev/null 2>&1; then
  log "Installing reMarkable from the Mac App Store"
  mas install "$REMARKABLE_APPSTORE_ID"
else
  cat >&2 <<EOF

==> reMarkable: NOT installed automatically.
    You are not signed in to the Mac App Store, so it cannot be installed
    headlessly. To finish:
      1. Open the App Store app and sign in.
      2. Re-run this script, OR install it directly:
         https://apps.apple.com/us/app/remarkable-desktop/id${REMARKABLE_APPSTORE_ID}
EOF
fi

log "Done."
log "Casks:    ${CASKS[*]}"
log "Formulae: ${FORMULAE[*]}"
log "TUI:      ${TUI_TOOLS[*]}"
log "yazi deps: ${YAZI_PREVIEW_DEPS[*]}"
log "rustup:   rust toolchain (rustc, cargo)"
log "uv tools: ${UV_TOOLS[*]}"
log "sioyek:   v${SIOYEK_VERSION} (pinned release) + sioyek-tools venv"
log "reMarkable handled via Mac App Store (see notes above)."

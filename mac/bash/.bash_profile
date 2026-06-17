# Source professional bash_profile (which sources ~/.bashrc + cargo env)
_mac_bash_this="$(readlink "${BASH_SOURCE[0]}" || echo "${BASH_SOURCE[0]}")"
source "$(cd "$(dirname "$_mac_bash_this")/../.." && pwd)/professional/bash/.bash_profile"
unset _mac_bash_this

# ── Elan (Lean theorem prover) ────────────────────────────────────────────────
export PATH="$HOME/.elan/bin:$PATH"

# ── conda (mambaforge) ────────────────────────────────────────────────────────
__conda_setup="$('/opt/homebrew/Caskroom/mambaforge/base/bin/conda' 'shell.bash' 'hook' 2>/dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/opt/homebrew/Caskroom/mambaforge/base/etc/profile.d/conda.sh" ]; then
        . "/opt/homebrew/Caskroom/mambaforge/base/etc/profile.d/conda.sh"
    else
        export PATH="/opt/homebrew/Caskroom/mambaforge/base/bin:$PATH"
    fi
fi
unset __conda_setup

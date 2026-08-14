#!/usr/bin/env bash
# Chasm install script.
# Usage: ./install.sh [--local] [--prefix PREFIX] [--yes]
#
# Default behaviour:
#   If run as root: install system-wide to /usr/local
#   If run as user: install to ~/.local

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PREFIX=""
LOCAL=""
YES=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --local) LOCAL="1"; shift ;;
        --prefix) PREFIX="$2"; shift 2 ;;
        --yes|-y) YES="1"; shift ;;
        --help)
            echo "Usage: ./install.sh [--local] [--prefix PREFIX] [--yes]"
            echo ""
            echo "  --local           Install to ~/.local (default if not root)"
            echo "  --prefix PREFIX   Install to PREFIX/bin and PREFIX/share/chasm"
            echo "  --yes             Non-interactive: accept defaults for all prompts"
            echo ""
            echo "Note: 'chasm update' refreshes files under \$XDG_DATA_HOME/chasm"
            echo "(default ~/.local/share/chasm). A custom --prefix that diverges from"
            echo "this path is not supported by 'chasm update'."
            exit 0
            ;;
        *) echo "Unknown option: $1" >&2; exit 1 ;;
    esac
done

# Interactive only when stdin is a tty. 'curl ... | bash' feeds the script
# through stdin, so prompts would read script bytes or hit EOF; default
# (non-interactive) answers apply instead, same as --yes.
INTERACTIVE=""
if [[ -t 0 && -z "$YES" ]]; then
    INTERACTIVE="1"
fi

# CHASM_NONINTERACTIVE=1 behaves like --yes.
if [[ -n "${CHASM_NONINTERACTIVE:-}" ]]; then
    INTERACTIVE=""
fi

if [[ -n "$PREFIX" ]]; then
    true
elif [[ -n "$LOCAL" || $EUID -ne 0 ]]; then
    PREFIX="${HOME}/.local"
else
    PREFIX="/usr/local"
fi

BIN_DIR="${PREFIX}/bin"
SHARE_DIR="${PREFIX}/share/chasm"
TEMPLATE_SRC="${SCRIPT_DIR}/template"
CLI_SRC="${SCRIPT_DIR}/chasm"

echo "Installing Chasm..."
echo "  prefix:  ${PREFIX}"
echo "  bin:     ${BIN_DIR}"
echo "  share:   ${SHARE_DIR}"
echo ""

# Dependency checks
die() { echo "Error: $*" >&2; exit 1; }

command -v git >/dev/null || die "git is required."
command -v npm >/dev/null || die "npm is required (install Node.js first)."
command -v python3 >/dev/null || die "python3 is required."



# Check pi
echo "Checking pi..."
if command -v pi >/dev/null; then
    echo "  pi is already installed."
else
    echo "  pi not found. Installing via npm..."
    npm install -g @earendil-works/pi-coding-agent
    command -v pi >/dev/null || die "pi installation failed. Try: npm install -g @earendil-works/pi-coding-agent"
    echo "  pi installed."
fi

# Create directories
echo ""
echo "Creating directories..."
mkdir -p "$BIN_DIR" "$SHARE_DIR"

# Copy template
echo "Copying template..."
if [[ -d "$TEMPLATE_SRC" ]]; then
    rm -rf "${SHARE_DIR}/template"
    cp -r "$TEMPLATE_SRC" "${SHARE_DIR}/template"
else
    die "Template not found at ${TEMPLATE_SRC}"
fi

# Create user gaming config if it doesn't exist. Never touch it on
# re-install. The canonical path is $XDG_DATA_HOME/chasm/models.json;
# games inherit it via a symlink created by 'chasm new'.
USER_CONFIG="${SHARE_DIR}/models.json"
PI_CONFIG="${HOME}/.pi/agent/models.json"
if [[ ! -f "$USER_CONFIG" ]]; then
    echo "Creating user gaming config..."
    if [[ -f "$PI_CONFIG" ]]; then
        answer=""
        if [[ -n "$INTERACTIVE" ]]; then
            read -r -p "Use your existing pi model config (${PI_CONFIG})? [Y/n] " answer || answer=""
        else
            echo "Using existing pi model config (${PI_CONFIG})."
        fi
        case "${answer,,}" in
            n|no)
                printf '{\n  "providers": {}\n}\n' > "$USER_CONFIG"
                echo "  -> wrote {\"providers\": {}} to ${USER_CONFIG}"
                echo "     Configure models with 'pi /login', or edit ${USER_CONFIG}"
                ;;
            *)
                cp "$PI_CONFIG" "$USER_CONFIG"
                echo "  -> ${USER_CONFIG} copied from ${PI_CONFIG}"
                ;;
        esac
    else
        printf '{\n  "providers": {}\n}\n' > "$USER_CONFIG"
        echo "  -> wrote {\"providers\": {}} to ${USER_CONFIG}"
        echo "     Configure models with 'pi /login', or edit ${USER_CONFIG}"
    fi
else
    echo "User gaming config already exists."
fi

# Copy CLI
echo "Installing chasm CLI..."
cp "$CLI_SRC" "${BIN_DIR}/chasm"
chmod +x "${BIN_DIR}/chasm"

# Ensure bin is on PATH
if [[ ":${PATH}:" != *":${BIN_DIR}:"* ]]; then
    # Detect the user's shell profile file
    profile_file=""
    case "${SHELL:-}" in
        */zsh)  profile_file="${HOME}/.zshrc" ;;
        */bash) profile_file="${HOME}/.bashrc" ;;
        *)      profile_file="${HOME}/.profile" ;;
    esac

    if [[ -n "$INTERACTIVE" ]]; then
        echo ""
        echo "${BIN_DIR} is not on your PATH."
        read -r -p "Add it to ${profile_file}? [Y/n] " answer || answer=""
        case "${answer,,}" in
            n|no)
                echo "Skipped. Add this line to your shell profile manually:"
                echo "  export PATH=\"${BIN_DIR}:\${PATH}\""
                ;;
            *)
                echo "export PATH=\"${BIN_DIR}:\${PATH}\"" >> "${profile_file}"
                echo "Added to ${profile_file}. Run 'source ${profile_file}' or open a new terminal."
                ;;
        esac
    else
        echo ""
        echo "${BIN_DIR} is not on your PATH. Adding it to ${profile_file}."
        echo "export PATH=\"${BIN_DIR}:\${PATH}\"" >> "${profile_file}"
    fi
fi

echo ""
echo "Done."
echo ""
echo "Usage:"
echo "  chasm new GAME_NAME     -- scaffold a new game"
echo "  chasm play GAME_NAME    -- launch a game"
echo "  chasm list              -- list all games"
echo "  chasm update            -- update the installed template + CLI"
echo ""
echo "Model config lives at ${USER_CONFIG} (games inherit it via symlink)."
echo "If it is empty, configure a model provider with 'pi /login' or edit it."
echo ""
echo "Then run 'chasm play GAME_NAME' to begin."

#!/usr/bin/env bash
set -eo pipefail

# Base configuration
declare -r AV_REMOTE="${AV_REMOTE:-AnoRebel/AnoNvim.git}"
declare -r INSTALL_PREFIX="${INSTALL_PREFIX:-"$HOME/.local"}"
declare -r XDG_DATA_HOME="${XDG_DATA_HOME:-"$HOME/.local/share"}"
declare -r XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-"$HOME/.config"}"
declare -r XDG_STATE_HOME="${XDG_STATE_HOME:-"$HOME/.local/state"}"
declare -r XDG_CACHE_HOME="${XDG_CACHE_HOME:-"$HOME/.cache"}"

# Directory structure
declare -A AVIM_DIRS=(
    [config]="$XDG_CONFIG_HOME/avim"
    [data]="$XDG_DATA_HOME/anonvim"
    [state]="$XDG_STATE_HOME/avim"
    [cache]="$XDG_CACHE_HOME/avim"
)
declare -r ANONVIM_BASE_DIR="${AVIM_DIRS[data]}/avim"

# Dependencies
declare -A DEPS=(
    [npm]="neovim tree-sitter-cli"
    [pip]="pynvim"
    [cargo]="fd-find ripgrep"
)

# Script arguments
declare ARGS_LOCAL=0
declare ARGS_OVERWRITE=0
declare ARGS_INSTALL_DEPENDENCIES=1
declare INSTALL_NEORAY=${INSTALL_NEORAY:-0}
declare INSTALL_NEOVIDE=${INSTALL_NEOVIDE:-0}
declare INTERACTIVE_MODE=${INTERACTIVE_MODE:-1}
declare ADDITIONAL_WARNINGS=""

# Get base directory
declare BASEDIR
BASEDIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
BASEDIR="$(dirname -- "$(dirname -- "$BASEDIR")")"
readonly BASEDIR

# Error handling
function error_handler() {
    local line_no=$1
    local error_code=$2
    echo "Error occurred in line $line_no (Exit code: $error_code)"
}
trap 'error_handler ${LINENO} $?' ERR

# Utility functions
function msg() {
    local text="$1"
    local flag="${2:-}"
    local line="......................................................"
    local lead="${line:${#text}}"

    if [ "$flag" != "" ]; then
        lead="${lead:2}"
    fi

    echo -e "$text $lead $flag"
}

function show_progress() {
    local text="$1"
    echo -ne "\r\033[K$text..."
}

function confirm() {
    local question="$1"
    local default="${2:-y}"

    while true; do
        [[ -n "$default" ]] && prompt="[Y/n]" || prompt="[y/N]"
        echo -n "$question $prompt "
        read -r answer

        [[ -z "$answer" ]] && answer="$default"
        case "${answer,,}" in
            y|yes) return 0 ;;
            n|no)  return 1 ;;
        esac
    done
}

# Platform detection
function detect_platform() {
    OS="$(uname -s)"
    case "$OS" in
        Linux)
            if [ -f "/etc/arch-release" ] || [ -f "/etc/artix-release" ]; then
                RECOMMEND_INSTALL="sudo pacman -S"
            elif [ -f "/etc/fedora-release" ] || [ -f "/etc/redhat-release" ]; then
                RECOMMEND_INSTALL="sudo dnf install -y"
            elif [ -f "/etc/gentoo-release" ]; then
                RECOMMEND_INSTALL="emerge -tv"
            else
                RECOMMEND_INSTALL="sudo apt install -y"
            fi
            ;;
        Darwin)
            RECOMMEND_INSTALL="brew install"
            ;;
        *)
            echo "OS $OS is not supported"
            exit 1
            ;;
    esac
}

# Dependency management
function install_deps() {
    local type="$1"
    local deps="${DEPS[$type]}"
    local cmd=""

    case "$type" in
        npm)   cmd="npm install -g" ;;
        pip)   cmd="pip install --user" ;;
        cargo) cmd="cargo install" ;;
    esac

    if [ -n "$cmd" ]; then
        show_progress "Installing $type dependencies"
        $cmd $deps
        echo "done"
    fi
}

function check_system_deps() {
    local deps=(
        git
        nvim
        node
        npm
        pip
        cargo
    )

    for dep in "${deps[@]}"; do
        if ! command -v "$dep" >/dev/null; then
            msg "Missing dependency: $dep"
            msg "Install using: $RECOMMEND_INSTALL $dep"
            exit 1
        fi
    done
}

# Installation functions
function validate_installation() {
    local required_files=(
        "init.lua"
        "lua/avim/core/init.lua"
        "lua/avim/lazy.lua"
    )

    for file in "${required_files[@]}"; do
        if [ ! -f "$ANONVIM_BASE_DIR/$file" ]; then
            msg "Error: Missing required file: $file"
            exit 1
        fi
    done
}

function verify_dirs() {
    for dir in "${AVIM_DIRS[@]}"; do
        if [ ! -d "$dir" ]; then
            mkdir -p "$dir"
        fi
    done
}

function backup_old_config() {
    local timestamp="$(date +%Y%m%d_%H%M%S)"
    local backup_dir="${AVIM_DIRS[config]}.bak.$timestamp"

    if [ -d "${AVIM_DIRS[config]}" ]; then
        show_progress "Backing up existing config"
        mv "${AVIM_DIRS[config]}" "$backup_dir"
        echo "done (saved to $backup_dir)"
    fi
}

function clone_avim() {
    show_progress "Cloning AnoNvim"
    git clone --depth 1 "https://github.com/$AV_REMOTE" "$ANONVIM_BASE_DIR"
    echo "done"
}

function link_local_avim() {
    show_progress "Linking local AnoNvim"
    ln -sf "$BASEDIR" "$ANONVIM_BASE_DIR"
    echo "done"
}

function setup_avim() {
    # Create neovim shim
    local shim_path="$INSTALL_PREFIX/bin/avim"
    mkdir -p "$(dirname "$shim_path")"
    ln -sf "$ANONVIM_BASE_DIR/.install/avim" "$shim_path"
    # cat > "$shim_path" << EOF
    #     #!/bin/sh
    #     ANONVIM_BASE_DIR="$ANONVIM_BASE_DIR" exec nvim -u "$ANONVIM_BASE_DIR/init.lua" "\$@"
    # EOF
    chmod +x "$shim_path"

    # Create desktop entry
    local desktop_path="$XDG_DATA_HOME/applications/avim.desktop"
    mkdir -p "$(dirname "$desktop_path")"
    ln -sf "$ANONVIM_BASE_DIR/.install/avim.desktop" "$desktop_path"
    # cat > "$desktop_path" << EOF
    #     [Desktop Entry]
    #     Name=AnoNvim
    #     Comment=Edit text files with AnoNvim
    #     Exec=avim %F
    #     Terminal=true
    #     Type=Application
    #     Icon=nvim
    #     Categories=Utility;TextEditor;
    #     MimeType=text/english;text/plain;
    # EOF
}

function cleanup() {
    # Remove temporary files
    rm -rf "${AVIM_DIRS[cache]}/tmp" 2>/dev/null || true

    # Remove old plugin data
    if [ -d "${AVIM_DIRS[data]}/lazy" ]; then
        find "${AVIM_DIRS[data]}/lazy" -type d -name "*.old" -exec rm -rf {} +
    fi
}

function print_completion_message() {
    cat << EOF

✓ AnoNvim installed successfully!

Quick Start:
  - Run: avim
  - First run will install plugins automatically

Requirements:
  - Nerd Font for icons: https://github.com/ryanoasis/nerd-fonts

Configuration:
  - Config dir: ${AVIM_DIRS[config]}
  - Data dir: ${AVIM_DIRS[data]}

For help: https://github.com/AnoRebel/AnoNvim
EOF
}

function print_logo() {
    cat << "EOF"
    _              _   _       _
   / \   _ __   __| \ | |_   _(_)_ __ ___
  / _ \ | '_ \ / _ \ \| \ \ / / | '_ ` _ \
 / ___ \| | | | (_) | |\ \ V /| | | | | | |
/_/   \_\_| |_|\___/|_| \_\_/ |_|_| |_| |_|
EOF
}

function usage() {
    cat << EOF
Usage: install.sh [<options>]

Options:
    -h, --help                    Print this help message
    -l, --local                   Install local copy of AnoNvim
    -y, --yes                     Automatic yes to prompts
    --overwrite                   Overwrite existing configuration
    --no-install-dependencies     Skip dependency installation
EOF
}

function parse_arguments() {
    while [ $# -gt 0 ]; do
        case "$1" in
            -h|--help)
                usage
                exit 0
                ;;
            -l|--local)
                ARGS_LOCAL=1
                ;;
            -y|--yes)
                INTERACTIVE_MODE=0
                ;;
            --overwrite)
                ARGS_OVERWRITE=1
                ;;
            --no-install-dependencies)
                ARGS_INSTALL_DEPENDENCIES=0
                ;;
            *)
                echo "Unknown option: $1"
                usage
                exit 1
                ;;
        esac
        shift
    done
}

function main() {
    parse_arguments "$@"
    print_logo

    # Platform and dependency checks
    show_progress "Detecting platform"
    detect_platform
    echo "done"

    show_progress "Checking system dependencies"
    check_system_deps
    echo "done"

    # Install dependencies if requested
    if [ "$ARGS_INSTALL_DEPENDENCIES" -eq 1 ]; then
        for dep_type in "${!DEPS[@]}"; do
            if [ "$INTERACTIVE_MODE" -eq 1 ]; then
                if confirm "Install $dep_type dependencies?"; then
                    install_deps "$dep_type"
                fi
            else
                install_deps "$dep_type"
            fi
        done
    fi

    # GUI installation
    if [ "$INSTALL_NEORAY" -eq 1 ] || [ "$INSTALL_NEOVIDE" -eq 1 ]; then
        if [ "$INTERACTIVE_MODE" -ne 1 ] || confirm "Install GUI?"; then
            install_gui
        fi
    fi

    # Core installation
    backup_old_config
    verify_dirs

    if [ "$ARGS_LOCAL" -eq 1 ]; then
        link_local_avim
    elif [ -d "$ANONVIM_BASE_DIR" ]; then
        validate_installation
    else
        clone_avim
    fi

    show_progress "Setting up AnoNvim"
    setup_avim
    echo "done"

    cleanup
    print_completion_message
}

main "$@"

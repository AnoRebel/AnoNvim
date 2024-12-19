#!/usr/bin/env bash
set -eo pipefail

# Base configuration
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

# Script arguments
declare ARGS_REMOVE_BACKUPS=0
declare INTERACTIVE_MODE=1

# Error handling
function error_handler() {
    local line_no=$1
    local error_code=$2
    echo "Error occurred in line $line_no (Exit code: $error_code)"
}
trap 'error_handler ${LINENO} $?' ERR

# Utility functions
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

function print_logo() {
    cat << "EOF"
    _              _   _       _           
   / \   _ __   __| \ | |_   _(_)_ __ ___  
  / _ \ | '_ \ / _ \ \| \ \ / / | '_ ` _ \ 
 / ___ \| | | | (_) | |\ \ V /| | | | | | |
/_/   \_\_| |_|\___/|_| \_\_/ |_|_| |_| |_|
                 Uninstaller
EOF
}

function usage() {
    cat << EOF
Usage: uninstall.sh [<options>]

Options:
    -h, --help              Print this help message
    -y, --yes              Automatic yes to prompts
    --remove-backups       Remove backup folders as well
EOF
}

function parse_arguments() {
    while [ $# -gt 0 ]; do
        case "$1" in
            -h|--help)
                usage
                exit 0
                ;;
            -y|--yes)
                INTERACTIVE_MODE=0
                ;;
            --remove-backups)
                ARGS_REMOVE_BACKUPS=1
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

function remove_avim_dirs() {
    for dir in "${!AVIM_DIRS[@]}"; do
        local path="${AVIM_DIRS[$dir]}"
        if [ -d "$path" ]; then
            show_progress "Removing $dir directory"
            rm -rf "$path"
            echo "done"
            
            if [ "$ARGS_REMOVE_BACKUPS" -eq 1 ]; then
                show_progress "Removing $dir backups"
                rm -rf "$path".{bak.*,old} 2>/dev/null || true
                echo "done"
            fi
        fi
    done
}

function remove_avim_bin() {
    show_progress "Removing AnoNvim binaries"
    
    # Check for legacy binaries
    local legacy_bins=("/usr/local/bin/avim" "/usr/local/bin/gavim")
    for bin in "${legacy_bins[@]}"; do
        if [ -x "$bin" ]; then
            echo "Warning: Cannot remove $bin without elevation. Please remove manually."
        fi
    done
    
    # Remove current binaries
    local bins=(
        "$INSTALL_PREFIX/bin/avim"
        "$INSTALL_PREFIX/bin/gavim"
    )
    for bin in "${bins[@]}"; do
        if [ -f "$bin" ]; then
            rm -f "$bin"
        fi
    done
    echo "done"
}

function remove_desktop_files() {
    show_progress "Removing desktop entries"
    
    local desktop_files=(
        "$XDG_DATA_HOME/applications/avim.desktop"
        "$XDG_DATA_HOME/applications/gavim.desktop"
    )
    
    # Remove desktop files
    for file in "${desktop_files[@]}"; do
        if [ -f "$file" ]; then
            rm -f "$file"
        fi
    done
    
    # Update desktop database if available
    if command -v update-desktop-database &>/dev/null; then
        update-desktop-database "$XDG_DATA_HOME/applications" &>/dev/null || true
    fi
    
    echo "done"
}

function print_completion_message() {
    cat << EOF

✓ AnoNvim has been uninstalled!

The following directories have been removed:
$(for dir in "${!AVIM_DIRS[@]}"; do echo "  - ${AVIM_DIRS[$dir]}"; done)

$([ "$ARGS_REMOVE_BACKUPS" -eq 1 ] && echo "Backup directories have also been removed.")

Thank you for trying AnoNvim!
EOF
}

function main() {
    parse_arguments "$@"
    print_logo
    
    if [ "$INTERACTIVE_MODE" -eq 1 ]; then
        if ! confirm "Are you sure you want to uninstall AnoNvim?"; then
            echo "Uninstallation cancelled."
            exit 0
        fi
        
        if [ "$ARGS_REMOVE_BACKUPS" -eq 0 ]; then
            if confirm "Would you like to remove backup directories as well?"; then
                ARGS_REMOVE_BACKUPS=1
            fi
        fi
    fi
    
    remove_avim_bin
    remove_avim_dirs
    remove_desktop_files
    print_completion_message
}

main "$@"

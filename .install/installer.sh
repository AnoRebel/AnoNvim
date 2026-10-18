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

# Toolchains and CLI tools, provisioned by mise (same set as the Dockerfile).
# neovim and node have hard floors in lua/avim/health.lua, so they track
# latest/lts rather than a pinned version.
declare -a MISE_TOOLS=(
	"neovim@latest"
	"node@lts"
	"python@3.12"
	"rust@stable"
	luajit
	tree-sitter
	ripgrep
	fd
	fzf
	uv
)

# Python packages installed with uv: pip refuses to modify externally-managed
# interpreters and is slower. pynvim is what the :python3 provider needs.
declare -a PYTHON_PACKAGES=(pynvim)

# Script arguments
declare ARGS_LOCAL=0
declare ARGS_OVERWRITE=0
declare ARGS_INSTALL_DEPENDENCIES=1
declare INSTALL_NEORAY=${INSTALL_NEORAY:-0}
declare INSTALL_NEOVIDE=${INSTALL_NEOVIDE:-0}
declare INTERACTIVE_MODE=${INTERACTIVE_MODE:-1}
declare ADDITIONAL_WARNINGS=""

# Get base directory (the repo root: this script lives in <repo>/.install/)
declare BASEDIR
BASEDIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." &>/dev/null && pwd)"
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
		y | yes) return 0 ;;
		n | no) return 1 ;;
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
function install_mise() {
	if command -v mise >/dev/null; then
		return
	fi

	show_progress "Installing mise"
	curl -fsSL https://mise.run | sh
	export PATH="$HOME/.local/bin:$PATH"
	echo "done"
}

function install_deps() {
	install_mise

	show_progress "Installing toolchains with mise"
	mise use -g -y "${MISE_TOOLS[@]}"
	mise reshim
	echo "done"

	local python_bin
	python_bin="$(command -v python3 || command -v python || true)"
	if [ -z "$python_bin" ]; then
		msg "python not found, skipping: ${PYTHON_PACKAGES[*]}"
		return
	fi

	show_progress "Installing ${PYTHON_PACKAGES[*]} with uv"
	if command -v uv >/dev/null; then
		uv pip install --python "$python_bin" "${PYTHON_PACKAGES[@]}"
	else
		# uv is not on PATH (mise install failed or was skipped): pip is all we have.
		"$python_bin" -m pip install --user "${PYTHON_PACKAGES[@]}"
	fi
	echo "done"

	activate_mise
}

# Interactive shells only see mise's tools after activation. Snippets match
# https://mise.jdx.dev/shell-setup.html and are written only if missing.
function activate_mise() {
	local shell_name
	shell_name="$(basename "${SHELL:-}")"
	local mise_bin
	mise_bin="$(command -v mise || echo "$HOME/.local/bin/mise")"
	local rc line

	case "$shell_name" in
	zsh)
		rc="${ZDOTDIR:-$HOME}/.zshrc"
		line="eval \"\$($mise_bin activate zsh)\""
		;;
	bash)
		rc="$HOME/.bashrc"
		line="eval \"\$($mise_bin activate bash)\""
		;;
	fish)
		rc="$HOME/.config/fish/config.fish"
		line="$mise_bin activate fish | source"
		;;
	*)
		# editors and desktop launchers resolve tools through the shims instead
		msg "Shell '$shell_name' not auto-activated: see https://mise.jdx.dev/shell-setup.html"
		return
		;;
	esac

	if [ "$INTERACTIVE_MODE" -eq 1 ] && ! confirm "Add mise activation to $rc?"; then
		msg "Skipped mise activation in $rc"
		return
	fi

	show_progress "Activating mise in $rc"
	mkdir -p "$(dirname "$rc")"
	grep -qxF "$line" "$rc" 2>/dev/null || printf '%s\n' "$line" >>"$rc"
	echo "done"
}

function check_system_deps() {
	# git clones/patches, curl bootstraps mise. Everything else -- neovim, node,
	# python, rust, ripgrep, fd, fzf -- comes from mise in install_deps.
	local deps=(
		git
		curl
	)

	for dep in "${deps[@]}"; do
		if ! command -v "$dep" >/dev/null; then
			msg "Missing dependency: $dep"
			msg "Install using: $RECOMMEND_INSTALL $dep"
			exit 1
		fi
	done

	if ! command -v nvim >/dev/null && ! command -v mise >/dev/null; then
		msg "Missing dependency: nvim"
		msg "Install using: $RECOMMEND_INSTALL neovim"
		msg "or install mise and let it provide Neovim: curl -fsSL https://mise.run | sh"
		exit 1
	fi
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
	if [ "$(readlink -f "$ANONVIM_BASE_DIR" 2>/dev/null)" = "$BASEDIR" ]; then
		msg "Already linked to $BASEDIR"
		return
	fi

	# `ln -sf` into an existing directory links *inside* it
	# ($ANONVIM_BASE_DIR/avim), so ask before replacing anything.
	if [ -e "$ANONVIM_BASE_DIR" ] || [ -L "$ANONVIM_BASE_DIR" ]; then
		if [ "$ARGS_OVERWRITE" -eq 1 ]; then
			:
		elif [ "$INTERACTIVE_MODE" -eq 1 ] && confirm "Replace existing $ANONVIM_BASE_DIR?"; then
			:
		else
			msg "Refusing to overwrite $ANONVIM_BASE_DIR (use --overwrite)"
			exit 1
		fi
		rm -rf "$ANONVIM_BASE_DIR"
	fi

	show_progress "Linking local AnoNvim"
	ln -sfn "$BASEDIR" "$ANONVIM_BASE_DIR"
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
	# .install/avim is committed executable (mode 100755), so no chmod: it would
	# follow the symlink and try to rewrite the repo file.

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
	cat <<EOF

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
	cat <<"EOF"
    _              _   _       _
   / \   _ __   __| \ | |_   _(_)_ __ ___
  / _ \ | '_ \ / _ \ \| \ \ / / | '_ ` _ \
 / ___ \| | | | (_) | |\ \ V /| | | | | | |
/_/   \_\_| |_|\___/|_| \_\_/ |_|_| |_| |_|
EOF
}

function usage() {
	cat <<EOF
Usage: installer.sh [<options>]

Options:
    -h, --help                    Print this help message
    -l, --local                   Install local copy of AnoNvim
    -y, --yes                     Automatic yes to prompts
    --overwrite                   Replace an existing AnoNvim directory/link without asking
    --no-install-dependencies     Skip dependency installation (mise toolchains, uv packages)
EOF
}

function parse_arguments() {
	while [ $# -gt 0 ]; do
		case "$1" in
		-h | --help)
			usage
			exit 0
			;;
		-l | --local)
			ARGS_LOCAL=1
			;;
		-y | --yes)
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
		if [ "$INTERACTIVE_MODE" -ne 1 ] || confirm "Install toolchains (mise) and python packages (uv)?"; then
			install_deps
		fi
	fi

	# GUI installation (TODO: install_gui function is not yet implemented)
	# if [ "$INSTALL_NEORAY" -eq 1 ] || [ "$INSTALL_NEOVIDE" -eq 1 ]; then
	# 	if [ "$INTERACTIVE_MODE" -ne 1 ] || confirm "Install GUI?"; then
	# 		install_gui
	# 	fi
	# fi

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

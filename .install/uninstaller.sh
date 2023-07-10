#!/usr/bin/env bash
set -eo pipefail

ARGS_REMOVE_BACKUPS=0

declare -r XDG_DATA_HOME="${XDG_DATA_HOME:-"$HOME/.local/share"}"
declare -r XDG_STATE_HOME="${XDG_STATE_HOME:-"$HOME/.local/state"}"
declare -r XDG_CACHE_HOME="${XDG_CACHE_HOME:-"$HOME/.cache"}"
declare -r XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-"$HOME/.config"}"

declare -r ANONVIM_RUNTIME_DIR="${ANONVIM_RUNTIME_DIR:-"$XDG_DATA_HOME/anonvim"}"
declare -r ANONVIM_CONFIG_DIR="${ANONVIM_CONFIG_DIR:-"$XDG_CONFIG_HOME/avim"}"
declare -r ANONVIM_STATE_DIR="${ANONVIM_STATE_DIR:-"$XDG_STATE_HOME/avim"}"
declare -r ANONVIM_CACHE_DIR="${ANONVIM_CACHE_DIR:-"$XDG_CACHE_HOME/avim"}"

declare -a __avim_dirs=(
	"$ANONVIM_CONFIG_DIR"
	"$ANONVIM_RUNTIME_DIR"
	"$ANONVIM_STATE_DIR"
	"$ANONVIM_CACHE_DIR"
)

function usage() {
	echo "Usage: uninstall.sh [<options>]"
	echo ""
	echo "Options:"
	echo "    -h, --help                       Print this help message"
	echo "    --remove-backups                 Remove old backup folders as well"
}

function parse_arguments() {
	while [ "$#" -gt 0 ]; do
		case "$1" in
		--remove-backups)
			ARGS_REMOVE_BACKUPS=1
			;;
		-h | --help)
			usage
			exit 0
			;;
		esac
		shift
	done
}

function remove_avim_dirs() {
	for dir in "${__avim_dirs[@]}"; do
		rm -rf "$dir"
		if [ "$ARGS_REMOVE_BACKUPS" -eq 1 ]; then
			rm -rf "$dir.{bak,old}"
		fi
	done
}

function remove_avim_bin() {
	local legacy_bin="/usr/local/bin/avim"
	local legacy_gbin="/usr/local/bin/gavim"
	if [ -x "$legacy_bin" ] || [ -x "$legacy_gbin" ]; then
		echo "Error! Unable to remove $legacy_bin / $legacy_gbin without elevation. Please remove manually."
		exit 1
	fi

	local avim_bin="$(command -v avim 2>/dev/null)"
	local gavim_bin="$(command -v gavim 2>/dev/null)"
	rm -f "$avim_bin"
	rm -f "$gavim_bin"
}

function remove_desktop_file() {
  OS="$(uname -s)"
  # TODO: Any other OSes that use desktop files?
  ([ "$OS" != "Linux" ] || ! command -v xdg-desktop-menu &>/dev/null) && return
  echo "Removing AnoNvim desktop file entries..."

  xdg-desktop-menu uninstall avim.desktop
  xdg-desktop-menu uninstall gavim.desktop
}

function main() {
	parse_arguments "$@"
	echo "Removing AnoNvim binary..."
	remove_avim_bin
	echo "Removing AnoNvim directories..."
	remove_avim_dirs
	remove_desktop_file
	echo "Uninstalled AnoNvim!"
}

main "$@"

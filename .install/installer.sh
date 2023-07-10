#!/usr/bin/env bash
set -eo pipefail

#Set branch to main unless specified by the user
declare AV_BRANCH="${AV_BRANCH:-"main"}"
declare -r AV_REMOTE="${AV_REMOTE:-AnoRebel/AnoNvim.git}"
declare -r INSTALL_PREFIX="${INSTALL_PREFIX:-"$HOME/.local"}"

declare -r XDG_STATE_HOME="${XDG_STATE_HOME:-"$HOME/.local/state"}"
declare -r XDG_DATA_HOME="${XDG_DATA_HOME:-"$HOME/.local/share"}"
declare -r XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-"$HOME/.config"}"
declare -r XDG_CACHE_HOME="${XDG_CACHE_HOME:-"$HOME/.cache"}"

declare -r ANONVIM_RUNTIME_DIR="${ANONVIM_RUNTIME_DIR:-"$XDG_DATA_HOME/anonvim"}"
declare -r ANONVIM_CONFIG_DIR="${ANONVIM_CONFIG_DIR:-"$XDG_CONFIG_HOME/avim"}"
declare -r ANONVIM_STATE_DIR="${ANONVIM_STATE_DIR:-"$XDG_STATE_HOME/avim"}"
declare -r ANONVIM_CACHE_DIR="${ANONVIM_CACHE_DIR:-"$XDG_CACHE_HOME/avim"}"
declare -r ANONVIM_BASE_DIR="${ANONVIM_BASE_DIR:-"$ANONVIM_RUNTIME_DIR/avim"}"

declare -r ANONVIM_LOG_LEVEL="${ANONVIM_LOG_LEVEL:-warn}"

declare BASEDIR
BASEDIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
BASEDIR="$(dirname -- "$(dirname -- "$BASEDIR")")"
readonly BASEDIR

declare ARGS_LOCAL=0
declare ARGS_OVERWRITE=0
declare ARGS_INSTALL_DEPENDENCIES=1
declare INSTALL_GUI=${INSTALL_GUI:-0}
declare INTERACTIVE_MODE=${INTERACTIVE_MODE:-1}
declare ADDITIONAL_WARNINGS=""

declare -a __avim_dirs=(
	"$ANONVIM_CONFIG_DIR"
	"$ANONVIM_RUNTIME_DIR"
	"$ANONVIM_STATE_DIR"
	"$ANONVIM_CACHE_DIR"
	"$ANONVIM_BASE_DIR"
)

declare -a __npm_deps=(
	"neovim"
	"tree-sitter-cli"
)

declare -a __pip_deps=(
	"pynvim"
)

function usage() {
	echo "Usage: install.sh [<options>]"
	echo ""
	echo "Options:"
	echo "    -h, --help                               Print this help message"
	echo "    -g, --gui                                Install \`neovide\` GUI"
	echo "    -l, --local                              Install local copy of AnoNvim"
	echo "    -y, --yes                                Disable confirmation prompts (answer yes to all questions)"
	echo "    --overwrite                              Overwrite previous AnoNvim configuration (a backup is always performed first)"
	echo "    --[no]-install-dependencies              Whether to automatically install external dependencies (will prompt by default)"
}

function parse_arguments() {
	while [ "$#" -gt 0 ]; do
		case "$1" in
		-l | --local)
			ARGS_LOCAL=1
			;;
		-g | --gui)
			INSTALL_GUI=1
			;;
		--overwrite)
			ARGS_OVERWRITE=1
			;;
		-y | --yes)
			INTERACTIVE_MODE=0
			;;
		--install-dependencies)
			ARGS_INSTALL_DEPENDENCIES=1
			;;
		--no-install-dependencies)
			ARGS_INSTALL_DEPENDENCIES=0
			;;
		-h | --help)
			usage
			exit 0
			;;
		esac
		shift
	done
}

function msg() {
	local text="$1"
	local div_width="80"
	printf "%${div_width}s\n" ' ' | tr ' ' -
	printf "%s\n" "$text"
}

function confirm() {
	local question="$1"
	while true; do
		msg "$question"
		read -p "[y]es or [n]o (default: no) : " -r answer
		case "$answer" in
		y | Y | yes | YES | Yes)
			return 0
			;;
		n | N | no | NO | No | *[[:blank:]]* | "")
			return 1
			;;
		*)
			msg "Please answer [y]es or [n]o."
			;;
		esac
	done
}

function detect_platform() {
	OS="$(uname -s)"
	case "$OS" in
	Linux)
		if [ -f "/etc/arch-release" ] || [ -f "/etc/artix-release" ]; then
			RECOMMEND_INSTALL="sudo pacman -S --noconfirm"
		elif [ -f "/etc/fedora-release" ] || [ -f "/etc/redhat-release" ]; then
			RECOMMEND_INSTALL="sudo dnf install -y"
		else # assume debian based
			RECOMMEND_INSTALL="sudo apt install -y"
		fi
		;;
	Darwin)
		RECOMMEND_INSTALL="brew install"
		;;
	*)
		echo "OS :$OS is not currently supported."
		exit 1
		;;
	esac
}

function print_missing_dep_msg() {
	if [ "$#" -eq 1 ]; then
		echo "[ERROR]: Unable to find dependency [$1]"
		echo "Please install it first and re-run the installer. Try: $RECOMMEND_INSTALL $1"
	else
		local cmds
		cmds=$(for i in "$@"; do echo "$RECOMMEND_INSTALL $i"; done)
		printf "[ERROR]: Unable to find dependencies [%s]" "$@"
		printf "Please install any one of the dependencies and re-run the installer. Try: \n%s\n" "$cmds"
	fi
}

function check_neovim_min_version() {
	local verify_version_cmd='if !has("nvim-0.8") | cquit | else | quit | endif'

	# exit with an error if min_version not found
	if ! nvim --headless -u NONE -c "$verify_version_cmd"; then
		echo "[ERROR]: AnoNvim requires at least Neovim v0.8 or higher"
		exit 1
	fi
}

function validate_anonvim_files() {
	local verify_version_cmd='if v:errmsg != "" | cquit | else | quit | endif'
	if ! "$INSTALL_PREFIX/bin/avim" --headless -c "$verify_version_cmd" &>/dev/null; then
		msg "Removing old installation files"
		rm -rf "$ANONVIM_BASE_DIR"
		clone_avim
	fi
}

function validate_install_prefix() {
	local prefix="$1"
	case $PATH in
	*"$prefix/bin"*)
		return
		;;
	esac
	local profile="$HOME/.profile"
	test -z "$ZSH_VERSION" && profile="$HOME/.zshenv"
	ADDITIONAL_WARNINGS="[WARN] the folder $prefix/bin is not on PATH, consider adding 'export PATH=$prefix/bin:\$PATH' to your $profile"

	# avoid problems when calling any verify_* function
	export PATH="$prefix/bin:$PATH"
}

function check_system_deps() {
	validate_install_prefix "$INSTALL_PREFIX"

	if ! command -v git &>/dev/null; then
		print_missing_dep_msg "git"
		exit 1
	fi
	if ! command -v nvim &>/dev/null; then
		print_missing_dep_msg "neovim"
		exit 1
	fi
	check_neovim_min_version
}

function __install_nodejs_deps_pnpm() {
	echo "Installing node modules with pnpm.."
	pnpm install -g "${__npm_deps[@]}"
	echo "All NodeJS dependencies are successfully installed"
}

function __install_nodejs_deps_npm() {
	echo "Installing node modules with npm.."
	for dep in "${__npm_deps[@]}"; do
		if ! npm ls -g "$dep" &>/dev/null; then
			printf "installing %s .." "$dep"
			npm install -g "$dep"
		fi
	done

	echo "All NodeJS dependencies are successfully installed"
}

function __install_nodejs_deps_yarn() {
	echo "Installing node modules with yarn.."
	yarn global add "${__npm_deps[@]}"
	echo "All NodeJS dependencies are successfully installed"
}

function __validate_node_installation() {
	local pkg_manager="$1"
	local manager_home

	if ! command -v "$pkg_manager" &>/dev/null; then
		return 1
	fi

	if [ "$pkg_manager" == "yarn" ]; then
		manager_home="$(yarn global bin 2>/dev/null)"
	elif [ "$pkg_manager" == "pnpm" ]; then
		manager_home="$(pnpm config get prefix 2>/dev/null)"
	else
		manager_home="$(npm config get prefix 2>/dev/null)"
	fi

	if [ ! -d "$manager_home" ] || [ ! -w "$manager_home" ]; then
		# echo "[ERROR] Unable to install using [$pkg_manager] without administrative privileges."
		return 1
	fi

	return 0
}

function install_nodejs_deps() {
	local -a pkg_managers=("yarn" "pnpm" "npm")
	for pkg_manager in "${pkg_managers[@]}"; do
		if __validate_node_installation "$pkg_manager"; then
			eval "__install_nodejs_deps_$pkg_manager"
			return
		fi
	done
	# print_missing_dep_msg "${pkg_managers[@]}"
	echo "[WARN]: skipping installing optional nodejs dependencies due to insufficient permissions."
	echo "check how to solve it: https://docs.npmjs.com/resolving-eacces-permissions-errors-when-installing-packages-globally"
	exit 1
}

function install_python_deps() {
	echo "Verifying that pip is available.."
	if ! python3 -m ensurepip &>/dev/null; then
		if ! python3 -m pip --version &>/dev/null; then
			echo "[WARN]: skipping installing optional python dependencies"
			return 1
			# print_missing_dep_msg "pip"
			# exit 1
		fi
	fi
	echo "Installing with pip.."
	for dep in "${__pip_deps[@]}"; do
		python3 -m pip install --user "$dep" || return 1
	done
	echo "All Python dependencies are successfully installed"
}

function __attempt_to_install_with_cargo() {
	if command -v cargo &>/dev/null; then
		echo "Installing missing Rust dependency with cargo"
		cargo install "$1"
	else
		echo "[WARN]: Unable to find cargo. Make sure to install it to avoid any problems"
		exit 1
	fi
}

# we try to install the missing one with cargo even though it's unlikely to be found
function install_rust_deps() {
	local -a deps=("fd::fd-find" "rg::ripgrep")
	for dep in "${deps[@]}"; do
		if ! command -v "${dep%%::*}" &>/dev/null; then
			__attempt_to_install_with_cargo "${dep##*::}"
		fi
	done
	echo "All Rust dependencies are successfully installed"
}

function install_gui() {
	OS="$(uname -s)"
	case "$OS" in
	Linux)
		# if command -v go &>/dev/null; then
		# 	echo "Installing \`neoray\` as the GUI"
		# 	go install github.com/hismailbulut/Neoray/cmd/neoray@latest
		# else
		# 	echo "[WARN]: Unable to find go. It's needed to install \`neoray\`, check \`https://github.com/hismailbulut/Neoray\`"
		# 	return 1
		# fi
		if command -v cargo &>/dev/null; then
			echo "Installing \`neovide\` as the GUI"
			cargo install --git https://github.com/neovide/neovide
		else
			echo "[WARN]: Unable to find cargo. It's needed to install \`neovide\`, check \`https://neovide.dev\`"
			return 1
		fi
		;;
	Darwin)
		if command -v brew &>/dev/null; then
			echo "Installing \`neovide\` as the GUI"
			brew install --cask neovide
		else
			echo "[WARN]: Unable to find brew. It's needed to install \`neovide\`, check \`https://neovide.dev\`"
			return 1
		fi
		;;
	*)
		echo "OS :$OS is not currently supported."
		exit 1
		;;
	esac
}

function verify_avim_dirs() {
	if [ "$ARGS_OVERWRITE" -eq 1 ]; then
		for dir in "${__avim_dirs[@]}"; do
			[ -d "$dir" ] && rm -rf "$dir"
		done
	fi

	for dir in "${__avim_dirs[@]}"; do
		mkdir -p "$dir"
	done
}

function backup_old_config() {
	local src="$ANONVIM_CONFIG_DIR"
	if [ ! -d "$src" ]; then
		return
	fi
	mkdir -p "$src.old"
	touch "$src/ignore"
	msg "Backing up old $src to $src.old"
	if command -v rsync &>/dev/null; then
		rsync --archive -hh --stats --partial --copy-links --cvs-exclude "$src"/ "$src.old"
	else
		OS="$(uname -s)"
		case "$OS" in
		Linux | *BSD)
			cp -r "$src/"* "$src.old/."
			;;
		Darwin)
			cp -R "$src/"* "$src.old/."
			;;
		*)
			echo "OS $OS is not currently supported."
			;;
		esac
	fi
	msg "Backup operation complete"
}

function clone_avim() {
	msg "Cloning AnoNvim configuration"
	if ! git clone --branch "$AV_BRANCH" \
		--depth 1 "https://github.com/${AV_REMOTE}" "$ANONVIM_BASE_DIR"; then
		echo "Failed to clone repository. Installation failed."
		exit 1
	fi
}

function link_local_avim() {
	echo "Linking local AnoNvim repo"

	# Detect whether it's a symlink or a folder
	if [ -d "$ANONVIM_BASE_DIR" ]; then
		echo "Removing old installation files"
		rm -rf "$ANONVIM_BASE_DIR"
	fi

	echo "   - $BASEDIR -> $ANONVIM_BASE_DIR"
	ln -s -f "$BASEDIR" "$ANONVIM_BASE_DIR"
}

function setup_shim() {
	[ ! -d "$INSTALL_PREFIX/bin" ] && mkdir -p "$INSTALL_PREFIX/bin"
	[ ! -d "$XDG_DATA_HOME/applications" ] && mkdir -p "$XDG_DATA_HOME/applications"
	echo "Installing binary scripts for terminal and GUI ..."
	local srcdir="$ANONVIM_BASE_DIR/.install"
	local dstdir="$INSTALL_PREFIX/bin"
	# Clean up old installations
	rm -f "$dstdir/avim"
	cp "$srcdir/avim" "$dstdir/avim"
	chmod u+x "$dstdir/avim"
	echo "Adding desktop files"
	if [ "$INSTALL_GUI" -eq 1 ]; then
    rm -f "$dstdir/gavim"
		cp "$srcdir/gavim" "$dstdir/gavim"
		chmod u+x "$dstdir/gavim"
	fi
}

function remove_old_cache_files() {
	local lazy_lock="$ANONVIM_CONFIG_DIR/lazy-lock.json"
	if [ -e "$lazy_lock" ]; then
		msg "Removing old lazy lock file"
		rm -f "$lazy_lock"
	fi

	if [ -e "$ANONVIM_CACHE_DIR/luacache" ] || [ -e "$ANONVIM_CACHE_DIR/avim_cache" ]; then
		msg "Removing old startup cache file"
		rm -f "$ANONVIM_CACHE_DIR/{luacache,avim_cache}"
	fi
}

function create_desktop_file() {
	OS="$(uname -s)"
	# TODO: Any other OSes that use desktop files?
	([ "$OS" != "Linux" ] || ! command -v xdg-desktop-menu &>/dev/null) && return
	echo "Creating desktop file"

	xdg-desktop-menu install --novendor "$ANONVIM_BASE_DIR/.install/avim.desktop"
	if [ "$INSTALL_GUI" -eq 1 ]; then
		xdg-desktop-menu install --novendor "$ANONVIM_BASE_DIR/.install/gavim.desktop"
	fi
}

function setup_avim() {
	remove_old_cache_files
	msg "Installing AnoNvim shim"
	setup_shim
	create_desktop_file
	echo "Preparing Lazy setup"
  echo "This might time a minute(Installing packages)"

	"$INSTALL_PREFIX/bin/avim" --headless \
		-c "lua require('avim.core.log'):set_level([[$ANONVIM_LOG_LEVEL]])" \
		-c 'autocmd User LazyDone quitall' \
		-c 'Lazy! sync'

	echo "Lazy setup complete"
}

function print_logo() {
	cat <<'EOF'
             d8888                   888b    888          d8b               
            d88888                   8888b   888          Y8P               
           d88P888                   88888b  888                            
          d88P 888 88888b.   .d88b.  888Y88b 888 888  888 888 88888b.d88b.  
         d88P  888 888 "88b d88""88b 888 Y88b888 888  888 888 888 "888 "88b 
        d88P   888 888  888 888  888 888  Y88888 Y88  88P 888 888  888  888 
       d8888888888 888  888 Y88..88P 888   Y8888  Y8bd8P  888 888  888  888 
      d88P     888 888  888  "Y88P"  888    Y888   Y88P   888 888  888  888 
                                                                      
EOF
}

function main() {
	parse_arguments "$@"
	print_logo
	msg "Detecting platform for managing any additional neovim dependencies"
	detect_platform
	check_system_deps

	if [ "$ARGS_INSTALL_DEPENDENCIES" -eq 1 ]; then
		if [ "$INTERACTIVE_MODE" -eq 1 ]; then
			if confirm "Would you like to install AnoNvim's NodeJS dependencies?"; then
				install_nodejs_deps
			fi
			if confirm "Would you like to install AnoNvim's Python dependencies?"; then
				install_python_deps
			fi
			if confirm "Would you like to install AnoNvim's Rust dependencies?"; then
				install_rust_deps
			fi
		else
			install_nodejs_deps
			install_python_deps
			install_rust_deps
		fi
	fi

	if [ "$INSTALL_GUI" -eq 1 ]; then
		# if ! command -v neoray &>/dev/null; then
		if ! command -v neovide &>/dev/null; then
			if [ "$INTERACTIVE_MODE" -eq 1 ]; then
				# if confirm "Would you like to install the GUI(neoray)?"; then
				if confirm "Would you like to install the GUI(neovide)?"; then
					install_gui
				fi
			else
				install_gui
			fi
		else
			return 1
		fi
	fi

	backup_old_config
	verify_avim_dirs

	if [ "$ARGS_LOCAL" -eq 1 ]; then
		link_local_avim
	elif [ -d "$ANONVIM_BASE_DIR" ]; then
		validate_anonvim_files
	else
		clone_avim
	fi

	setup_avim
	msg "$ADDITIONAL_WARNINGS"
	msg "AnoNvim installed."
	echo "You can start it by running: $INSTALL_PREFIX/bin/avim or just \`avim\`"
	echo "It will install required plugins on the first run, so be patient while it does."
	echo "Do not forget to use a font with glyphs (icons) support [https://github.com/ryanoasis/nerd-fonts]."
}

main "$@"

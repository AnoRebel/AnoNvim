# AnoNvim Configuration Files

This directory contains various script files used by AnoNvim for installation.

## Directory Structure

```
.install/
├── avim              # Unix executable
├── avim.desktop      # Desktop entry for AnoNvim
├── avim.ps1          # Windows executable
├── installer.sh      # Unix installation script
├── uninstaller.sh    # Unix uninstallation script
└── README.md         # This file
```

## Installation

Run the following to start installation.

```bash
bash <(curl -s https://raw.githubusercontent.com/AnoRebel/AnoNvim/main/.install/installer.sh)
```

### Installation Options

```bash
Options:
    -h, --help                    Print this help message
    -l, --local                   Install local copy of AnoNvim
    -y, --yes                     Automatic yes to prompts
    --overwrite                   Overwrite existing configuration
    --no-install-dependencies     Skip dependency installation
    --neovide                     Install Neovide GUI
    --neoray                      Install Neoray GUI
```

After installation:

1. Run `avim` to start AnoNvim
2. Initial setup will install required plugins

## Uninstall

Run the following to uninstall AnoNvim.

```bash
bash <(curl -s https://raw.githubusercontent.com/AnoRebel/AnoNvim/main/.install/uninstaller.sh)
```

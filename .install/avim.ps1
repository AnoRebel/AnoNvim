#Requires -Version 7.1
[CmdletBinding()]
param()

# Stop on any error
$ErrorActionPreference = "Stop"

# Function to write error messages and exit
function Write-ErrorAndExit {
    param([string]$Message)
    Write-Error $Message
    exit 1
}

# Function to ensure directory exists
function Ensure-Directory {
    param([string]$Path)
    if (-not (Test-Path -Path $Path)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
    }
}

# Set up XDG Base Directories
$env:XDG_DATA_HOME = $env:XDG_DATA_HOME ?? $env:APPDATA
$env:XDG_CONFIG_HOME = $env:XDG_CONFIG_HOME ?? $env:LOCALAPPDATA
$env:XDG_STATE_HOME = $env:XDG_STATE_HOME ?? "$env:LOCALAPPDATA\State"
$env:XDG_CACHE_HOME = $env:XDG_CACHE_HOME ?? $env:TEMP
$env:XDG_LOG_HOME = $env:XDG_LOG_HOME ?? "$env:LOCALAPPDATA\State"

# Set up AnoNvim directories
$env:ANONVIM_RUNTIME_DIR = $env:ANONVIM_RUNTIME_DIR ?? "$env:XDG_DATA_HOME\anonvim"
$env:ANONVIM_CONFIG_DIR = $env:ANONVIM_CONFIG_DIR ?? "$env:XDG_CONFIG_HOME\avim"
$env:ANONVIM_STATE_DIR = $env:ANONVIM_STATE_DIR ?? "$env:XDG_STATE_HOME\avim"
$env:ANONVIM_CACHE_DIR = $env:ANONVIM_CACHE_DIR ?? "$env:XDG_CACHE_HOME\avim"
$env:ANONVIM_LOG_DIR = $env:ANONVIM_LOG_DIR ?? "$env:XDG_STATE_HOME\avim"
$env:ANONVIM_BASE_DIR = $env:ANONVIM_BASE_DIR ?? "$env:ANONVIM_RUNTIME_DIR\avim"

# Validate Neovim installation
try {
    $nvimVersion = nvim --version
    if (-not $?) {
        Write-ErrorAndExit "Neovim is not installed or not in PATH. Please install Neovim first."
    }
} catch {
    Write-ErrorAndExit "Failed to check Neovim version: $_"
}

# Validate configuration
$initLua = Join-Path $env:ANONVIM_BASE_DIR "init.lua"
if (-not (Test-Path $initLua -PathType Leaf)) {
    Write-ErrorAndExit "AnoNvim configuration not found at: $initLua"
}

# Ensure directories exist
$directories = @(
    $env:ANONVIM_RUNTIME_DIR,
    $env:ANONVIM_CONFIG_DIR,
    $env:ANONVIM_STATE_DIR,
    $env:ANONVIM_CACHE_DIR
    $env:ANONVIM_LOG_DIR
)

foreach ($dir in $directories) {
    Ensure-Directory $dir
}

# Set process name
$env:NVIM_APPNAME = $env:NVIM_APPNAME ?? "avim"

# Launch Neovim with AnoNvim configuration
try {
    nvim -u $initLua @args
} catch {
    Write-ErrorAndExit "Failed to launch Neovim: $_"
}

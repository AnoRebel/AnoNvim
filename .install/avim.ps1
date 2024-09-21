#Requires -Version 7.1
$ErrorActionPreference = "Stop" # exit when command fails

$env:XDG_DATA_HOME = $env:XDG_DATA_HOME ?? $env:APPDATA
$env:XDG_CONFIG_HOME = $env:XDG_CONFIG_HOME ?? $env:LOCALAPPDATA
$env:XDG_CACHE_HOME = $env:XDG_CACHE_HOME ?? $env:TEMP

$env:ANONVIM_RUNTIME_DIR = $env:ANONVIM_RUNTIME_DIR ?? "$env:XDG_DATA_HOME\anonvim"
$env:ANONVIM_CONFIG_DIR = $env:ANONVIM_CONFIG_DIR ?? "$env:XDG_CONFIG_HOME\avim"
$env:ANONVIM_STATE_DIR = $env:ANONVIM_STATE_DIR ?? "$env:XDG_STATE_HOME\avim"
$env:ANONVIM_CACHE_DIR = $env:ANONVIM_CACHE_DIR ?? "$env:XDG_CACHE_HOME\avim"
$env:ANONVIM_BASE_DIR = $env:ANONVIM_BASE_DIR ?? "$env:ANONVIM_RUNTIME_DIR\avim"

nvim -u "$env:ANONVIM_BASE_DIR\init.lua" @args


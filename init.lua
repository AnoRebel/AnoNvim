-- Startup profiling (set AVIM_PROFILE=1 to enable)
local profile_start
if vim.env.AVIM_PROFILE then
  profile_start = vim.loop.hrtime()
end

local base_dir = vim.env.ANONVIM_BASE_DIR
  or (function()
    local init_path = debug.getinfo(1, "S").source
    return init_path:sub(2):match("(.*[/\\])"):sub(1, -2)
  end)()

if not vim.tbl_contains(vim.opt.rtp:get(), base_dir) then
  vim.opt.rtp:append(base_dir)
end

vim.uv = vim.uv or vim.loop

-- Redirect Neovim's internal log file to our custom avim.log
-- This must be set BEFORE any logging occurs (including LSP logs)
local cache_dir = vim.env.ANONVIM_CACHE_DIR or vim.fn.stdpath("cache")
local custom_log_path = string.format("%s/avim.log", cache_dir)
vim.env.NVIM_LOG_FILE = custom_log_path

-- Initialize logger first
local Log = require("avim.core.log")
Log:init() -- Initialize the logger before anything else
Log:setup_commands() -- Setup AvimLog command

require("avim.core"):init(base_dir)
require("avim.core.settings")
require("avim.lazy"):init()
require("avim.lazy").load()
require("avim.commands"):setup()

-- Configure notifications after plugins are loaded
Log:configure_notifications(vim.notify)
Log:debug("AnoNvim started successfully")

-- Display startup time if profiling is enabled
if vim.env.AVIM_PROFILE and profile_start then
  vim.defer_fn(function()
    local ms = (vim.loop.hrtime() - profile_start) / 1e6
    local msg = string.format("AnoNvim loaded in %.2f ms", ms)
    print(msg)
    Log:info(msg)
  end, 0)
end

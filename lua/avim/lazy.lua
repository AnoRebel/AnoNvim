---@class avim.lazy
---@field load fun(): boolean # Load and setup plugins
---@field init fun(): boolean # Initialize lazy.nvim
---@field options LazyConfig # Lazy configuration options

---@class LazyConfig
---@field root string # Directory where plugins will be installed
---@field defaults table # Default plugin options
---@field lockfile string # Path to lockfile
---@field concurrency? number # Maximum concurrent tasks
---@field git table # Git options
---@field install table # Installation options
---@field ui table # UI options
---@field diff table # Diff options
---@field checker table # Update checker options
---@field readme table # README options
---@field performance table # Performance options

local M = {}

local fn = vim.fn
local Log = require("avim.core.log")
local utilities = require("avim.utilities")

---Get platform-specific settings
---@return table settings Platform-specific settings
local function get_platform_settings()
  local settings = {}

  if fn.has("macunix") == 1 then
    settings.concurrency = 4
    settings.checker = { concurrency = 1 }
  elseif fn.has("win32") == 1 then
    settings.concurrency = 2
    settings.git = { timeout = 500 }
  end

  return settings
end

---Get runtime paths
---@return string[] paths List of runtime paths
local function get_runtime_paths()
  local home = fn.expand("$HOME")
  local base_dir = _G.get_avim_base_dir()

  return {
    -- Base paths
    base_dir,
    utilities.join_paths(base_dir, "after"),

    -- Data paths
    utilities.join_paths(utilities.get_runtime_dir(), "lazy"),
    utilities.join_paths(utilities.get_runtime_dir(), "lazy", "lazy.nvim"),

    -- Cache paths
    utilities.get_cache_dir(),
    utilities.join_paths(utilities.get_cache_dir(), "after"),

    -- State paths
    utilities.get_state_dir(),
    utilities.join_paths(utilities.get_state_dir(), "after"),

    -- Config paths
    utilities.get_config_dir(),
    utilities.join_paths(utilities.get_config_dir(), "after"),

    -- Lua paths
    utilities.join_paths(home, ".luarocks/share/lua/5.1/?/init.lua"),
    utilities.join_paths(home, ".luarocks/share/lua/5.1/?.lua"),
    utilities.join_paths(home, ".local/share/mise/shims"),
  }
end

-- Default configuration
M.options = {
  root = utilities.join_paths(utilities.get_runtime_dir(), "lazy"),
  defaults = {
    lazy = true,
  },
  lockfile = utilities.join_paths(utilities.get_config_dir(), "lazy-lock.json"),
  git = {
    timeout = 300,
  },
  install = {
    missing = true,
    colorscheme = { "habamax", "tokyodark" },
  },
  ui = {
    border = "rounded",
    icons = {
      loaded = "",
      not_loaded = "",
      cmd = " ",
      config = "",
      event = "",
      ft = " ",
      init = " ",
      keys = " ",
      plugin = " ",
      runtime = " ",
      source = " ",
      start = "",
      task = " ",
      lazy = " ",
      list = { "", "", "", "" },
    },
    throttle = 20,
  },
  diff = {
    cmd = "diffview.nvim",
  },
  checker = {
    enabled = true,
    notify = false,
    frequency = 14400, -- 4 hours
  },
  readme = {
    root = utilities.join_paths(utilities.get_runtime_dir(), "lazy", "readme"),
  },
  rocks = {
    enabled = true,
    hererocks = true,
  },
  performance = {
    rtp = {
      reset = false,
      disabled_plugins = {
        "gzip",
        "tarPlugin",
        "tohtml",
        "tutor",
        "zipPlugin",
        "netrw",
        "netrwPlugin",
        "netrwSettings",
        "netrwFileHandlers",
      },
    },
    paths = get_runtime_paths(),
  },
}

---Initialize lazy.nvim
---@return boolean success Whether initialization was successful
function M:init()
  local lazypath = utilities.join_paths(utilities.get_runtime_dir(), "lazy", "lazy.nvim")

  -- Check if lazy.nvim is already installed
  if vim.uv.fs_stat(lazypath) then
    vim.opt.rtp:prepend(lazypath)
    return true
  end

  -- Clone lazy.nvim
  Log:debug("Cloning lazy.nvim")
  local ok, result = pcall(fn.system, {
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    lazypath,
  })

  if not ok then
    Log:error("Failed to clone lazy.nvim: " .. tostring(result))
    vim.notify("Failed to clone lazy.nvim. Check :AvimLog for details.", vim.log.levels.ERROR)
    return false
  end

  -- Check git exit code
  if vim.v.shell_error ~= 0 then
    Log:error("Git clone failed with exit code " .. vim.v.shell_error .. ": " .. tostring(result))
    vim.notify("Git clone failed. Check :AvimLog for details.", vim.log.levels.ERROR)
    return false
  end

  -- Setup installation notification
  local oldcmdheight = vim.opt.cmdheight:get()
  vim.opt.cmdheight = 1
  vim.notify("Please wait while plugins are installed...")

  -- Create autocmd for post-installation
  vim.api.nvim_create_autocmd("User", {
    once = true,
    pattern = "LazyInstall",
    callback = function()
      vim.cmd.bw()
      vim.opt.cmdheight = oldcmdheight

      -- Load essential plugins
      for _, module in ipairs({ "nvim-treesitter", "mason" }) do
        local success = pcall(require, module)
        if success then
          Log:debug("Loaded " .. module)
        else
          Log:warn("Failed to load " .. module)
        end
      end

      utilities.notify("Mason is installing packages if configured, check status with :Mason")
    end,
  })

  vim.opt.rtp:prepend(lazypath)
  return true
end

---Load and setup plugins
---@return boolean success Whether loading was successful
function M.load()
  Log:debug("Loading plugins")

  -- Check if lazy.nvim is available
  local ok, lazy = pcall(require, "lazy")
  if not ok then
    Log:warn("Lazy is not installed, skipping plugin loading")
    return false
  end

  -- Apply platform-specific settings
  local platform_settings = get_platform_settings()
  M.options = vim.tbl_deep_extend("force", M.options, platform_settings)

  -- Setup plugins
  local success, err = xpcall(function()
    lazy.setup("avim.plugins", M.options)
    return true
  end, function(error_msg)
    local trace = debug.traceback(error_msg, 2)
    Log:error("Failed to setup plugins:\n" .. trace)
    return false
  end)

  if not success then
    Log:warn("Problems detected while loading plugins")
    vim.notify(
      "Plugin loading encountered errors. Check :AvimLog for details.",
      vim.log.levels.WARN,
      { title = "Lazy.nvim" }
    )
    return false
  end

  return true
end

return M

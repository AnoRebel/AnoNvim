local M = {}

local fn = vim.fn
local Log = require("avim.core.log")
local utils = require("avim.utils")

local options = {
  root = utils.join_paths(utils.get_runtime_dir(), "lazy"), -- directory where plugins will be installed
  defaults = {
    lazy = true, -- should plugins be lazy-loaded?
  },
  lockfile = utils.join_paths(utils.get_config_dir(), "lazy-lock.json"), -- lockfile generated after running update.
  concurrency = nil, ---@type number limit the maximum amount of concurrent tasks
  git = {
    timeout = 300,
  },
  install = {
    missing = true,
    -- try to load one of these colorschemes when starting an installation during startup
    colorscheme = { "habamax", "tokyodark" },
  },
  ui = {
    -- The border to use for the UI window. Accepts same border values as |nvim_open_win()|.
    border = "rounded", -- "none",
    icons = {
      loaded = "●",
      not_loaded = "○",
      cmd = " ",
      config = "",
      event = "",
      ft = " ",
      init = " ",
      keys = " ",
      plugin = " ",
      runtime = " ",
      source = " ",
      start = "",
      task = "✔ ",
      lazy = "鈴 ",
      list = {
        "●",
        "➜",
        "★",
        "‒",
      },
    },
    throttle = 20, -- how frequently should the ui process render events
  },
  diff = {
    -- diff command <d> can be one of:
    -- * browser: opens the github compare view. Note that this is always mapped to <K> as well,
    --   so you can have a different command for diff <d>
    -- * git: will run git diff and open a buffer with filetype git
    -- * terminal_git: will open a pseudo terminal with git diff
    -- * diffview.nvim: will open Diffview to show the diff
    cmd = "diffview.nvim",
  },
  checker = {
    -- automatically check for plugin updates
    enabled = true,
    concurrency = nil, ---@type number? set to 1 to check for updates very slowly
    notify = false, -- get a notification when new updates are found
    frequency = 14400, -- check for updates every 4 hours
  },
  readme = {
    root = require("avim.utils").join_paths(utils.get_runtime_dir(), "lazy", "readme"),
  },
  performance = {
    -- reset_packpath = true, -- reset the package path to improve startup time
    rtp = {
      reset = false, -- reset the runtime path to $VIMRUNTIME and your config directory
    },
    paths = {
      _G.get_avim_base_dir(),
      utils.join_paths(_G.get_avim_base_dir(), "after"),
      -- Data
      utils.join_paths(utils.get_runtime_dir(), "lazy"),
      utils.join_paths(utils.get_runtime_dir(), "lazy", "lazy.nvim"),
      -- Cache
      utils.get_cache_dir(),
      utils.join_paths(utils.get_cache_dir(), "after"),
      -- State
      utils.get_state_dir(),
      utils.join_paths(utils.get_state_dir(), "after"),
      -- Config
      utils.get_config_dir(),
      utils.join_paths(utils.get_config_dir(), "after"),
      -- Lua 5.1 Luarocks
      vim.fn.expand("$HOME") .. "/.luarocks/share/lua/5.1/?/init.lua",
      vim.fn.expand("$HOME") .. "/.luarocks/share/lua/5.1/?.lua",
      vim.fn.expand("$HOME") .. "/.local/share/mise/shims",
    }, -- add any custom paths here that you want to indluce in the rtp
  },
}

if fn.has("macunix") == 1 then
  -- fix Lazy Sync freezing on mac
  options.concurrency = 4
  options.checker.concurrency = 1
end

---Initialize lazy and prepare for installing plugins
---@return nil
function M:init()
  local lazypath = utils.join_paths(utils.get_runtime_dir(), "lazy", "lazy.nvim")
  if not vim.uv.fs_stat(lazypath) then
    local output = vim.fn.system({
      "git",
      "clone",
      "--filter=blob:none",
      -- "--single-branch",
      --    "--branch=stable", -- remove this if you want to bootstrap to HEAD
      "https://github.com/folke/lazy.nvim.git",
      lazypath,
    })
    if vim.api.nvim_get_vvar("shell_error") ~= 0 then
      vim.api.nvim_err_writeln("Error cloning lazy.nvim repository...\n\n" .. output)
    end
    local oldcmdheight = vim.opt.cmdheight:get()
    vim.opt.cmdheight = 1
    vim.notify("Please wait while plugins are installed...")
    vim.api.nvim_create_autocmd("User", {
      once = true,
      pattern = "LazyInstall",
      callback = function()
        vim.cmd.bw()
        vim.opt.cmdheight = oldcmdheight
        vim.tbl_map(function(module)
          pcall(require, module)
        end, { "nvim-treesitter", "mason" })
        utils.notify("Mason is installing packages if configured, check status with :Mason")
      end,
    })
  end
  vim.opt.rtp:prepend(lazypath)
end

-- Load available plugins
-- @return nil
M.load = function()
  Log:debug("Loading plugins")
  local lazy_available, lazy = pcall(require, "lazy")
  if not lazy_available then
    Log:warn("skipping loading plugins until Lazy is installed")
    return
  end

  local status_ok, _ = xpcall(function()
    lazy.setup("avim.plugins", options)
  end, debug.traceback)
  if not status_ok then
    Log:warn("problems detected while loading plugins")
    Log:trace(debug.traceback())
  end
end

return M

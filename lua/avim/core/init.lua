---@class avim.core
---@field init fun(base_dir: string): avim.core
local M = {}
_G.avim = {}

if vim.fn.has("nvim-0.10") ~= 1 then
  vim.notify("Please upgrade your Neovim base installation. AnoNvim recommends v0.10+", vim.log.levels.WARN)
  vim.wait(5000, function()
    return false
  end)
  vim.cmd("cquit")
end

---Get the full path to `$ANONVIM_RUNTIME_DIR`
---@return string
function _G.get_runtime_dir()
  return require("avim.utilities").get_runtime_dir()
end

---Get the full path to `$ANONVIM_CONFIG_DIR`
---@return string
function _G.get_config_dir()
  return require("avim.utilities").get_config_dir()
end

---Get the full path to `$ANONVIM_CACHE_DIR`
---@return string
function _G.get_cache_dir()
  return require("avim.utilities").get_cache_dir()
end

---Get the full path to `$ANONVIM_LOG_DIR`
---@return string
function _G.get_log_dir()
  return require("avim.utilities").get_log_dir()
end

---Get the full path to `$ANONVIM_STATE_DIR`
---@return string
function _G.get_state_dir()
  return require("avim.utilities").get_state_dir()
end

---Initialize the `&runtimepath` variables and prepare for startup
---@return table
function M:init(base_dir)
  local utilities = require("avim.utilities")
  _G.avim = vim.tbl_deep_extend("force", vim.deepcopy(require("avim.core.defaults")), _G.avim)

  ---@meta overridden to use ANONVIM_XXX_DIR instead, since a lot of plugins call this function interally
  vim.fn.stdpath = function(what)
    if what == "data" then
      return _G.get_runtime_dir()
    elseif what == "cache" then
      return _G.get_cache_dir()
    elseif what == "log" then
      return _G.get_log_dir()
    elseif what == "state" then
      return _G.get_state_dir()
    elseif what == "config" then
      return _G.get_config_dir()
    end
    return vim.call("stdpath", what)
  end

  ---Get the full path to AnoNvim's base directory
  ---@return string
  function _G.get_avim_base_dir()
    return base_dir
  end

  _G.avim.base_dir = _G.get_avim_base_dir()
  -- Set Global `session` and `undo` directory
  local sessiondir = utilities.join_paths(_G.get_state_dir(), "sessions")
  local shadadir = utilities.join_paths(_G.get_state_dir(), "shada")
  local undodir = utilities.join_paths(_G.get_state_dir(), "undo")
  if not utilities.is_directory(sessiondir) then
    vim.fn.mkdir(sessiondir, "p")
  end
  if not utilities.is_directory(undodir) then
    vim.fn.mkdir(undodir, "p")
  end
  if not utilities.is_directory(shadadir) then
    vim.fn.mkdir(shadadir, "p")
  end
  _G.avim.SESSIONDIR = sessiondir
  _G.avim.SHADADIR = shadadir
  _G.avim.UNDODIR = undodir

  utilities.load_env()

  return self
end

return M

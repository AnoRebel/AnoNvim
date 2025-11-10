---@class avim.core
---@field init fun(base_dir: string): avim.core
local M = {}
_G.avim = {}

if vim.fn.has("nvim-0.11") ~= 1 then
  vim.notify("Please upgrade your Neovim base installation. AnoNvim requires v0.11+", vim.log.levels.ERROR)
  vim.defer_fn(function()
    vim.cmd("cquit")
  end, 5000)
  return M
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

  -- Validate base_dir parameter
  if type(base_dir) ~= "string" or base_dir == "" then
    error("base_dir must be a non-empty string", 2)
  end

  -- Override stdpath to use ANONVIM directories (centralized in utilities)
  utilities.override_stdpath()

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

  -- Ensure required directories exist
  local dirs = {
    { path = sessiondir, name = "session" },
    { path = shadadir, name = "shada" },
    { path = undodir, name = "undo" },
  }

  local all_dirs_created = true
  for _, dir in ipairs(dirs) do
    if not utilities.ensure_directory(dir.path, dir.name) then
      all_dirs_created = false
      break
    end
  end

  if not all_dirs_created then
    vim.notify(
      "Critical directories could not be created. AnoNvim may not function properly.",
      vim.log.levels.WARN,
      { title = "AnoNvim Init" }
    )
  end

  _G.avim.SESSIONDIR = sessiondir
  _G.avim.SHADADIR = shadadir
  _G.avim.UNDODIR = undodir

  utilities.load_env()

  -- Optional: Validate environment variables (only warn, don't fail)
  if vim.env.AVIM_DEBUG then
    local optional_vars = {
      "ANONVIM_RUNTIME_DIR",
      "ANONVIM_CONFIG_DIR",
      "ANONVIM_CACHE_DIR",
      "ANONVIM_STATE_DIR",
      "ANONVIM_LOG_DIR",
    }

    for _, var in ipairs(optional_vars) do
      if not vim.env[var] then
        vim.notify(
          string.format("Optional environment variable %s not set (using defaults)", var),
          vim.log.levels.DEBUG,
          { title = "AnoNvim Init" }
        )
      end
    end
  end

  return self
end

return M

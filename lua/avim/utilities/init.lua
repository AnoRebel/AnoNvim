---@module avim.utilities
---@class avim.utilities
---@field lsp avim.utilities.lsp
---@field dbee avim.utilities.dbee
---@field peek avim.utilities.peek
---@field snippet avim.utilities.snippet
local M = {}

local fn = vim.fn
local api = vim.api
local uv = vim.uv
local is_windows = vim.uv.os_uname().sysname == "Windows_NT"

local diagnostic_map = {}
diagnostic_map[vim.diagnostic.severity.ERROR] = { "✗", guifg = "red" }
diagnostic_map[vim.diagnostic.severity.WARN] = { "", guifg = "orange" }
diagnostic_map[vim.diagnostic.severity.INFO] = { "", guifg = "green" }
diagnostic_map[vim.diagnostic.severity.HINT] = { "", guifg = "blue" }

setmetatable(M, {
  __index = function(t, k)
    -- Avoid recursion if key is already being accessed
    if rawget(t, k) then
      return rawget(t, k)
    end

    local LazyUtil = require("lazy.core.util")
    if LazyUtil[k] then
      t[k] = LazyUtil[k]
      return t[k]
    end
    local t_ok, t_k = pcall(require, "avim.utilities." .. k)
    if t_ok then
      t[k] = t_k
      return t[k]
    end
    -- If not found, return nil instead of M[k]
    return nil -- Or rawget(t, k) to be explicit
  end,
})

--- Clears old and loads new paths if run under ANONVIM_XXX_DIR environment variable(s).
M.load_env = function()
  ---@meta overridden to use ANONVIM_XXX_DIR instead, since a lot of plugins call this function interally
  vim.fn.stdpath = function(what)
    if what == "data" then
      return M.get_runtime_dir()
    elseif what == "cache" then
      return M.get_cache_dir()
    elseif what == "log" then
      return M.get_log_dir()
    elseif what == "state" then
      return M.get_state_dir()
    elseif what == "config" then
      return M.get_config_dir()
    end
    return vim.call("stdpath", what)
  end
  if os.getenv("ANONVIM_RUNTIME_DIR") then
    -- vim.opt.rtp:append(os.getenv "ANONVIM_RUNTIME_DIR" .. path_sep .. "avim")
    -- Data
    vim.opt.rtp:remove(M.join_paths(vim.call("stdpath", "data"), "lazy", "lazy.nvim"))
    vim.opt.rtp:remove(M.join_paths(vim.call("stdpath", "data"), "lazy"))
    vim.opt.rtp:prepend(M.join_paths(M.get_runtime_dir(), "lazy"))
    vim.opt.rtp:append(M.join_paths(M.get_runtime_dir(), "lazy", "lazy.nvim"))

    -- Cache
    vim.opt.rtp:remove(M.join_paths(vim.call("stdpath", "cache"), "after"))
    vim.opt.rtp:remove(vim.call("stdpath", "cache"))
    vim.opt.rtp:prepend(M.get_cache_dir())
    vim.opt.rtp:append(M.join_paths(M.get_cache_dir(), "after"))

    -- Log
    vim.opt.rtp:remove(M.join_paths(vim.call("stdpath", "log"), "after"))
    vim.opt.rtp:remove(vim.call("stdpath", "log"))
    vim.opt.rtp:prepend(M.get_log_dir())
    vim.opt.rtp:append(M.join_paths(M.get_log_dir(), "after"))

    -- State
    vim.opt.rtp:remove(M.join_paths(vim.call("stdpath", "state"), "after"))
    vim.opt.rtp:remove(vim.call("stdpath", "state"))
    vim.opt.rtp:prepend(M.get_state_dir())
    vim.opt.rtp:append(M.join_paths(M.get_state_dir(), "after"))

    -- Config
    vim.opt.rtp:remove(M.join_paths(vim.call("stdpath", "config"), "after"))
    vim.opt.rtp:remove(vim.call("stdpath", "config"))
    vim.opt.rtp:prepend(M.get_config_dir())
    vim.opt.rtp:append(M.join_paths(M.get_config_dir(), "after"))
    -- TODO: we need something like this: vim.opt.packpath = vim.opt.rtp

    vim.cmd([[let &packpath = &runtimepath]]) -- Remove this line
    -- vim.opt.packpath = vim.opt.runtimepath -- Use Lua equivalent
    -- add mason binaries to path
    vim.env.PATH = vim.env.PATH .. (is_windows and ";" or ":") .. M.get_runtime_dir() .. "/mason/bin"
    vim.env.MYVIMRC = _G.get_avim_base_dir() .. "/init.lua"
    -- vim.v.progpath = utils.join_paths(vim.env.HOME, ".local", "bin", "avim")
  end
end

---Get the full path to `$ANONVIM_RUNTIME_DIR`
---@return string
function M.get_runtime_dir()
  local avim_runtime_dir = os.getenv("ANONVIM_RUNTIME_DIR")
  if not avim_runtime_dir then
    -- when nvim is used directly
    return vim.call("stdpath", "data")
  end
  return avim_runtime_dir
end

---Get the full path to `$ANONVIM_CONFIG_DIR`
---@return string
function M.get_config_dir()
  local avim_config_dir = os.getenv("ANONVIM_CONFIG_DIR")
  if not avim_config_dir then
    return vim.call("stdpath", "config")
  end
  return avim_config_dir
end

---Get the full path to `$ANONVIM_CACHE_DIR`
---@return string
function M.get_cache_dir()
  local avim_cache_dir = os.getenv("ANONVIM_CACHE_DIR")
  if not avim_cache_dir then
    return vim.call("stdpath", "cache")
  end
  return avim_cache_dir
end

---Get the full path to `$ANONVIM_STATE_DIR`
---@return string
function M.get_state_dir()
  local avim_state_dir = os.getenv("ANONVIM_STATE_DIR")
  if not avim_state_dir then
    return vim.call("stdpath", "state")
  end
  return avim_state_dir
end

---Get the full path to `$ANONVIM_LOG_DIR`
---@return string
function M.get_log_dir()
  local avim_log_dir = os.getenv("ANONVIM_LOG_DIR")
  if not avim_log_dir then
    return vim.call("stdpath", "log")
  end
  return avim_log_dir
end

---@param name string
---@return string
function M.normname(name)
  local ret = name:lower():gsub("^n?vim%-", ""):gsub("%.n?vim$", ""):gsub("%.lua", ""):gsub("[^a-z]+", "")
  return ret
end

---@return string
function M.norm(path)
  if path:sub(1, 1) == "~" then
    local home = vim.loop.os_homedir()
    if home:sub(-1) == "\\" or home:sub(-1) == "/" then
      home = home:sub(1, -2)
    end
    path = home .. path:sub(2)
  end
  path = path:gsub("\\", "/"):gsub("/+", "/")
  return path:sub(-1) == "/" and path:sub(1, -2) or path
end

function M.is_win()
  return vim.loop.os_uname().sysname:find("Windows") ~= nil
end

--- Merges two provided tables.
---@param t1 table
---@param t2 table
---@param method? string # "keep" or "force"
M.table_merge = function(t1, t2, method)
  -- Use vim.tbl_extend or vim.tbl_deep_extend for proper merging
  -- Example using deep_extend:
  return vim.tbl_deep_extend(method or "force", t1, t2)
end

---@param mode string|string[] Mode short-name, see |nvim_set_keymap()|. Can also be list of modes to create mapping on multiple modes.
---@param keymap string Left-hand side |{lhs}| of the mapping.
---@param command? string|function Right-hand side |{rhs}| of the mapping, can be a Lua function.
---@param opts? vim.keymap.set.Opts|{ desc?: string, mode?: string|string[], prefix?: string, buffer?: string|nil, silent?: boolean, noremap?: boolean, nowait?: boolean, expr?: boolean }
M.map = function(mode, keymap, command, opts)
  -- Store mapping info (optional, depends on _G.avim.mappings usage)
  table.insert(_G.avim.mappings, { mode, keymap, command, opts })

  opts = vim.tbl_deep_extend("force", {
    silent = true,
    noremap = true,
    nowait = true,
    -- which-key description should be in opts.desc
    -- If opts.name was intended for which-key group, use opts.desc
  }, opts or {}) -- Ensure opts is a table
  if opts.name then
    opts.desc = opts.desc and "[" .. opts.name .. "]" .. opts.desc or opts.desc
  end

  -- Handle prefix if needed (might be better handled by plugin manager or lazy keymaps)
  local final_keymap = opts.prefix and (opts.prefix .. keymap) or keymap
  opts.prefix = nil -- Remove prefix from opts passed to set

  if command ~= nil then
    -- Pass opts directly to vim.keymap.set
    vim.keymap.set(mode, final_keymap, command, opts)
  end
end

M.fold_handler = function(virtText, lnum, endLnum, width, truncate)
  local newVirtText = {}
  local suffix = ("  %d "):format(endLnum - lnum)
  local sufWidth = fn.strdisplaywidth(suffix)
  local targetWidth = width - sufWidth
  local curWidth = 0
  for _, chunk in ipairs(virtText) do
    local chunkText = chunk[1]
    local chunkWidth = fn.strdisplaywidth(chunkText)
    if targetWidth > curWidth + chunkWidth then
      table.insert(newVirtText, chunk)
    else
      chunkText = truncate(chunkText, targetWidth - curWidth)
      local hlGroup = chunk[2]
      table.insert(newVirtText, { chunkText, hlGroup })
      chunkWidth = fn.strdisplaywidth(chunkText)
      -- str width returned from truncate() may less than 2nd argument, need padding
      if curWidth + chunkWidth < targetWidth then
        suffix = suffix .. (" "):rep(targetWidth - curWidth - chunkWidth)
      end
      break
    end
    curWidth = curWidth + chunkWidth
  end
  table.insert(newVirtText, { suffix, "MoreMsg" })
  return newVirtText
end

local function windowIsCf(windowId)
  local buftype = vim.bo.buftype
  if windowId ~= nil then
    local bufferId = api.nvim_win_get_buf(windowId)
    buftype = api.nvim_buf_get_option(bufferId, "buftype")
  end
  return buftype == "quickfix"
end

M.nN = function(c)
  local ok, winid = require("hlslens").nNPeekWithUFO(c)
  if ok and winid then
    -- Safe to override buffer scope keymaps remapped by ufo
    -- ufo will restore previous buffer keymaps before closing preview window
    -- Type <CR> will switch to preview window and fire `tarce` action
    M.map("n", "<CR>", function()
      local keyCodes = vim.api.nvim_replace_termcodes("<Tab><CR>", true, false, true)
      vim.api.nvim_feedkeys(keyCodes, "im", false)
    end, { buffer = true })
  end
end

-- Returns the colors/palette of the current theme
M.get_theme_colors = function()
  local colors = {}
  local theme = vim.g.colors_name
  if theme == "kanagawa" then
    colors = require("kanagawa.colors").setup()
  end
  if theme == "rose-pine" then
    colors = require("rose-pine").colorscheme()
  end
  if theme == "tokydark" then
    colors = require("tokyodark").colorscheme()
  end
  if theme == "catppuccin" then
    colors = require("catppuccin.palettes").get_palette()
  end
  return colors
end

M.toggle_diff = function()
  local present, diffview = pcall(require, "diffview")

  if not present then
    return nil
  end
  local lib = require("diffview.lib")
  local view = lib.get_current_view()
  if view == nil then
    diffview.file_history()
    return
  end

  if view then
    view:close()
    lib.dispose_view(view)
  end
end

local function toggleTermMaximize()
  local currentHeight = api.nvim_win_get_height(0)
  local defaultHeight = 15

  if currentHeight > defaultHeight then
    api.nvim_win_set_height(0, defaultHeight)
  else
    local totalHeight = vim.o.lines
    local nextHeight = totalHeight - defaultHeight

    api.nvim_win_set_height(0, math.max(nextHeight, defaultHeight))
  end
end
local function windowIsRelative(windowId)
  return api.nvim_win_get_config(windowId).relative ~= ""
end

M.maximize_window = function()
  -- resize only term
  if vim.bo.filetype == "toggleterm" then
    toggleTermMaximize()
    return
  end
  local currentWindowId = api.nvim_get_current_win()
  local windowsIds = api.nvim_list_wins()
  -- nothing to resize
  if #windowsIds < 2 or windowIsRelative(currentWindowId) then
    return
  end
  local minWidth = 15
  local totalWidth = 0
  local currentRow = api.nvim_win_get_position(0)[1]
  local currentRowWindowIds = {}
  for _, id in ipairs(windowsIds) do
    if not windowIsRelative(id) then
      local y = api.nvim_win_get_position(id)[1]
      if y == currentRow then
        totalWidth = totalWidth + api.nvim_win_get_width(id)
        table.insert(currentRowWindowIds, id)
      end
    end
  end
  local windowsInRow = #currentRowWindowIds
  -- nothing to resize
  if windowsInRow < 2 then
    return
  end
  local maximizedWidth = totalWidth - (windowsInRow - 1) * minWidth
  if maximizedWidth > minWidth and maximizedWidth > api.nvim_win_get_width(0) then
    for _, id in ipairs(currentRowWindowIds) do
      if id == currentWindowId then
        api.nvim_win_set_option(0, "wrap", true)
        api.nvim_win_set_width(id, maximizedWidth)
      else
        api.nvim_win_set_option(id, "wrap", false)
        api.nvim_win_set_width(id, minWidth)
      end
    end
  end
end

--- Serve a notification with a title of AnoNvim
-- @param msg the notification body
-- @param type the type of the notification (:help vim.log.levels)
-- @param opts table of nvim-notify options to use (:help notify-options)
function M.notify(msg, type, opts)
  vim.schedule(function()
    vim.notify(msg, type, vim.tbl_extend("force", { title = "AnoNvim" }, opts or {}))
  end)
end

_G.avim.notify = M.notify

--- Check if a plugin is defined in lazy. Useful with lazy loading when a plugin is not necessarily loaded yet
-- @param plugin the plugin string to search for
-- @return boolean value if the plugin is available
function M.is_available(plugin)
  local lazy_config_avail, lazy_config = pcall(require, "lazy.core.config")
  return lazy_config_avail and lazy_config.plugins[plugin] ~= nil
end

--- Check if a buffer is valid
-- @param bufnr the buffer to check
-- @return true if the buffer is valid or false
function M.is_valid(bufnr)
  if not bufnr or bufnr < 1 then
    return false
  end
  return vim.api.nvim_buf_is_valid(bufnr) and vim.bo[bufnr].buflisted
end

--- Trigger an AnoNvim user event
-- @param event the event name to be appended to AnoNvim
function M.event(event)
  vim.schedule(function()
    vim.api.nvim_exec_autocmds("User", { pattern = "Avim" .. event })
  end)
end

M.get_status = function(filename)
  local diagnostics = vim.diagnostic.get()
  local get_icon_color = require("nvim-web-devicons").get_icon_color
  if vim.tbl_count(diagnostics) > 0 then
    local highest_severity = 100
    for _, diagnostic in ipairs(diagnostics) do
      local severity = diagnostic.severity
      if severity < highest_severity then
        highest_severity = severity
      end
    end
    return diagnostic_map[highest_severity]
  else
    local filetype_icon, color = get_icon_color(filename)
    return { filetype_icon, guifg = color }
  end
end

M.toggle_diagnostics = function()
  local defaults = require("avim.core.defaults")
  defaults.options.diag_enabled = not defaults.options.diag_enabled
  if defaults.options.diag_enabled then
    vim.diagnostic.enable()
    vim.notify("Enabled diagnostics", vim.log.levels.INFO, { title = "Diagnostics" })
  else
    vim.diagnostic.disable()
    vim.notify("Disabled diagnostics", vim.log.levels.WARN, { title = "Diagnostics" })
  end
end

--- Open a URL under the cursor with the current operating system
-- @param path the path of the file to open with the system opener
function M.system_open(path)
  local cmd
  if vim.fn.has("win32") == 1 and vim.fn.executable("explorer") == 1 then
    cmd = "explorer"
  elseif vim.fn.has("unix") == 1 and vim.fn.executable("xdg-open") == 1 then
    cmd = "xdg-open"
  elseif (vim.fn.has("mac") == 1 or vim.fn.has("unix") == 1) and vim.fn.executable("open") == 1 then
    cmd = "open"
  end
  if not cmd then
    M.notify("Available system opening tool not found!", "error")
  end
  vim.fn.jobstart({ cmd, path or vim.fn.expand("<cfile>") }, { detach = true })
end

M.get_greeting = function(name)
  local tableTime = os.date("*t")
  local hour = tableTime.hour
  local greetingsTable = {
    [1] = "  Sleep well",
    [2] = "  Good morning",
    [3] = "  Good afternoon",
    [4] = "  Good evening",
    [5] = "望 Good night",
    [6] = " Welcome back",
  }
  local greetingIndex = 6
  if hour == 23 or hour < 7 then
    greetingIndex = 1
  elseif hour < 12 then
    greetingIndex = 2
  elseif hour >= 12 and hour < 18 then
    greetingIndex = 3
  elseif hour >= 18 and hour < 21 then
    greetingIndex = 4
  elseif hour >= 21 then
    greetingIndex = 5
  end
  return greetingsTable[greetingIndex] .. ", " .. name
end

M.join_paths = function(...)
  -- if vim.version().minor < 10 then
  local path_sep = vim.loop.os_uname().version:match("Windows") and "\\" or "/"
  local result = table.concat({ ... }, path_sep)
  return result
  -- else
  --   return vim.fs.join_paths(...)
  -- end
end

M.starts_with = function(line, prefix)
  local line_trimmed = fn.trim(line)
  return line_trimmed:sub(1, #prefix) == prefix
end

M.split = function(str, sep, opts)
  local len = string.len(str)
  if len == 0 then
    return {}
  end

  local rv = {}

  opts = opts or {}

  local max = opts.max
  local is_pattern = opts.pattern
  local discard = opts.discard
  local capture = opts.capture
  local pattern = sep
  local plain = not is_pattern

  if max then
    max = max - 1 -- Max without the last string.
    if capture then
      max = max * 2 -- Max including the separators.
    end
  end

  local i = 1
  while i <= len and not (max and #rv >= max) do
    local j, k = string.find(str, pattern, i, plain)
    if not j then
      break
    end
    if k < j then
      error("Separator pattern matched zero characters")
    end
    table.insert(rv, string.sub(str, i, j - 1))
    if capture then
      table.insert(rv, string.sub(str, j, k))
    end
    i = k + 1
  end

  table.insert(rv, string.sub(str, i))

  if discard then
    while #rv > 0 and rv[#rv] == "" do
      table.remove(rv)
    end
  end

  return rv
end

--- Checks whether a given path exists and is a file.
--@param path (string) path to check
--@returns (bool)
M.is_file = function(path)
  local stat = uv.fs_stat(path)
  return stat and stat.type == "file" or false
end

--- Checks whether a given path exists and is a directory
--@param path (string) path to check
--@returns (bool)
M.is_directory = function(path)
  local stat = uv.fs_stat(path)
  return stat and stat.type == "directory" or false
end

-- Determine if there is enough space in the window to display components
M.there_is_width = function(winid)
  return api.nvim_win_get_width(winid) > 80 -- 120
end

M.get_os = function()
  local uname = vim.uv.os_uname()
  local sysname = uname.sysname or ""
  local machine = uname.machine or "" -- Machine often gives architecture

  local os_name = "unknown"
  local arch_name = "unknown"

  local sysname_lower = sysname:lower()
  if sysname_lower:find("windows") or sysname_lower:find("mingw") or sysname_lower:find("cygwin") then
    os_name = "Windows"
  elseif sysname_lower:find("linux") then
    os_name = "Linux"
  elseif sysname_lower:find("darwin") then
    os_name = "Mac" -- macOS
  elseif sysname_lower:find("bsd") then
    os_name = "BSD"
  elseif sysname_lower:find("sunos") then
    os_name = "Solaris"
  end

  local machine_lower = machine:lower()
  if machine_lower:find("x86_64") or machine_lower:find("amd64") then
    arch_name = "x86_64"
  elseif machine_lower:find("^i%d86$") or machine_lower:find("x86$") then -- Matches i386, i686 etc.
    arch_name = "x86"
  elseif machine_lower:find("^arm") then
    arch_name = "arm"
  elseif machine_lower:find("^aarch64") then -- Newer ARM architecture name
    arch_name = "aarch64"
  elseif machine_lower:find("^powerpc") then
    arch_name = "powerpc"
  elseif machine_lower:find("^mips") then
    arch_name = "mips"
  end

  return os_name, arch_name
end

M.read_json_file = function(filename)
  local Path = require("plenary.path")

  local path = Path:new(filename)
  if not path:exists() then
    return nil
  end

  local json_contents = path:read()
  local json = vim.fn.json_decode(json_contents)

  return json
end

---Check if the given NPM package is installed in the current project.
---@param package string
---@return boolean
M.is_npm_package_installed = function(package)
  local package_json = M.read_json_file("package.json")
  if not package_json then
    return false
  end

  if package_json.dependencies and package_json.dependencies[package] then
    return true
  end

  if package_json.devDependencies and package_json.devDependencies[package] then
    return true
  end

  return false
end

return M

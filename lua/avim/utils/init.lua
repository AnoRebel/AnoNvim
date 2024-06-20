local M = {}

local fn = vim.fn
local api = vim.api
local uv = vim.uv
local lsp = vim.lsp
local is_windows = vim.uv.os_uname().sysname == "Windows_NT"

local diagnostic_map = {}
diagnostic_map[vim.diagnostic.severity.ERROR] = { "✗", guifg = "red" }
diagnostic_map[vim.diagnostic.severity.WARN] = { "", guifg = "orange" }
diagnostic_map[vim.diagnostic.severity.INFO] = { "", guifg = "green" }
diagnostic_map[vim.diagnostic.severity.HINT] = { "", guifg = "blue" }

-- use lsp formatting if it's available (and if it's good)
-- otherwise, fall back to null-ls
local preferred_formatting_clients = { "null-ls" }
local fallback_formatting_client = "eslint"

-- prevent repeated lookups
local buffer_client_ids = {}

M.load_env = function()
  ---@meta overridden to use ANONVIM_XXX_DIR instead, since a lot of plugins call this function interally
  vim.fn.stdpath = function(what)
    if what == "data" then
      return _G.get_runtime_dir()
    elseif what == "cache" then
      return _G.get_cache_dir()
    elseif what == "state" then
      return _G.get_state_dir()
    elseif what == "config" then
      return _G.get_config_dir()
    end
    return vim.call("stdpath", what)
  end
  if os.getenv("ANONVIM_RUNTIME_DIR") then
    -- vim.opt.rtp:append(os.getenv "ANONVIM_RUNTIME_DIR" .. path_sep .. "avim")
    -- Data
    vim.opt.rtp:remove(M.join_paths(vim.call("stdpath", "data"), "lazy"))
    vim.opt.rtp:remove(M.join_paths(vim.call("stdpath", "data"), "lazy", "lazy.nvim"))
    vim.opt.rtp:prepend(M.join_paths(_G.get_runtime_dir(), "lazy"))
    vim.opt.rtp:append(M.join_paths(_G.get_runtime_dir(), "lazy", "lazy.nvim"))

    -- Cache
    vim.opt.rtp:remove(vim.call("stdpath", "cache"))
    vim.opt.rtp:remove(M.join_paths(vim.call("stdpath", "cache"), "after"))
    vim.opt.rtp:prepend(_G.get_cache_dir())
    vim.opt.rtp:append(M.join_paths(_G.get_cache_dir(), "after"))

    -- State
    vim.opt.rtp:remove(vim.call("stdpath", "state"))
    vim.opt.rtp:remove(M.join_paths(vim.call("stdpath", "state"), "after"))
    vim.opt.rtp:prepend(_G.get_state_dir())
    vim.opt.rtp:append(M.join_paths(_G.get_state_dir(), "after"))

    -- Config
    vim.opt.rtp:remove(vim.call("stdpath", "config"))
    vim.opt.rtp:remove(M.join_paths(vim.call("stdpath", "config"), "after"))
    vim.opt.rtp:prepend(_G.get_config_dir())
    vim.opt.rtp:append(M.join_paths(_G.get_config_dir(), "after"))
    -- TODO: we need something like this: vim.opt.packpath = vim.opt.rtp

    vim.cmd([[let &packpath = &runtimepath]])
    -- add mason binaries to path
    vim.env.PATH = vim.env.PATH .. (is_windows and ";" or ":") .. _G.get_runtime_dir() .. "/mason/bin"
    vim.env.MYVIMRC = _G.get_avim_base_dir() .. "/init.lua"
    -- vim.v.progpath = utils.join_paths(vim.env.HOME, ".local", "bin", "avim")
  end
end

--- Merges two provided tables.
---@param t1 table
---@param t2 table
M.table_merge = function(t1, t2)
  local op = {}
  for _, v in ipairs(t1) do
    table.insert(op, v)
  end
  for _, v in ipairs(t2) do
    table.insert(op, v)
  end

  return op
end

---@param mode string|string[] Mode short-name, see |nvim_set_keymap()|. Can also be list of modes to create mapping on multiple modes.
---@param keymap string Left-hand side |{lhs}| of the mapping.
---@param command? string|function Right-hand side |{rhs}| of the mapping, can be a Lua function.
---@param opts? vim.keymap.set.Opts|{ name?: string, mode?: string|string[], prefix?: string, buffer?: string|nil, silent?: boolean, noremap?: boolean, nowait?: boolean, expr?: boolean }
M.map = function(mode, keymap, command, opts)
  opts = vim.tbl_deep_extend("force", {
    silent = true, -- use `silent` when creating keymaps
    noremap = true, -- use `noremap` when creating keymaps
    nowait = true, -- use `nowait` when creating keymaps
  }, opts)
  -- TODO: Check for duplicates
  table.insert(_G.avim.mappings, { mode, keymap, command, opts })
  local ok, wk = pcall(require, "which-key")
  if ok then
    if opts.name ~= nil and command == nil then
      local name = opts.name
      opts.name = nil
      wk.register({ [keymap] = { name = name } })
    else
      wk.register({ [keymap] = { command, opts.desc or "" } }, opts)
    end
  else
    opts.name = nil
    if command ~= nil then
      if opts.prefix ~= nil then
        local prefix = opts.prefix
        opts.prefix = nil
        vim.keymap.set(mode, prefix .. keymap, command, opts)
      else
        vim.keymap.set(mode, keymap, command, opts)
      end
    end
  end
end

--- Gets a path to a package in the Mason registry.
--- Prefer this to `get_package`, since the package might not always be
--- available yet and trigger errors.
---@param pkg string
---@param path? string
---@param opts? { warn?: boolean }
M.get_pkg_path = function(pkg, path, opts)
  pcall(require, "mason") -- make sure Mason is loaded. Will fail when generating docs
  local root = vim.env.MASON or (vim.fn.stdpath("data") .. "/mason")
  opts = opts or {}
  opts.warn = opts.warn == nil and true or opts.warn
  path = path or ""
  local ret = root .. "/packages/" .. pkg .. "/" .. path
  if opts.warn and not vim.loop.fs_stat(ret) and not require("lazy.core.config").headless() then
    M.warn(
      ("Mason package path not found for **%s**:\n- `%s`\nYou may need to force update the package."):format(pkg, path)
    )
  end
  return ret
end

M.move_to_file_refactor = function(client, buffer)
  client.commands["_typescript.moveToFileRefactoring"] = function(command, ctx)
    ---@type string, string, lsp.Range
    local action, uri, range = unpack(command.arguments)

    local function move(newf)
      client.request("workspace/executeCommand", {
        command = command.command,
        arguments = { action, uri, range, newf },
      })
    end

    local fname = vim.uri_to_fname(uri)
    client.request("workspace/executeCommand", {
      command = "typescript.tsserverRequest",
      arguments = {
        "getMoveToRefactoringFileSuggestions",
        {
          file = fname,
          startLine = range.start.line + 1,
          startOffset = range.start.character + 1,
          endLine = range["end"].line + 1,
          endOffset = range["end"].character + 1,
        },
      },
    }, function(_, result)
      ---@type string[]
      local files = result.body.files
      table.insert(files, 1, "Enter new path...")
      vim.ui.select(files, {
        prompt = "Select move destination:",
        format_item = function(f)
          return vim.fn.fnamemodify(f, ":~:.")
        end,
      }, function(f)
        if f and f:find("^Enter new path") then
          vim.ui.input({
            prompt = "Enter move destination:",
            default = vim.fn.fnamemodify(fname, ":h") .. "/",
            completion = "file",
          }, function(newf)
            return newf and move(newf)
          end)
        elseif f then
          move(f)
        end
      end)
    end)
  end
end

---@alias lsp.Client.filter {id?: number, bufnr?: number, name?: string, method?: string, filter?:fun(client: lsp.Client):boolean}

---@param opts? lsp.Client.filter
M.get_clients = function(opts)
  local ret = {} ---@type vim.lsp.Client[]
  if vim.lsp.get_clients then
    ret = vim.lsp.get_clients(opts)
  else
    ---@diagnostic disable-next-line: deprecated
    ret = vim.lsp.get_active_clients(opts)
    if opts and opts.method then
      ---@param client vim.lsp.Client
      ret = vim.tbl_filter(function(client)
        return client.supports_method(opts.method, { bufnr = opts.bufnr })
      end, ret)
    end
  end
  return opts and opts.filter and vim.tbl_filter(opts.filter, ret) or ret
end

---@param method string|string[]
M.lsp_has = function(buffer, method)
  if type(method) == "table" then
    for _, m in ipairs(method) do
      if M.lsp_has(buffer, m) then
        return true
      end
    end
    return false
  end
  method = method:find("/") and method or "textDocument/" .. method
  local clients = M.get_clients({ bufnr = buffer })
  for _, client in ipairs(clients) do
    if client.supports_method(method) then
      return true
    end
  end
  return false
end

---@class LspCommand: lsp.ExecuteCommandParams
---@field open? boolean
---@field handler? lsp.Handler

---@param opts LspCommand
M.lsp_execute = function(opts)
  local params = {
    command = opts.command,
    arguments = opts.arguments,
  }
  if opts.open then
    require("trouble").open({
      mode = "lsp_command",
      params = params,
    })
  else
    return vim.lsp.buf_request(0, "workspace/executeCommand", params, opts.handler)
  end
end

M.lsp_action = setmetatable({}, {
  __index = function(_, action)
    return function()
      vim.lsp.buf.code_action({
        apply = true,
        context = {
          only = { action },
          diagnostics = {},
        },
      })
    end
  end,
})

M.format = function(bufnr)
  bufnr = tonumber(bufnr) or api.nvim_get_current_buf()

  local selected_client
  if buffer_client_ids[bufnr] then
    selected_client = lsp.get_client_by_id(buffer_client_ids[bufnr])
  else
    for _, client in ipairs(M.get_clients({ buffer = bufnr })) do
      if vim.tbl_contains(preferred_formatting_clients, client.name) then
        selected_client = client
        break
      end

      if client.name == fallback_formatting_client then
        selected_client = client
      end
    end
  end

  if not selected_client then
    return
  end

  buffer_client_ids[bufnr] = selected_client.id

  local params = lsp.util.make_formatting_params()
  local res, err = selected_client.request_sync("textDocument/formatting", params, 4500, bufnr)
  if err then
    local err_msg = type(err) == "string" and err or err.message
    vim.notify("Formatting: " .. err_msg, vim.log.levels.WARN)
    return
  end

  -- if not api.nvim_buf_is_loaded(bufnr) or api.nvim_buf_get_option(bufnr, "modified") then
  --   return
  -- end

  if res and res.result then
    lsp.util.apply_text_edits(res.result, bufnr, selected_client.offset_encoding or "utf-16")
    api.nvim_buf_call(bufnr, function()
      vim.cmd("silent noautocmd update")
    end)
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
M.toggle_windows_dim = function()
  local windowsIds = api.nvim_list_wins()
  local currentWindowId = api.nvim_get_current_win()
  if api.nvim_win_get_config(currentWindowId).relative ~= "" then
    return
  end
  pcall(fn.matchdelete, currentWindowId)
  if windowIsCf(currentWindowId) then
    return
  end
  for _, id in ipairs(windowsIds) do
    if id ~= currentWindowId and not api.nvim_win_get_config(id).relative ~= "" then
      pcall(fn.matchadd, "BufDimText", ".", 200, id, { window = id })
    end
  end
end

M.peek_or_hover = function()
  local winid = require("ufo").peekFoldedLinesUnderCursor()
  if not winid then
    -- vim.lsp.buf.hover()
    require("hover").hover()
  end
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

local view_selection = function(prompt_bufnr, map)
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")
  local openfile = require("nvim-tree.actions.node.open-file")
  actions.select_default:replace(function()
    actions.close(prompt_bufnr)
    local selection = action_state.get_selected_entry()
    local filename = selection.filename
    if filename == nil then
      filename = selection[1]
    end
    openfile.fn("preview", filename)
  end)
  return true
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

-- For Autocmd
M.auto_maximize_window = function()
  if M.disableAutoMaximize or vim.bo.filetype == "toggleterm" or windowIsCf() then
    return
  end
  M.maximize_window()
end

M.close_buffer = function(bufnr, force)
  if force == nil then
    force = false
  end
  if vim.bo.buftype == "terminal" then
    api.nvim_win_hide(0)
    return
  end

  local fts = {
    "qf",
    "help",
    "man",
    -- "nofile",
    "lspinfo",
    "messages",
    "spectre_panel",
    "startuptime",
  }
  bufnr = bufnr or api.nvim_get_current_buf()
  local buf_type = vim.bo[bufnr].buftype
  local buf_filetype = vim.bo[bufnr].filetype
  local bufhidden = vim.bo.bufhidden
  -- Skip if the filetype is on the list of exclusions.
  if
    vim.b.buftype == "messages"
    or vim.tbl_contains(fts, buf_filetype)
    or vim.tbl_contains(fts, buf_type)
    or vim.tbl_contains(fts, vim.api.nvim_buf_get_option(0, "buftype"))
  then
    vim.cmd((force and "bd!" or "confirm bd") .. bufnr)
    return
  end

  -- force close floating wins
  if bufhidden == "wipe" and buf_filetype ~= "alpha" then
    vim.cmd("SatelliteDisable")
    vim.cmd("bw")
    return
  end
  if not (bufhidden == "delete") and buf_filetype ~= "alpha" then
    vim.cmd("SatelliteDisable")
    vim.cmd("confirm bd" .. bufnr)
    return
  end

  -- if file doesnt exist & its modified
  if fn.filereadable(fn.expand("%p")) == 0 then
    vim.notify("Really bruh, no file name?!", vim.log.levels.WARN)
    -- print "Really bruh, no file name? Add it now!"
    return
  end
  if vim.bo.modified then
    vim.ui.input({
      prompt = "You have unsaved changes. Quit anyway? (y/n) ",
    }, function(input)
      if input == "y" then
        vim.cmd("SatelliteDisable")
        vim.cmd("q!")
      end
    end)
  end

  vim.cmd("SatelliteDisable")
  vim.cmd("bp | bd" .. bufnr)
  if #vim.t.bufs >= 1 then
    vim.cmd("SatelliteEnable")
  end
end

--- Serve a notification with a title of AnoNvim
-- @param msg the notification body
-- @param type the type of the notification (:help vim.log.levels)
-- @param opts table of nvim-notify options to use (:help notify-options)
function M.notify(msg, type, opts)
  vim.schedule(function()
    vim.notify(msg, type, M.extend_tbl({ title = "AnoNvim" }, opts))
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
  local path_sep = vim.loop.os_uname().version:match("Windows") and "\\" or "/"
  local result = table.concat({ ... }, path_sep)
  return result
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
  local raw_os_name, raw_arch_name = "", ""
  -- Luajit shortcut
  if jit and jit.os and jit.arch then
    raw_os_name = jit.os
    raw_arch_name = jit.arch
  else
    -- is popen supported?
    local popen_status, popen_result = pcall(io.popen, "")
    if popen_status then
      popen_result:close()
      -- Unix-based OS
      raw_os_name = io.popen("uname -s", "r"):read("*l")
      raw_arch_name = io.popen("uname -m", "r"):read("*l")
    else
      -- Windows
      local env_OS = os.getenv("OS")
      local env_ARCH = os.getenv("PROCESSOR_ARCHITECTURE")
      if env_OS and env_ARCH then
        raw_os_name, raw_arch_name = env_OS, env_ARCH
      end
    end
  end
  raw_os_name = (raw_os_name):lower()
  raw_arch_name = (raw_arch_name):lower()
  local os_patterns = {
    ["windows"] = "Windows",
    ["linux"] = "Linux",
    ["mac"] = "Mac",
    ["darwin"] = "Mac",
    ["^mingw"] = "Windows",
    ["^cygwin"] = "Windows",
    ["bsd$"] = "BSD",
    ["SunOS"] = "Solaris",
  }
  local arch_patterns = {
    ["^x86$"] = "x86",
    ["i[%d]868"] = "x86",
    ["^x64$"] = "x86_64",
    ["amd64"] = "x86_64",
    ["x86_64"] = "x86_64",
    ["Power Macintosh"] = "powerpc",
    ["^arm"] = "arm",
    ["^mips"] = "mips",
  }
  local os_name, arch_name = "unknown", "unknown"
  for pattern, name in pairs(os_patterns) do
    if raw_os_name:match(pattern) then
      os_name = name
      break
    end
  end
  for pattern, name in pairs(arch_patterns) do
    if raw_arch_name:match(pattern) then
      arch_name = name
      break
    end
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

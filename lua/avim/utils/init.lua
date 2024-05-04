local M = {}
local Log = require("avim.core.log")

local fn = vim.fn
local api = vim.api
local uv = vim.loop
local lsp = vim.lsp
local is_windows = vim.loop.os_uname().sysname == "Windows_NT"

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

M.disableAutoMaximize = false
M.bufferDimNSId = api.nvim_create_namespace("buffer-dim")

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

M.require_safe = function(mod)
  local status_ok, module = pcall(require, mod)
  if not status_ok then
    local trace = debug.getinfo(2, "SL")
    local shorter_src = trace.short_src
    local lineinfo = shorter_src .. ":" .. (trace.currentline or trace.linedefined)
    local msg = string.format("%s : skipped loading [%s]", lineinfo, mod)
    Log:debug(msg)
  end
  return module
end

M.format = function(bufnr)
  bufnr = tonumber(bufnr) or api.nvim_get_current_buf()

  local selected_client
  if buffer_client_ids[bufnr] then
    selected_client = lsp.get_client_by_id(buffer_client_ids[bufnr])
  else
    for _, client in ipairs(lsp.get_active_clients({ buffer = bufnr })) do
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

local function windowIsRelative(windowId)
  return api.nvim_win_get_config(windowId).relative ~= ""
end

local function windowIsCf(windowId)
  local buftype = vim.bo.buftype
  if windowId ~= nil then
    local bufferId = api.nvim_win_get_buf(windowId)
    buftype = api.nvim_buf_get_option(bufferId, "buftype")
  end
  return buftype == "quickfix"
end

M.toggle_dim_windows = function()
  local windowsIds = api.nvim_list_wins()
  local currentWindowId = api.nvim_get_current_win()
  if windowIsRelative(currentWindowId) then
    return
  end
  pcall(fn.matchdelete, currentWindowId)
  if windowIsCf(currentWindowId) then
    return
  end
  for _, id in ipairs(windowsIds) do
    if id ~= currentWindowId and not windowIsRelative(id) then
      pcall(fn.matchadd, "BufDimText", ".", 200, id, { window = id })
    end
  end
end

M.peek_or_hover = function()
  local winid = require("ufo").peekFoldedLinesUnderCursor()
  if not winid then
    vim.lsp.buf.hover()
  end
end

M.nN = function(c)
  local ok, winid = require("hlslens").nNPeekWithUFO(c)
  if ok and winid then
    -- Safe to override buffer scope keymaps remapped by ufo
    -- ufo will restore previous buffer keymaps before closing preview window
    -- Type <CR> will switch to preview window and fire `tarce` action
    vim.keymap.set("n", "<CR>", function()
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

M.start_telescope = function(telescope_mode, opts)
  local present, lib = pcall(require, "nvim-tree.lib")

  if not present then
    vim.notify("NvimTree Not Found/Loaded", vim.log.levels.WARN)
    return
  end
  local node = lib.get_node_at_cursor()
  local abspath = node.absolute_path or node.link_to
  local is_folder = node.fs_stat and node.fs_stat.type == "directory" or false
  local basedir = is_folder and abspath or fn.fnamemodify(abspath, ":h")
  -- if (node.name == '..' and TreeExplorer ~= nil) then
  --   basedir = TreeExplorer.cwd
  -- end
  opts = opts or {}
  opts.cwd = basedir
  opts.search_dirs = { basedir }
  opts.attach_mappings = view_selection
  return require("telescope.builtin")[telescope_mode](opts)
end

M.tree_git_add = function()
  local lib = require("nvim-tree.lib")
  local node = lib.get_node_at_cursor()
  local gs = node.git_status.file

  -- If the file is untracked, unstaged or partially staged, we stage it
  if gs == "??" or gs == "MM" or gs == "AM" or gs == " M" then
    vim.cmd("silent !git add " .. node.absolute_path)

  -- If the file is staged, we unstage
  elseif gs == "M " or gs == "A " then
    vim.cmd("silent !git restore --staged " .. node.absolute_path)
  end

  lib.refresh_tree()
end

local not_id
HardMode = false
local function avoid_keys(mode, mov_keys)
  for _, key in ipairs(mov_keys) do
    local count = 0
    vim.keymap.set(mode, key, function()
      if count >= 5 then
        not_id = vim.notify("Hold it Cowboy!", vim.log.levels.WARN, {
          icon = "🤠",
          replace = not_id,
          keep = function()
            return count >= 5
          end,
        })
      else
        count = count + 1
        -- after 5 seconds decrement
        vim.defer_fn(function()
          count = count - 1
        end, 5000)
        return key
      end
    end, { expr = true })
  end
end

M.ToggleHardMode = function()
  local modes = { "n", "v" }
  local movement_keys = { "h", "j", "k", "l", "<Left>", "<Down>", "<Up>", "<Right>" }
  if HardMode then
    for _, mode in pairs(modes) do
      for _, m_key in pairs(movement_keys) do
        vim.api.nvim_del_keymap(mode, m_key)
      end
    end
    vim.notify("Hard mode OFF", vim.log.levels.INFO, { timeout = 5 })
  else
    for _, mode in pairs(modes) do
      avoid_keys(mode, movement_keys)
    end
    vim.notify("Hard mode ON", vim.log.levels.INFO, { timeout = 5 })
  end
  HardMode = not HardMode
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

-- lightbulb
M.update_lightbulb = function()
  require("nvim-lightbulb").update_lightbulb({
    sign = { enabled = false },
    float = { enabled = false },
    virtual_text = { enabled = true },
  })
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

-- taken from https://github.com/neovim/neovim/issues/3688
M.hide_cursor = function()
  vim.cmd("hi Cursor blend=100")

  -- for some reason unable to set through the M.opt
  vim.cmd("set guicursor=" .. vim.o.guicursor .. ",a:Cursor/lCursor")
end

M.restore_cursor = function()
  vim.cmd("hi Cursor blend=0")
  vim.cmd("set guicursor=" .. vim.o.guicursor)
end

M.enable_transparent_mode = function()
  api.nvim_create_autocmd("ColorScheme", {
    pattern = "*",
    callback = function()
      local hl_groups = {
        "Normal",
        "SignColumn",
        "NormalNC",
        "TelescopeBorder",
        "NvimTreeNormal",
        "EndOfBuffer",
        "MsgArea",
      }
      for _, name in ipairs(hl_groups) do
        vim.cmd(string.format("highlight %s ctermbg=none guibg=none", name))
      end
    end,
  })
  vim.opt.fillchars = "eob: "
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
    vim.cmd("bw")
    return
  end
  if not (bufhidden == "delete") and buf_filetype ~= "alpha" then
    vim.cmd("confirm bd" .. bufnr)
    return
  end

  local fileExists = fn.filereadable(fn.expand("%p"))

  -- if file doesnt exist & its modified
  if fileExists == 0 then
    vim.notify("Really bruh, no file name?!", vim.log.levels.WARN)
    -- print "Really bruh, no file name? Add it now!"
    return
  end
  if vim.bo.modified then
    vim.ui.input({
      prompt = "You have unsaved changes. Quit anyway? (y/n) ",
    }, function(input)
      if input == "y" then
        vim.cmd("q!")
      end
    end)
  end

  vim.cmd("bp | bd" .. bufnr)
end

M.close_all = function(keep_current, type, force)
  if force == nil then
    force = false
  end
  if keep_current == nil then
    keep_current = false
  end
  local current = api.nvim_get_current_buf()
  local bufs = api.nvim_list_bufs()
  for _, bufnr in ipairs(bufs) do
    if not keep_current or bufnr ~= current then
      M.close_buffer(bufnr, force)
    else
      vim.cmd((force and "bd!" or "confirm bd") .. bufnr)
    end
  end
  if type == "tab" then
    if #vim.api.nvim_list_tabpages() > 1 then
      vim.t.bufs = nil
      -- require("astronvim.utils").event "BufsUpdated"
      -- vim.cmd.tabclose()
      vim.cmd(force and "tabclose!" or "confirm tabclose")
    end
    -- else
    -- 	vim.cmd("enew")
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

local get_highest_diagnostic_severity = function(diagnostics)
  local highest_severity = 100
  for _, diagnostic in ipairs(diagnostics) do
    local severity = diagnostic.severity
    if severity < highest_severity then
      highest_severity = severity
    end
  end
  return highest_severity
end

M.get_status = function(filename)
  local diagnostics = vim.diagnostic.get()
  local get_icon_color = M.require_safe("nvim-web-devicons").get_icon_color
  if vim.tbl_count(diagnostics) > 0 then
    local highest_severity = get_highest_diagnostic_severity(diagnostics)
    return diagnostic_map[highest_severity]
  else
    local filetype_icon, color = get_icon_color(filename)
    return { filetype_icon, guifg = color }
  end
end

local diag_enabled = true
function M.toggle_diagnostics()
  diag_enabled = not diag_enabled
  if diag_enabled then
    vim.diagnostic.enable()
    vim.notify("Enabled diagnostics", vim.log.levels.INFO, { title = "Diagnostics" })
  else
    vim.diagnostic.disable()
    vim.notify("Disabled diagnostics", vim.log.levels.WARN, { title = "Diagnostics" })
  end
end

--- Toggle background="dark"|"light"
M.toggle_background = function()
  vim.go.background = vim.go.background == "light" and "dark" or "light"
  vim.notify(string.format("background=%s", vim.go.background))
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

M.load_keymaps = function(mappings, map_opts)
  local merge_tb = vim.tbl_deep_extend
  -- set mapping function with/without whichkey
  local map_func
  local whichkey_exists, wk = pcall(require, "which-key")
  -- local nopts = {
  --    mode = "n", -- NORMAL mode
  --    prefix = "<leader>",
  --    buffer = nil, -- Global mappings. Specify a buffer number for buffer local mappings
  --    silent = true, -- use `silent` when creating keymaps
  --    noremap = true, -- use `noremap` when creating keymaps
  --    nowait = true, -- use `nowait` when creating keymaps
  -- }
  -- local vopts = {
  --    mode = "v", -- VISUAL mode
  --    prefix = "<leader>",
  --    buffer = nil, -- Global mappings. Specify a buffer number for buffer local mappings
  --    silent = true, -- use `silent` when creating keymaps
  --    noremap = true, -- use `noremap` when creating keymaps
  --    nowait = true, -- use `nowait` when creating keymaps
  -- }
  local local_opts = {
    silent = true, -- use `silent` when creating keymaps
    noremap = true, -- use `noremap` when creating keymaps
    nowait = true, -- use `nowait` when creating keymaps
  }

  if whichkey_exists then
    map_func = function(keybind, mapping_info, opts)
      wk.register({ [keybind] = mapping_info }, opts)
    end
  else
    map_func = function(keybind, mapping_info, opts)
      local mode = opts.mode
      opts.mode = nil
      if mapping_info[1] ~= nil then
        vim.keymap.set(mode, keybind, mapping_info[1], opts)
      end
    end
  end

  local maps = merge_tb("force", require("avim.core.defaults").mappings, mappings or {})

  -- TODO: require("leap").add_default_mappings()
  for mode, mode_mappings in pairs(maps) do
    for keybind, mapping_info in pairs(mode_mappings) do
      local default_opts = merge_tb("force", { mode = mode }, map_opts or local_opts)
      local opts = merge_tb("force", default_opts, mapping_info.opts or {})

      if mapping_info.opts then
        mapping_info.opts = nil
      end

      map_func(keybind, mapping_info, opts)
    end
  end
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
  }
  local greetingIndex = ""
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

M.get_relative_fname = function()
  local fname = fn.expand("%:p")
  return fname:gsub(fn.getcwd() .. "/", "")
end

M.get_relative_gitdir = function()
  local fname = fn.expand("%:p")
  local gitpath = fn.systemlist("git rev-parse --show-toplevel")[1]
  return fname:gsub(gitpath .. "/", "")
end

M.sleep = function(n)
  os.execute("sleep " .. tonumber(n))
end

M.toggle_quicklist = function()
  if fn.empty(fn.filter(fn.getwininfo(), "v:val.quickfix")) == 1 then
    vim.cmd("copen")
  else
    vim.cmd("cclose")
  end
end

-- Split a string and return a table of the split values
--@param inputstr (string) string to split
--@param sep (string) string to use as split character
--@returns (table)
M.split = function(inputstr, sep)
  if sep == nil then
    sep = "%s"
  end
  local t = {}
  for str in string.gmatch(inputstr, "([^" .. sep .. "]+)") do
    table.insert(t, str)
  end
  return t
end

-- Determine if we're using a session file
M.using_session = function()
  return (vim.g.persisting ~= nil)
end

M.loadsession = function()
  local ok, persisted = pcall(require, "persisted")
  if not ok then
    return
  end

  local sessions = persisted.list()

  local sessions_short = {}
  for _, session in pairs(sessions) do
    sessions_short[#sessions_short + 1] = session.file_path:gsub(_G.SESSIONDIR, "")
  end

  vim.ui.select(sessions_short, {
    prompt = "Sessions",
    format_item = function(sess)
      local spl = M.split(sess:gsub("%%", "/"):gsub("@", "/"):gsub(".vim", ""), "/")
      return "Load: `" .. spl[#spl - 1] .. "` from: `" .. spl[#spl - 2] .. "` on branch: " .. spl[#spl]
    end,
  }, function(choice)
    if choice == nil then
      return
    end
    vim.api.nvim_exec_autocmds("User", { pattern = "PersistedLoadPre" })
    local ok, res = pcall(vim.cmd, "source " .. fn.fnameescape(_G.SESSIONDIR .. choice))
    if not ok then
      local spl = M.split(choice:gsub("%%", "/"):gsub("@", "/"):gsub(".vim", ""), "/")
      local sesh = "`" .. spl[#spl - 1] .. "` from: `" .. spl[#spl - 2] .. "` on branch: " .. spl[#spl]
      vim.notify("Failed to load: " .. sesh .. ". Because: " .. res, vim.log.levels.WARN, { "Sessions" })
      return
    end
    -- vim.cmd("lua require('persisted').stop()")
    vim.api.nvim_exec_autocmds("User", { pattern = "PersistedLoadPost" })
    local spl = M.split(choice:gsub("%%", "/"):gsub("@", "/"):gsub(".vim", ""), "/")
    local sesh = "`" .. spl[#spl - 1] .. "` from: `" .. spl[#spl - 2] .. "` on branch: " .. spl[#spl]
    vim.notify("Loaded: " .. sesh, vim.log.levels.INFO, { "Sessions" })
  end)
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

M.read_package_json = function()
  return M.read_json_file("package.json")
end

---Check if the given NPM package is installed in the current project.
---@param package string
---@return boolean
M.is_npm_package_installed = function(package)
  local package_json = M.read_package_json()
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

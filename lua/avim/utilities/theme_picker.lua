---@class avim.utilities.theme_picker
---@field themes string[] List of available themes
---@field prev_theme string Previously active theme
---@field needs_restore boolean Whether to restore previous theme
---@field cache table Theme cache state
local M = {}

M.themes = {
  "blue",
  "catppuccin",
  "catppuccin-latte",
  "catppuccin-mocha",
  "catppuccin-frappe",
  "catppuccin-macchiato",
  "darkblue",
  "delek",
  "desert",
  "elflord",
  "evening",
  "habamax",
  "industry",
  "kanagawa",
  "koehler",
  "lunaperche",
  "morning",
  "murphy",
  "oxocarbon",
  "pablo",
  "peachpuff",
  "quiet",
  "ron",
  "rose-pine",
  "shine",
  "slate",
  "tokyodark",
  "torte",
  "zellner",
}

-- Theme state
M.cache = {
  active_theme = nil,    -- Currently active theme
  preview_theme = nil,   -- Theme being previewed
  original_theme = nil,  -- Theme before picker was opened
  highlights = {},       -- Cached highlight groups
}

-- Initialize cache
M.cache.original_theme = _G.avim.theme or vim.g.colors_name
M.cache.active_theme = M.cache.original_theme

--- Call a function; show a notification if it fails
---@param func function Function to call
---@param args table Arguments to pass
---@param err? string Error message
---@param context? string Context for error
---@return any result Function result
local function call(func, args, err, context)
  err = err or "Failed to call function"
  context = context or "Avim"
  
  local ok, res = pcall(func, unpack(args))
  if not ok then
    vim.notify(err, vim.log.levels.ERROR, { title = context })
  end
  return res
end

--- Cache current theme highlights
---@param theme string Theme name
local function cache_highlights(theme)
  -- Only cache if not already cached
  if M.cache.highlights[theme] then return end
  
  -- Get current highlights
  local highlights = {}
  local current = vim.api.nvim_exec("highlight", true)
  
  -- Parse highlight groups
  for line in current:gmatch("[^\r\n]+") do
    if line:match("^%s*[^%s]") then
      local group = line:match("^(%S+)")
      if group then
        highlights[group] = line
      end
    end
  end
  
  M.cache.highlights[theme] = highlights
end

--- Restore cached theme highlights
---@param theme string Theme name
local function restore_highlights(theme)
  local highlights = M.cache.highlights[theme]
  if not highlights then return end
  
  -- Clear current highlights
  vim.cmd("highlight clear")
  
  -- Restore cached highlights
  for _, hl in pairs(highlights) do
    vim.cmd("highlight " .. hl)
  end
end

--- Load a theme with caching
---@param theme string Theme name
---@param notify? boolean Whether to show notification
local function load_theme(theme, notify)
  notify = notify ~= false
  
  -- Cache current theme if switching
  if M.cache.active_theme and M.cache.active_theme ~= theme then
    cache_highlights(M.cache.active_theme)
  end
  
  -- Load theme
  vim.cmd("colorscheme default")
  local ok = pcall(vim.cmd, "colorscheme " .. theme)
  
  if ok then
    M.cache.active_theme = theme
    _G.avim.theme = theme
    
    if notify then
      vim.notify("Switched to theme " .. theme, vim.log.levels.INFO, {
        title = "Theme Chooser",
      })
    end
  else
    vim.notify("Failed to load theme " .. theme, vim.log.levels.ERROR, {
      title = "Theme Chooser",
    })
    
    -- Restore previous theme on failure
    if M.cache.active_theme then
      load_theme(M.cache.active_theme, false)
    end
  end
end

-- Telescope components
local T = {
  utils = require("telescope.utils"),
  previewers = require("telescope.previewers"),
  config = require("telescope.config").values,
  pickers = require("telescope.pickers"),
  finders = require("telescope.finders"),
  themes = require("telescope.themes"),
  actions = require("telescope.actions"),
}

---Open theme picker
---@return nil
return function()
  local bufnr = vim.api.nvim_get_current_buf()
  local preview_buf = vim.api.nvim_buf_get_name(bufnr)
  local demo_win = nil
  local close_demo_win = false
  
  -- Create previewer
  local previewer = T.previewers.new_buffer_previewer({
    get_buffer_by_name = function()
      return preview_buf
    end,
    
    define_preview = function(self, entry)
      -- Setup preview buffer
      if vim.loop.fs_stat(preview_buf) then
        T.config.buffer_previewer_maker(preview_buf, self.state.bufnr, {
          bufname = self.state.bufname
        })
      else
        local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
        vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
      end
      
      -- Preview theme
      M.cache.preview_theme = entry.value
      load_theme(entry.value, false)
    end,
  })
  
  -- Reset function
  local function reset()
    if M.cache.original_theme then
      -- Restore original theme and highlights
      load_theme(M.cache.original_theme, false)
      restore_highlights(M.cache.original_theme)
    end
    
    if close_demo_win and demo_win then
      vim.api.nvim_win_close(demo_win, true)
    end
    
    vim.cmd("stopinsert")
  end
  
  -- Create picker
  local picker = T.pickers.new({}, {
    prompt_title = "Choose a theme:",
    finder = T.finders.new_table({
      results = M.themes,
    }),
    sorter = T.config.generic_sorter({}),
    previewer = previewer,
    
    attach_mappings = function(_)
      -- Handle selection
      T.actions.select_default:replace(function(prompt_bufnr)
        local selection = require("telescope.actions.state").get_selected_entry()
        
        if not selection then
          T.utils.__warn_no_selection("avim.utilities.theme_picker")
          T.actions.close(prompt_bufnr)
          reset()
          return
        end
        
        -- Apply selected theme
        M.cache.original_theme = selection.value
        T.actions.close(prompt_bufnr)
        load_theme(selection.value, true)
      end)
      
      return true
    end,
  })
  
  -- Handle window closing
  local close_wins = picker.close_windows
  picker.close_windows = function(status)
    close_wins(status)
    
    -- If cancelled, restore original theme
    if M.cache.preview_theme ~= M.cache.original_theme then
      reset()
    end
  end
  
  -- Show picker
  picker:find()
end

local themes = {
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
local prev_theme = _G.avim.theme ~= nil and _G.avim.theme or vim.g.colors_name
local needs_restore = true

--- Call a function; show a notification if it fails
---@param func function
---@param args table
---@param err? string
---@param context? string
local call = function(func, args, err, context)
  if err == nil then
    err = "Failed to call function"
  end
  if context == nil then
    context = "Avim"
  end
  local ok, res = pcall(func, unpack(args))
  if not ok then
    vim.notify(err, vim.log.levels.ERROR, { title = context })
  end
  return res
end

--- Try to load theme, show an error notification on fail
--- If loader is nil, it will call vim.cmd('colorscheme ' .. name)
---@param name string
---@param loader? function
local _load_theme = function(name, loader)
  if loader == nil then
    loader = function()
      vim.cmd("colorscheme " .. prev_theme)
      _G.avim.theme = prev_theme
    end
  end
  call(loader, {}, "Failed to load theme " .. name, "avim.theme_manager")
end

---Load specified theme
---@param theme string
---@param notify? boolean = true
local load_theme = function(theme, notify)
  if notify == nil then
    notify = true
  end
  vim.cmd("colorscheme default")
  _load_theme(theme, function()
    vim.cmd("colorscheme " .. theme)
    if notify then
      vim.notify("Switched to theme " .. theme, vim.log.levels.INFO, {
        title = "Theme Chooser",
      })
    end
  end)
end

local T = {
  utils = require("telescope.utils"),
  previewers = require("telescope.previewers"),
  config = require("telescope.config").values,
  pickers = require("telescope.pickers"),
  finders = require("telescope.finders"),
  themes = require("telescope.themes"),
  actions = require("telescope.actions"),
}

return function()
  -- loosely based on:
  -- https://github.com/nvim-telescope/telescope.nvim/blob/master/lua/telescope/builtin/__internal.lua#L926

  local bufnr = vim.api.nvim_get_current_buf()
  local p = vim.api.nvim_buf_get_name(bufnr)
  local demo_win = nil
  local close_demo_win = false

  -- if vim.fn.buflisted(bufnr) ~= 1 then
  -- 	vim.cmd("tabedit " .. _G.get_config_dir() .. "/lazy-lock.json")
  -- 	bufnr = vim.api.nvim_get_current_buf()
  -- 	vim.api.nvim_buf_set_option(bufnr, "modifiable", false)
  -- 	p = vim.api.nvim_buf_get_name(bufnr)
  -- 	demo_win = vim.api.nvim_get_current_win()
  -- 	close_demo_win = true
  -- end

  local previewer = T.previewers.new_buffer_previewer({
    get_buffer_by_name = function()
      return p
    end,
    define_preview = function(self, entry)
      if vim.loop.fs_stat(p) then
        T.config.buffer_previewer_maker(p, self.state.bufnr, { bufname = self.state.bufname })
      else
        local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
        vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
      end
      load_theme(entry.value, false)
    end,
  })

  local function reset()
    if needs_restore then
      load_theme(prev_theme, false)
      needs_restore = false
    end
    if close_demo_win and demo_win ~= nil then
      vim.api.nvim_win_close(demo_win, true)
      close_demo_win = false
    end
    vim.cmd("stopinsert")
  end

  local picker = T.pickers.new({}, {
    prompt_title = "Choose a theme:",
    finder = T.finders.new_table({
      results = themes,
    }),
    sorter = T.config.generic_sorter({}),
    previewer = previewer,
    attach_mappings = function(_)
      T.actions.select_default:replace(function(prompt_bufnr)
        local selection = require("telescope.actions.state").get_selected_entry()
        if selection == nil then
          T.utils.__warn_no_selection("avim.theme_selector")
          T.actions.close(prompt_bufnr)
          reset()
          return
        end

        needs_restore = false
        T.actions.close(prompt_bufnr)
        load_theme(selection.value)
        reset()
      end)

      return true
    end,
  })

  local close_wins = picker.close_windows
  picker.close_windows = function(status)
    close_wins(status)
    reset()
  end

  picker:find()
end

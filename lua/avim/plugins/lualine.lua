local constants = require("avim.utilities.constants")
local icons = require("avim.icons")

local diff = {
  add = {
    icon = " ",
    hl = {
      fg = "#A3BA5E",
      bg = "Normal",
    },
  },

  change = {
    icon = "  ",
    hl = {
      fg = "#EFB839",
      bg = "Normal",
    },
  },

  remove = {
    icon = "  ",
    hl = {
      fg = "#EC5241",
      bg = "Normal",
    },
  },
}

local diag = {
  error = {
    icon = "  ",
    hl = {
      fg = "#EC5241",
      bg = "Normal",
    },
  },

  warn = {
    icon = "  ",
    hl = {
      fg = "#EFB839",
      bg = "Normal",
    },
  },

  hint = {
    icon = "  ",
    hl = {
      fg = "#A3BA5E",
      bg = "Normal",
    },
  },

  info = {
    icon = "  ",
    hl = {
      fg = "#7EA9A7",
      bg = "Normal",
    },
  },
}
local conditions = {
  buffer_not_empty = function()
    return vim.fn.empty(vim.fn.expand("%:t")) ~= 1
  end,
  hide_in_width = function()
    return vim.fn.winwidth(0) > 80
  end,
  has_updates = function()
    return require("lazy.status").has_updates()
  end,
  has_venv = function()
    return os.getenv("VIRTUAL_ENV") ~= nil
  end,
  is_flutter = function()
    return vim.g.flutter_tools_decorations and vim.g.flutter_tools_decorations.device ~= nil or false
  end,
  has_session = function()
    return vim.g.persisting ~= nil
  end,
  has_file_type = function()
    local f_type = vim.bo.filetype
    if not f_type or f_type == "" then
      return false
    end
    return true
  end,
  has_package_info = function()
    local has_it, _ = pcall(require, "package-info")
    return has_it
  end,
}

local function mode()
  return constants.modes[vim.fn.mode()]
end

local function dir_name()
  local _name = vim.fn.fnamemodify(vim.fn.getcwd(), ":t")
  return icons.folderD .. _name .. " "
end

local function sessions()
  if vim.g.persisting then
    return " "
  elseif vim.g.persisting == false or vim.g.persisting == nil then
    return " "
  end
end

local function venv()
  local venv_path = require("venv-selector").venv()
  if not venv_path or venv_path == "" then
      return " Select Venv"
  end

  local venv_name = vim.fn.fnamemodify(venv_path, ":t")
  if not venv_name then
      return " Select Venv"
  end
  return " " .. venv_name
end

-- Clock
local function clock()
  return vim.fn.strftime("%H:%M")
end

local function osinfo()
  local os = vim.bo.fileformat
  local icon
  if os == "unix" then
    icon = "  "
  elseif os == "mac" then
    icon = "  "
  else
    icon = "  "
  end
  return icon .. os
end

local function updates()
  return require("lazy.status").updates()
end

local function scrollbar()
  -- Another variant, because the more choice the better.
  -- local sbar = { "▁", "▂", "▃", "▄", "▅", "▆", "▇", "█" }
  local sbar = { "🭶", "🭷", "🭸", "🭹", "🭺", "🭻" }
  local curr_line = vim.api.nvim_win_get_cursor(0)[1]
  local lines = vim.api.nvim_buf_line_count(0)
  local i = math.floor((curr_line - 1) / lines * #sbar) + 1
  return string.rep(sbar[i], 2)
end

--- @param trunc_width number trunctates component when screen width is less then trunc_width
--- @param trunc_len number truncates component to trunc_len number of chars
--- @param hide_width number hides component when window width is smaller then hide_width
--- @param no_ellipsis boolean whether to disable adding '...' at end after truncation
--- return function that can format the component accordingly
local function trunc(trunc_width, trunc_len, hide_width, no_ellipsis)
  return function(str)
    local win_width = vim.fn.winwidth(0)
    if hide_width and win_width < hide_width then
      return ""
    elseif trunc_width and trunc_len and win_width < trunc_width and #str > trunc_len then
      return str:sub(1, trunc_len) .. (no_ellipsis and "" or "...")
    end
    return str
  end
end

local processing = false
local spinner_index = 1

local spinner_symbols = {
  "⠋",
  "⠙",
  "⠹",
  "⠸",
  "⠼",
  "⠴",
  "⠦",
  "⠧",
  "⠇",
  "⠏",
}
local spinner_symbols_len = 10

-- Function that runs every time statusline is updated
function companion_status()
  if processing then
    spinner_index = (spinner_index % spinner_symbols_len) + 1
    return spinner_symbols[spinner_index]
  else
    return nil
  end
end

local group = vim.api.nvim_create_augroup("CodeCompanionHooks", {})

vim.api.nvim_create_autocmd({ "User" }, {
  pattern = "CodeCompanionRequest*",
  group = group,
  callback = function(request)
    if request.match == "CodeCompanionRequestStarted" then
      processing = true
    elseif request.match == "CodeCompanionRequestFinished" then
      processing = false
    end
  end,
})

return {
  "nvim-lualine/lualine.nvim",
  event = "VeryLazy",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  opts = {
    options = {
      icons_enabled = true,
      theme = "auto",
      globalstatus = true,
      always_divide_middle = true, -- false,
      component_separators = "", -- "|",
      section_separators = { left = "", right = "" }, -- { left = "", right = "" },
    },
    sections = {
      lualine_a = {
        {
          mode,
          color = {
            fg = constants.mode_colors[vim.fn.mode()],
            gui = "bold",
            bg = "Normal",
          },
        },
        {
          dir_name,
          cond = conditions.hide_in_width,
          color = { fg = constants.mode_color[vim.fn.mode()], bg = "Normal" },
          separator = { right = "" },
          on_click = function()
            -- vim.cmd("Neotree filesystem left toggle")
            Snacks.explorer()
          end,
        },
      },
      lualine_b = {
        {
          "diagnostics",
          colored = true,
          sources = { "nvim_diagnostic", "nvim_lsp" },
          sections = { "error", "warn", "hint", "info" },
          separator = { right = "" },
          symbols = {
            error = diag.error.icon,
            warn = diag.warn.icon,
            hint = diag.hint.icon,
            info = diag.info.icon,
          },
          diagnostics_color = {
            error = "DiagnosticError", -- Changes diagnostics' error color.
            warn = "DiagnosticWarn", -- Changes diagnostics' warn color.
            info = "DiagnosticInfo", -- Changes diagnostics' info color.
            hint = "DiagnosticHint", -- Changes diagnostics' hint color.
          },
          on_click = function(clicks, button, modifiers)
            if "r" == button then
              Snacks.picker.diagnostics()
            end
            if "l" == button then
              Snacks.picker.diagnostics_buffer()
            end
          end,
        },
      },
      lualine_c = {
        {
          companion_status,
          cond = function()
            return processing
          end,
          color = { fg = "#CDD6F4", bg = "Normal" },
        },
        --[[ {
          function()
            return require("mcphub.extensions.lualine")
          end,
          color = { fg = "#CDD6F4", bg = "Normal" },
        }, ]]
      },
      lualine_x = {
        {
          function()
            return vim.g.flutter_tools_decorations and vim.g.flutter_tools_decorations.device or ""
          end,
          cond = conditions.is_flutter,
          color = { bg = "Normal" },
        },
        {
          venv,
          cond = conditions.has_venv,
          color = { fg = "#CDD6F4", bg = "Normal" },
          on_click = function()
            vim.cmd("VenvSelect")
          end,
        },
        {
          "diff",
          colored = true,
          diff_color = {
            added = "DiffAdd", -- Changes the diff's added color
            modified = "DiffChange", -- Changes the diff's modified color
            removed = "DiffDelete", -- Changes the diff's removed color you
          },
          color = { bg = "Normal" },
          symbols = { added = diff.add.icon, modified = diff.change.icon, removed = diff.remove.icon }, -- Changes the symbols used by the diff.
          on_click = function()
            vim.cmd("DiffviewOpen")
          end,
        },
        {
          "branch",
          icon = "",
          cond = conditions.hide_in_width,
          color = { bg = "Normal" },
          on_click = function(clicks, button, modifiers)
            Snacks.lazygit()
          end,
        },
      },
      lualine_y = {
        {
          "filetype",
          colored = true,
          icon_only = false,
          icon = { align = "left" },
          color = { bg = "Normal" },
          on_click = function(clicks, button, modifiers)
            if "l" == button then
              vim.cmd("Mason")
            end
          end,
        },
        {
          updates,
          cond = conditions.has_updates,
          on_click = function(clicks, button, modifiers)
            if "l" == button then
              vim.cmd("Lazy")
            end
            if "r" == button then
              vim.cmd("Lazy sync")
            end
          end,
        },
        { osinfo, cond = conditions.hide_in_width, separator = { right = "" } }, -- "", "" } },
      },
      lualine_z = {
        {
          sessions,
          color = { fg = vim.g.persisting and "#7EA9A7" or "#EFB839", bg = "Normal" },
          cond = conditions.has_session,
          separator = { left = "" }, -- "" },
          on_click = function(clicks, button, modifiers)
            if "l" == button then
              if vim.g.persisting then
                vim.cmd("Persisted load")
              else
                vim.cmd("Persisted select")
              end
            end
            if "r" == button then
              vim.cmd("Persisted select")
            end
          end,
        },
        { "location", color = { fg = constants.mode_colors[vim.fn.mode()], bg = "Normal" } },
        { "progress", color = { fg = constants.mode_colors[vim.fn.mode()], bg = "Normal" } },
        { scrollbar, color = { fg = constants.mode_color[vim.fn.mode()], bg = "Normal" } },
      },
    },
    inactive_sections = {
      lualine_a = { { mode, color = { fg = constants.mode_colors[vim.fn.mode()], gui = "bold", bg = "Normal" } } },
      lualine_b = {
        {
          dir_name,
          cond = conditions.hide_in_width,
          color = { fg = constants.mode_color[vim.api.nvim_get_mode().mode], bg = "Normal" },
          separator = { right = "" },
          on_click = function()
            Snacks.explorer()
          end,
        },
      },
      lualine_c = {
        -- { "%=", color = { bg = "Normal" } },
        -- { clock, icon = " ", color = { fg = mode_color[vim.fn.mode()], bg = "Normal" } },
      },
      lualine_x = {},
      lualine_y = {},
      lualine_z = {
        {
          "branch",
          icon = "",
          cond = conditions.hide_in_width,
          color = { bg = "Normal" },
          on_click = function(clicks, button, modifiers)
            Snacks.lazygit()
          end,
        },
        { "location", color = { fg = constants.mode_colors[vim.fn.mode()], bg = "Normal" } },
        { "progress", color = { fg = constants.mode_colors[vim.fn.mode()], bg = "Normal" } },
        {
          clock,
          icon = " ",
          color = { fg = constants.mode_color[vim.fn.mode()], bg = "Normal" },
          on_click = function()
            require("lualine").refresh()
          end,
        },
      },
    },
  },
}

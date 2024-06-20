local features = require("avim.core.defaults").features

if features.bufferline then
  vim.cmd([[
    function! Quit_vim(a,b,c,d)
        qa
    endfunction
  ]])
end

return {
  "akinsho/bufferline.nvim",
  enabled = features.bufferline,
  event = "VeryLazy",
  version = "*",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  opts = {
    options = {
      offsets = {
        {
          filetype = "NvimTree",
          text = "File Explorer",
          highlight = "Directory",
          text_align = "center", -- "left" | "right"
          padding = 1,
        },
        {
          filetype = "undotree",
          text = "Undotree",
          highlight = "PanelHeading",
          padding = 1,
        },
        {
          filetype = "DiffviewFiles",
          text = "Diff View",
          highlight = "PanelHeading",
          padding = 1,
        },
        {
          filetype = "flutterToolsOutline",
          text = "Flutter Outline",
          highlight = "PanelHeading",
        },
        {
          filetype = "lazy",
          text = "Lazy",
          highlight = "PanelHeading",
          padding = 1,
        },
      },
      right_mouse_command = "vertical sbuffer %d",
      color_icons = true,
      show_close_icon = true,
      show_buffer_icons = true,
      show_tab_indicators = true,
      show_buffer_close_icons = true,
      show_buffer_default_icons = true,
      enforce_regular_tabs = false,
      always_show_bufferline = true,
      buffer_close_icon = "", -- icons.close_icon
      modified_icon = "",
      close_icon = "",
      left_trunc_marker = " ",
      right_trunc_marker = " ",
      max_name_length = 14,
      max_prefix_length = 13,
      tab_size = 20,
      view = "multiwindow",
      -- indicator = {
      --   -- icon = '▎', -- this should be omitted if indicator style is not 'icon'
      --   style = "underline", -- "icon" | "underline" | "none",
      -- },
      separator_style = "thick", -- "thick" | "slant" | "slope"
      -- NOTE: this plugin is designed with this icon in mind,
      -- and so changing this is NOT recommended, this is intended
      -- as an escape hatch for people who cannot bear it for whatever reason
      -- indicator_icon = '▎',
      -- For ⁸·₂
      numbers = function(opts)
        return string.format("%s·%s", opts.raise(opts.id), opts.lower(opts.ordinal))
      end,
      diagnostics = false, -- "nvim_lsp"
      diagnostics_indicator = function(count, level, diagnostics_dict, context)
        local s = " "
        for e, n in pairs(diagnostics_dict) do
          local sym = e == "error" and " " or (e == "warning" and " " or "")
          s = s .. n .. sym
        end
        return s
      end,
      themable = true,
      hover = {
        enabled = true, -- requires nvim 0.8+
        delay = 200,
        reveal = { "close" },
      },
      custom_areas = {
        right = function()
          local result = {}
          local seve = vim.diagnostic.severity
          local error = #vim.diagnostic.get(0, { severity = seve.ERROR })
          local warning = #vim.diagnostic.get(0, { severity = seve.WARN })
          local info = #vim.diagnostic.get(0, { severity = seve.INFO })
          local hint = #vim.diagnostic.get(0, { severity = seve.HINT })

          if error ~= 0 then
            table.insert(result, { text = "  " .. error, guifg = "#EC5241" })
          end
          if warning ~= 0 then
            table.insert(result, { text = "  " .. warning, guifg = "#EFB839" })
          end
          if hint ~= 0 then
            table.insert(result, { text = "  " .. hint, guifg = "#A3BA5E" })
          end
          if info ~= 0 then
            table.insert(result, { text = "  " .. info, guifg = "#7EA9A7" })
          end
          -- table.insert(result, { text = "%@Quit_vim@  %X" })
          return result
        end,
      },

      custom_filter = function(buf_number)
        -- Func to filter out our managed/persistent split terms
        local present_type, type = pcall(function()
          return vim.api.nvim_buf_get_var(buf_number, "term_type")
        end)

        if present_type then
          if type == "vert" then
            return false
          elseif type == "hori" then
            return false
          end
          return true
        end

        return true
      end,
    },
  },
}

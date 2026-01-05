local autocmd = vim.api.nvim_create_autocmd
local augroup = vim.api.nvim_create_augroup
local utilities = require("avim.utilities")

-- Maximizer
vim.g.maximizer_set_default_mapping = 1
vim.g.maximizer_set_mapping_with_bang = 1
-- vim.g.maximizer_default_mapping_key = "<F3>"

-- Illuminate
-- vim.g.Illuminate_delay = 0
-- vim.g.Illuminate_highlightUnderCursor = 0
vim.g.Illuminate_ftblacklist = { "alpha", "NvimTree", "neo-tree" }
-- vim.g.Illuminate_highlightUnderCursor = 0

-- Fix Highlight group instead of underline, highlight
vim.api.nvim_set_hl(0, "IlluminatedWordText", { link = "Visual" }) -- underline = false
vim.api.nvim_set_hl(0, "IlluminatedWordRead", { link = "Visual" })
vim.api.nvim_set_hl(0, "IlluminatedWordWrite", { link = "Visual" })
vim.api.nvim_set_hl(0, "IlluminatedCurWord", { italic = true })

local d_theme, _ = pcall(vim.api.nvim_get_autocmds, { group = "_dynamic_theme" })
if not d_theme then
  augroup("_dynamic_theme", { clear = true })
end
autocmd({ "VimEnter", "VimResume" }, {
  group = "_dynamic_theme",
  desc = "Sets up a theme according to time of day",
  pattern = "*",
  callback = function()
    local _time = os.date("*t")
    local hour = _time.hour
    
    -- Simplified time-based theme selection
    local theme
    if hour >= 21 or hour < 1 then
      theme = "catppuccin"
    elseif hour >= 16 then
      theme = "rose-pine"
    elseif hour >= 11 then
      theme = "oxocarbon"
    elseif hour >= 5 then
      theme = "tokyodark"
    else -- 1-5 AM
      theme = "kanagawa"
    end
    
    vim.cmd("colorscheme " .. theme)
    _G.avim.theme = vim.g.colors_name
  end,
})

-------------------------------------------------------------------------------
--- Keymaps
-------------------------------------------------------------------------------
-- Window Move
utilities.map("n", "<A-m>", nil, { name = " Window Movement" })
-- Illuminate
-------------------------------------------------------------------------------

return {
  {
    "MunifTanjim/nui.nvim",
    config = function()
      require("avim.utilities.ui").load()
    end,
  },
  {
    "folke/noice.nvim",
    event = "VeryLazy",
    dependencies = {
      "MunifTanjim/nui.nvim",
      {
        "rcarriga/nvim-notify",
        opts = {
          -- active = false,
          ---@usage Animation style one of { "fade", "slide", "fade_in_slide_out", "static" }
          stages = "slide",

          ---@usage timeout for notifications in ms, default 5000
          timeout = 5000,

          -- Render function for notifications. See notify-render()
          render = "default",

          ---@usage minimum width for notification windows
          minimum_width = 50,

          ---@usage Icons for the different levels
          icons = {
            ERROR = "",
            WARN = "",
            INFO = "",
            DEBUG = "",
            TRACE = "✎",
          },
        },
      },
    },
    opts = {
      cmdline = {
        format = {
          cmdline = { icon = ">" },
          search_down = { icon = "🔍⌄" },
          search_up = { icon = "🔍⌃" },
          filter = { icon = "$" },
          lua = { icon = "☾" },
          help = { icon = "?" },
        },
      },
      format = {
        level = {
          icons = {
            error = "✖",
            warn = "▼",
            info = "●",
          },
        },
      },
      lsp = {
        signature = { enabled = false },
        hover = { enabled = false },
        -- override markdown rendering so that **cmp** and other plugins use **Treesitter**
        override = {
          ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
          ["vim.lsp.util.stylize_markdown"] = true,
          ["cmp.entry.get_documentation"] = true,
        },
      },
      -- you can enable a preset for easier configuration
      presets = {
        bottom_search = false, -- use a classic bottom cmdline for search
        command_palette = true, -- position the cmdline and popupmenu together
        long_message_to_split = true, -- long messages will be sent to a split
        inc_rename = true, -- enables an input dialog for inc-rename.nvim
        lsp_doc_border = false, -- add a border to hover docs and signature help
      },
      views = {
        cmdline_popup = {
          position = {
            row = 5,
            col = "50%",
          },
          size = {
            width = 60,
            height = "auto",
          },
        },
        popupmenu = {
          relative = "editor",
          position = {
            row = 8,
            col = "50%",
          },
          size = {
            width = 60,
            height = 10,
          },
          border = {
            style = "rounded",
            padding = { 0, 1 },
          },
          win_options = {
            winhighlight = { Normal = "Normal", FloatBorder = "DiagnosticInfo" },
          },
        },
      },
      routes = {
        {
          filter = {
            event = "notify",
            find = "No information available",
          },
          opts = { skip = true },
        },
        {
          view = "notify",
          filter = { event = "msg_showmode" },
        },
        {
          filter = {
            event = "msg_show",
            any = {
              { find = "%d+L, %d+B" },
              { find = "; after #%d+" },
              { find = "; before #%d+" },
            },
          },
          view = "mini",
        },
        -- Filter out LSP progress errors from servers with invalid tokens
        {
          filter = {
            event = "lsp",
            kind = "progress",
            cond = function(message)
              local client = vim.lsp.get_client_by_id(message.opts.progress and message.opts.progress.client_id)
              -- Skip progress messages from Roslyn and other problematic servers
              return client and (client.name == "roslyn" or client.name == "omnisharp")
            end,
          },
          opts = { skip = true },
        },
      },
    },
  },
  {
    "goolord/alpha-nvim",
    lazy = false,
    config = function()
      local alpha = require("alpha")
      local fortune = require("alpha.fortune")
      local greeting = utilities.get_greeting("Rebel")
      local banner = require("avim.utilities.banners")["random"]

      --- @param sc string
      --- @param txt string
      --- @param keybind string? optional
      --- @param keybind_opts table? optional
      local function button(sc, txt, keybind, keybind_opts)
        local sc_ = sc:gsub("%s", ""):gsub("SPC", "<leader>")

        local opts = {
          position = "center",
          -- text = txt,
          shortcut = sc,
          cursor = 5,
          width = 30,
          align_shortcut = "right",
          hl_shortcut = "AlphaKeyPrefix",
          hl = {
            { "WildMenu", 1, 3 }, -- highlight the icon glyph
            { "AlphaButtonLabelText", 4, 15 }, -- highlight the part after the icon glyph
          },
        }

        if keybind then
          keybind_opts = vim.F.if_nil(keybind_opts, { noremap = true, silent = true, nowait = true })
          if sc ~= "" then
            opts.keymap = { "n", sc_, keybind, keybind_opts }
          end
        end

        return {
          type = "button",
          val = txt,
          on_press = function()
            local key = vim.api.nvim_replace_termcodes(keybind or sc_ .. "<Ignore>", true, false, true)
            vim.api.nvim_feedkeys(key, "t", false)
          end,
          opts = opts,
        }
      end

      local section = {}

      section.header = {
        type = "text",
        val = banner,
        opts = {
          position = "center",
          hl = "AlphaHeader",
        },
      }

      section.greetings = {
        type = "text",
        val = greeting,
        opts = {
          position = "center",
          hl = "String",
        },
      }

      -- ╭──────────────────────────────────────────────────────────╮
      -- │ Heading Info                                             │
      -- ╰──────────────────────────────────────────────────────────╯

      local thingy = io.popen('echo "$(date +%a) $(date +%d) $(date +%b)" | tr -d "\n"')
      if thingy == nil then
        return
      end
      local date = thingy:read("*a")
      thingy:close()

      local datetime = os.date(" %H:%M")

      section.hi_top_section = {
        type = "text",
        val = "┌────────────   Today is "
          .. date
          .. " ────────────┐",
        opts = {
          position = "center",
          hl = "String", -- AlphaLoaded
        },
      }

      section.hi_middle_section = {
        type = "text",
        val = "│                                                │",
        opts = {
          position = "center",
          hl = "String",
        },
      }

      section.hi_bottom_section = {
        type = "text",
        val = "└───══───══───══───  "
          .. datetime
          .. "  ───══───══───══────┘",
        opts = {
          position = "center",
          hl = "String",
        },
      }

      section.buttons = {
        type = "group",
        val = {
          -- button("SPC e", "  > New file" , "<cmd>ene <BAR> startinsert <CR>"),
          -- button("SPC f f", "  Find File  ", "<cmd>Snacks.picker.files()<CR>"),
          button("o", "  Recent Files  ", "<cmd>lua Snacks.picker.recent()<CR>"),
          -- button("SPC fw", "  Find Word  ", "<cmd>Snacks.picker.grep()<CR>"),
          -- button("SPC fk", "  Mappings  ", "<cmd>Snacks.picker.keymaps()<CR>"),
          button("r", "⟳ Restore Session  ", "<cmd>SessionLoad<CR>"),
          button("s", "⮪  Recent Session  ", "<cmd>SessionLoadLast<CR>"),
          button("l", "  List Sessions  ", "<cmd>SessionSelect<CR>"),
          -- button("SPC e s", "  Settings", "<cmd>e $MYVIMRC | :cd %:p:h | split . | wincmd k | pwd<CR>"),
          button("q", "  Quit", "<Cmd>qa<CR>"),
        },
        opts = {
          spacing = 1,
        },
      }

      local footer = function()
        local stats = require("lazy").stats()
        local v = vim.version()
        local platform = vim.fn.has("win32") == 1 and "" or ""
        return string.format(
          " v%d.%d.%d | Took %.2f ms to load  %d of %d plugins on  %s",
          v.major,
          v.minor,
          v.patch,
          (math.floor(stats.startuptime * 100 + 0.5) / 100),
          stats.loaded,
          stats.count,
          platform
        )
        -- return string.format(" v%d.%d.%d   %d  %s", v.major, v.minor, v.patch, plugins, platform)
      end

      section.footer = {
        type = "text",
        val = { footer() },
        opts = {
          position = "center",
          hl = "AlphaLoaded",
        },
      }

      section.message = {
        type = "text",
        val = fortune({ max_width = 60 }),
        opts = {
          position = "center",
          hl = "AlphaFooting",
        },
      }

      alpha.setup({
        layout = {
          { type = "padding", val = 2 },
          section.header,
          { type = "padding", val = 1 },
          section.hi_top_section,
          section.hi_middle_section,
          section.greetings,
          section.hi_middle_section,
          section.hi_bottom_section,
          { type = "padding", val = 1 },
          section.buttons,
          -- { type = "padding", val = 1 },
          section.footer,
          { type = "padding", val = 1 },
          section.message,
        },
        opts = {
          margin = 5,
        },
      })
      -- Disable statusline in dashboard
      ---- Hmmm, with winbar, i doubt that i need this though 🤔
      -- https://github.com/goolord/alpha-nvim/issues/42
      local dash, _ = pcall(vim.api.nvim_get_autocmds, { group = "_dashboard_settings" })
      if not dash then
        augroup("_dashboard_settings", {})
      end
      autocmd("FileType", {
        group = "_dashboard_settings",
        desc = "Hide statusline on Alpha",
        pattern = "alpha",
        -- command = "set showtabline=0 | autocmd BufLeave <buffer> set showtabline=" .. vim.opt.showtabline._value,
        command = "set laststatus=0 | autocmd BufUnload <buffer> set laststatus=" .. vim.opt.laststatus._value,
      })
    end,
    keys = {
      { "<leader>h", "<cmd>Alpha<CR>", mode = { "n", "v" }, desc = " Dashboard" },
    },
  },
  { "DanilaMihailov/beacon.nvim" }, -- cmd = { "Beacon", "BeaconToggle", "BeaconOn", "BeaconOff" } },
  {
    "RRethy/vim-illuminate",
    -- keys = {
    --     {
    --         "<A-n>",
    --         '<cmd>lua require"illuminate".next_reference{wrap=true}<cr>',
    --         desc = "Next Illuminated Reference"
    --     },
    --     {
    --         "<A-p>",
    --         '<cmd>lua require"illuminate".next_reference{reverse=true,wrap=true}<cr>',
    --         desc = "Previous Illuminated Reference"
    --     },
    -- },
  },
  {
    "nvim-mini/mini.animate",
    event = "VeryLazy",
    cond = vim.g.neovide == nil,
    opts = function(_, opts)
      -- don't use animate when scrolling with the mouse
      local mouse_scrolled = false
      for _, scroll in ipairs({ "Up", "Down" }) do
        local key = "<ScrollWheel" .. scroll .. ">"
        vim.keymap.set({ "", "i" }, key, function()
          mouse_scrolled = true
          return key
        end, { expr = true })
      end

      autocmd("FileType", {
        pattern = "grug-far",
        callback = function()
          vim.b.minianimate_disable = true
        end,
      })

      Snacks.toggle({
        name = "Mini Animate",
        get = function()
          return not vim.g.minianimate_disable
        end,
        set = function(state)
          vim.g.minianimate_disable = not state
        end,
      }):map("<leader>ua")

      local animate = require("mini.animate")
      return vim.tbl_deep_extend("force", opts, {
        resize = {
          timing = animate.gen_timing.linear({ duration = 50, unit = "total" }),
        },
        scroll = {
          timing = animate.gen_timing.linear({ duration = 150, unit = "total" }),
          subscroll = animate.gen_subscroll.equal({
            predicate = function(total_scroll)
              if mouse_scrolled then
                mouse_scrolled = false
                return false
              end
              return total_scroll > 1
            end,
          }),
        },
      })
    end,
  },
  {
    "nvim-tree/nvim-web-devicons",
    config = true,
  },
  {
    "kevinhwang91/nvim-hlslens",
    event = "VeryLazy",
    config = function()
      require("hlslens").setup({
        override_lens = function(render, posList, nearest, idx, relIdx)
          local sfw = vim.v.searchforward == 1
          local indicator, text, chunks
          local absRelIdx = math.abs(relIdx)
          if absRelIdx > 1 then
            indicator = ("%d%s"):format(absRelIdx, sfw ~= (relIdx > 1) and "▲" or "▼")
          elseif absRelIdx == 1 then
            indicator = sfw ~= (relIdx == 1) and "▲" or "▼"
          else
            indicator = ""
          end

          local lnum, col = unpack(posList[idx]) --table.unpack
          if nearest then
            local cnt = #posList
            if indicator ~= "" then
              text = ("[%s %d/%d]"):format(indicator, idx, cnt)
            else
              text = ("[%d/%d]"):format(idx, cnt)
            end
            chunks = { { " ", "Ignore" }, { text, "HlSearchLensNear" } }
          else
            text = ("[%s %d]"):format(indicator, idx)
            chunks = { { " ", "Ignore" }, { text, "HlSearchLens" } }
          end
          render.setVirt(0, lnum - 1, col - 1, chunks, nearest)
        end,
      })
    end,
  },
  {
    -- "NvChad/nvim-colorizer.lua",
    "brenoprata10/nvim-highlight-colors",
    event = "BufReadPre",
    opts = {
      render = "background", -- "foreground" | "virtual"
      enable_named_colors = true,
      enable_tailwind = true,
    },
  },
  {
    "b0o/incline.nvim",
    event = "VeryLazy",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      local get_buf_option = vim.api.nvim_buf_get_option
      require("incline").setup({
        hide = {
          -- only_win = "count_ignored",
          -- cursorline = "focused_win",
        },
        render = function(props)
          local bufname = vim.api.nvim_buf_get_name(props.buf)
          local filename = vim.fn.fnamemodify(bufname, ":t")
          local status = utilities.get_status(filename)
          local modified = get_buf_option(props.buf, "modified") and "" or "" -- "⦁"
          local fg = require("avim.utilities.constants").mode_color[vim.fn.mode()]
          local readonly = (vim.bo.readonly and vim.bo ~= "help") and require("avim.icons").ui.Lock or ""
          return {
            status,
            { " " },
            readonly,
            { readonly == "" and "" or " " },
            { filename, guifg = fg },
            { " " },
            { modified, guifg = "#A3BA5E" },
          }
        end,
      })
    end,
  },
  {
    "3rd/image.nvim",
    opts = {
      backend = "kitty",
      processor = "magick_rock", -- or "magick_cli"
      integrations = {
        markdown = {
          enabled = true,
          clear_in_insert_mode = true,
          download_remote_images = true,
          only_render_image_at_cursor = false,
          filetypes = { "markdown", "vimwiki" }, -- markdown extensions (ie. quarto) can go here
        },
        html = {
          enabled = false,
        },
        css = {
          enabled = false,
        },
      },
      editor_only_render_when_focused = false, -- auto show/hide images when the editor gains/looses focus
    },
  },
  {
    "barrett-ruth/import-cost.nvim",
    enabled = false, -- NOTE: Seems resource intensive
    event = "VeryLazy",
    build = "sh install.sh yarn",
    opts = {
      filetypes = {
        "javascript",
        "javascriptreact",
        "typescript",
        "typescriptreact",
        "vue",
        "svelte",
        "astro",
      },
    },
  },
  { "szw/vim-maximizer", cmd = { "MaximizerToggle" } },
  {
    "sindrets/winshift.nvim",
    cmd = "WinShift",
    config = true,
    keys = {
      { "<A-m><Tab>", "<CMD>WinShift swap<CR>", desc = "Swap Windows", noremap = true },
      { "<A-m>h", "<CMD>WinShift left<CR>", desc = "Shift Window Left", noremap = true },
      { "<A-m><Left>", "<CMD>WinShift left<CR>", desc = "Shift Window Left", noremap = true },
      { "<A-m>j", "<CMD>WinShift down<CR>", desc = "Shift Window Down", noremap = true },
      { "<A-m><Down>", "<CMD>WinShift down<CR>", desc = "Shift Window Down", noremap = true },
      { "<A-m>k", "<CMD>WinShift up<CR>", desc = "Shift Window Up", noremap = true },
      { "<A-m><Up>", "<CMD>WinShift up<CR>", desc = "Shift Window Up", noremap = true },
      { "<A-m>l", "<CMD>WinShift right<CR>", desc = "Shift Window Right", noremap = true },
      { "<A-m><Right>", "<CMD>WinShift right<CR>", desc = "Shift Window Right", noremap = true },
    },
  },
}

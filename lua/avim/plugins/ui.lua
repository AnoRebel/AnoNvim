local autocmd = vim.api.nvim_create_autocmd
local augroup = vim.api.nvim_create_augroup
local features = require("avim.core.defaults").features
local utils = require("avim.utils")

-- Maximizer
vim.g.maximizer_set_default_mapping = 1
vim.g.maximizer_set_mapping_with_bang = 1
-- vim.g.maximizer_default_mapping_key = "<F3>"

-- Beacon
vim.g.beacon_timeout = 300

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

if features.buffer_dim then
  -- Dim buffer text if inactive
  vim.api.nvim_set_hl(_G.avim.bufferDimNSId or 0, "BufDimText", { bg = "NONE", fg = "#222222", sp = "#555555" })
  -- Dim Windows
  local win_dim, _ = pcall(vim.api.nvim_get_autocmds, { group = "_window_dim" })
  if not win_dim then
    augroup("_window_dim", {})
  end
  autocmd("WinEnter", {
    group = "_window_dim",
    desc = "Dim inactive windows",
    pattern = "*",
    command = 'lua require("avim.utils").toggle_windows_dim()',
    -- callback = utils.toggle_windows_dim,
  })
end

if features.dynamic_theme then
  local d_theme, _ = pcall(vim.api.nvim_get_autocmds, { group = "_dynamic_theme" })
  if not d_theme then
    augroup("_dynamic_theme", { clear = true })
  end
  autocmd({ "VimEnter", "VimResume", "FocusGained", "BufEnter" }, {
    group = "_dynamic_theme",
    desc = "Sets up a theme according to time of day",
    pattern = "*",
    callback = function()
      local _time = os.date("*t")
      if (_time.hour >= 21 and _time.hour < 24) or (_time.hour >= 0 and _time.hour < 1) then
        vim.cmd([[colorscheme catppuccin]])
        _G.avim.theme = vim.g.colors_name
      elseif (_time.hour >= 16 and _time.hour < 21) or (_time.hour >= 0 and _time.hour < 1) then
        vim.cmd([[colorscheme rose-pine]])
        _G.avim.theme = vim.g.colors_name
      elseif _time.hour >= 1 and _time.hour < 5 then
        vim.cmd([[colorscheme kanagawa]])
        _G.avim.theme = vim.g.colors_name
      elseif _time.hour >= 5 and _time.hour < 11 then
        vim.cmd([[colorscheme tokyodark]])
        _G.avim.theme = vim.g.colors_name
      elseif _time.hour >= 11 and _time.hour < 16 then
        vim.cmd([[colorscheme oxocarbon]])
        _G.avim.theme = vim.g.colors_name
      else
        vim.cmd([[colorscheme tokyodark]])
        _G.avim.theme = vim.g.colors_name
      end
    end,
  })
else
  vim.cmd([[colorscheme tokyodark]])
  _G.avim.theme = vim.g.colors_name
end

if features.kitty then
  -- recommended mappings
  -- resizing splits
  -- these keymaps will also accept a range,
  -- for example `10<A-h>` will `resize_left` by `(10 * config.default_amount)`
  utils.map(
    { "n", "v" },
    "<A-Left>",
    '<cmd>lua require("smart-splits").resize_left()<CR>',
    { desc = "Resize Window Left" }
  )
  utils.map(
    { "n", "v" },
    "<A-Down>",
    '<cmd>lua require("smart-splits").resize_down()<CR>',
    { desc = "Resize Window Down" }
  )
  utils.map({ "n", "v" }, "<A-Up>", '<cmd>lua require("smart-splits").resize_up()<CR>', { desc = "Resize Window Up" })
  utils.map(
    { "n", "v" },
    "<A-Right>",
    '<cmd>lua require("smart-splits").resize_right()<CR>',
    { desc = "Resize Window Right" }
  )
  -- moving between splits
  utils.map(
    { "n", "v" },
    "<C-h>",
    '<cmd>lua require("smart-splits").move_cursor_left()<CR>',
    { desc = "Move to Left Window" }
  )
  utils.map(
    { "n", "v" },
    "<C-j>",
    '<cmd>lua require("smart-splits").move_cursor_down()<CR>',
    { desc = "Move to Bottom Window" }
  )
  utils.map(
    { "n", "v" },
    "<C-k>",
    '<cmd>lua require("smart-splits").move_cursor_up()<CR>',
    { desc = "Move to Top Window" }
  )
  utils.map(
    { "n", "v" },
    "<C-l>",
    '<cmd>lua require("smart-splits").move_cursor_right()<CR>',
    { desc = "Move to Right Window" }
  )
  utils.map(
    { "n", "v" },
    "<C-\\>",
    '<cmd>lua require("smart-splits").move_cursor_previous()<CR>',
    { desc = "Move to Previous Window" }
  )
  -- swapping buffers between windows
  utils.map({ "n", "v" }, "<leader><leader>", nil, { name = "󰓡 Swap Windows" })
  utils.map(
    { "n", "v" },
    "<leader><leader>h",
    '<cmd>lua require("smart-splits").swap_buf_left()<CR>',
    { desc = "Swap Window Left" }
  )
  utils.map(
    { "n", "v" },
    "<leader><leader>j",
    '<cmd>lua require("smart-splits").swap_buf_down()<CR>',
    { desc = "Swap Window Down" }
  )
  utils.map(
    { "n", "v" },
    "<leader><leader>k",
    '<cmd>lua require("smart-splits").swap_buf_up()<CR>',
    { desc = "Swap Window Up" }
  )
  utils.map(
    { "n", "v" },
    "<leader><leader>l",
    '<cmd>lua require("smart-splits").swap_buf_right()<CR>',
    { desc = "Swap Window Right" }
  )
end
autocmd({ "FocusGained", "TermClose", "TermLeave" }, { command = "checktime" })
-- Highlight yanked text
local yankin, _ = pcall(vim.api.nvim_get_autocmds, { group = "_general_settings" })
if not yankin then
  augroup("_general_settings", {})
end
autocmd("TextYankPost", {
  group = "_general_settings",
  pattern = "*",
  desc = "Highlight text on yank",
  callback = function()
    vim.highlight.on_yank({ higroup = "Search", timeout = 200 })
  end,
})
local bcon, _ = pcall(vim.api.nvim_get_autocmds, { group = "_beacon_cursor_line" })
if not bcon then
  augroup("_beacon_cursor_line", {})
end
autocmd("WinEnter", {
  group = "_beacon_cursor_line",
  pattern = "*",
  desc = "Hide cursor line on inactive windows",
  command = "setlocal cursorline",
})
autocmd("WinLeave", {
  group = "_beacon_cursor_line",
  pattern = "*",
  desc = "Hide cursor line on inactive windows",
  command = "setlocal nocursorline",
})

-------------------------------------------------------------------------------
--- Keymaps
-------------------------------------------------------------------------------
-- Window Move
utils.map("n", "<A-m>", nil, { name = " Window Movement" })
utils.map("n", "<A-m><Tab>", "<CMD>WinShift swap<CR>", { desc = "Swap Windows", noremap = true })
utils.map("n", "<A-m>h", "<CMD>WinShift left<CR>", { desc = "Shift Window Left", noremap = true })
utils.map("n", "<A-m><Left>", "<CMD>WinShift left<CR>", { desc = "Shift Window Left", noremap = true })
utils.map("n", "<A-m>j", "<CMD>WinShift down<CR>", { desc = "Shift Window Down", noremap = true })
utils.map("n", "<A-m><Down>", "<CMD>WinShift down<CR>", { desc = "Shift Window Down", noremap = true })
utils.map("n", "<A-m>k", "<CMD>WinShift up<CR>", { desc = "Shift Window Up", noremap = true })
utils.map("n", "<A-m><Up>", "<CMD>WinShift up<CR>", { desc = "Shift Window Up", noremap = true })
utils.map("n", "<A-m>l", "<CMD>WinShift right<CR>", { desc = "Shift Window Right", noremap = true })
utils.map("n", "<A-m><Right>", "<CMD>WinShift right<CR>", { desc = "Shift Window Right", noremap = true })
-- Illuminate
utils.map(
  "n",
  "<A-n>",
  '<cmd>lua require"illuminate".next_reference{wrap=true}<cr>',
  { desc = "Next Illuminated Reference" }
)
utils.map(
  "n",
  "<A-p>",
  '<cmd>lua require"illuminate".next_reference{reverse=true,wrap=true}<cr>',
  { desc = "Previous Illuminated Reference" }
)
-------------------------------------------------------------------------------

return {
  {
    "MunifTanjim/nui.nvim",
    config = function()
      require("avim.utils.vim_ui").load()
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
      },
    },
  },
  {
    "goolord/alpha-nvim",
    enabled = features.dashboard,
    lazy = false,
    config = function()
      local alpha = require("alpha")
      local fortune = require("alpha.fortune")
      local greeting = utils.get_greeting("Rebel")
      local banner = require("avim.utils.banners")["random"]

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
          opts.keymap = { "n", sc_, keybind, keybind_opts }
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
          -- button("SPC f f", "  Find File  ", "<cmd>Telescope find_files<CR>"),
          button("SPC f o", "  Recent File  ", "<cmd>Telescope oldfiles<CR>"),
          -- button("SPC f w", "  Find Word  ", "<cmd>Telescope live_grep<CR>"),
          -- button("SPC f k", "  Mappings  ", "<cmd>Telescope keymaps<CR>"),
          button("", "⟳ Restore Session  ", "<cmd>SessionLoad<CR>"),
          button("", "⮪  Recent Session  ", "<cmd>SessionLoadLast<CR>"),
          button("", "  List Sessions  ", "<cmd>Telescope persisted<CR>"),
          -- button("SPC e s", "  Settings", "<cmd>e $MYVIMRC | :cd %:p:h | split . | wincmd k | pwd<CR>"),
          button("CTRL q", "  Quit", "<Cmd>qa<CR>"),
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
      utils.map({ "n", "v", "x" }, "<leader>h", "<cmd>Alpha<CR>", { desc = " Dashboard" })
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
  },
  { "DanilaMihailov/beacon.nvim" }, -- cmd = { "Beacon", "BeaconToggle", "BeaconOn", "BeaconOff" } },
  { "RRethy/vim-illuminate" },
  {
    "nvim-tree/nvim-web-devicons",
    config = true,
  },
  {
    "kevinhwang91/nvim-hlslens",
    enabled = features.inline,
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
    enabled = features.incline,
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
          local status = utils.get_status(filename)
          local modified = get_buf_option(props.buf, "modified") and "" or "" -- "⦁"
          local fg = require("avim.utils.constants").mode_color[vim.fn.mode()]
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
    "echasnovski/mini.animate",
    version = false,
    enabled = features.animate,
    config = function()
      local mouse_scrolled = false
      for _, scroll in ipairs({ "Up", "Down" }) do
        local key = "<ScrollWheel" .. scroll .. ">"
        vim.keymap.set("", key, function()
          mouse_scrolled = true
          return key
        end, { remap = true, expr = true })
      end
      require("mini.animate").setup({
        scroll = {
          subscroll = require("mini.animate").gen_subscroll.equal({
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
    "3rd/image.nvim",
    opts = {
      backend = "kitty",
      integrations = {
        markdown = { enabled = true },
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
  -- { "knubie/vim-kitty-navigator", enabled = features.kitty, build = "cp ./*.py ~/.config/kitty/" },
  {
    "mrjones2014/smart-splits.nvim",
    enabled = features.kitty,
    build = "./kitty/install-kittens.bash",
    opts = {
      ignored_buftypes = {
        "nofile",
        "quickfix",
        "prompt",
        "noice",
      },
      ignored_filetypes = { "NvimTree", "neo-tree", "noice" },
    },
  },
  {
    "barrett-ruth/import-cost.nvim",
    enabled = features.cost, -- NOTE: Seems resource intensive
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
  },
  {
    "stevearc/dressing.nvim",
    event = "VeryLazy",
    dependencies = { "MunifTanjim/nui.nvim" },
    config = function()
      require("dressing").setup({
        input = {
          enabled = true,

          -- Default prompt string
          default_prompt = "➤ ",

          -- Can be 'left', 'right', or 'center'
          prompt_align = "center",

          -- When true, <Esc> will close the modal
          insert_only = true,

          -- These are passed to nvim_open_win
          override = function(conf)
            -- This is the config that will be passed to nvim_open_win.
            -- Change values here to customize the layout
            conf.col = -1
            conf.row = 0
            conf.anchor = "SW"
            return conf
          end,
          -- 'editor' and 'win' will default to being centered
          relative = "cursor",
          border = "rounded",

          -- These can be integers or a float between 0 and 1 (e.g. 0.4 for 40%)
          prefer_width = 40,
          width = nil,
          -- min_width and max_width can be a list of mixed types.
          -- min_width = {20, 0.2} means "the greater of 20 columns or 20% of total"
          max_width = { 140, 0.9 },
          min_width = { 20, 0.2 },

          -- Window transparency (0-100)
          win_options = { winblend = 10 },
        },
        select = {
          enabled = true,

          -- Priority list of preferred vim.select implementations
          backend = { "telescope", "fzf_lua", "nui", "fzf", "builtin" },

          -- Options for telescope selector
          telescope = nil, -- {
          -- -- can be 'dropdown', 'cursor', or 'ivy'
          -- theme = "dropdown",
          -- },

          -- Options for fzf selector
          fzf = {
            window = {
              width = 0.5,
              height = 0.4,
            },
          },

          -- Options for nui Menu
          nui = {
            -- position = {
            -- 	row = 1,
            -- 	col = 0,
            -- },
            position = "50%",
            size = nil,
            relative = "cursor", -- "editor"
            border = {
              style = "rounded",
              highlight = "NightflyRed",
              text = {
                top_align = "right",
              },
            },
            max_width = 80,
            max_height = 40,
          },

          -- Options for built-in selector
          builtin = {
            -- These are passed to nvim_open_win
            override = function(conf)
              conf.anchor = "NW"
              return conf
            end,
            -- 'editor' and 'win' will default to being centered
            relative = "cursor", -- "editor" | "win"
            border = "rounded",

            -- Window transparency (0-100)
            win_options = { winblend = 10 },

            -- These can be integers or a float between 0 and 1 (e.g. 0.4 for 40%)
            -- the min_ and max_ options can be a list of mixed types.
            -- max_width = {140, 0.8} means "the lesser of 140 columns or 80% of total"
            width = nil,
            max_width = { 140, 0.8 },
            min_width = { 40, 0.2 },
            height = nil,
            max_height = 0.9,
            min_height = { 10, 0.2 },
          },

          -- Used to override format_item. See :help dressing-format
          format_item_override = {},

          -- see :help dressing_get_config
          get_config = function(opts)
            if opts.kind == "codeaction" then
              return {
                backend = "telescope", -- "nui",
                nui = {
                  relative = "cursor",
                  max_width = 80,
                },
              }
            end
          end,
        },
      })
    end,
  },
}

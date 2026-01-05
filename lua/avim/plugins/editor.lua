local utilities = require("avim.utilities")

local highlight = {
  "RainbowRed",
  "RainbowYellow",
  "RainbowBlue",
  "RainbowOrange",
  "RainbowGreen",
  "RainbowViolet",
  "RainbowCyan",
}

vim.cmd([[
  hi default link BqfPreviewFloat Normal
  hi default link BqfPreviewBorder FloatBorder
  hi default link BqfPreviewTitle Title
  hi default link BqfPreviewThumb PmenuThumb
  hi default link BqfPreviewSbar PmenuSbar
  hi default link BqfPreviewCursor Cursor
  hi default link BqfPreviewCursorLine CursorLine
  hi default link BqfPreviewRange IncSearch
  hi default link BqfPreviewBufLabel BqfPreviewRange
  hi default BqfSign ctermfg=14 guifg=Cyan
]])

-- Suda
-- vim.cmd[[let g:suda#prompt = "Password:"]]
vim.g.suda_smart_edit = 1

vim.g.rainbow_delimiters = { highlight = highlight }

function _G.qftf(info)
  local items
  local ret = {}
  -- The name of item in list is based on the directory of quickfix window.
  -- Change the directory for quickfix window make the name of item shorter.
  -- It's a good opportunity to change current directory in quickfixtextfunc :)
  --
  -- local alterBufnr = vim.fn.bufname('#') -- alternative buffer is the buffer before enter qf window
  -- local root = getRootByAlterBufnr(alterBufnr)
  -- vim.cmd(('noa lcd %s'):format(vim.fn.fnameescape(root)))
  --
  if info.quickfix == 1 then
    items = vim.fn.getqflist({ id = info.id, items = 0 }).items
  else
    items = vim.fn.getloclist(info.winid, { id = info.id, items = 0 }).items
  end
  local limit = 31
  local fnameFmt1, fnameFmt2 = "%-" .. limit .. "s", "…%." .. (limit - 1) .. "s"
  local validFmt = "%s │%5d:%-3d│%s %s"
  for i = info.start_idx, info.end_idx do
    local e = items[i]
    local fname = ""
    local str
    if e.valid == 1 then
      if e.bufnr > 0 then
        fname = vim.fn.bufname(e.bufnr)
        if fname == "" then
          fname = "[No Name]"
        else
          fname = fname:gsub("^" .. vim.env.HOME, "~")
        end
        -- char in fname may occur more than 1 width, ignore this issue in order to keep performance
        if #fname <= limit then
          fname = fnameFmt1:format(fname)
        else
          fname = fnameFmt2:format(fname:sub(1 - limit))
        end
      end
      local lnum = e.lnum > 99999 and -1 or e.lnum
      local col = e.col > 999 and -1 or e.col
      local qtype = e.type == "" and "" or " " .. e.type:sub(1, 1):upper()
      str = validFmt:format(fname, lnum, col, qtype, e.text)
    else
      str = e.text
    end
    table.insert(ret, str)
  end
  return ret
end

vim.o.qftf = "{info -> v:lua._G.qftf(info)}"

vim.cmd([[
  hi BqfPreviewBorder guifg=#50a14f ctermfg=71
  hi link BqfPreviewRange Search
]])

-----------------------------------------------------------------------
--- Keymaps
-----------------------------------------------------------------------
local function termcodes(str)
  return vim.api.nvim_replace_termcodes(str, true, true, true)
end
utilities.map(
  "n",
  "<leader>ur",
  "<Cmd>nohlsearch<Bar>diffupdate<Bar>normal! <C-L><CR>",
  { desc = "Redraw / Clear hlsearch / Diff Update" }
)
utilities.map("x", "<A-k>", "<cmd>move '<-2<CR>gv-gv", { desc = "Move Selection Up" })
utilities.map("x", "<A-j>", "<cmd>move '>+1<CR>gv-gv", { desc = "Move Selection Down" })
utilities.map("v", "<", "<gv", { desc = "Indent Backwards" })
utilities.map("v", ">", ">gv", { desc = "Indent Forward" })
utilities.map("v", "p", "p<cmd>let @+=@0<CR>", { desc = "Paste" })
-- utilities.map("v", "<Tab>", ">gv", { desc = "Tab Forward" })
-- utilities.map("v", "<S-Tab>", "<gv", { desc = "Tab Backwards" })
utilities.map({ "i", "n", "x", "s" }, "<C-s>", "<CMD>w<CR><esc>", { nowait = false, silent = false, desc = "Save File" })
utilities.map({ "i", "n", "x", "v" }, "<C-S-w>", "<cmd>wa<CR><esc>", { nowait = false, silent = false, desc = "Save All" })
utilities.map({ "i", "n", "s" }, "<esc>", function()
  vim.cmd.nohlsearch() -- clear highlights
  --vim.cmd.echo()       -- clear short-message
  vim.api.nvim_feedkeys(termcodes("<esc>"), "n", false)
  return "<esc>"
end, { desc = "Clear Visuals", silent = true })
utilities.map({ "n", "v" }, "<C-,>", function()
  vim.api.nvim_feedkeys(termcodes("<esc>"), "n", false)
  -- TODO: Not sure about this one
  require("trouble").close() -- close trouble
  require("notify").dismiss() -- clear notifications
  require("noice").cmd("dismiss")
  require("goto-preview").close_all_win()
  vim.cmd.nohlsearch() -- clear highlights
  vim.cmd.echo() -- clear short-message
end, { desc = "Clear All Visuals", silent = true })
---
utilities.map(
  { "n", "x" },
  "n",
  "<Cmd>lua require('avim.utilities').nN('n')<CR>",
  { desc = "Next Search Item", noremap = true, silent = true }
)
utilities.map(
  { "n", "x" },
  "N",
  "<Cmd>lua require('avim.utilities').nN('N')<CR>",
  { desc = "Previous Search Item", noremap = true, silent = true }
)
utilities.map(
  "n",
  "*",
  "[[*<Cmd>lua require('hlslens').start()<CR>]]",
  { desc = "Start * Search", noremap = true, silent = true }
)
utilities.map(
  "n",
  "#",
  "[[#<Cmd>lua require('hlslens').start()<CR>]]",
  { desc = "Start # Search", noremap = true, silent = true }
)
utilities.map(
  "n",
  "g*",
  "[[g*<Cmd>lua require('hlslens').start()<CR>]]",
  { desc = "Start g* Search", noremap = true, silent = true }
)
utilities.map(
  "n",
  "g#",
  "[[g#<Cmd>lua require('hlslens').start()<CR>]]",
  { desc = "Start g# Search", noremap = true, silent = true }
)
-- Movement
utilities.map({ "n", "v" }, "<C-h>", "<C-n><C-w>h", { desc = "Move to Left Window", silent = true })
utilities.map({ "n", "v" }, "<C-j>", "<C-n><C-w>j", { desc = "Move to Bottom Window", silent = true })
utilities.map({ "n", "v" }, "<C-k>", "<C-n><C-w>k", { desc = "Move to Top Window", silent = true })
utilities.map({ "n", "v" }, "<C-l>", "<C-n><C-w>l", { desc = "Move to Right Window", silent = true })
utilities.map({ "n", "v" }, "<A-Up>", "<cmd>resize -2<CR>", { desc = "Decrease Window Height", silent = true })
utilities.map({ "n", "v" }, "<A-Down>", "<cmd>resize +2<CR>", { desc = "Increase Window Height", silent = true })
utilities.map(
  { "n", "v" },
  "<A-Left>",
  "<cmd>vertical resize -2<CR>",
  { desc = "Decrease Window Width", silent = true }
)
utilities.map(
  { "n", "v" },
  "<A-Right>",
  "<cmd>vertical resize +2<CR>",
  { desc = "Increase Window Width", silent = true }
)

-- File System
utilities.map("n", "<C-q>", "<cmd>q <CR>", { desc = "Quit Editor" })
utilities.map("n", ">", "<cmd>><CR>", { desc = "Indent Forwards" })
utilities.map("n", "<", "<cmd><<CR>", { desc = "Indent Backward" })
-- Move lines Up and Down
utilities.map("n", "<A-j>", "<cmd>move .+1<CR>==", { desc = "Move Line Down" })
utilities.map("n", "<A-k>", "<cmd>move .-2<CR>==", { desc = "Move Line Up" })
utilities.map("n", "<A-u>", "viwU<ESC>", { desc = "Change To Uppercase", silent = true })

---
utilities.map("i", "<A-j>", "<Esc><cmd>move .+1<CR>==gi", { desc = "Move Line Down" })
utilities.map("i", "<A-k>", "<Esc><cmd>move .-2<CR>==gi", { desc = "Move Line Up" })
utilities.map("i", "<A-u>", "<esc>viwUi", { desc = "Uppercase", noremap = true })
utilities.map("i", "<C-h>", termcodes("<C-\\><C-n><C-w>h"), { desc = "Move to Left Window", silent = true })
utilities.map("i", "<C-j>", termcodes("<C-\\><C-n><C-w>j"), { desc = "Move to Bottom Window", silent = true })
utilities.map("i", "<C-k>", termcodes("<C-\\><C-n><C-w>k"), { desc = "Move to Top Window", silent = true })
utilities.map("i", "<C-l>", termcodes("<C-\\><C-n><C-w>l"), { desc = "Move to Right Window", silent = true })
-- utilities.map("i", "kj", "<ESC>", { desc = "Escape Insert Mode" }) -- { noremap = true, silent = true }
utilities.map("i", "<C-c>", "<ESC>gg<S-v>Gy`.i", { desc = "Copy All Text" })
utilities.map("n", "<C-c>", "gg<S-v>G", { desc = "Select All Text", silent = true })
-- utilities.map("n", "<C-c>", "ggVG", { desc = "Select All Text", silent = true })
-- utilities.map("n", "<C-A>", "ggVGy`.", { desc = "Copy All Text", silent = true })
-- Package Manager
utilities.map({ "n", "v" }, "<leader>p", nil, { name = "󰏖 Package Management" })
utilities.map({ "n", "v" }, "<leader>pi", "<cmd>Lazy install<CR>", { desc = "[Lazy] Install Packages" })
utilities.map({ "n", "v" }, "<leader>ps", "<cmd>Lazy home<CR>", { desc = "[Lazy] Packages Status" })
utilities.map({ "n", "v" }, "<leader>pS", "<cmd>Lazy sync<CR>", { desc = "[Lazy] Sync Packages" })
utilities.map({ "n", "v" }, "<leader>pc", "<cmd>Lazy check<CR>", { desc = "[Lazy] Check Updates" })
utilities.map({ "n", "v" }, "<leader>pu", "<cmd>Lazy update<CR>", { desc = "[Lazy] Update Packages" })
---
utilities.map({ "n", "v" }, "<leader>x", nil, { name = " Trouble" })
-----------------------------------------------------------------------

return {
  { "nvim-lua/plenary.nvim" },
  { "editorconfig/editorconfig-vim", event = "BufReadPre" },
  { "tpope/vim-repeat", event = "VeryLazy" },
  { "tpope/vim-abolish", event = "VeryLazy" },
  {
    "Tastyep/structlog.nvim",
    lazy = false,
  },
  {
    "lambdalisue/suda.vim",
    cmd = { "SudaRead", "SudaWrite" },
    keys = {
      { "<leader>W", "<cmd>SudaWrite<CR>", desc = "Suda Write" },
    },
  },
  { "lbrayner/vim-rzip", lazy = false },
  { "tpope/vim-dotenv" },
  {
    "folke/which-key.nvim",
    event = "BufWinEnter",
    opts = {
      preset = "helix", -- "classic" | "helix"
      -- add operators that will trigger motion and text object completion
      -- to enable all native operators, set the preset / operators plugin above
      -- defer = { gc = "Comments" },
      icons = {
        breadcrumb = "»", -- symbol used in the command line area that shows your active key combo
        separator = "", -- "➜", -- symbol used between a key and it's label
        group = " ", -- "+", -- symbol prepended to a group
      },
      win = {
        border = "rounded", -- none, single, double, shadow
      },
    },
    keys = {
      {
        "<leader>?",
        function()
          require("which-key").show({ global = false })
        end,
        desc = "Buffer Local Keymaps (which-key)",
      },
    },
  },
  {
    "ssstba/ecolog.nvim",
    branch = "beta",
    keys = {
      { "<leader>ge", "<cmd>EcologGoto<cr>", desc = "Go to env file" },
      { "<leader>gpe", "<cmd>EcologPeek<cr>", desc = "Ecolog peek variable" },
      { "<leader>gps", "<cmd>EcologSelect<cr>", desc = "Switch env file" },
      { "<leader>gpc", "<cmd>EcologCopy<cr>", desc = "Copy var to clipboard" },
      { "<leader>gpl", "<cmd>EcologShelterLinePeek<cr>", desc = "Ecolog Line Peek" },
      { "<leader>gpo", "<cmd>EcologShelterToggle<cr>", desc = "Ecolog Toggle" },
    },
    -- Lazy loading is done internally
    lazy = false,
    opts = {
      integrations = {
        -- WARNING: for both cmp integrations see readme section below
        nvim_cmp = true, -- If you dont plan to use nvim_cmp set to false, enabled by default
        -- If you are planning to use blink cmp uncomment this line
        blink_cmp = true,
        -- omnifunc = false,  -- Enable omnifunc integration with automatic setup (default)
        -- Or with configuration options:
        -- omnifunc = {
        -- auto_setup = false,  -- Disable automatic setup, allowing manual configuration
        -- },
        lsp = false,
        statusline = {
          hidden_mode = true,
        },
        snacks = true,
      },
      -- Enables shelter mode for sensitive values
      shelter = {
        configuration = {
          -- Partial mode configuration:
          -- false: completely mask values (default)
          -- true: use default partial masking settings
          -- table: customize partial masking
          -- partial_mode = false,
          -- or with custom settings:
          partial_mode = {
            show_start = 3, -- Show first 3 characters
            show_end = 3, -- Show last 3 characters
            min_mask = 3, -- Minimum masked characters
          },
          mask_char = "*", -- Character used for masking
        },
        modules = {
          cmp = true, -- Mask values in completion
          peek = false, -- Mask values in peek view
          files = true,
          telescope = true, -- Mask values in telescope integration
          telescope_previewer = false, -- Mask values in telescope preview buffers
          fzf = false, -- Mask values in fzf picker
          fzf_previewer = false, -- Mask values in fzf preview buffers
          snacks = true,
          snacks_previewer = false,
        },
      },
      -- true by default, enables built-in types (database_url, url, etc.)
      types = true,
      path = vim.fn.getcwd(), -- Path to search for .env files
      preferred_environment = "development", -- Optional: prioritize specific env files
      -- Controls how environment variables are extracted from code and how cmp works
      provider_patterns = true, -- true by default, when false will not check provider patterns
    },
  },
  {
    "shellRaining/hlchunk.nvim",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      require("hlchunk").setup({
        chunk = {
          enable = true,
          -- textobject = "ic",
          chars = {
            right_arrow = "─",
          },
        },
        indent = {
          enable = false,
          chars = {
            "│",
            "¦",
            "┆",
            "┊",
          },
        },
        line_num = {
          enable = false,
          style = "#806d9c", -- Violet
          -- "#c21f30", -- maple red
          priority = 10,
          use_treesitter = false,
        },
        blank = {
          enable = true,
          chars = {
            " ",
            -- "․",
            -- "⁚",
            -- "⁖",
            -- "⁘",
            -- "⁙",
          },
          style = {
            { bg = vim.fn.synIDattr(vim.fn.synIDtrans(vim.fn.hlID("cursorline")), "bg", "gui") },
            { bg = "", fg = "" },
            -- { bg = "#434437" },
            -- { bg = "#2f4440" },
            -- { bg = "#433054" },
            -- { bg = "#284251" },
          },
        },
      })
    end,
  },
  { "HiPhish/rainbow-delimiters.nvim" },
  {
    "numToStr/Comment.nvim",
    event = "BufRead",
    dependencies = {
      "JoosepAlviste/nvim-ts-context-commentstring",
    },
    config = function()
      require("Comment").setup({
        mappings = {
          basic = true,
          extra = true,
          extended = true,
        },
        pre_hook = require("ts_context_commentstring.integrations.comment_nvim").create_pre_hook(),
      })
    end,
    keys = {
      { "<C-/>", "<cmd>lua require('Comment.api').toggle.linewise.current()<CR>", desc = "Comment" },
      {
        "<C-/>",
        function()
          vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<ESC>", true, false, true), "nx", false)
          require("Comment.api").toggle.linewise(vim.fn.visualmode())
        end,
        mode = { "v" },
        desc = "Comment Selection",
      },
      {
        "<C-/>",
        function()
          vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<ESC>", true, false, true), "nx", false)
          require("Comment.api").toggle.blockwise(vim.fn.visualmode())
        end,
        mode = { "x" },
        desc = "Comment Selection",
      },
    },
  },
  {
    "folke/todo-comments.nvim",
    cmd = { "TodoTrouble" },
    event = "BufReadPost",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = true,
    keys = {
      -- { "<leader>tq", ":TodoQuickFix<CR>",  mode = { "n", "v" }, desc = "Todo Quickfix" },
      -- { "<leader>tS", ":TodoTrouble keywords=TODO,FIX,FIXME<CR>",  mode = { "n", "v" }, desc = "Todo/Fix/Fixme (Trouble)" },
    },
  },
  {
    "olimorris/persisted.nvim",
    event = "VimEnter",
    init = function()
      vim.api.nvim_create_autocmd("User", {
        pattern = "PersistedSavePre",
        callback = function()
          for _, buf in ipairs(vim.api.nvim_list_bufs()) do
            if vim.bo[buf].filetype == "codecompanion" then
              vim.api.nvim_buf_delete(buf, { force = true })
            end
          end
        end,
      })
    end,
    opts = {
      save_dir = vim.fn.stdpath("state") .. "/sessions/", -- utilities.join_paths(_G.get_state_dir(), "sessions"),
      autoload = false,
      autosave = true,
      use_git_branch = true,
      should_autosave = function()
        -- do not autosave if the alpha dashboard is the current filetype
        if vim.bo.filetype == "alpha" then
          return false
        end
        return true
      end,
    },
    keys = {
      { "<A-h>", "<cmd>SessionSelect<cr>", mode = { "n", "v" }, desc = "List Session" },
    },
  },
  {
    "Bekaboo/dropbar.nvim",
    event = "BufReadPost",
    -- optional, but required for fuzzy finder support
    dependencies = {
      "nvim-tree/nvim-web-devicons", -- optional dependency
    },
    opts = {
      bar = {
        -- below adds dropbar to oil windows
        enable = function(buf, win, _)
          if
            not vim.api.nvim_buf_is_valid(buf)
            or not vim.api.nvim_win_is_valid(win)
            or vim.fn.win_gettype(win) ~= ""
            or vim.wo[win].winbar ~= ""
            or vim.bo[buf].ft == "help"
          then
            return false
          end

          local stat = vim.uv.fs_stat(vim.api.nvim_buf_get_name(buf))
          if stat and stat.size > 1024 * 1024 then
            return false
          end

          return vim.bo[buf].ft == "markdown"
            or vim.bo[buf].ft == "oil" -- enable in oil buffers
            or pcall(vim.treesitter.get_parser, buf)
            or not vim.tbl_isempty(vim.lsp.get_clients({
              bufnr = buf,
              method = "textDocument/documentSymbol",
            }))
        end,
      },
    },
  },
  {
    "lewis6991/satellite.nvim",
    event = "BufReadPost",
    opts = {
      excluded_filetypes = { "neo-tree", "alpha", "dashboard", "oil", "trouble", "Outline" },
      -- Handlers configuration to avoid conflicts during buffer operations
      handlers = {
        gitsigns = {
          enable = true,
        },
      },
    },
    config = function(_, opts)
      require("satellite").setup(opts)
      -- Disable satellite temporarily during buffer delete to prevent E565 errors
      vim.api.nvim_create_autocmd("User", {
        pattern = "BDeletePre",
        callback = function()
          pcall(function()
            require("satellite.view").disable()
          end)
        end,
      })
      vim.api.nvim_create_autocmd("User", {
        pattern = "BDeletePost",
        callback = function()
          vim.defer_fn(function()
            pcall(function()
              require("satellite.view").enable()
            end)
          end, 100)
        end,
      })
    end,
  },
  {
    "hedyhli/outline.nvim",
    cmd = { "Outline", "OutlineOpen" },
    opts = { show_numbers = true, show_relative_numbers = true, auto_preview = true },
    keys = {
      { "<F8>", "<cmd>Outline<CR>", mode = { "n", "i", "v" }, desc = "Symbols Outline", silent = true },
    },
  },
  {
    "otavioschwanck/arrow.nvim",
    event = "BufReadPost",
    config = function()
      require("arrow").setup({
        show_icons = true,
        leader_key = ";", -- Recommended to be a single key
        buffer_leader_key = ",", -- Per Buffer Mappings
        separate_by_branch = true, -- Bookmarks will be separated by git branch
        always_show_path = false,
        window = {
          border = "rounded",
        },
        per_buffer_config = {
          satellite = { -- defualt to nil, display arrow index in scrollbar at every update
            enable = true,
          },
        },
      })
    end,
    keys = {
      { ";" },
      { "," },
      --     { "H", '<cmd>lua require("arrow.persist").previous()<CR>',  mode = { "n", "v" }, desc = "" },
      --     { "L", '<CMD>lua require("arrow.persist").next()<CR>',  mode = { "n", "v" }, desc = "" },
      --     { "<C-s>", '<CMD> lua require("arrow.persist").toggle()<CR>',  mode = { "n", "v" }, desc = "" },
    },
  },
  {
    "kevinhwang91/nvim-bqf",
    ft = { "qf" },
    command = { "BqfToggle", "BqfAutoToggle" },
    opts = {
      auto_enable = true,
      auto_resize_height = true, -- highly recommended enable
      func_map = {
        split = "h",
        vsplit = "v",
      },
      filter = {
        fzf = {
          extra_opts = { "--bind", "ctrl-o:toggle-all", "--delimiter", "│", "--prompt", "> " },
        },
      },
    },
  },
  {
    "brenton-leighton/multiple-cursors.nvim",
    version = "*",
    opts = {
      pre_hook = function()
        vim.opt.cursorline = false
        vim.cmd("NoMatchParen")
        require("cmp").setup({ enabled = false })
        vim.b.completion = false
        -- require("blink.cmp").setup({ completion = { menu = { enabled = false } } })
        require("nvim-autopairs").disable()
      end,
      post_hook = function()
        vim.opt.cursorline = true
        vim.cmd("DoMatchParen")
        require("cmp").setup({ enabled = true })
        vim.b.completion = true
        -- require("blink.cmp").setup({ completion = { menu = { enabled = true } } })
        require("nvim-autopairs").enable()
      end,
      custom_key_maps = {
        {
          "n",
          "<Leader>|",
          function()
            require("multiple-cursors").align()
          end,
        },
        {
          { "n", "i" },
          "<C-/>",
          function()
            vim.cmd("normal gcc")
          end,
        },
        {
          "v",
          "<C-/>",
          function()
            vim.cmd("normal gc")
          end,
        },
      },
    },
    keys = {
      {
        "<leader><Up>",
        "<Cmd>MultipleCursorsAddUp<CR>",
        mode = { "n", "i", "x" },
        desc = "Add cursor and move up",
      },
      {
        "<leader><Down>",
        "<Cmd>MultipleCursorsAddDown<CR>",
        mode = { "n", "i", "x" },
        desc = "Add cursor and move down",
      },

      {
        "<A-LeftMouse>",
        "<Cmd>MultipleCursorsMouseAddDelete<CR>",
        mode = { "n", "i" },
        desc = "Add or remove cursor",
      },

      {
        "<A-a>",
        "<Cmd>MultipleCursorsAddMatches<CR>",
        mode = { "n", "x" },
        desc = "Add cursors to cword",
      },
      {
        "<A-v>",
        "<Cmd>MultipleCursorsAddMatchesV<CR>",
        mode = { "n", "x" },
        desc = "Add cursors to cword in previous area",
      },

      {
        "<A-d>",
        "<Cmd>MultipleCursorsAddJumpNextMatch<CR>",
        mode = { "n", "x" },
        desc = "Add cursor and jump to next cword",
      },
      {
        "<A-w>",
        "<Cmd>MultipleCursorsJumpNextMatch<CR>",
        mode = { "n", "x" },
        desc = "Jump to next cword",
      },
      { "<A-l>", "<Cmd>MultipleCursorsLockToggle<CR>", mode = { "n", "x" }, desc = "Toggle locking virtual cursors" },
    },
  },
  {
    "kylechui/nvim-surround",
    version = "*", -- Use for stability; omit to use `main` branch for the latest features
    event = "VeryLazy",
    config = true,
  },
  -- Editor Visuals
  {
    "windwp/nvim-autopairs",
    event = "BufRead",
    opts = {
      fast_wrap = {},
      disable_filetype = { "vim", "clap_input" },
    },
  },
  {
    "folke/trouble.nvim",
    cmd = { "Trouble", "TroubleRefresh", "TroubleToggle", "TroubleClose" },
    opts = {
      keys = {
        j = "next",
        k = "prev",
        ["<Tab>"] = "jump",
      },
      ---@type table<string, trouble.Mode>
      modes = {
        preview = {
          mode = "diagnostics",
          preview = {
            type = "split",
            relative = "win",
            position = "right",
            size = 0.3,
          },
        },
        diagnostics = {
          filter = function(items)
            return vim.tbl_filter(function(item)
              return not string.match(item.basename, [[%__virtual.cs$]])
            end, items)
          end,
        },
        -- preview_float = {
        --   mode = "diagnostics",
        --   preview = {
        --     type = "float",
        --     relative = "editor",
        --     border = "rounded",
        --     title = "Preview",
        --     title_pos = "center",
        --     position = { 0, -2 },
        --     size = { width = 0.3, height = 0.3 },
        --     zindex = 200,
        --   },
        -- },
      },
    },
    keys = {
      { "<leader>xd", "<cmd>Trouble diagnostics toggle<CR>", mode = { "n", "v" }, desc = "Diagnostics (Trouble)" },
      {
        "<leader>xb",
        "<cmd>Trouble diagnostics toggle filter.buf=0<CR>",
        mode = { "n", "v" },
        desc = "Buffer Diagnostics (Trouble)",
      },
      {
        "<leader>xf",
        "<cmd>Trouble lsp_definitions toggle<CR>",
        mode = { "n", "v" },
        desc = "LSP Definitions (Trouble)",
      },
      {
        "<leader>xc",
        "<cmd>Trouble lsp_declarations toggle<CR>",
        mode = { "n", "v" },
        desc = "LSP Declarations (Trouble)",
      },
      {
        "<leader>xi",
        "<cmd>Trouble lsp_implementations toggle<CR>",
        mode = { "n", "v" },
        desc = "LSP Implementations (Trouble)",
      },
      {
        "<leader>xr",
        "<cmd>Trouble lsp_references toggle<CR>",
        mode = { "n", "v" },
        desc = "LSP References (Trouble)",
      },
      {
        "<leader>xt",
        "<cmd>Trouble lsp_type_definitions toggle<CR>",
        mode = { "n", "v" },
        desc = "LSP Type Definitions (Trouble)",
      },
      {
        "<leader>xx",
        "<cmd>Trouble lsp_document_symbols toggle<CR>",
        mode = { "n", "v" },
        desc = "LSP Document Symbols (Trouble)",
      },
      {
        "<leader>xs",
        ":Trouble symbols toggle pinned=true results.win.relative=win results.win.position=right<CR>",
        mode = { "n", "v" },
        desc = "Symbols (Trouble)",
      },
      { "<leader>xS", ":Trouble symbols toggle focus=false<CR>", mode = { "n", "v" }, desc = "Symbols (Trouble)" },
      {
        "<leader>xl",
        ":Trouble loclist toggle<CR>",
        mode = { "n", "v" },
        desc = "Location List (Trouble)",
      },
      {
        "<leader>xq",
        ":Trouble qflist toggle<CR>",
        mode = { "n", "v" },
        desc = "Quickfix List (Trouble)",
      },
      -- utilities.map(
      --   { "n", "v" },
      --   "gR",
      --   ":Trouble lsp toggle focus=false win.position=right<CR>",
      --   { desc = "LSP Definitions / references / ... (Trouble)" }
      -- )
    },
  },
}

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

-- Suda
vim.g.suda_smart_edit = 1

vim.g.rainbow_delimiters = { highlight = highlight }

function _G.qftf(info)
  local items
  local ret = {}
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

-----------------------------------------------------------------------
--- Keymaps
-----------------------------------------------------------------------
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
utilities.map(
  { "i", "n", "x", "s" },
  "<C-s>",
  "<CMD>w<CR><esc>",
  { desc = "Save File" }
)
utilities.map(
  { "i", "n", "x", "v" },
  "<C-S-w>",
  "<cmd>wa<CR><esc>",
  { desc = "Save All" }
)
utilities.map({ "i", "n", "s" }, "<esc>", function()
  vim.cmd.nohlsearch()
  vim.api.nvim_feedkeys(vim.keycode("<esc>"), "n", false)
  return "<esc>"
end, { desc = "Clear Visuals", silent = true })
utilities.map({ "n", "v" }, "<C-,>", function()
  vim.api.nvim_feedkeys(vim.keycode("<esc>"), "n", false)
  require("trouble").close()
  require("notify").dismiss()
  require("noice").cmd("dismiss")
  require("goto-preview").close_all_win()
  vim.cmd.nohlsearch()
  vim.cmd.echo()
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
utilities.map("i", "<C-h>", vim.keycode("<C-\\><C-n><C-w>h"), { desc = "Move to Left Window", silent = true })
utilities.map("i", "<C-j>", vim.keycode("<C-\\><C-n><C-w>j"), { desc = "Move to Bottom Window", silent = true })
utilities.map("i", "<C-k>", vim.keycode("<C-\\><C-n><C-w>k"), { desc = "Move to Top Window", silent = true })
utilities.map("i", "<C-l>", vim.keycode("<C-\\><C-n><C-w>l"), { desc = "Move to Right Window", silent = true })
utilities.map("i", "<C-c>", "<ESC>gg<S-v>Gy`.i", { desc = "Copy All Text" })
utilities.map("n", "<C-c>", "gg<S-v>G", { desc = "Select All Text", silent = true })
-- Package Manager
utilities.map({ "n", "v" }, "<leader>p", nil, { name = "󰏖 Package Management" })
utilities.map({ "n", "v" }, "<leader>pi", "<cmd>Lazy install<CR>", { desc = "[Lazy] Install Packages" })
utilities.map({ "n", "v" }, "<leader>ps", "<cmd>Lazy home<CR>", { desc = "[Lazy] Packages Status" })
utilities.map({ "n", "v" }, "<leader>pS", "<cmd>Lazy sync<CR>", { desc = "[Lazy] Sync Packages" })
utilities.map({ "n", "v" }, "<leader>pc", "<cmd>Lazy check<CR>", { desc = "[Lazy] Check Updates" })
utilities.map({ "n", "v" }, "<leader>pu", "<cmd>Lazy update<CR>", { desc = "[Lazy] Update Packages" })
---
utilities.map({ "n", "v" }, "<leader>x", nil, { name = " Trouble" })
-----------------------------------------------------------------------

return {
  { "nvim-lua/plenary.nvim" },
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
  {
    "folke/which-key.nvim",
    event = "BufWinEnter",
    opts = {
      preset = "helix",
      icons = {
        breadcrumb = "»",
        separator = "",
        group = " ",
      },
      win = { border = "rounded" },
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
    "ph1losof/ecolog2.nvim",
    build = "cargo install ecolog-lsp",
    config = function()
      require("ecolog").setup()
    end,
    dependencies = { "ph1losof/shelter.nvim" },
    keys = {
      { "<leader>cel", "<cmd>Ecolog list<cr>", desc = "Open variable picker" },
      { "<leader>cey", "<cmd>Ecolog copy value<cr>", desc = "Copy variable value at cursor" },
      { "<leader>cef", "<cmd>Ecolog files<cr>", desc = "Toggle File source" },
      { "<leader>ces", "<cmd>Ecolog shell<cr>", desc = "Toggle Shell source" },
      { "<leader>cei", "<cmd>Ecolog interpolation<cr>", desc = "Toggle interpolation" },
      { "<leader>ceo", "<cmd>Ecolog remote<cr>", desc = "Toggle Remote source" },
      { "<leader>cer", "<cmd>Ecolog refresh<cr>", desc = "Restart LSP and reload env files" },
    },
    lazy = false,
    opts = {
      statusline = { hidden_mode = false },
    },
  },
  {
    "ph1losof/shelter.nvim",
    lazy = false,
    build = ":ShelterBuild",
    keys = {
      { "<leader>csf", "<cmd>:Shelter toggle files<CR>", desc = "Toggle file masking on/off" },
      { "<leader>csp", "<cmd>:Shelter peek<CR>", desc = "Reveal current line temporarily" },
      { "<leader>csi", "<cmd>:Shelter info<CR>", desc = "Show status and modes" },
    },
    opts = {
      default_mode = "partial",
      modules = {
        ecolog = {
          cmp = true,
          peek = true,
          picker = true,
        },
        files = true,
        snacks_previewer = false,
      },
    },
  },
  {
    "shellRaining/hlchunk.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      chunk = {
        enable = true,
        chars = { right_arrow = "─" },
      },
      indent = { enable = false },
      line_num = { enable = false },
      blank = {
        enable = true,
        chars = { " " },
        style = {
          { bg = vim.fn.synIDattr(vim.fn.synIDtrans(vim.fn.hlID("cursorline")), "bg", "gui") },
          { bg = "", fg = "" },
        },
      },
    },
  },
  { "HiPhish/rainbow-delimiters.nvim", event = { "BufReadPost", "BufNewFile" } },
  {
    "numToStr/Comment.nvim",
    event = "BufRead",
    dependencies = { "JoosepAlviste/nvim-ts-context-commentstring" },
    config = function()
      require("Comment").setup({
        mappings = { basic = true, extra = true, extended = true },
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
      save_dir = vim.fn.stdpath("state") .. "/sessions/",
      autoload = false,
      autosave = true,
      use_git_branch = true,
      should_autosave = function()
        if vim.bo.filetype == "alpha" then
          return false
        end
        return true
      end,
    },
    keys = {
      { "<A-h>", "<cmd>Persisted select<cr>", mode = { "n", "v" }, desc = "List Session" },
    },
  },
  {
    "Bekaboo/dropbar.nvim",
    event = "BufReadPost",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {
      bar = {
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
            or vim.bo[buf].ft == "oil"
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
      handlers = { gitsigns = { enable = true } },
    },
    config = function(_, opts)
      require("satellite").setup(opts)
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
    opts = {
      show_icons = true,
      leader_key = ";",
      buffer_leader_key = ",",
      separate_by_branch = true,
      always_show_path = false,
      window = { border = "rounded" },
      per_buffer_config = {
        satellite = { enable = true },
      },
    },
    keys = { { ";" }, { "," } },
  },
  {
    "kevinhwang91/nvim-bqf",
    ft = { "qf" },
    cmd = { "BqfToggle", "BqfAutoToggle" },
    opts = {
      auto_enable = true,
      auto_resize_height = true,
      func_map = { split = "h", vsplit = "v" },
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
        require("nvim-autopairs").disable()
      end,
      post_hook = function()
        vim.opt.cursorline = true
        vim.cmd("DoMatchParen")
        require("cmp").setup({ enabled = true })
        vim.b.completion = true
        require("nvim-autopairs").enable()
      end,
      custom_key_maps = {
        { "n", "<Leader>|", function() require("multiple-cursors").align() end },
        { { "n", "i" }, "<C-/>", function() vim.cmd("normal gcc") end },
        { "v", "<C-/>", function() vim.cmd("normal gc") end },
      },
    },
    keys = {
      { "<leader><Up>", "<Cmd>MultipleCursorsAddUp<CR>", mode = { "n", "i", "x" }, desc = "Add cursor and move up" },
      { "<leader><Down>", "<Cmd>MultipleCursorsAddDown<CR>", mode = { "n", "i", "x" }, desc = "Add cursor and move down" },
      { "<A-LeftMouse>", "<Cmd>MultipleCursorsMouseAddDelete<CR>", mode = { "n", "i" }, desc = "Add or remove cursor" },
      { "<A-a>", "<Cmd>MultipleCursorsAddMatches<CR>", mode = { "n", "x" }, desc = "Add cursors to cword" },
      { "<A-v>", "<Cmd>MultipleCursorsAddMatchesV<CR>", mode = { "n", "x" }, desc = "Add cursors to cword in previous area" },
      { "<A-d>", "<Cmd>MultipleCursorsAddJumpNextMatch<CR>", mode = { "n", "x" }, desc = "Add cursor and jump to next cword" },
      { "<A-w>", "<Cmd>MultipleCursorsJumpNextMatch<CR>", mode = { "n", "x" }, desc = "Jump to next cword" },
      { "<A-l>", "<Cmd>MultipleCursorsLockToggle<CR>", mode = { "n", "x" }, desc = "Toggle locking virtual cursors" },
    },
  },
  {
    "kylechui/nvim-surround",
    version = "*",
    event = "VeryLazy",
    config = true,
  },
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
    cmd = { "Trouble" },
    opts = {
      keys = { j = "next", k = "prev", ["<Tab>"] = "jump" },
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
      },
    },
    keys = {
      { "<leader>xd", "<cmd>Trouble diagnostics toggle<CR>", mode = { "n", "v" }, desc = "Diagnostics (Trouble)" },
      { "<leader>xb", "<cmd>Trouble diagnostics toggle filter.buf=0<CR>", mode = { "n", "v" }, desc = "Buffer Diagnostics (Trouble)" },
      { "<leader>xf", "<cmd>Trouble lsp_definitions toggle<CR>", mode = { "n", "v" }, desc = "LSP Definitions (Trouble)" },
      { "<leader>xc", "<cmd>Trouble lsp_declarations toggle<CR>", mode = { "n", "v" }, desc = "LSP Declarations (Trouble)" },
      { "<leader>xi", "<cmd>Trouble lsp_implementations toggle<CR>", mode = { "n", "v" }, desc = "LSP Implementations (Trouble)" },
      { "<leader>xr", "<cmd>Trouble lsp_references toggle<CR>", mode = { "n", "v" }, desc = "LSP References (Trouble)" },
      { "<leader>xt", "<cmd>Trouble lsp_type_definitions toggle<CR>", mode = { "n", "v" }, desc = "LSP Type Definitions (Trouble)" },
      { "<leader>xx", "<cmd>Trouble lsp_document_symbols toggle<CR>", mode = { "n", "v" }, desc = "LSP Document Symbols (Trouble)" },
      { "<leader>xs", ":Trouble symbols toggle pinned=true results.win.relative=win results.win.position=right<CR>", mode = { "n", "v" }, desc = "Symbols (Trouble)" },
      { "<leader>xS", ":Trouble symbols toggle focus=false<CR>", mode = { "n", "v" }, desc = "Symbols (Trouble)" },
      { "<leader>xl", ":Trouble loclist toggle<CR>", mode = { "n", "v" }, desc = "Location List (Trouble)" },
      { "<leader>xq", ":Trouble qflist toggle<CR>", mode = { "n", "v" }, desc = "Quickfix List (Trouble)" },
    },
  },
}

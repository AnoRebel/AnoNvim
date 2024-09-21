local set = vim.opt
local api = vim.api
local g = vim.g

if vim.fn.has("nvim-0.9") == 1 then
  set.diffopt:append("linematch:60") -- enable linematch diff algorithm
end
vim.t.bufs = api.nvim_list_bufs()
if #api.nvim_list_uis() == 0 then
  set.shortmess = ""   -- try to prevent echom from cutting messages off or prompting
  set.more = false     -- don't pause listing when screen is filled
  set.cmdheight = 9999 -- helps avoiding |hit-enter| prompts.
  set.columns = 9999   -- set the widest screen possible
  set.swapfile = false -- don't use a swap file
else
  g.mapleader = " "
  g.maplocalleader = " "
  -- use filetype.lua instead of filetype.vim
  -- g.do_legacy_filetype = 1
  -- g.did_load_filetypes = 1 -- check Neovim PR #19216
  -- g.do_filetype_lua = 1
  g.background = require("avim.core.defaults").ui.background

  set.jumpoptions = "stack,view"
  set.confirm = true
  set.fileencoding = "utf-8" -- the encoding written to a file
  set.conceallevel = 0       -- so that `` is visible in markdown files
  set.laststatus = 3         -- global statusline
  set.title = true
  -- set.titlestring = "AnoNvim" -- "%<%F%=%l/%L - nvim" -- what the title of the window will be set to
  set.clipboard = vim.env.SSH_TTY and "" or "unnamedplus"         -- Sync with system clipboard
  set.cmdheight = 1
  set.cul = true                                                  -- cursor line
  set.completeopt = { "menu", "menuone", "noinsert", "noselect" } -- Completion opions for code completion
  set.cursorline = true
  set.cursorlineopt =
  "screenline,number"                                             -- Highlight the screen line of the cursor with CursorLine and the line number with CursorLineNr
  set.emoji = true                                                -- Turn on emojis
  set.pumheight = 10                                              -- pop up menu height
  set.showtabline = 2                                             -- always show tabs
  set.formatoptions:remove("cro")                                 -- auto-wrap comments, don't auto insert comment on o/O and enter

  -- Add mouse movement events for bufferline
  -- set.mousemoveevent = true
  -- vim.o.mousemoveevent = true

  -- Indentline
  set.expandtab = true      -- Use spaces instead of tabs
  set.shiftwidth = 2        -- Size of an indent
  set.smartindent = true    -- Insert indents automatically
  set.autoindent = true
  set.preserveindent = true -- Preserve indent structure as much as possible
  set.softtabstop = 2       -- Number of spaces tabs count for
  set.shiftround = true     -- Round indent

  -- Folding (Finally)
  -- vim.o.fillchars = [[eob: ,fold: ,foldopen:,foldsep: ,foldclose:]]
  vim.wo.foldcolumn = "1"
  vim.wo.foldlevel = 99 -- ufo provider needs large value
  vim.o.foldlevelstart = 99
  -- set.foldmethod = "manual" -- folding, set to "expr" for treesitter based folding
  -- set.foldexpr = "" -- set to "nvim_treesitter#foldexpr()" for treesitter based folding
  set.foldenable = true -- Enable folding
  -- set.foldmethod = "marker" -- Fold based on markers as opposed to indentation

  -- disable tilde on end of buffer: https://github.com/neovim/neovim/pull/8546#issuecomment-643643758
  set.fillchars = {
    horiz = "━",
    horizup = "┻",
    horizdown = "┳",
    vert = "┃",
    vertleft = "┫",
    vertright = "┣",
    verthoriz = "╋",
    eob = " ",
    fold = " ",
    foldopen = "",
    foldsep = " ",
    foldclose = "",
  }

  -- reveal already opened files from the quickfix window instead of opening new
  -- buffers
  vim.o.switchbuf = "useopen"

  set.hidden = true
  set.ignorecase = true                                           -- Ignore case
  set.infercase = true                                            -- Infer cases in keyword completion
  set.smartcase = true                                            -- Don't ignore case with capitals
  set.inccommand = "nosplit"                                      -- for incsearch while sub
  set.splitbelow = true                                           -- Put new windows below current
  set.splitkeep = vim.fn.has("nvim-0.9") == 1 and "screen" or nil -- Maintain code view when splitting
  set.splitright = true                                           -- Put new windows right of current
  -- set.termguicolors = true -- True color support
  if vim.fn.has("termguicolors") == 1 then
    g.t_8f = "[[38;2;%lu;%lu;%lum"
    g.t_8b = "[[48;2;%lu;%lu;%lum"
    -- vim.go.t_8f = "[[38;2;%lu;%lu;%lum"
    -- vim.go.t_8b = "[[48;2;%lu;%lu;%lum"
    set.termguicolors = true
  end
  -- vim.o.t_Co = 256
  g.t_co = 256
  set.guifont = require("avim.core.defaults").ui.fonts
  -- set.guicursor = "n-v-c:block-Cursor/lCursor-blinkon0,i-ci:ver25-Cursor/lCursor,r-cr:hor20-Cursor/lCursor"
  set.mouse = "a" -- Use the mouse in all modes

  -- Misc
  set.showmatch = true                                -- Show matching brackets by flickering
  set.showcmd = false                                 -- Do not show the mode
  set.showmode = false                                -- Do not show the mode
  set.scrolloff = 3                                   -- minimal number of screen lines to keep above and below the cursor.
  set.sidescrolloff = 3                               -- The minimal number of columns to keep to the left and to the right of the cursor if 'nowrap' is set
  set.wildmode = "list:longest"                       -- Command-line completion mode
  set.wildignore = { "*/.git/*", "*/node_modules/*" } -- Ignore these files/folders

  -- Numbers
  set.number = true
  set.numberwidth = 4
  set.relativenumber = false
  set.ruler = false
  -- the line will be right after column 80, &tw+3
  set.colorcolumn = { "+3", "120" }
  -- set.colorcolumn = "120" -- "80,120" -- Make a ruler at 80px and 120px
  set.list = require("avim.core.defaults").ui.list -- Show some invisible characters like tabs etc
  set.listchars = { tab = ">>>", trail = "·", precedes = "←", extends = "→", eol = "↲", nbsp = "␣" }
  -- set.wrapmargin = 1
  -- set.wrap = false -- Do not display text over multiple lines

  -- disable nvim intro
  -- set.shortmess:append("csSI")
  set.shortmess:append({
    c = true, -- Disable "Pattern not found" messages
    m = true, -- use "[+]" instead of "[Modified]"
    r = true, -- use "[RO]" instead of "[readonly]"
    I = true, -- don't give the intro message when starting Vim |:intro|.
    S = true, -- hide search info echoing (i have a statusline for that)
    W = true, -- don't give "written" or "[w]" when writing a file
  })
  -- vim.opt.shortmess = {
  --   A = true, -- ignore annoying swap file messages
  --   c = true, -- Do not show completion messages in command line
  --   F = true, -- Do not show file info when editing a file, in the command line
  --   I = true, -- Do not show the intro message
  --   W = true, -- Do not show "written" in command line when writing
  -- }

  set.textwidth = 120                                                                  -- Total allowed width on the screen
  set.sessionoptions =
  "globals,buffers,curdir,folds,tabpages,winpos,winsize,terminal"                      -- Session options to store in the session

  -- min 1, max 4 signs
  vim.o.signcolumn = "auto" -- "auto:1-4"
  -- set.signcolumn = "yes" -- Show information next to the line numbers
  set.tabstop = 2
  set.timeoutlen = 250
  -- set.swapfile = false
  set.undofile = true
  set.undodir = _G.avim.UNDODIR
  set.undolevels = 100 -- Ensure we can undo a lot!

  -- interval for writing swap file to disk, also used by gitsigns
  set.updatetime = 200

  -- go to previous/next line with h,l,left arrow and right arrow
  -- when cursor reaches end/beginning of line
  set.whichwrap:append("<>[]hl")

  vim.diagnostic.config({
    virtual_text = {
      prefix = "",
    },
    float = {
      focusable = true,
      source = true,
      border = "rounded",
      style = "minimal",
      format = function(diagnostic)
        local code = diagnostic.code or (diagnostic.user_data and diagnostic.user_data.lsp.code)
        if not diagnostic.source then
          return string.format("%s [%s]", diagnostic.message, code)
        end

        if diagnostic.source == "eslint" then
          return string.format("%s [%s]", diagnostic.message, diagnostic.user_data.lsp.code)
        end

        return string.format("%s [%s]", diagnostic.message, diagnostic.source)
      end,
    },
    severity_sort = true,
    signs = true,
    underline = true,
    update_in_insert = false,
  })

  ----------------------------------------------------------------
  -- Custom missing filetypes
  ----------------------------------------------------------------
  -- Custom Filetypes
  vim.filetype.add({
    extension = {
      conf = "dosini",
      env = "dotenv",
      tiltfile = "tiltfile",
      Tiltfile = "tiltfile",
      jinja = "jinja",
      jinja2 = "jinja",
      j2 = "jinja",
      ejs = "html",
      sh = "sh",
      rasi = "rasi",
      rofi = "rasi",
      wofi = "rasi",
    },
    filename = {
      [".env"] = "dotenv",
      [".eslintrc.json"] = "jsonc", -- assuming nx project.json
      ["project.json"] = "jsonc",   -- assuming nx project.json
      [".yamlfmt"] = "yaml",
      ["vifmrc"] = "vim",
    },
    pattern = {
      ["docker%-compose%.y.?ml"] = "yaml.docker-compose",
      ["%.env%.[%w_.-]+"] = "dotenv",
      ["tsconfig%."] = "jsonc",
      [".*/waybar/config"] = "jsonc",
      [".*/mako/config"] = "dosini",
      [".*/kitty/.+%.conf"] = "bash",
      [".*/hypr/.+%.conf"] = "hyprlang",
      -- ["%.env%.[%w_.-]+"] = "sh",
      -- ["env%.(%a+)"] = function(_path, _bufnr, ext)
      --   vim.print(ext)
      --   if vim.tbl_contains({ "local", "example", "dev", "prod" }, ext) then
      --     return "dotenv"
      --   end
      -- end,
    },
  })

  ----------------------------------------------------------------
  -- Plugin Specific Options
  ----------------------------------------------------------------
  -- (GUI) Neovide settings
  g.neovide_no_idle = true
  g.neovide_input_use_logo = true
  g.neovide_cursor_antialiasing = true

  -- Codeium
  g.codeium_disable_bindings = 1

  -- TS??
  g.markdown_fenced_languages = {
    "javascript",
    "typescript",
    "bash",
    "python",
    "lua",
    "go",
    "rust",
    "c",
    "cpp",
  }
  ----------------------------------------------------------------

  vim.schedule(function()
    set.shada = "!,'100,<30,:50,@50,/50,s10,h"
    set.shadafile = require("avim.utils").join_paths(_G.avim.SHADADIR, "avim.shada")
    vim.cmd([[ silent! rsh ]])
  end)
end

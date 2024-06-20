local features = require("avim.core.defaults").features
local utils = require("avim.utils")

return {
  {
    "akinsho/toggleterm.nvim",
    enabled = features.terminal,
    version = "*",
    event = "BufWinEnter",
    config = function()
      local terminal = require("toggleterm")
      terminal.setup({
        -- size can be a number or function which is passed the current terminal
        size = function(term) -- 25,
          if term.direction == "horizontal" then
            return 20
          elseif term.direction == "vertical" then
            return vim.o.columns * 0.3
          end
        end,
        -- open_mapping = [[<c-t>]], -- [[<c-`]]
        open_mapping = [[<c-\>]],
        hide_numbers = true, -- hide the number column in toggleterm buffers
        shade_filetypes = {},
        shade_terminals = true,
        shading_factor = 2, -- the degree by which to darken to terminal colour, default: 1 for dark backgrounds, 3 for light
        start_in_insert = true,
        insert_mappings = true, -- whether or not the open mapping applies in insert mode
        -- terminal_mappings = true, -- whether or not the open mapping applies in the opened terminals
        persist_size = false,
        -- direction = 'vertical' | 'horizontal' | 'window' | 'float' | 'tab',
        direction = "tab",
        close_on_exit = true, -- close the terminal window when the process exits
        shell = vim.o.shell, -- change the default shell
        -- This field is only relevant if direction is set to 'float'
        float_opts = {
          -- The border key is *almost* the same as 'nvim_win_open'
          -- see :h nvim_win_open for details on borders however
          -- the 'curved' border is a custom border type
          -- not natively supported but implemented in this plugin.
          -- border = 'single' | 'double' | 'shadow' | 'curved' | ... other options supported by win open
          border = "shadow",
          -- width = <value>,
          -- height = <value>,
          winblend = 0,
          highlights = {
            border = "Normal",
            background = "Normal",
          },
        },
        winbar = {
          enabled = true,
        },
      })

      local Terminal = require("toggleterm.terminal").Terminal
      local floatTerm = Terminal:new({
        hidden = true,
        direction = "float",
        float_opts = {
          border = "curved",
        },
      })

      local bottomTerm = Terminal:new({
        hidden = true,
        direction = "horizontal",
      })

      local rightTerm = Terminal:new({
        hidden = true,
        direction = "vertical",
      })

      local lazyGit = Terminal:new({
        cmd = "lazygit",
        hidden = true,
        direction = "float",
        float_opts = {
          border = "curved",
        },
      })

      terminal.float_toggle = function()
        floatTerm:toggle()
      end
      terminal.lazygit_toggle = function()
        lazyGit:toggle()
      end

      terminal.bottom_toggle = function()
        bottomTerm:toggle(20) -- options.size
      end
      terminal.right_toggle = function()
        rightTerm:toggle(vim.o.columns * 0.25)
      end
      local function termcodes(str)
        return vim.api.nvim_replace_termcodes(str, true, true, true)
      end
      -- Term rav
      utils.map({ "n", "v" }, "<leader>t", nil, { name = " Terminal" })
      utils.map({ "n", "v" }, "<leader>ta", "<cmd>ToggleTermToggleAll<CR>", { desc = "[Terminal] Toggle All" })
      utils.map(
        { "n", "v" },
        "<leader>tr",
        "<cmd>lua require('toggleterm').right_toggle()<CR>",
        { desc = "[Terminal] Toggle Vertical" }
      )
      utils.map(
        { "n", "v" },
        "<leader>tf",
        "<cmd>lua require('toggleterm').float_toggle()<CR>",
        { desc = "[Terminal] Toggle Floating" }
      )
      utils.map(
        { "n", "v" },
        "<leader>tb",
        "<cmd>lua require('toggleterm').bottom_toggle()<CR>",
        { desc = "[Terminal] Toggle Horizontal" }
      )
      utils.map("t", "<C-h>", [[<Cmd>wincmd h<CR>]], { desc = "[Terminal] Move Left", silent = true })
      utils.map("t", "<C-j>", [[<Cmd>wincmd j<CR>]], { desc = "[Terminal] Move Down", silent = true })
      utils.map("t", "<C-k>", [[<Cmd>wincmd k<CR>]], { desc = "[Terminal] Move Up", silent = true })
      utils.map("t", "<C-l>", [[<Cmd>wincmd l<CR>]], { desc = "[Terminal] Move Right", silent = true })
      utils.map("t", "jk", [[<C-\><C-n>]], { desc = "Escape Terminal Mode", silent = true })
      utils.map("t", "<esc>", [[<C-\><C-n>]], { desc = "Escape Terminal Mode", silent = true })
      -- vim.keymap.set('t', '<C-w>', [[<C-\><C-n><C-w>]], opts)
    end,
  },
  {
    "willothy/flatten.nvim",
    enabled = features.terminal,
    dependencies = { "akinsho/toggleterm.nvim" },
    opts = function()
      ---@type Terminal?
      local saved_terminal

      return {
        window = {
          open = "alternate",
        },
        callbacks = {
          should_block = function(argv)
            -- Note that argv contains all the parts of the CLI command, including
            -- Neovim's path, commands, options and files.
            -- See: :help v:argv

            -- In this case, we would block if we find the `-b` flag
            -- This allows you to use `nvim -b file1` instead of
            -- `nvim --cmd 'let g:flatten_wait=1' file1`
            return vim.tbl_contains(argv, "-b")

            -- Alternatively, we can block if we find the diff-mode option
            -- return vim.tbl_contains(argv, "-d")
          end,
          pre_open = function()
            local term = require("toggleterm.terminal")
            local termid = term.get_focused_id()
            saved_terminal = term.get(termid)
          end,
          post_open = function(bufnr, winnr, ft, is_blocking)
            if is_blocking and saved_terminal then
              -- Hide the terminal while it's blocking
              saved_terminal:close()
            else
              -- If it's a normal file, just switch to its window
              vim.api.nvim_set_current_win(winnr)
            end
            -- If the file is a git commit, create one-shot autocmd to delete its buffer on write
            -- If you just want the toggleable terminal integration, ignore this bit
            if ft == "gitcommit" or ft == "gitrebase" then
              vim.api.nvim_create_autocmd("BufWritePost", {
                buffer = bufnr,
                once = true,
                callback = vim.schedule_wrap(function()
                  vim.api.nvim_buf_delete(bufnr, {})
                end),
              })
            end
          end,
          block_end = function()
            -- After blocking ends (for a git commit, etc), reopen the terminal
            vim.schedule(function()
              if saved_terminal then
                saved_terminal:open()
                saved_terminal = nil
              end
            end)
          end,
        },
      }
    end,
    lazy = false,
    priority = 1001,
  },
}

-- Helper function to parse line number from query
local function parse_line_number(query)
  if not query then
    return nil
  end
  local line_num = query:match(":(%d+)$")
  return line_num and tonumber(line_num) or nil
end

-- Helper function to strip line number from query for filtering
local function strip_line_number(query)
  if not query then
    return query
  end
  return query:gsub(":(%d+)$", "")
end

return {
  {
    "folke/snacks.nvim",
    priority = 1000,
    lazy = false,
    init = function()
      vim.api.nvim_create_autocmd("User", {
        pattern = "VeryLazy",
        callback = function()
          -- Setup some globlas fir debugging (lazy-loaded)
          _G.dd = function(...)
            Snacks.debug.inspect(...)
          end
          _G.bt = function()
            Snacks.debug.backtrace()
          end
          vim.print = _G.dd -- Override print to use snacks for `:=` command

          -- Setup autocmd to handle preview window line highlighting
          local preview_augroup = vim.api.nvim_create_augroup("SnacksPickerPreview", { clear = true })
          vim.api.nvim_create_autocmd("FileType", {
            group = preview_augroup,
            pattern = "*",
            callback = function(args)
              -- Check if we're in a Snacks picker context
              if vim.g._snacks_picker_line_query then
                local line_num = parse_line_number(vim.g._snacks_picker_line_query)
                if line_num then
                  vim.schedule(function()
                    local buf = args.buf
                    if not vim.api.nvim_buf_is_valid(buf) then return end

                    local line_count = vim.api.nvim_buf_line_count(buf)
                    if line_num > 0 and line_num <= line_count then
                      -- Find the window showing this buffer
                      for _, win in ipairs(vim.api.nvim_list_wins()) do
                        if vim.api.nvim_win_is_valid(win) and vim.api.nvim_win_get_buf(win) == buf then
                          -- Jump to line and center
                          pcall(vim.api.nvim_win_set_cursor, win, { line_num, 0 })
                          vim.api.nvim_win_call(win, function()
                            vim.cmd("normal! zz")
                          end)

                          -- Highlight the line
                          local ns_id = vim.api.nvim_create_namespace("snacks_picker_highlight")
                          pcall(vim.api.nvim_buf_clear_namespace, buf, ns_id, 0, -1)
                          pcall(vim.api.nvim_buf_add_highlight, buf, ns_id, "CursorLine", line_num - 1, 0, -1)
                          break
                        end
                      end
                    end
                  end)
                end
              end
            end
          })

          -- Create wrapper for file picker with line number support
          local original_files = Snacks.picker.files
          Snacks.picker.files = function(opts)
            opts = opts or {}

            -- Set global to nil when picker starts
            vim.g._snacks_picker_line_query = nil

            -- Hook into input changes to track query for preview highlighting
            if not opts.win then opts.win = {} end
            if not opts.win.input then opts.win.input = {} end
            if not opts.win.input.keys then opts.win.input.keys = {} end

            -- Add a key handler that updates on every input change
            local original_on_change = opts.win.input.keys["<any>"]
            opts.win.input.keys["<any>"] = function(picker)
              -- Update global query state for preview highlighting
              if picker.input then
                vim.g._snacks_picker_line_query = picker.input:get() or ""
              end

              -- Call original handler if exists
              if original_on_change then
                return original_on_change(picker)
              end
            end

            -- Save original on_choice callback if it exists
            local original_on_choice = opts.on_choice

            -- Override on_choice to handle line jumping after file is opened
            opts.on_choice = function(item, ctx)
              -- Clear global query state
              vim.g._snacks_picker_line_query = nil

              if item and item.file then
                -- Parse line number from the input query
                local query = ctx and ctx.query or ""
                local line_num = parse_line_number(query)

                -- Call original on_choice if it exists
                if original_on_choice then
                  original_on_choice(item, ctx)
                end

                -- Schedule line jump after file opens
                if line_num then
                  vim.schedule(function()
                    local line_count = vim.api.nvim_buf_line_count(0)

                    -- Silently validate line number is within bounds
                    if line_num > 0 and line_num <= line_count then
                      pcall(function()
                        vim.api.nvim_win_set_cursor(0, { line_num, 0 })
                        vim.cmd("normal! zz")
                      end)
                    end
                  end)
                end
              end
            end

            return original_files(opts)
          end

          -- Create some toggle mappings
          Snacks.toggle.option("spell", { name = "Spelling" }):map("<leader>us")
          Snacks.toggle.option("wrap", { name = "Wrap" }):map("<leader>uw")
          Snacks.toggle.option("relativenumber", { name = "Relative Number" }):map("<leader>uL")
          Snacks.toggle.diagnostics():map("<leader>ud")
          Snacks.toggle
            .option("showtabline", { off = 0, on = vim.o.showtabline > 0 and vim.o.showtabline or 2, name = "Tabline" })
            :map("<leader>uA")
          Snacks.toggle
            .option("conceallevel", { off = 0, on = vim.o.conceallevel > 0 and vim.o.conceallevel or 2 })
            :map("<leader>uc")
          Snacks.toggle.treesitter():map("<leader>uT")
          Snacks.toggle.option("background", { off = "light", on = "dark", name = "Dark Background" }):map("<leader>ub")
          if vim.lsp.inlay_hint then
            Snacks.toggle.inlay_hints():map("<leader>cl")
          end
          -- Snacks.toggle.animate():map("<leader>ua")
          Snacks.toggle.indent():map("<leader>ug")
          Snacks.toggle.scroll():map("<leader>uS")
          -- Snacks.toggle.zen():map("<C-z>")
        end,
      })
    end,
    opts = {
      -- your configuration comes here
      -- or leave it empty to use the default settings
      -- refer to the configuration section below
      animate = { enabled = true },
      bigfile = { enabled = true },
      bufdelete = { enabled = true },
      dim = { enabled = true },
      git = { enabled = true },
      image = { enabled = true },
      indent = { enabled = false },
      input = { enabled = true },
      lazygit = { enabled = true },
      notifier = { enabled = true, timeout = 3500 },
      rename = { enabled = true },
      toggle = { enabled = true },
      picker = {
        win = {
          input = {
            keys = {
              ["<c-t>"] = {
                "trouble_open",
                mode = { "n" },
              },
              ["<c-t>"] = {
                "trouble_add",
                mode = { "i" },
              },
            },
          },
        },
        formatters = {
          file = {
            filename_first = true,
          },
        },
      },
      quickfile = { enabled = true },
      scope = { enabled = false },
      scratch = {
        enabled = true,
        root = vim.env.HOME .. "/Documents/obsidian/notes",
      },
      statuscolumn = { enabled = true },
      scroll = { enabled = false },
      -- styles = {},
      words = { enabled = true },
      zen = {
        enabled = true,
        show = {
          statusline = true,
          tabline = true,
        },
        zoom = {
          backdrop = true,
          -- width = 0.85,
        },
      },
      dashboard = {
        enabled = false,
        preset = {
          header = require("avim.utilities.banners")["random"],
        },
        keys = {
          { icon = " ", key = "f", desc = "Find File", action = ":lua Snacks.dashboard.pick('files')" },
          { icon = " ", key = "n", desc = "New File", action = ":ene | startinsert" },
          { icon = " ", key = "g", desc = "Find Text", action = ":lua Snacks.dashboard.pick('live_grep')" },
          { icon = " ", key = "o", desc = "Recent Files", action = ":lua Snacks.dashboard.pick('oldfiles')" },
          {
            icon = "",
            key = "r",
            desc = "Recent Sessions",
            action = "<cmd>SessionSelect<cr>",
            enabled = package.loaded.persisted ~= nil,
          },
          {
            icon = " ",
            key = "s",
            desc = "Restore Session",
            section = "session",
            enabled = package.loaded.persisted ~= nil,
          },
          { icon = "󰒲 ", key = "l", desc = "Lazy", action = ":Lazy", enabled = package.loaded.lazy ~= nil },
          {
            icon = " ",
            key = "m",
            desc = "Mason",
            action = ":Mason",
            enabled = package.loaded.mason ~= nil,
          },
          { icon = " ", key = "q", desc = "Quit", action = ":qa" },
        },
        sections = {
          { section = "header", height = 20, gap = 1 },
          { section = "keys", gap = 1, padding = 1 },
          { section = "startup" },
          { section = "terminal", cmd = "fortune -o -a vimtips", hl = "header", padding = 1, indent = 8 },
        },
      },
    },
    keys = {
      {
        "<leader>ff",
        function()
          Snacks.picker.files()
        end,
        mode = { "n", "v" },
        desc = "Find Files (type :123 to jump to line)",
      },
      {
        "<leader>fa",
        function()
          Snacks.picker.files({ hidden = true, follow = true })
        end,
        mode = { "n", "v" },
        desc = "All Files",
      },
      {
        "<leader>fs",
        function()
          Snacks.picker.smart()
        end,
        mode = { "n", "v" },
        desc = "Smart Search",
      },
      {
        "<leader>fw",
        function()
          Snacks.picker.grep()
        end,
        mode = { "n", "v" },
        desc = "Live Search",
      },
      {
        "<leader>fo",
        function()
          Snacks.picker.recent()
        end,
        mode = { "n", "v" },
        desc = "Recent Files",
      },
      {
        "<leader>fc",
        function()
          Snacks.picker.commands()
        end,
        mode = { "n", "v" },
        desc = "Commands",
      },
      {
        "<leader>fh",
        function()
          Snacks.picker.command_history()
        end,
        mode = { "n", "v" },
        desc = "Command History",
      },
      {
        "<leader>fk",
        function()
          Snacks.picker.keymaps()
        end,
        mode = { "n", "v" },
        desc = "Key Mappings",
      },
      {
        "<leader>fm",
        function()
          Snacks.picker.man()
        end,
        mode = { "n", "v" },
        desc = "Man Pages",
      },
      {
        "<leader>fr",
        function()
          Snacks.picker.resume()
        end,
        mode = { "n", "v" },
        desc = "Resume",
      },
      {
        "<leader>fp",
        function()
          Snacks.picker.lazy()
        end,
        mode = { "n", "v" },
        desc = "Search for Plugin Spec",
      },
      {
        "<leader>fD",
        function()
          Snacks.picker.lsp_symbols()
        end,
        mode = { "n", "v" },
        desc = "Document Symbols",
      },
      {
        "<leader>fu",
        function()
          Snacks.picker.colorschemes()
        end,
        -- "<cmd>lua require('avim.utilities.theme_picker')()<CR>",
        mode = { "n", "v" },
        desc = "Themes",
      },
      {
        "<leader>fb",
        function()
          Snacks.picker.buffers()
        end,
        desc = "Buffer List",
        mode = { "n", "v" },
      },
      {
        "<leader>fB",
        function()
          Snacks.picker.grep_buffers()
        end,
        mode = { "n", "v" },
        desc = "Fuzzy Buffer List",
      },

      {
        "<leader>fC",
        function()
          Snacks.picker.git_log()
        end,
        mode = { "n", "v" },
        desc = "Git Log",
      },
      -- Flutter tools
      -- utilities.map("n", "<leader>fd", "<cmd>Telescope flutter commands <CR>", { desc = "Flutter" })
      -- utilities.map("n", "<leader>ft", "<cmd>FlutterOutlineToggle<CR>", { desc = "Flutter Toggle Outline" })

      {
        "<leader>q",
        function()
          Snacks.bufdelete()
        end,
        desc = " Close Buffer",
      },
      -- { "<leader>Q", function() Snacks.bufdelete.other() end, desc = " Close All Except Buffer" },
      {
        "<leader>Q",
        function()
          Snacks.bufdelete.all()
        end,
        desc = " Close All",
      },
      {
        "<leader>nf",
        function()
          Snacks.scratch({ root = vim.env.HOME .. "/Documents/obsidian/notes" })
        end,
        desc = "Toggle Floating Scratch Buffer",
      },
      {
        "<leader>ns",
        function()
          Snacks.scratch.select()
        end,
        desc = "Select Scratch Buffer",
      },
      {
        "<leader>nr",
        function()
          Snacks.scratch({
            root = vim.env.HOME .. "/Documents/obsidian/notes",
            win = {
              position = "right",
              width = 45,
              height = 100,
            },
          })
        end,
        desc = "Toggle Right Scratch Buffer",
      },
      {
        "<C-z>",
        function()
          Snacks.toggle.dim():toggle()
          Snacks.toggle.zen():toggle()
        end,
        mode = { "n", "v" },
        desc = "Dimmed Zen Mode",
        silent = true,
      },
      {
        "<C-.>",
        function()
          Snacks.toggle.zen():toggle()
        end,
        mode = { "n", "v" },
        desc = "Zen Mode",
        silent = true,
      },
      -- { "<C-v>",      function() Snacks.zen.zoom() end,              mode = { "n", "v" },               desc = "Zoom Zen Mode",         silent = true },
      {
        "<leader>nh",
        function()
          Snacks.notifier.show_history()
        end,
        desc = "Notification History",
      },
      -- { "<leader>gb", function() Snacks.git.blame_line() end,        desc = "Git Blame Line" },
      -- { "<leader>gf", function() Snacks.lazygit.log_file() end,      desc = "Lazygit Current File History" },
      {
        "<leader>gl",
        function()
          Snacks.lazygit()
        end,
        desc = "Lazygit",
      },
      {
        "<leader>gg",
        function()
          Snacks.lazygit.log()
        end,
        desc = "Lazygit Log (cwd)",
      },
      {
        "<leader>un",
        function()
          Snacks.notifier.hide()
        end,
        desc = "Dismiss All Notifications",
      },
      {
        "<C-h>",
        "<Cmd>wincmd h<CR>",
        mode = { "t" },
        desc = "[Terminal] Move Left",
        silent = true,
      },
      {
        "<C-j>",
        "<Cmd>wincmd j<CR>",
        mode = { "t" },
        desc = "[Terminal] Move Down",
        silent = true,
      },
      {
        "<C-k>",
        "<Cmd>wincmd k<CR>",
        mode = { "t" },
        desc = "[Terminal] Move Up",
        silent = true,
      },
      {
        "<C-l>",
        "<Cmd>wincmd l<CR>",
        mode = { "t" },
        desc = "[Terminal] Move Right",
        silent = true,
      },
      {
        "jk",
        [[<C-\><C-n>]],
        mode = { "t" },
        desc = "Escape Terminal Mode",
        silent = true,
      },
      {
        "<Esc>",
        [[<C-\><C-n>]],
        mode = { "t" },
        desc = "Escape Terminal Mode",
        silent = true,
      },
      {
        mode = { "n", "v" },
        "<leader>tr",
        function()
          Snacks.terminal.toggle(nil, { win = { relative = "editor", position = "right" } })
        end,
        desc = "[Terminal] Toggle Vertical",
      },
      {
        mode = { "n", "v" },
        "<leader>tf",
        "<CMD>FloatermToggle<CR>",
        desc = "[Terminal] Toggle Floating",
      },
      {
        mode = { "n", "v" },
        "<leader>tb",
        function()
          Snacks.terminal.toggle(false, { win = { relative = "editor", position = "bottom" } })
        end,
        desc = "[Terminal] Toggle Horizontal",
      },
      {
        mode = { "n", "v" },
        "<leader>ty",
        function()
          Snacks.terminal.toggle("yazi", { win = { relative = "editor", position = "float" } })
        end,
        desc = "[Terminal] Toggle Yazi",
      },
    },
  },
  {
    "DestopLine/scratch-runner.nvim",
    dependencies = "folke/snacks.nvim",
    opts = {
      sources = {
        javascript = { "node" },
        typescript = { "bun" },
        python = function(filepath)
          vim.uv = vim.uv or vim.loop
          local on_windows = vim.uv.os_name().sysname == "Windows_NT"
          return {
            on_windows and "py" or "python3",
            filepath,
            "-",
            vim.version().build, -- Pass Neovim version as an argument
          }
        end,
        golang = function(filepath)
          return {
            "go",
            "run",
            filepath,
            "-",
            vim.version().build, -- Pass Neovim version as an argument
          }
        end,
      },
    },
    keys = {
      {
        "<leader>np",
        function()
          local filetypes = vim.fn.getcompletion("", "filetype")
          ---@diagnostic disable-next-line: missing-fields
          Snacks.picker.select(filetypes, nil, function(ft)
            Snacks.scratch({ ft = ft })
          end)
        end,
        mode = { "n", "v" },
        desc = "Open some filetype scratch window",
      },
    },
  },
  {
    "willothy/flatten.nvim",
    opts = {
      window = {
        open = "alternate",
      },
    },
    lazy = false,
    priority = 1001,
  },
}

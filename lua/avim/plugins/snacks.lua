-- `init.lua:42` / `init:42:7` -> pattern + position, like telescope's `:line`.
-- Note: `file:12` counts as a line, not as the `file` field with pattern `12`.
local function split_pos(pattern)
  local file, line, col = pattern:match("^(.-):(%d+):(%d+)$")
  if not file or file == "" then
    file, line = pattern:match("^(.-):(%d+)$")
  end
  if not file or file == "" then
    return pattern
  end
  return file, { tonumber(line), tonumber(col) or 0 }
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
      -- Performance: disable snacks.animate (using mini.animate instead)
      animate = { enabled = false },
      bigfile = { enabled = true },
      bufdelete = { enabled = true },
      dim = { enabled = true },
      git = { enabled = true },
      -- snacks.image handles picker previews and image files opened in a
      -- buffer; image.nvim keeps doing inline markdown images, so leave
      -- snacks' doc rendering off to avoid double-rendering markdown.
      image = { enabled = true, doc = { enabled = false } },
      indent = { enabled = false },
      input = { enabled = true },
      lazygit = { enabled = true },
      -- Use snacks.notifier as primary notification system
      notifier = {
        enabled = true,
        timeout = 3500,
        style = "compact",
      },
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
        sources = {
          files = {
            filter = {
              -- Snacks only parses `file.ext:line`; strip any `:line[:col]` here so
              -- `init:42` filters on `init` and lands on line 42 of the match.
              -- Also (re)points the current item, since `on_change` only fires when
              -- the selection changes and not when the line number is edited.
              transform = function(picker, filter)
                local file, pos = split_pos(filter.pattern)
                filter.pattern = file
                local cur = picker.list and picker:current()
                if cur then
                  cur.pos = pos
                  -- the list only re-previews when the selection changes
                  vim.schedule(function()
                    if not picker.closed then
                      picker:show_preview()
                    end
                  end)
                end
              end,
            },
            on_change = function(picker, item)
              if item then
                local _, pos = split_pos(picker.input:get())
                item.pos = pos
              end
            end,
          },
          keymaps = {
            -- Upstream prints the description after the rhs, so a long `<Cmd>`
            -- line pushes it off the window. Put it right after the keys.
            format = function(item)
              local map = item.item
              local align = Snacks.picker.util.align
              return {
                { map.mode, "SnacksPickerKeymapMode" },
                { " " },
                { align(Snacks.util.normkey(map.lhs), 18), "SnacksPickerKeymapLhs" },
                { " " },
                { align(map.desc or "", 34) },
                { (map.rhs and map.rhs ~= "") and map.rhs or "callback", "NonText" },
              }
            end,
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
      styles = {
        terminal = {
          -- snacks binds a buffer-local <esc> ("double escape to normal mode")
          -- that shadows our single-<esc> exit map, so ESC leaks to the shell,
          -- where zsh meta bindings (M-u, M-a, M-l) mangle the command line.
          keys = { term_normal = false },
        },
      },
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
            action = "<cmd>Persisted select<cr>",
            enabled = package.loaded.persisted ~= nil,
          },
          {
            icon = " ",
            key = "s",
            desc = "Restore Session",
            action = "<cmd>Persisted load<cr>",
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
          -- Disable satellite temporarily to prevent E565 errors during buffer delete
          pcall(function()
            require("satellite.view").disable()
          end)
          Snacks.bufdelete()
          vim.defer_fn(function()
            pcall(function()
              require("satellite.view").enable()
            end)
          end, 100)
        end,
        desc = "Close Buffer",
      },
      {
        "<leader>Q",
        function()
          pcall(function()
            require("satellite.view").disable()
          end)
          Snacks.bufdelete.all()
          vim.defer_fn(function()
            pcall(function()
              require("satellite.view").enable()
            end)
          end, 100)
        end,
        desc = "Close All Buffers",
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

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
      -- your configuration comes here
      -- or leave it empty to use the default settings
      -- refer to the configuration section below
      animate = { enabled = true },
      bigfile = { enabled = true },
      bufdelete = { enabled = true },
      dim = { enabled = true },
      git = { enabled = true },
      indent = { enabled = false },
      lazygit = { enabled = true },
      notifier = { enabled = true, timeout = 5000 },
      rename = { enabled = false },
      toggle = { enabled = true },
      quickfile = { enabled = true },
      scope = { enabled = false },
      scratch = {
        enabled = true,
        root = vim.env.HOME .. "/Documents/obsidian/notes",
      },
      statuscolumn = { enabled = true },
      scroll = { enabled = false },
      -- styles = {},
      words = { enabled = false },
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
            action = "<cmd>Telescope persisted<cr>",
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
        "<leader>nb",
        function()
          Snacks.scratch({
            root = vim.env.HOME .. "/Documents/obsidian/notes",
            win = {
              position = "bottom",
              height = 0.4,
              width = 1,
            },
          })
        end,
        desc = "Toggle Bottom Scratch Buffer",
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
          if Snacks.zen.enabled then
            Snacks.dim.disable()
          else
            Snacks.dim.enable()
          end
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
        function()
          Snacks.terminal.toggle(nil, { win = { relative = "editor", position = "float" } })
        end,
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

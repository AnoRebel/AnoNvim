local utilities = require("avim.utilities")

-- Git Messenger
-- TODO: Needs work
vim.g.git_messenger_no_default_mappings = true
vim.g.git_messenger_floating_win_opts = { border = "rounded" }
vim.g.git_messenger_popup_content_margins = false
-- vim.g.git_messenger_include_diff = "none" -- "current" | "all"
-- vim.g.git_messenger_max_popup_height = null
-- vim.g.git_messenger_max_popup_width = null
-- Committia
vim.g.committia_open_only_vim_starting = 0
-----------------------------------------------------------------------------
--- Keymaps
-----------------------------------------------------------------------------
utilities.map("n", "<leader>g", nil, { name = " Git + DiffView" })
-- utilities.map("n", "<leader>gc", "<cmd>Telescope git_commits<CR>", { desc = "[Git] Commits" })
utilities.map("n", "<leader>gs", function()
  Snacks.picker.git_status()
end, { desc = "[Git] Status" })
-----------------------------------------------------------------------------

return {
  {
    "echasnovski/mini.diff",
    version = "*",
    config = function()
      require("mini.diff").setup({
        view = {
          -- Visualization style. Possible values are 'sign' and 'number'.
          -- Default: 'number' if line numbers are enabled, 'sign' otherwise.
          style = "sign",
        },
        -- Module mappings. Use `''` (empty string) to disable one.
        mappings = {
          -- Apply hunks inside a visual/operator region
          apply = "", -- "gh",

          -- Reset hunks inside a visual/operator region
          reset = "", -- "gH",

          -- Hunk range textobject to be used inside operator
          -- Works also in Visual mode if mapping differs from apply and reset
          textobject = "", -- "gh",

          -- Go to hunk range in corresponding direction
          goto_first = "", -- "[H",
          goto_prev = "", --"[h",
          goto_next = "", --"]h",
          goto_last = "", --"]H",
        },
      })
    end,
    keys = {
      { "<leader>gu", "<cmd>lua require('mini.diff').toggle_overlay()<CR>", desc = "[Diff] Overlay" },
    },
  },
  {
    "lewis6991/gitsigns.nvim",
    event = "BufReadPre",
    opts = {
      signs = {
        add = {
          text = "▎",
        },
        change = {
          text = "▎",
        },
        delete = {
          text = "_", -- "契",
        },
        topdelete = {
          text = "‾", -- "契",
        },
        changedelete = {
          text = "~", -- "▎",
        },
      },
      numhl = true,
      word_diff = false,
      attach_to_untracked = true,
      current_line_blame_opts = {
        virt_text_pos = "eol", -- 'eol' | 'overlay' | 'right_align'
      },
      preview_config = {
        -- Options passed to nvim_open_win
        border = "rounded",
      },
      watch_gitdir = {
        follow_files = true,
      },
    },
    keys = {
      { "<leader>gb", "<cmd>Gitsigns toggle_current_line_blame<CR>", desc = "[Git] Blame Line" },
    },
  },
  {
    "SuperBo/fugit2.nvim",
    enabled = false,
    opts = {
      width = 70,
      external_diffview = true, -- tell fugit2 to use diffview.nvim instead of builtin implementation.
    },
    dependencies = {
      "MunifTanjim/nui.nvim",
      "nvim-tree/nvim-web-devicons",
      "nvim-lua/plenary.nvim",
      {
        "chrisgrieser/nvim-tinygit", -- Optional: For Github PR view
      },
    },
    cmd = { "Fugit2", "Fugit2Graph" },
  },
  {
    "isakbm/gitgraph.nvim",
    dependencies = { "sindrets/diffview.nvim" },
    ---@type I.GGConfig
    opts = {
      symbols = {
        merge_commit = "M",
        commit = "*",
      },
      format = {
        timestamp = "%H:%M:%S %d-%m-%Y",
        fields = { "hash", "timestamp", "author", "branch_name", "tag" },
      },
      hooks = {
        -- Check diff of a commit
        on_select_commit = function(commit)
          vim.notify("DiffviewOpen " .. commit.hash .. "^!")
          vim.cmd(":DiffviewOpen " .. commit.hash .. "^!")
        end,
        -- Check diff from commit a -> commit b
        on_select_range_commit = function(from, to)
          vim.notify("DiffviewOpen " .. from.hash .. "~1.." .. to.hash)
          vim.cmd(":DiffviewOpen " .. from.hash .. "~1.." .. to.hash)
        end,
      },
    },
    keys = {
      {
        "<leader>gd",
        function()
          require("gitgraph").draw({}, { all = true, max_count = 5000 })
        end,
        desc = "GitGraph - Draw",
      },
    },
  },
  {
    "sindrets/diffview.nvim",
    cmd = {
      "DiffviewOpen",
      "DiffviewClose",
      "DiffviewRefresh",
      "DiffviewToggleFiles",
      "DiffviewFocusFiles",
      "DiffviewFileHistory",
    },
    dependencies = { "nvim-lua/plenary.nvim", "nvim-tree/nvim-web-devicons" },
    opts = {
      use_icons = true, -- Requires nvim-web-devicons
      icons = { -- Only applies when use_icons is true.
        folder_closed = "",
        folder_open = "",
      },
      signs = {
        fold_closed = "",
        fold_open = "",
      },
    },
    keys = {
      { "<leader>gh", "<cmd>lua require('avim.utilities').toggle_diff()<CR>", desc = "[Diff] Toggle History" },
      { "<leader>go", "<cmd>DiffviewOpen<CR>", desc = "[Diff] Open" },
      { "<leader>gc", "<cmd>DiffviewClose<CR>", desc = "[Diff] Close" },
      { "<leader>gr", "<cmd>DiffviewRefresh<CR>", desc = "[Diff] Refresh" },
      { "<leader>gf", "<cmd>DiffviewToggleFiles<CR>", desc = "[Diff] Toggle Files" },
    },
  },
  {
    "akinsho/git-conflict.nvim",
    cmd = {
      "GitConflictChooseOurs",
      "GitConflictChooseTheirs",
      "GitConflictChooseBoth",
      "GitConflictChooseNone",
      "GitConflictNextConflict",
      "GitConflictPrevConflict",
      "GitConflictListQf",
    },
    config = true,
  },
  { "rhysd/committia.vim", lazy = false },
  {
    "rhysd/git-messenger.vim",
    cmd = { "GitMessenger" },
    keys = {
      { "<leader>gm", "<cmd>GitMessenger<CR>", mode = { "n", "v" }, desc = "[Git] Blame Code" },
    },
  },
}

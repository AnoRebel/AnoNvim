local features = require("avim.core.defaults").features
local utils = require("avim.utils")

if features.git then
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
  -- vim.g.committia_use_singlecolumn = "fallback" -- "always"
  -----------------------------------------------------------------------------
  --- Keymaps
  -----------------------------------------------------------------------------
  utils.map("n", "<leader>g", nil, { name = " Git + DiffView" })
  utils.map("n", "<leader>gl", "<cmd>lua require('toggleterm').lazygit_toggle()<CR>", { desc = "[Git] UI" })
  -- utils.map("n", "<leader>gc", "<cmd>Telescope git_commits<CR>", { desc = "[Git] Commits" })
  utils.map("n", "<leader>gs", "<cmd>Telescope git_status<CR>", { desc = "[Git] Status" })
  -- Git Messenger
  utils.map({ "n", "v" }, "<leader>gm", "<cmd>GitMessenger<CR>", { desc = "[Git] Blame Code" })
  utils.map("n", "<leader>gb", "<cmd>Gitsigns toggle_current_line_blame<CR>", { desc = "[Git] Blame Line" })
  -- Diffview
  utils.map("n", "<leader>gu", "<cmd>lua require('mini.diff').toggle_overlay()<CR>", { desc = "[Diff] Overlay" })
  utils.map("n", "<leader>go", "<cmd>DiffviewOpen<CR>", { desc = "[Diff] Open" })
  utils.map("n", "<leader>gc", "<cmd>DiffviewClose<CR>", { desc = "[Diff] Close" })
  utils.map("n", "<leader>gr", "<cmd>DiffviewRefresh<CR>", { desc = "[Diff] Refresh" })
  utils.map("n", "<leader>gf", "<cmd>DiffviewToggleFiles<CR>", { desc = "[Diff] Toggle Files" })
  utils.map("n", "<leader>gh", "<cmd>lua require('avim.utils').toggle_diff()<CR>", { desc = "[Diff] Toggle History" })
  -----------------------------------------------------------------------------
end

return {
  {
    "echasnovski/mini.diff",
    enabled = features.git,
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
  },
  {
    "lewis6991/gitsigns.nvim",
    enabled = features.git,
    event = "BufReadPre",
    opts = {
      signs = {
        add = {
          hl = "GitSignsAdd",
          text = "▎",
          numhl = "GitSignsAddNr",
          linehl = "GitSignsAddLn",
        },
        change = {
          hl = "GitSignsChange",
          text = "▎",
          numhl = "GitSignsChangeNr",
          linehl = "GitSignsChangeLn",
        },
        delete = {
          hl = "GitSignsDelete",
          text = "_", -- "契",
          numhl = "GitSignsDeleteNr",
          linehl = "GitSignsDeleteLn",
        },
        topdelete = {
          hl = "GitSignsDelete",
          text = "‾", -- "契",
          numhl = "GitSignsDeleteNr",
          linehl = "GitSignsDeleteLn",
        },
        changedelete = {
          hl = "GitSignsChange",
          text = "~", -- "▎",
          numhl = "GitSignsChangeNr",
          linehl = "GitSignsChangeLn",
        },
      },
      numhl = true,
      word_diff = false,
      attach_to_untracked = true,
      current_line_blame_opts = {
        virt_text_pos = "eol", -- 'eol' | 'overlay' | 'right_align'
      },
      current_line_blame_formatter_opts = {
        relative_time = true,
      },
      preview_config = {
        -- Options passed to nvim_open_win
        border = "rounded",
      },
      watch_gitdir = {
        follow_files = true,
      },
    },
  },
  {
    "NeogitOrg/neogit",
    enabled = features.neogit,
    dependencies = {
      "nvim-lua/plenary.nvim", -- required
      "sindrets/diffview.nvim", -- optional - Diff integration

      -- Only one of these is needed, not both.
      "nvim-telescope/telescope.nvim", -- optional
      -- "ibhagwan/fzf-lua",              -- optional
    },
    cmd = { "Neogit" },
    -- config = true,
    opts = {
      integrations = {
        telescope = true,
        diffview = true,
      },
    },
  },
  {
    "SuperBo/fugit2.nvim",
    enabled = features.fugit,
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
        dependencies = "stevearc/dressing.nvim",
      },
    },
    cmd = { "Fugit2", "Fugit2Graph" },
  },
  {
    "sindrets/diffview.nvim",
    enabled = features.git,
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
  },
  {
    "akinsho/git-conflict.nvim",
    enabled = features.git,
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
  { "rhysd/committia.vim", enabled = features.git, lazy = false },
  {
    "rhysd/git-messenger.vim",
    enabled = features.git,
    cmd = { "GitMessenger" },
  },
}

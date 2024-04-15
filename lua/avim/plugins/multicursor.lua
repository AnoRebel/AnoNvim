local M = {
  "smoka7/multicursors.nvim",
  enabled = true,
  event = "VeryLazy",
  dependencies = {
    "nvim-treesitter/nvim-treesitter",
    "smoka7/hydra.nvim",
  },
  opts = function()
    local N = require("multicursors.normal_mode")
    local I = require("multicursors.insert_mode")
    return {
      normal_keys = {
        -- to change default lhs of key mapping change the key
        [","] = {
          -- assigning nil to method exits from multi cursor mode
          method = N.clear_others,
          -- you can pass :map-arguments here
          opts = { desc = "Clear others" },
        },
      },
      insert_keys = {
        -- to change default lhs of key mapping change the key
        ["<CR>"] = {
          -- assigning nil to method exits from multi cursor mode
          method = I.Cr_method,
          -- you can pass :map-arguments here
          opts = { desc = "New line" },
        },
      },
      hint_config = {
        border = "rounded",
        position = "bottom",
        -- border = { "┏", "━", "┓", "┃", "┛", "━", "┗", "┃" },
      },
      generate_hints = {
        normal = true,
        insert = true,
        extend = true,
      },
    }
  end,
  cmd = { "MCstart", "MCvisual", "MCclear", "MCpattern", "MCvisualPattern", "MCunderCursor" },
  keys = {
    {
      mode = { "v", "n" },
      "<Leader>m",
      "<cmd>MCstart<cr>",
      desc = "Create a selection for selected text or word under the cursor",
    },
  },
}

return M

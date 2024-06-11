local M = {
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
      test = {
        mode = "diagnostics",
        preview = {
          type = "split",
          relative = "win",
          position = "right",
          size = 0.3,
        },
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
}

return M

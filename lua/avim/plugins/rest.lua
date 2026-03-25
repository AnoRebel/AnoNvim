local defaults = require("avim.core.defaults")
local utilities = require("avim.utilities")

return {
  "rest-nvim/rest.nvim",
  ft = "http",
  dependencies = {
    {
      "vhyrro/luarocks.nvim",
      enabled = false,
      priority = 1000,
      opts = {
        rocks = defaults.rocks,
        luarocks_build_args = { "--with-lua=/usr/bin/lua5.1" },
      },
    },
  },
  cmd = { "Rest" },
  config = function(_, opts)
    require("rest-nvim").setup(opts)
    utilities.map("n", "<leader>r", nil, { name = " Rest APIs" })
    utilities.map("n", "<leader>rr", "<CMD>Rest run<CR>", { desc = "Run Request Under the Cursor" })
    utilities.map("n", "<leader>rl", "<CMD>Rest run last<CR>", { desc = "Re-run Latest Request" })
  end,
}

local utilities = require("avim.utilities")

-- Rocks (nvim-nio, mimetypes, xml2lua, tree-sitter-http) come from the
-- rockspec: lazy.nvim builds them into lazy-rocks/rest.nvim.
return {
  "rest-nvim/rest.nvim",
  ft = "http",
  cmd = { "Rest" },
  config = function(_, opts)
    require("rest-nvim").setup(opts)
    utilities.map("n", "<leader>r", nil, { name = " Rest APIs" })
    utilities.map("n", "<leader>rr", "<CMD>Rest run<CR>", { desc = "Run Request Under the Cursor" })
    utilities.map("n", "<leader>rl", "<CMD>Rest run last<CR>", { desc = "Re-run Latest Request" })
  end,
}

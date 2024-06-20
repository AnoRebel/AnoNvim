local features = require("avim.core.defaults").features

return {
  "nvim-neotest/neotest",
  enabled = features.tests,
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-treesitter/nvim-treesitter",
    "antoinemadec/FixCursorHold.nvim",
    -- Adapters
    "nvim-neotest/neotest-python",
    "nvim-neotest/neotest-go",
    "sidlatau/neotest-dart",
    "marilari88/neotest-vitest",
    "haydenmeade/neotest-jest",
    "jfpedroza/neotest-elixir",
    "MarkEmmons/neotest-deno",
  },
  opts = {
    adapters = {
      -- 		require("neotest-python")({
      -- 			dap = { justMyCode = false },
      -- 		}),
      -- 		require("neotest-go"),
      -- 		require("neotest-vitest"),
      -- 		require("neotest-jest"),
      -- 		require("neotest-dart"),
      -- 		require("neotest-elixir"),
      -- 		require("neotest-deno"),
    },
  },
}

local defaults = require("avim.core.defaults")

-- Vim Matchup
vim.g.matchup_matchparen_offscreen = { method = "popup" }
vim.g.matchup_surround_enabled = 1
--disable specific module
-- vim.g.matchup_matchparen_enabled = 0
-- vim.g.matchup_motion_enabled = 0
-- vim.g.matchup_text_obj_enabled = 0

return {
  "nvim-treesitter/nvim-treesitter",
  enabled = defaults.features.treesitter,
  event = "BufReadPost",
  dependencies = {
    { "mtdl9/vim-log-highlighting", ft = { "text", "log" } },
    {
      "romgrk/nvim-treesitter-context",
      opts = {
        separator = "_",
        max_lines = 5, -- 0
        multiline_threshold = 10, -- 20
      },
    },
    { "JoosepAlviste/nvim-ts-context-commentstring" },
    { "windwp/nvim-ts-autotag", setup = true },
    { "andymass/vim-matchup", branch = "master" },
  },
  -- :TSUpdate[Sync] doesn't exist until plugin/nvim-treesitter is loaded (i.e. not after first install); call update() directly
  -- build = ":TSUpdate",
  build = function()
    require("nvim-treesitter.install").update({ with_sync = true })
  end,

  opts = {
    ensure_installed = defaults.treesitter,
    highlight = {
      enable = true,
      use_languagetree = true,
      additional_vim_regex_highlighting = { "markdown" },
    },
    matchup = {
      enable = true, -- mandatory, false will disable the whole extension
      enable_quotes = true,
    },
  },
}

local M = {
  "nvim-treesitter/nvim-treesitter",
  event = "BufReadPost",
  dependencies = {
    {
      "romgrk/nvim-treesitter-context",
      opts = {
        separator = "_",
        max_lines = 5, -- 0
        multiline_threshold = 10, -- 20
      },
    },
    { "JoosepAlviste/nvim-ts-context-commentstring" },
    { "HiPhish/rainbow-delimiters.nvim" },
    { "windwp/nvim-ts-autotag", setup = true },
    { "andymass/vim-matchup", enabled = true, branch = "master" },
  },
  -- :TSUpdate[Sync] doesn't exist until plugin/nvim-treesitter is loaded (i.e. not after first install); call update() directly
  -- build = ":TSUpdate",
  build = function()
    require("nvim-treesitter.install").update({ with_sync = true })
  end,

  opts = {
    ensure_installed = require("avim.core.defaults").treesitter,
    highlight = {
      enable = true,
      use_languagetree = true,
      additional_vim_regex_highlighting = { "markdown" },
    },
    matchup = {
      enable = true, -- mandatory, false will disable the whole extension
      enable_quotes = true,
      -- disable = { "c", "ruby" },  -- optional, list of language that will be disabled
      -- [options]
    },
  },
}

return M

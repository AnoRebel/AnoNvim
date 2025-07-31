return {
  "OXY2DEV/markview.nvim",
  lazy = false, -- Recommended

  dependencies = {
    "nvim-treesitter/nvim-treesitter",
    "nvim-tree/nvim-web-devicons",
  },
  opts = {
    preview = {
      filetypes = { "md", "rmd", "quarto", "markdown", "codecompanion" },
      ignore_buftypes = {},
    },
    experimental = {
      check_rtp_message = false,
    },
  },
}

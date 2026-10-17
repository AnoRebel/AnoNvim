-- { "noisesfromspace/touchup.nvim", opts = {} }
return {
  "OXY2DEV/markview.nvim",
  ft = { "markdown", "md", "rmd", "quarto", "codecompanion" },

  dependencies = {
    "nvim-treesitter/nvim-treesitter",
    "nvim-tree/nvim-web-devicons",
  },
  opts = {
    preview = {
      filetypes = { "md", "rmd", "quarto", "markdown", "codecompanion" },
      ignore_buftypes = {},
    },
  },
}

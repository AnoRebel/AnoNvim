local M = {
  "lukas-reineke/indent-blankline.nvim",
  main = "ibl",
  enabled = false,
  opts = {
    char = "▏",
    exclude = {
      --  filetypes = {
      --  "help",
      --  "terminal",
      --  "alpha",
      --  "packer",
      --  "lazy",
      --  "lspinfo",
      --  "TelescopePrompt",
      --  "TelescopeResults",
      --  "lsp-installer",
      --  "",
      -- },
      -- buftypes = { "terminal", "nofile" },
    },
  },
}

return M

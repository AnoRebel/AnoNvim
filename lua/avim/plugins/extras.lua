-- Undotree
vim.g.undotree_SplitWidth = 35
vim.g.undotree_DiffpanelHeight = 30
vim.g.undotree_WindowLayout = 4
vim.g.undotree_TreeNodeShape = "◉"
vim.g.undotree_SetFocusWhenToggle = 1
-----------------------------------------------------------------------------
--- Keymaps
-----------------------------------------------------------------------------
-----------------------------------------------------------------------------

return {
  {
    "wakatime/vim-wakatime",
    lazy = false,
    -- init = function()
    --   vim.g.wakatime_CLIPath = vim.env.HOME .. "/.wakatime/wakatime-cli"
    -- end,
  },
  {
    "tamton-aquib/zone.nvim",
    enabled = false,
    opts = {
      style = "vanish",
      after = 60,
    },
  },
  {
    "vuki656/package-info.nvim",
    dependencies = "MunifTanjim/nui.nvim",
    config = true,
  },
  {
    "metakirby5/codi.vim",
    cmd = { "Codi", "CodiNew", "CodiSelect" },
  },
  {
    "nvim-mini/mini.splitjoin",
    opts = {},
    keys = {
      {
        "<leader>j",
        "<cmd>lua MiniSplitjoin.toggle()<cr>",
        desc = "Toggle node under cursor (split if one-line and join if multiline)",
      },
    },
  },
  {
    "tversteeg/registers.nvim",
    cmd = "Registers",
    config = true,
    keys = {
      { '"', "<CMD>Registers<CR>", mode = { "n", "v" } },
      { "<C-R>", mode = "i" },
    },
    name = "registers",
  },
  {
    "mbbill/undotree",
    cmd = { "UndotreeShow", "UndotreeToggle" },
    keys = {
      { "<leader><F5>", "<cmd>lua vim.cmd.UndotreeToggle()<CR>", desc = "Toggle undo tree" },
    },
  },
  {
    "tris203/precognition.nvim",
    event = "VeryLazy",
    cmd = "Precognition",
    opts = {
      startVisible = false,
    },
    keys = {
      {
        "<leader>pt",
        function()
          if require("precognition").toggle() then
            vim.notify("precognition on")
          else
            vim.notify("precognition off")
          end
        end,
        desc = "Toggle precognition",
      },
      { "<leader>pk", "<CMD>Precognition peek<CR>", desc = "Precognition peek" },
    },
  },
}

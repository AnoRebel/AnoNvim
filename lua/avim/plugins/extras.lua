-- Cheat
vim.g.cheat_default_window_layout = "float" -- "vertical_split" | "split" | "tab"
-- Undotree
vim.g.undotree_SplitWidth = 35
vim.g.undotree_DiffpanelHeight = 10
vim.g.undotree_WindowLayout = 4
vim.g.undotree_TreeNodeShape = "◉"
vim.g.undotree_SetFocusWhenToggle = 1
-----------------------------------------------------------------------------
--- Keymaps
-----------------------------------------------------------------------------
-----------------------------------------------------------------------------

local comp_hl = {
  PmenuSel = { bg = "#282C34", fg = "NONE" },
  Pmenu = { fg = "#C5CDD9", bg = "#22252A" },

  CmpItemAbbrDeprecated = { fg = "#7E8294", bg = "NONE", strikethrough = true },
  CmpItemAbbrMatch = { fg = "#82AAFF", bg = "NONE", bold = true },
  CmpItemAbbrMatchFuzzy = { fg = "#82AAFF", bg = "NONE", bold = true },
  CmpItemMenu = { fg = "#C792EA", bg = "NONE", italic = true },

  CmpItemKindField = { fg = "#EED8DA", bg = "#B5585F" },
  CmpItemKindProperty = { fg = "#EED8DA", bg = "#B5585F" },
  CmpItemKindEvent = { fg = "#EED8DA", bg = "#B5585F" },

  CmpItemKindText = { fg = "#C3E88D", bg = "#9FBD73" },
  CmpItemKindEnum = { fg = "#C3E88D", bg = "#9FBD73" },
  CmpItemKindKeyword = { fg = "#C3E88D", bg = "#9FBD73" },

  CmpItemKindConstant = { fg = "#FFE082", bg = "#D4BB6C" },
  CmpItemKindConstructor = { fg = "#FFE082", bg = "#D4BB6C" },
  CmpItemKindReference = { fg = "#FFE082", bg = "#D4BB6C" },

  CmpItemKindFunction = { fg = "#EADFF0", bg = "#A377BF" },
  CmpItemKindStruct = { fg = "#EADFF0", bg = "#A377BF" },
  CmpItemKindClass = { fg = "#EADFF0", bg = "#A377BF" },
  CmpItemKindModule = { fg = "#EADFF0", bg = "#A377BF" },
  CmpItemKindOperator = { fg = "#EADFF0", bg = "#A377BF" },

  CmpItemKindVariable = { fg = "#C5CDD9", bg = "#7E8294" },
  CmpItemKindFile = { fg = "#C5CDD9", bg = "#7E8294" },

  CmpItemKindUnit = { fg = "#F5EBD9", bg = "#D4A959" },
  CmpItemKindSnippet = { fg = "#F5EBD9", bg = "#D4A959" },
  CmpItemKindFolder = { fg = "#F5EBD9", bg = "#D4A959" },

  CmpItemKindMethod = { fg = "#DDE5F5", bg = "#6C8ED4" },
  CmpItemKindValue = { fg = "#DDE5F5", bg = "#6C8ED4" },
  CmpItemKindEnumMember = { fg = "#DDE5F5", bg = "#6C8ED4" },

  CmpItemKindInterface = { fg = "#D8EEEB", bg = "#58B5A8" },
  CmpItemKindColor = { fg = "#D8EEEB", bg = "#58B5A8" },
  CmpItemKindTypeParameter = { fg = "#D8EEEB", bg = "#58B5A8" },
}
for grp, hls in pairs(comp_hl) do
  vim.api.nvim_set_hl(0, grp, hls)
end

return {
  {
    "mistricky/codesnap.nvim",
    enabled = false,
    build = "make",
    cmd = { "CodeSnap", "CodeSnapSave" },
    opts = {
      save_path = "~/Pictures",
      has_breadcrumbs = true,
      bg_theme = "grape",
      code_font_family = "Iosevka Nerd Font",
      watermark_font_family = "FiraCode Nerd Font",
      watermark = "AnoRebel",
    },
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
    "max397574/colortils.nvim",
    enabled = false,
    cmd = "Colortils",
    opts = {
      default_format = "hex", -- "rgb" || "hsl"
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
    "Wansmer/treesj",
    cmd = { "TSJToggle", "TSJSplit", "TSJJoin" },
    opts = {
      use_default_keymaps = false,
    },
    keys = {
      {
        "<space>j",
        "<cmd>lua require('treesj').toggle()<cr>",
        desc = "Toggle node under cursor (split if one-line and join if multiline)",
      },
      -- { '<space>m', "<cmd>lua require('treesj').toggle()<cr>", desc = "Toggle node under cursor (split if one-line and join if multiline)" },
      -- { '<space>j', "<cmd>lua require('treesj').join()<cr>",   desc = "Split node under cursor" },
      -- { '<space>s', "<cmd>lua require('treesj').split()<cr>",  desc = "Join node under cursor" },
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

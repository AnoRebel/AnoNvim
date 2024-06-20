local features = require("avim.core.defaults").features
local icons = require("avim.icons").kind
local utils = require("avim.utils")

if features.extras then
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
end

if features.navic then
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
  vim.api.nvim_set_hl(0, "NavicIconsFile", { default = true, fg = "#7E8294" }) -- bg = "#C5CDD9", })
  vim.api.nvim_set_hl(0, "NavicIconsModule", { default = true, fg = "#A377BF" }) -- bg = "#EADFF0", })
  vim.api.nvim_set_hl(0, "NavicIconsNamespace", { default = true, fg = "#58B5A8" }) -- bg = "#D8EEEB", })
  vim.api.nvim_set_hl(0, "NavicIconsPackage", { default = true, fg = "#A377BF" }) -- bg = "#EADFF0", })
  vim.api.nvim_set_hl(0, "NavicIconsClass", { default = true, fg = "#A377BF" }) -- bg = "#EADFF0", })
  vim.api.nvim_set_hl(0, "NavicIconsMethod", { default = true, fg = "#6C8ED4" }) -- bg = "#DDE5F5", })
  vim.api.nvim_set_hl(0, "NavicIconsProperty", { default = true, fg = "#B5585F" }) -- bg = "#EED8DA", })
  vim.api.nvim_set_hl(0, "NavicIconsField", { default = true, fg = "#B5585F" }) -- bg = "#EED8DA", })
  vim.api.nvim_set_hl(0, "NavicIconsConstructor", { default = true, fg = "#D4BB6C" }) -- bg = "#FFE082", })
  vim.api.nvim_set_hl(0, "NavicIconsEnum", { default = true, fg = "#9FBD73" }) -- bg = "#C3E88D", })
  vim.api.nvim_set_hl(0, "NavicIconsInterface", { default = true, fg = "#58B5A8" }) -- bg = "#D8EEEB", })
  vim.api.nvim_set_hl(0, "NavicIconsFunction", { default = true, fg = "#A377BF" }) -- bg = "#EADFF0", })
  vim.api.nvim_set_hl(0, "NavicIconsVariable", { default = true, fg = "#7E8294" }) -- bg = "#C5CDD9", })
  vim.api.nvim_set_hl(0, "NavicIconsConstant", { default = true, fg = "#D4BB6C" }) -- bg = "#FFE082", })
  vim.api.nvim_set_hl(0, "NavicIconsString", { default = true, fg = "#B5585F" }) -- bg = "#EED8DA", })
  vim.api.nvim_set_hl(0, "NavicIconsNumber", { default = true, fg = "#B5585F" }) -- bg = "#EED8DA", })
  vim.api.nvim_set_hl(0, "NavicIconsBoolean", { default = true, fg = "#B5585F" }) -- bg = "#EED8DA", })
  vim.api.nvim_set_hl(0, "NavicIconsArray", { default = true, fg = "#A377BF" }) -- bg = "#EADFF0", })
  vim.api.nvim_set_hl(0, "NavicIconsObject", { default = true, fg = "#A377BF" }) -- bg = "#EADFF0", })
  vim.api.nvim_set_hl(0, "NavicIconsKey", { default = true, fg = "#9FBD73" }) -- bg = "#C3E88D", })
  vim.api.nvim_set_hl(0, "NavicIconsNull", { default = true, fg = "#6C8ED4" }) -- bg = "#DDE5F5", })
  vim.api.nvim_set_hl(0, "NavicIconsEnumMember", { default = true, fg = "#6C8ED4" }) -- bg = "#DDE5F5", })
  vim.api.nvim_set_hl(0, "NavicIconsStruct", { default = true, fg = "#A377BF" }) -- bg = "#EADFF0", })
  vim.api.nvim_set_hl(0, "NavicIconsEvent", { default = true, fg = "#B5585F" }) -- bg = "#EED8DA", })
  vim.api.nvim_set_hl(0, "NavicIconsOperator", { default = true, fg = "#A377BF" }) -- bg = "#EADFF0", })
  vim.api.nvim_set_hl(0, "NavicIconsTypeParameter", { default = true, fg = "#58B5A8" }) -- bg = "#D8EEEB", })
  vim.api.nvim_set_hl(0, "NavicText", { default = true, fg = "#9FBD73" }) -- bg = "#C3E88D", })
  vim.api.nvim_set_hl(0, "NavicSeparator", { default = true, fg = "#58B5A8" }) -- bg = "#D8EEEB", })
end

if features.zen then
  utils.map({ "n", "v" }, "<C-z>", "<cmd>ZenMode<CR>", { desc = "Zen Mode", silent = true })
end

if features.notes then
  -- No Neck Pain
  utils.map("n", "<leader>n", nil, { name = "NoNeckPain" })
  utils.map("n", "<leader>nn", "<cmd>NoNeckPain<CR>", { desc = "No Neck Pain" })
  utils.map("n", "<leader>nl", "<cmd>NoNeckPainToggleLeftSide<CR>", { desc = "Toggle Left Pane" })
  utils.map("n", "<leader>nr", "<cmd>NoNeckPainToggleRightSide<CR>", { desc = "Toggle Right Pain" })
  utils.map("n", "<leader>ns", "<cmd>NoNeckPainScratchPad<CR>", { desc = "Scratchpad" })
end

return {
  {
    "mistricky/codesnap.nvim",
    enabled = features.screenshot,
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
  { "eandrju/cellular-automaton.nvim", enabled = features.extras, cmd = "CellularAutomaton" },
  {
    "tamton-aquib/zone.nvim",
    enabled = features.screensaver,
    opts = {
      style = "vanish",
      after = 60,
    },
  },
  {
    "max397574/colortils.nvim",
    enabled = features.extras,
    cmd = "Colortils",
    opts = {
      default_format = "hex", -- "rgb" || "hsl"
    },
  },
  {
    "metakirby5/codi.vim",
    enabled = features.repl,
    cmd = { "Codi", "CodiNew", "CodiSelect" },
  },
  {
    "RishabhRD/nvim-cheat.sh",
    enabled = features.extras,
    dependencies = { "RishabhRD/popfix" },
    cmd = { "Cheat", "CheatWithoutComments", "CheatList", "CheatListWithoutComments" },
  },
  {
    "kawre/leetcode.nvim",
    enabled = features.extras,
    build = ":TSUpdate html",
    lazy = vim.fn.argv()[1] ~= "leetcode.nvim",
    cmd = { "Leet" },
    dependencies = {
      "nvim-telescope/telescope.nvim",
      "nvim-lua/plenary.nvim", -- required by telescope
      "MunifTanjim/nui.nvim",

      -- optional
      "nvim-treesitter/nvim-treesitter",
      "rcarriga/nvim-notify",
      "nvim-tree/nvim-web-devicons",
    },
    opts = {
      arg = "leetcode.nvim",
    },
  },
  {
    "Wansmer/treesj",
    enabled = features.extras,
    cmd = { "TSJToggle", "TSJSplit", "TSJJoin" },
    opts = {
      use_default_keymaps = false,
    },
  },
  {
    "SmiteshP/nvim-navic",
    enabled = features.navic,
    dependencies = { "neovim/nvim-lspconfig" },
    opts = {
      depth_limit = 5,
      highlight = true,
      icons = {
        ["class-name"] = "%#CmpItemKindClass#" .. icons.Class .. "%*" .. " ",
        ["function-name"] = "%#CmpItemKindFunction#" .. icons.Function .. "%*" .. " ",
        ["method-name"] = "%#CmpItemKindMethod#" .. icons.Method .. "%*" .. " ",
        ["container-name"] = "%#CmpItemKindProperty#" .. icons.Object .. "%*" .. " ",
        ["tag-name"] = "%#CmpItemKindKeyword#" .. icons.Tag .. "%*" .. " ",
        ["mapping-name"] = "%#CmpItemKindProperty#" .. icons.Object .. "%*" .. " ",
        ["sequence-name"] = "%CmpItemKindProperty#" .. icons.Array .. "%*" .. " ",
        ["null-name"] = "%CmpItemKindField#" .. icons.Field .. "%*" .. " ",
        ["boolean-name"] = "%CmpItemKindValue#" .. icons.Boolean .. "%*" .. " ",
        ["integer-name"] = "%CmpItemKindValue#" .. icons.Number .. "%*" .. " ",
        ["float-name"] = "%CmpItemKindValue#" .. icons.Number .. "%*" .. " ",
        ["string-name"] = "%CmpItemKindValue#" .. icons.String .. "%*" .. " ",
        ["array-name"] = "%CmpItemKindProperty#" .. icons.Array .. "%*" .. " ",
        ["object-name"] = "%CmpItemKindProperty#" .. icons.Object .. "%*" .. " ",
        ["number-name"] = "%CmpItemKindValue#" .. icons.Number .. "%*" .. " ",
        ["table-name"] = "%CmpItemKindProperty#" .. icons.Table .. "%*" .. " ",
        ["date-name"] = "%CmpItemKindValue#" .. icons.Calendar .. "%*" .. " ",
        ["date-time-name"] = "%CmpItemKindValue#" .. icons.Table .. "%*" .. " ",
        ["inline-table-name"] = "%CmpItemKindProperty#" .. icons.Calendar .. "%*" .. " ",
        ["time-name"] = "%CmpItemKindValue#" .. icons.Watch .. "%*" .. " ",
        ["module-name"] = "%CmpItemKindModule#" .. icons.Module .. "%*" .. " ",
      },
    },
  },
  {
    "tversteeg/registers.nvim",
    enabled = features.extras,
    cmd = { "Registers" },
    config = true,
  },
  {
    "max397574/better-escape.nvim",
    enabled = features.extras,
    event = "BufRead",
    config = true,
  },
  {
    "folke/zen-mode.nvim",
    enabled = features.zen,
    cmd = "ZenMode",
    dependencies = {
      { "folke/twilight.nvim", cmd = "Twilight" },
    },
    opts = {
      window = {
        -- height and width can be:
        -- * an absolute number of cells when > 1
        -- * a percentage of the width / height of the editor when <= 1
        width = 0.85, -- width of the Zen window
      },
      plugins = {
        -- disable some global vim options (vim.o...)
        -- comment the lines to not apply the options
        options = {
          enabled = true,
        },
        -- this will change the font size on kitty when in zen mode
        -- to make this work, you need to set the following kitty options:
        -- - allow_remote_control socket-only
        -- - listen_on unix:/tmp/kitty
        kitty = {
          enabled = true,
          font = "+4", -- font size increment
        },
        alacritty = {
          enabled = true,
          font = "14", -- font size
        },
      },
    },
  },
  {
    "mbbill/undotree",
    enabled = features.extras,
    cmd = { "UndotreeShow", "UndotreeToggle" },
  },
  {
    "smjonas/inc-rename.nvim",
    enabled = features.extras,
    cmd = "IncRename",
    opts = {
      input_buffer_type = "dressing",
    },
  },
  {
    "ziontee113/icon-picker.nvim",
    enabled = features.extras,
    cmd = { "IconPickerNormal", "IconPickerInsert", "IconPickerYank" },
    opts = {
      disable_legacy_commands = true,
    },
  },
  {
    "tris203/precognition.nvim",
    enabled = features.precognition,
    event = "VeryLazy",
    config = true,
  },
  {
    "shortcuts/no-neck-pain.nvim",
    enabled = features.notes,
    cmd = {
      "NoNeckPain",
      "NoNeckPainToggleLeftSide",
      "NoNeckPainToggleRightSide",
      "NoNeckPainResize",
      "NoNeckPainScratchPad",
      "NoNeckPainWidthUp",
      "NoNeckPainWidthDown",
    },
    opts = {
      bufferOptionsColor = {
        blend = -0.2,
      },
      buffers = {
        left = { enabled = true },
        right = { enabled = true },
        colors = {
          background = vim.g.colors_name,
          blend = -0.2,
        },
        scratchPad = {
          enabled = true,
          location = "~/Documents/obsidian/notes/",
          fileName = "scratchpad",
        },
        wo = { fillchars = "eob: " },
        bo = {
          filetype = "md",
        },
      },
      autocmds = {
        -- When `true`, reloads the plugin configuration after a colorscheme change.
        --- @type boolean
        reloadOnColorSchemeChange = true,
      },
      integrations = {
        NvimTree = {
          position = "left",
          reopen = true,
        },
        NeoTree = {
          position = "right",
          reopen = true,
        },
        undotree = {
          position = "right",
        },
        neotest = {
          -- The position of the tree.
          --- @type "right"
          position = "right",
          -- When `true`, if the tree was opened before enabling the plugin, we will reopen it.
          reopen = true,
        },
        NvimDAPUI = {
          -- The position of the tree.
          --- @type "none"
          position = "none",
          -- When `true`, if the tree was opened before enabling the plugin, we will reopen it.
          reopen = true,
        },
      },
    },
  },
}

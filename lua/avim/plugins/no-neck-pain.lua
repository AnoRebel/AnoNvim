local M = {
  "shortcuts/no-neck-pain.nvim",
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
}

return M

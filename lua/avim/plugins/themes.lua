-- Themes
vim.g.catppuccin_flavour = "mocha" -- latte, frappe, macchiato, catppuccino
-- vim.g.tokyodark_transparent_background = false
vim.g.tokyodark_enable_italic_comment = true
vim.g.tokyodark_enable_italic = true
vim.g.tokyodark_color_gamma = "1.0"
vim.g.tokyonight_style = "night" -- "day", "storm"
vim.g.tokyonight_italic_functions = true
-- vim.g.tokyonight_transparent = true -- dont set bg

return {
    {
        "folke/styler.nvim",
        opts = {
            themes = {
                markdown = { colorscheme = "oxocarbon" },
                gitcommit = { colorscheme = "tokyodark" },
                gitrebase = { colorscheme = "rose-pine" },
                help = { colorscheme = "catppuccin", background = "dark" },
            },
        },
    },
    {
        "catppuccin/nvim",
        lazy = false,
        name = "catppuccin",
        config = function()
            local ctpcn_ok, ctpcn = pcall(require, "catppuccin")
            if ctpcn_ok then
                ctpcn.setup({
                    flavour = "mocha",
                    no_italic = false,
                    no_bold = false,
                    -- Awesome dark variant I got from https://github.com/nullchilly/nvim/blob/nvim/lua/config/catppuccin.lua
                    -- But I couldn't get the time to research how to make NvimTree Context match it so, commented out for now
                    -- color_overrides = {
                    -- 	mocha = {
                    -- 		base = "#000000",
                    -- 	},
                    -- },
                    dim_inactive = {
                        enabled = true,
                    },
                    styles = {
                        types = { "italic" },
                        booleans = { "italic" },
                    },
                    term_colors = true,
                    integrations = {
                        alpha = true,
                        aerial = true,
                        barbecue = {
                            dim_dirname = true, -- directory name is dimmed by default
                            bold_basename = true,
                            dim_context = true,
                            alt_background = false,
                        },
                        beacon = true,
                        blink_cmp = true,
                        cmp = true,
                        dap = true,
                        dap_ui = true,
                        -- diffview = require("avim.core.defaults").features.git,
                        dropbar = {
                            enabled = true,
                            color_mode = true, -- enable color for kind's texts, not just kind's icons
                        },
                        fidget = true,
                        gitgutter = true,
                        gitsigns = true,
                        illuminate = true,
                        indent_blankline = { enabled = true, colored_indent_levels = true },
                        leap = true,
                        lsp_trouble = true,
                        mason = true,
                        markdown = true,
                        notify = true,
                        mini = {
                            enabled = true,
                            -- indentscope_color = "", -- catppuccin color (eg. `lavender`) Default: text
                        },
                        navic = false,
                        native_lsp = {
                            enabled = true,
                            underlines = {
                                errors = { "undercurl" },
                                hints = { "undercurl" },
                                warnings = { "undercurl" },
                                information = { "undercurl" },
                            },
                        },
                        neotest = true,
                        neotree = true,
                        neogit = true,
                        noice = true,
                        -- nvimtree = true,
                        rainbow_delimiters = true,
                        semantic_tokens = true,
                        telescope = {
                            enabled = true,
                        },
                        treesitter = true,
                        treesitter_context = true,
                        ts_rainbow = true,
                        ufo = true,
                        which_key = true,
                    },
                    native_lsp = {
                        enabled = true,
                        virtual_text = {
                            errors = { "italic" },
                            hints = { "italic" },
                            warnings = { "italic" },
                            information = { "italic" },
                        },
                        underlines = {
                            errors = { "underline" },
                            hints = { "underline" },
                            warnings = { "underline" },
                            information = { "underline" },
                        },
                    },
                    highlight_overrides = {
                        mocha = function(C)
                            return {
                                TabLineSel = { bg = C.pink },
                                NvimTreeNormal = { bg = C.none },
                                CmpBorder = { fg = C.surface2 },
                                Pmenu = { bg = C.none },
                                NormalFloat = { bg = C.none },
                            }
                        end,
                    },
                })
            else
                vim.notify("Theme Error: catppuccin", vim.log.levels.WARN)
            end
        end,
    },
    {
        "tiagovla/tokyodark.nvim",
        lazy = false,
    },
    {
        "rose-pine/neovim",
        lazy = false,
        name = "rose-pine",
        config = function()
            local rp_ok, rp = pcall(require, "rose-pine")
            if rp_ok then
                rp.setup()
            else
                vim.notify("Theme Error: rose-pine", vim.log.levels.WARN)
            end
        end,
    },
    {
        "rebelot/kanagawa.nvim",
        lazy = false,
        config = function()
            local kngw_ok, kngw = pcall(require, "kanagawa")
            if kngw_ok then
                kngw.setup({
                    compile = true,
                    theme = "dragon",
                    background = {
                        dark = "dragon",
                        light = "wave",
                    },
                })
            else
                vim.notify("Theme Error : kanagawa", vim.log.levels.WARN)
            end
        end,
    },
    {
        "nyoom-engineering/oxocarbon.nvim",
        lazy = false,
    },
}

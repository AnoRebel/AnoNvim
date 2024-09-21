local utils = require("avim.utils")

vim.cmd([[
    function! Quit_vim(a,b,c,d)
        qa
    endfunction
  ]])
-- Bufferline
utils.map({ "n", "v" }, "<Tab>", "<cmd>BufferLineCycleNext<CR>", { desc = "Next Tab" })
utils.map({ "n", "v" }, "<S-Tab>", "<cmd>BufferLineCyclePrev<CR>", { desc = "Previous Tab" })
-- utils.map({ "n", "v" }, "<C-Tab>", "<cmd>BufferLineCycleNext<CR>", { desc = "Next Tab" })
-- utils.map({ "n", "v" }, "<C-S-Tab>", "<cmd>BufferLineCyclePrev<CR>", { desc = "Previous Tab" })
utils.map({ "n", "v" }, "<leader>b", nil, { name = "󰓩 Buffers" })
utils.map({ "n", "v" }, "<leader>bp", "<cmd>BufferLinePick<CR>", { desc = "Pick Tab" })
utils.map({ "n", "v" }, "<leader>bc", "<cmd>BufferLinePickClose<CR>", { desc = "Pick And Close Tab" })
utils.map({ "n", "v" }, "<leader>bb", "<cmd>e #<cr>", { desc = "Switch Tab" })
utils.map({ "n", "v" }, "<leader>`", "<cmd>e #<cr>", { desc = "Switch Tab" })
utils.map({ "n", "v" }, "<leader>bl", "<cmd>BufferLineMoveNext<CR>", { desc = "Move Tab Forward" })
utils.map({ "n", "v" }, "<leader>br", "<cmd>BufferLineMovePrev<CR>", { desc = "Move Tab Back" })
utils.map({ "n", "v" }, "<leader>bh", "<cmd>sp<CR>", { desc = "Split Horizontal", silent = true, noremap = true })
utils.map({ "n", "v" }, "<leader>bv", "<cmd>vsp<CR>", { desc = "Split Vertical", silent = true, noremap = true })
utils.map({ "n", "v" }, "<leader>bq", "<C-w>q", { desc = "Close Split", silent = true, noremap = true })
utils.map({ "n", "v" }, "<leader>bm", "<cmd>MaximizerToggle!<CR>", { desc = "Toggle Maximize Tab" })
utils.map({ "n", "v" }, "<leader>bt", "<cmd>BufferLineGoToBuffer -1<CR>", { desc = "Go to Last Visible Tab" })
-- Opt
for i = 1, 9 do
    utils.map(
        { "n", "v" },
        "<C-" .. i .. ">",
        "<cmd>BufferLineGoToBuffer " .. i .. "<CR>",
        { desc = "Go to Tab " .. i }
    )
end

return {
    "akinsho/bufferline.nvim",
    event = "VeryLazy",
    version = "*",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {
        options = {
            offsets = {
                {
                    filetype = "NvimTree",
                    text = "File Explorer",
                    highlight = "Directory",
                    text_align = "center", -- "left" | "right"
                    padding = 1,
                },
                {
                    filetype = "undotree",
                    text = "Undotree",
                    highlight = "PanelHeading",
                    padding = 1,
                },
                {
                    filetype = "DiffviewFiles",
                    text = "Diff View",
                    highlight = "PanelHeading",
                    padding = 1,
                },
                {
                    filetype = "flutterToolsOutline",
                    text = "Flutter Outline",
                    highlight = "PanelHeading",
                },
                {
                    filetype = "lazy",
                    text = "Lazy",
                    highlight = "PanelHeading",
                    padding = 1,
                },
            },
            right_mouse_command = "vertical sbuffer %d",
            color_icons = true,
            show_close_icon = true,
            show_buffer_icons = true,
            show_tab_indicators = true,
            show_buffer_close_icons = true,
            show_buffer_default_icons = true,
            enforce_regular_tabs = false,
            always_show_bufferline = true,
            buffer_close_icon = "", -- icons.close_icon
            modified_icon = "",
            close_icon = "",
            left_trunc_marker = " ",
            right_trunc_marker = " ",
            max_name_length = 14,
            max_prefix_length = 13,
            tab_size = 20,
            view = "multiwindow",
            -- indicator = {
            --   -- icon = '▎', -- this should be omitted if indicator style is not 'icon'
            --   style = "underline", -- "icon" | "underline" | "none",
            -- },
            separator_style = "thick", -- "thick" | "slant" | "slope"
            -- NOTE: this plugin is designed with this icon in mind,
            -- and so changing this is NOT recommended, this is intended
            -- as an escape hatch for people who cannot bear it for whatever reason
            -- indicator_icon = '▎',
            -- For ⁸·₂
            numbers = function(opts)
                return string.format("%s·%s", opts.raise(opts.id), opts.lower(opts.ordinal))
            end,
            diagnostics = false, -- "nvim_lsp"
            diagnostics_indicator = function(count, level, diagnostics_dict, context)
                local s = " "
                for e, n in pairs(diagnostics_dict) do
                    local sym = e == "error" and " " or (e == "warning" and " " or "")
                    s = s .. n .. sym
                end
                return s
            end,
            themable = true,
            hover = {
                enabled = false, -- requires nvim 0.8+
                delay = 200,
                reveal = { "close" },
            },
            custom_areas = {
                right = function()
                    local result = {}
                    local seve = vim.diagnostic.severity
                    local error = #vim.diagnostic.get(0, { severity = seve.ERROR })
                    local warning = #vim.diagnostic.get(0, { severity = seve.WARN })
                    local info = #vim.diagnostic.get(0, { severity = seve.INFO })
                    local hint = #vim.diagnostic.get(0, { severity = seve.HINT })

                    if error ~= 0 then
                        table.insert(result, { text = "  " .. error, guifg = "#EC5241" })
                    end
                    if warning ~= 0 then
                        table.insert(result, { text = "  " .. warning, guifg = "#EFB839" })
                    end
                    if hint ~= 0 then
                        table.insert(result, { text = "  " .. hint, guifg = "#A3BA5E" })
                    end
                    if info ~= 0 then
                        table.insert(result, { text = "  " .. info, guifg = "#7EA9A7" })
                    end
                    -- table.insert(result, { text = "%@Quit_vim@  %X" })
                    return result
                end,
            },

            custom_filter = function(buf_number)
                -- Func to filter out our managed/persistent split terms
                local present_type, type = pcall(function()
                    return vim.api.nvim_buf_get_var(buf_number, "term_type")
                end)

                if present_type then
                    if type == "vert" then
                        return false
                    elseif type == "hori" then
                        return false
                    end
                    return true
                end

                return true
            end,
        },
    },
}

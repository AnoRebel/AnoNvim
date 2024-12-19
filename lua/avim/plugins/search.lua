local utilities = require("avim.utilities")

-- Spectre
-- run command :Spectre
utilities.map("n", "<leader>s", nil, { name = "󰛔 Search and Replace" })

return {
    {
        "nvim-pack/nvim-spectre",
        dependencies = { "nvim-lua/plenary.nvim" },
        cmd = "Spectre",
        opts = {
            live_update = true, -- auto execute search again when you write to any file in vim
            open_cmd = "noswapfile vnew",
        },
        keys = {
            { "<leader>ss", "<cmd>lua require('spectre').open()<CR>",        desc = "[Spectre] Open" },
            {
                "<leader>sw",
                "<cmd>lua require('spectre').open_visual({select_word=true})<CR>",
                mode = { "v" },
                { desc = "[Spectre] Open Visual" }
            },
            {
                "<leader>sp",
                "viw<cmd>lua require('spectre').open_file_search()<CR>",
                desc = "[Spectre] File Search"
            },
            { "<leader>sw", "<cmd>lua require('spectre').open_visual()<CR>", mode = { "v" },         desc = "[Spectre] Open Visual" },
        },
    },
    {
        "AckslD/muren.nvim",
        config = true,
        cmd = {
            "MurenOpen",
            "MurenClose",
            "MurenToggle",
            "MurenFresh",
            "MurenUnique",
        },
        keys = {
            { "<leader>st", "<cmd>MurenToggle<CR>", desc = "[Muren] Toggle" },
            { "<leader>sf", "<cmd>MurenFresh<CR>",  desc = "[Muren] Fresh Search" },
            { "<leader>su", "<cmd>MurenUnique<CR>", desc = "[Muren] Unique Search" },
        },
    },
    {
        "ggandor/flit.nvim",
        dependencies = { "ggandor/leap.nvim", dependencies = { "tpope/vim-repeat" } },
        keys = function()
            local ret = {}
            for _, key in ipairs({ "f", "F", "t", "T" }) do
                ret[#ret + 1] = { key, mode = { "n", "x", "o" }, desc = key }
            end
            return ret
        end,
        opts = { labeled_modes = "nx" },
    },
}

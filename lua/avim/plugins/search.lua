local utils = require("avim.utils")

-- Spectre
-- run command :Spectre
utils.map("n", "<leader>s", nil, { name = "󰛔 Search and Replace" })
utils.map("n", "<leader>ss", "<cmd>lua require('spectre').open()<CR>", { desc = "[Spectre] Open" })
utils.map(
    { "n", "v" },
    "<leader>sw",
    "<cmd>lua require('spectre').open_visual({select_word=true})<CR>",
    { desc = "[Spectre] Open Visual" }
)
utils.map(
    "n",
    "<leader>sp",
    "viw<cmd>lua require('spectre').open_file_search()<CR>",
    { desc = "[Spectre] File Search" }
)
utils.map("v", "<leader>sw", "<cmd>lua require('spectre').open_visual()<CR>", { desc = "[Spectre] Open Visual" })

-- Muren Search
-- utils.map("n", "<leader>so", "<cmd>MurenOpen<CR>", { desc = "[Muren] Open" })
-- utils.map("n", "<leader>sc", "<cmd>MurenClose<CR>", { desc = "[Muren] Close" })
utils.map("n", "<leader>st", "<cmd>MurenToggle<CR>", { desc = "[Muren] Toggle" })
utils.map("n", "<leader>sf", "<cmd>MurenFresh<CR>", { desc = "[Muren] Fresh Search" })
utils.map("n", "<leader>su", "<cmd>MurenUnique<CR>", { desc = "[Muren] Unique Search" })

return {
    {
        "nvim-pack/nvim-spectre",
        dependencies = { "nvim-lua/plenary.nvim" },
        cmd = "Spectre",
        opts = {
            live_update = true, -- auto execute search again when you write to any file in vim
            open_cmd = "noswapfile vnew",
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

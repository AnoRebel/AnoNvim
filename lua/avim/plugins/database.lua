local utils = require("avim.utils")

utils.map({ "n", "v" }, "<leader>d", nil, { name = " Database" })
utils.map({ "n", "v" }, "<leader>do", "<cmd>lua require('dbee').open()<CR>", { desc = "[Database] Open" })
utils.map({ "n", "v" }, "<leader>dc", "<cmd>lua require('dbee').close()<CR>", { desc = "[Database] Close" })
utils.map({ "n", "v" }, "<leader>dt", "<cmd>lua require('dbee').toggle()<CR>", { desc = "[Database] Toggle" })
utils.map(
    { "n", "v" },
    "<leader>de",
    "<cmd>lua require('avim.utils.dbee').execute()<CR>",
    { desc = "[Database] Execute Query" }
)
utils.map(
    { "n", "v" },
    "<leader>ds",
    "<cmd>lua require('avim.utils.dbee').save()<CR>",
    { desc = "[Database] Save Output" }
)
utils.map(
    { "n", "v" },
    "<leader>dr",
    "<cmd>lua require('avim.utils.dbee').save(true)<CR>",
    { desc = "[Database] Save Output" }
)
utils.map({ "n", "v" }, "<leader>dp", "<cmd>lua require('dbee').prev()<CR>", { desc = "[Database] Previous Page" })
utils.map({ "n", "v" }, "<leader>dn", "<cmd>lua require('dbee').next()<CR>", { desc = "[Database] Next Page" })

return {
    "kndndrj/nvim-dbee",
    dependencies = {
        "MunifTanjim/nui.nvim",
    },
    event = "VeryLazy",
    build = function()
        -- Install tries to automatically detect the install method
        -- If it fails, try calling it with one of these paramaters:
        --    "curl", "wget", "bitsadmin", "go"
        require("dbee").install()
    end,
    config = function()
        require("dbee").setup({
            sources = {
                require("dbee.sources").FileSource:new(_G.get_config_dir() .. "/dbee/persistence.json"),
                require("dbee.sources").EnvSource:new("DBEE_CONNECTIONS"),
            },
        })
    end,
}

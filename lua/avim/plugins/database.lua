local utilities = require("avim.utilities")

utilities.map({ "n", "v" }, "<leader>d", nil, { name = " Database" })

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
    keys = {
        { "<leader>do", "<cmd>lua require('dbee').open()<CR>",   mode = { "n", "v" }, desc = "[Database] Open" },
        { "<leader>dc", "<cmd>lua require('dbee').close()<CR>",  mode = { "n", "v" }, desc = "[Database] Close" },
        { "<leader>dt", "<cmd>lua require('dbee').toggle()<CR>", mode = { "n", "v" }, desc = "[Database] Toggle" },
        {
            "<leader>de",
            "<cmd>lua require('avim.utilities.dbee').execute()<CR>",
            mode = { "n", "v" },
            desc = "[Database] Execute Query"
        },
        {
            "<leader>ds",
            "<cmd>lua require('avim.utilities.dbee').save()<CR>",
            mode = { "n", "v" },
            desc = "[Database] Save Output"
        },
        {
            "<leader>dr",
            "<cmd>lua require('avim.utilities.dbee').save(true)<CR>",
            mode = { "n", "v" },
            desc = "[Database] Save Output"
        },
        { "<leader>dp", "<cmd>lua require('dbee').prev()<CR>", mode = { "n", "v" }, desc = "[Database] Previous Page" },
        { "<leader>dn", "<cmd>lua require('dbee').next()<CR>", mode = { "n", "v" }, desc = "[Database] Next Page" },
    },
}

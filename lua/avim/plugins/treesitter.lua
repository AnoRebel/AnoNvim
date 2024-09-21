local defaults = require("avim.core.defaults")

-- Vim Matchup
vim.g.matchup_matchparen_offscreen = { method = "popup" }
vim.g.matchup_surround_enabled = 1
--disable specific module
-- vim.g.matchup_matchparen_enabled = 0
-- vim.g.matchup_motion_enabled = 0
-- vim.g.matchup_text_obj_enabled = 0

return {
    "nvim-treesitter/nvim-treesitter",
    event = "BufReadPost",
    -- :TSUpdate[Sync] doesn't exist until plugin/nvim-treesitter is loaded (i.e. not after first install); call update() directly
    -- build = ":TSUpdate",
    build = function()
        require("nvim-treesitter.install").update({ with_sync = true })
    end,
    init = function(plugin)
        -- PERF: add nvim-treesitter queries to the rtp and it's custom query predicates early
        -- This is needed because a bunch of plugins no longer `require("nvim-treesitter")`, which
        -- no longer trigger the **nvim-treesitter** module to be loaded in time.
        -- Luckily, the only things that those plugins need are the custom queries, which we make available
        -- during startup.
        require("lazy.core.loader").add_to_rtp(plugin)
        require("nvim-treesitter.query_predicates")
    end,
    cmd = { "TSUpdateSync", "TSUpdate", "TSInstall" },
    dependencies = {
        { "mtdl9/vim-log-highlighting",                 ft = { "text", "log" } },
        {
            "romgrk/nvim-treesitter-context",
            opts = {
                separator = "_",
                max_lines = 5,    -- 0
                multiline_threshold = 10, -- 20
            },
        },
        { "JoosepAlviste/nvim-ts-context-commentstring" },
        { "windwp/nvim-ts-autotag",                     config = true },
        { "andymass/vim-matchup",                       branch = "master" },
    },
    opts = {
        ensure_installed = defaults.treesitter,
        highlight = {
            enable = true,
            use_languagetree = true,
            additional_vim_regex_highlighting = { "markdown" },
        },
        matchup = {
            enable = true, -- mandatory, false will disable the whole extension
            enable_quotes = true,
        },
    },
}

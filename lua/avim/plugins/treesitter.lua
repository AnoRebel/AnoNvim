local defaults = require("avim.core.defaults")

-- Vim Matchup
vim.g.matchup_matchparen_offscreen = { method = "popup" }
vim.g.matchup_surround_enabled = 1
--disable specific module
-- vim.g.matchup_matchparen_enabled = 1
-- vim.g.matchup_motion_enabled = 1
-- vim.g.matchup_text_obj_enabled = 1

return {
  "nvim-treesitter/nvim-treesitter",
  version = false,
  lazy = vim.fn.argc(-1) == 0, -- load treesitter early when opening a file from the cmdline
  event = { "VeryLazy" },
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
  keys = {
    { "<c-space>", desc = "Increment Selection" },
    { "<bs>", desc = "Decrement Selection", mode = "x" },
  },
  dependencies = {
    "nvim-treesitter/nvim-treesitter-textobjects",
    { "mtdl9/vim-log-highlighting", ft = { "text", "log" } },
    {
      "nvim-treesitter/nvim-treesitter-context",
      opts = function()
        local tsc = require("treesitter-context")
        Snacks.toggle({
          name = "Treesitter Context",
          get = tsc.enabled,
          set = function(state)
            if state then
              tsc.enable()
            else
              tsc.disable()
            end
          end,
        }):map("<leader>ut")
        return {
          separator = "_",
          max_lines = 2, -- 0
          multiline_threshold = 5, -- 20
        }
      end,
    },
    { "JoosepAlviste/nvim-ts-context-commentstring" },
    { "windwp/nvim-ts-autotag", config = true },
    { "andymass/vim-matchup", branch = "master" },
  },
  ---@type TSConfig
  ---@diagnostic disable-next-line: missing-fields
  opts = {
    ensure_installed = defaults.treesitter,
    sync_install = true,
    auto_install = true,
    indent = { enable = true },
    highlight = {
      enable = true,
      use_languagetree = true,
      additional_vim_regex_highlighting = { "markdown" },
    },
    matchup = {
      enable = true, -- mandatory, false will disable the whole extension
      enable_quotes = true,
    },
    incremental_selection = {
      enable = true,
      keymaps = {
        init_selection = "<C-space>",
        node_incremental = "<C-space>",
        scope_incremental = false,
        node_decremental = "<bs>",
      },
    },
  },
  ---@param opts TSConfig
  config = function(_, opts)
    vim.treesitter.language.register("markdown", "livebook")
    require("nvim-treesitter.configs").setup(opts)
  end,
}

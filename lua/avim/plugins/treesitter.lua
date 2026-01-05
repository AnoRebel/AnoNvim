local defaults = require("avim.core.defaults")

return {
  "nvim-treesitter/nvim-treesitter",
  -- Defer loading - only eager load when opening a file from cmdline
  lazy = vim.fn.argc(-1) == 0,
  event = { "BufReadPost", "BufNewFile" },
  branch = "main",
  -- build = ":TSUpdate",
  build = function()
    require("nvim-treesitter").install(defaults.treesitter)
    require("nvim-treesitter.install").update({ with_sync = true })
  end,
  init = function(plugin)
    -- PERF: add nvim-treesitter queries to the rtp and it's custom query predicates early
    -- This is needed because a bunch of plugins no longer `require("nvim-treesitter")`, which
    -- no longer trigger the **nvim-treesitter** module to be loaded in time.
    -- Luckily, the only things that those plugins need are the custom queries, which we make available
    -- during startup.
    -- require("lazy.core.loader").add_to_rtp(plugin)
    -- require("nvim-treesitter.query_predicates")
  end,
  cmd = { "TSUpdateSync", "TSUpdate", "TSInstall" },
  dependencies = {
    -- "nvim-treesitter/nvim-treesitter-textobjects",
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
          enable = true, -- Enable this plugin (Can be enabled/disabled later via commands)
          separator = "_",
          max_lines = 2, -- 0
          line_numbers = true,
          multiline_threshold = 5, -- 20
          multiwindow = true, -- Enable multiwindow support.
        }
      end,
    },
    { "JoosepAlviste/nvim-ts-context-commentstring" },
    { "windwp/nvim-ts-autotag", config = true },
    { "andymass/vim-matchup",
      init = function()
        vim.g.matchup_matchparen_offscreen = { method = "popup" }
        vim.g.matchup_surround_enabled = 0
        --   Do not use virtual text to highlight the virtual end of a block, for languages without explicit end markers (e.g., Python). >
        vim.g.matchup_treesitter_disable_virtual_text = 0
        -- vim.g.matchup_matchparen_enabled = 0
        -- vim.g.matchup_motion_enabled = 0
        -- vim.g.matchup_text_obj_enabled = 0
      end,
      opts = {
        treesitter = {
          stopline = 500,
          -- Do not use virtual text to highlight the virtual end of a block, for languages without explicit end markers (e.g., Python). >
          disable_virtual_text = false,
        }
      },
    },
  },
  ---@type TSConfig
  ---@diagnostic disable-next-line: missing-fields
  opts = {
    install_dir = _G.get_runtime_dir() .. "/site",
    -- ensure_installed = defaults.treesitter,
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
    -- vim.treesitter.language.register("markdown", "livebook")
    require("nvim-treesitter").setup(opts)
    -- require("nvim-treesitter.configs").setup(opts)
    local installed = vim.api.nvim_get_runtime_file("parser/*.so", true)

    local missing = {}
    for _, lang in ipairs(defaults.treesitter) do
      local found = false

      for _, file in ipairs(installed) do
        if file:match(lang .. "%.so$") then
          found = true
          break
        end
      end

      if not found then
        table.insert(missing, lang)
      end
    end

    if #missing > 0 then
      print("Missing parsers: " .. table.concat(missing, ", "))
      require("nvim-treesitter").install(missing)
    end

    vim.api.nvim_create_autocmd("FileType", {
      pattern = defaults.treesitter,
      callback = function()
        vim.treesitter.start()
        -- vim.opt.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
        -- vim.opt.foldmethod = 'expr'
        -- vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
      end,
    })
  end,
}

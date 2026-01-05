---@class avim.defaults
---@field version string
---@field ui table
---@field servers table<string>
---@field packages table<string>
---@field rocks table<string>
---@field treesitter table<string>
---@field tools table<string>
---@field options table
---@field log table
---@field mappings table
local M = {}

M.version = "v4.1.0"

---- UI -----
M.ui = {
  transparency = false,
  background = "dark",
  fonts = "JetBrainsMono NF:h10",
  list = false,
}

M.servers = {
  "basedpyright",
  "bashls",
  "cssls",
  "docker_compose_language_service",
  "dockerls",
  "dotls",
  "elixirls",
  "emmet_language_server",
  "gopls",
  "html",
  "intelephense",
  "jsonls",
  "lua_ls",
  "marksman",
  "ruff",
  "svelte",
  "sqlls",
  "tailwindcss",
  "templ",
  -- "vectorcode_server",
  "vue_ls",
  "vtsls",
  "yamlls",
}

M.packages = {
  "eslint_d",
  "goimports-reviser",
  "golines",
  "gomodifytags",
  "iferr",
  "impl",
  "jq",
  "selene",
  "prettierd",
  "revive",
  "roslyn",
  -- "rzls", -- Deprecated: Razor support now in roslyn.nvim via cohosting
  "shellcheck",
  "shfmt",
  "stylua",
}

M.rocks = { "lua-curl", "nvim-nio", "mimetypes", "xml2lua", "magick" }

-- Trimmed to essential languages for better performance
-- Additional parsers will be auto-installed on demand if auto_install is enabled
M.treesitter = {
  -- Core languages
  "bash",
  "c",
  "c_sharp",
  "css",
  "dart",
  "dockerfile",
  "elixir",
  "go",
  "gomod",
  "gosum",
  "html",
  "javascript",
  "json",
  "jsonc",
  "lua",
  "luadoc",
  "markdown",
  "markdown_inline",
  "python",
  "rust",
  "scss",
  "sql",
  "svelte",
  "tsx",
  "typescript",
  "vim",
  "vimdoc",
  "vue",
  "xml",
  "yaml",
  -- Git support
  "diff",
  "gitcommit",
  "gitignore",
  -- Query/config files
  "query",
  "regex",
  "toml",
  -- Template languages
  "templ",
  "heex",
}

M.tools = require("avim.utilities").table_merge(M.packages, M.servers)

M.log = {
  ---@usage can be { "trace", "debug", "info", "warn", "error", "fatal" },
  level = "warn",
  viewer = {
    ---@usage this will fallback on "less +F" if not found
    cmd = "lnav",
    layout_config = {
      ---@usage direction = 'vertical' | 'horizontal' | 'window' | 'float',
      direction = "horizontal",
      open_mapping = "",
      size = 40,
      float_opts = {},
    },
  },
  -- currently disabled due to instabilities
  override_notify = false,
}

M.options = {
  undodir = require("avim.utilities").join_paths(require("avim.utilities").get_state_dir(), "undo"),
  sessiondir = require("avim.utilities").join_paths(require("avim.utilities").get_state_dir(), "sessions"),
  peek = {
    max_height = 15,
    max_width = 30,
    context = 10,
  },
  diagnostics = true,
}

M.mappings = {}

return M

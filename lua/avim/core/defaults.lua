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

M.version = "v3.0.0"

---- UI -----
M.ui = {
  transparency = false,
  background = "dark",
  fonts = "JetBrainsMono NF:h10",
  list = false,
}

M.servers = {
  -- "astro",
  "basedpyright",
  "bashls",
  "cssls",
  -- "denols",
  "docker_compose_language_service",
  "dockerls",
  "dotls",
  "elixirls",
  "emmet_language_server",
  -- "eslint",
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
  "volar",
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
  "shellcheck",
  "shfmt",
  "stylua",
}

M.rocks = { "lua-curl", "nvim-nio", "mimetypes", "xml2lua", "magick" }

M.treesitter = {
  "astro",
  "bash",
  "c",
  "c_sharp",
  "cmake",
  "comment",
  "cpp",
  "css",
  "csv",
  "dart",
  "diff",
  "dockerfile",
  "dot",
  "eex",
  "elixir",
  "erlang",
  "fennel",
  "fish",
  "git_config",
  "git_rebase",
  "gitcommit",
  "gitignore",
  "gleam",
  "go",
  "gomod",
  "gosum",
  "gotmpl",
  "gowork",
  "graphql",
  "heex",
  "html",
  "http",
  "hyprlang",
  "ini",
  "java",
  "javascript",
  "jsdoc",
  "json",
  "jsonc",
  "json5",
  "julia",
  "lua",
  "luadoc",
  "make",
  "markdown",
  "markdown_inline",
  "meson",
  "ninja",
  "nix",
  "php",
  "phpdoc",
  "prisma",
  "proto",
  "python",
  "query",
  "rasi",
  "regex",
  "requirements",
  "rust",
  "scss",
  "svelte",
  "sxhkdrc",
  "ssh_config",
  "sql",
  "templ",
  "tmux",
  "toml",
  "tsv",
  "tsx",
  "typescript",
  "udev",
  "v",
  "vim",
  "vimdoc",
  "vue",
  "xml",
  "yaml",
  "yuck",
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

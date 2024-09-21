local M = {}

M.version = "v2.0.0"

---- UI -----
M.ui = {
  cheat_theme = "grid", -- "simple/grid"
  transparency = false,
  background = "dark",
  fonts = "JetBrainsMono NF:h10",
  list = false,
}

M.servers = {
  "astro",
  "basedpyright",
  "bashls",
  "cssls",
  -- "denols",
  "docker_compose_language_service",
  "dockerls",
  "dotls",
  "elixirls",
  "emmet_language_server",
  "eslint",
  "gopls",
  "graphql",
  "html",
  "intelephense",
  "jsonls",
  "lua_ls",
  "marksman",
  -- "pyright",
  "ruff",
  -- "ruff_lsp",
  "sourcery",
  "svelte",
  "sqlls",
  "tailwindcss",
  "templ",
  -- "tsserver",
  "volar",
  "vtsls",
  "yamlls",
}

M.packages = {
  -- "autopep8",
  -- "eslint_d",
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
  "wsgl",
  "xml",
  "yaml",
  "yuck",
}

M.tools = require("avim.utils").table_merge(M.packages, M.servers)

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
  undodir = require("avim.utils").join_paths(require("avim.utils").get_state_dir(), "undo"),
  sessiondir = require("avim.utils").join_paths(require("avim.utils").get_state_dir(), "sessions"),
  peek = {
    max_height = 15,
    max_width = 30,
    context = 10,
  },
  diagnostics = true,
}

M.bufferDimNSId = vim.api.nvim_create_namespace("buffer-dim")
M.disableAutoMaximize = false

M.mappings = {}

return M

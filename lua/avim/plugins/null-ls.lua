local M = {
  -- "jose-elias-alvarez/null-ls.nvim",
  "nvimtools/none-ls.nvim",
  event = "BufReadPre",
  dependencies = { "nvim-lua/plenary.nvim" },
}

function M.config()
  local null_ls = require("null-ls")
  local b = null_ls.builtins

  local sources = {
    -- Diagnostics
    b.diagnostics.selene,
    -- b.diagnostics.luacheck.with({ extra_args = { "--global vim" } }),
    -- b.diagnostics.shellcheck.with({ diagnostics_format = "#{m} [#{c}]" }),
    b.diagnostics.markdownlint,
    -- b.diagnostics.php,
    b.diagnostics.todo_comments,
    b.diagnostics.revive,
    -- b.diagnostics.tsc,
    -- b.diagnostics.eslint_d,
    -- Formatting
    b.formatting.stylua,
    b.formatting.shfmt,
    -- b.formatting.autopep8,
    b.formatting.black,
    b.formatting.dart_format,
    b.formatting.gofmt,
    b.formatting.goimports_reviser,
    b.formatting.golines,
    b.formatting.tidy,
    b.formatting.isort,
    -- b.formatting.jq,
    b.formatting.prettierd.with({
      env = {
        PRETTIERD_DEFAULT_CONFIG = vim.fn.expand(_G.get_avim_base_dir() .. "/.configs/formatters/.prettierrc.json"),
      },
    }),
    -- b.formatting.prettierd.with { filetypes = { "html", "markdown", "css" } },
    -- b.formatting.deno_fmt,
    -- b.formatting.markdownlint,
    -- b.formatting.eslint_d,
    -- Code Actions
    b.code_actions.gitsigns,
    b.code_actions.refactoring,
    -- b.code_actions.eslint_d,
    -- Hover
    b.hover.dictionary,
    b.hover.printenv,
  }

  -- if you want to set up formatting on save, you can use this as a callback
  local augroup = vim.api.nvim_create_augroup("LspFormatting", {})

  local options = {
    debug = true,
    sources = sources,

    -- format on save
    on_attach = function(client, bufnr)
      if client.server_capabilities.documentFormattingProvider then
        vim.api.nvim_clear_autocmds({ group = augroup, buffer = bufnr })
        vim.api.nvim_create_autocmd("BufWritePre", {
          group = augroup,
          buffer = bufnr,
          callback = function()
            require("avim.utils").format(bufnr)
          end,
        })
      end
    end,
  }

  null_ls.setup(options)
end

return M

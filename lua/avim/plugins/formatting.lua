local features = require("avim.core.defaults").features

return {
  {
    "nvimtools/none-ls.nvim",
    enabled = features.formatting,
    event = "BufReadPre",
    dependencies = { "nvim-lua/plenary.nvim", "nvimtools/none-ls-extras.nvim" },
    config = function()
      local null_ls = require("null-ls")
      local b = null_ls.builtins

      local sources = {
        -- Diagnostics
        b.diagnostics.selene,
        b.diagnostics.todo_comments.with({
          disabled_filetypes = { "NvimTree", "neo-tree" },
        }),
        b.diagnostics.revive,
        -- Formatting
        b.formatting.stylua,
        b.formatting.shfmt,
        -- b.formatting.black,
        b.formatting.dart_format,
        b.formatting.gofmt,
        b.formatting.goimports_reviser.with({
          extra_args = { "-set-alias" },
        }),
        b.formatting.golines,
        b.formatting.tidy,
        -- b.formatting.isort,
        b.formatting.prettierd.with({
          env = {
            PRETTIERD_DEFAULT_CONFIG = vim.fn.expand(_G.get_avim_base_dir() .. "/.configs/formatters/.prettierrc.json"),
          },
        }),
        -- b.formatting.prettierd.with { filetypes = { "html", "markdown", "css" } },
        -- b.formatting.deno_fmt.with({
        --   condition = function(utils)
        --     return utils.root_has_file({ "deno.json", "deno.jsonc" })
        --   end,
        -- }),
        -- Code Actions
        b.code_actions.gomodifytags,
        b.code_actions.impl,
        b.code_actions.gitsigns.with({
          disabled_filetypes = { "NvimTree", "neo-tree" },
        }),
        b.code_actions.refactoring,
        -- Hover
        b.hover.dictionary,
        b.hover.printenv,
      }

      -- if you want to set up formatting on save, you can use this as a callback
      local augroup = vim.api.nvim_create_augroup("LspFormatting", {})

      local options = {
        debug = false,
        cmd = { "avim" },
        diagnostics_format = "[#{c}] #{m} (#{s})",
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
    end,
  },
  {
    "ThePrimeagen/refactoring.nvim",
    enabled = features.formatting,
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
    },
    config = true,
  },
}

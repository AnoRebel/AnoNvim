---@class avim.lsp.servers.common
---@field get_config fun(server_name: string, opts: table): table|nil
local M = {}

---Get common server configurations
---@param server_name string
---@param opts table
---@return table|nil
function M.get_config(server_name, opts)
  local on_attach = opts.on_attach
  local capabilities = opts.capabilities

  local configs = {
    basedpyright = {
      on_attach = on_attach,
      capabilities = capabilities,
      settings = {
        basedpyright = {
          disableOrganizeImports = true,
          typeCheckingMode = "standard",
        },
        pyright = {
          disableOrganizeImports = true,
          typeCheckingMode = "standard",
        },
        python = {
          analysis = {
            ignore = { "*" }, -- Use Ruff for linting
          },
        },
      },
    },

    ruff = {
      on_attach = function(client, bufnr)
        client.server_capabilities.hoverProvider = false
        on_attach(client, bufnr)
      end,
      capabilities = capabilities,
    },

    elixirls = {
      cmd = { _G.get_runtime_dir() .. "/mason/packages/elixir-ls/language_server.sh" },
      on_attach = on_attach,
      capabilities = capabilities,
      filetypes = { "elixir", "eelixir", "heex", "surface", "exs" },
    },

    emmet_language_server = {
      on_attach = on_attach,
      capabilities = capabilities,
      init_options = {
        showAbbreviationSuggestions = true,
        showExpandedAbbreviation = "always",
        showSuggestionsAsSnippets = true,
      },
      filetypes = {
        "html",
        "css",
        "scss",
        "htmldjango",
        "sass",
        "javascriptreact",
        "typescriptreact",
        "vue",
        "svelte",
        "astro",
      },
    },

    eslint = {
      settings = {
        workingDirectories = { mode = "auto" },
        experimental = {
          useFlatConfig = true,
        },
        useFlatConfig = true,
      },
      on_attach = on_attach,
      capabilities = capabilities,
    },

    gopls = {
      on_attach = function(client, bufnr)
        if not client.server_capabilities.semanticTokensProvider then
          local semantic = client.config.capabilities.textDocument.semanticTokens
          client.server_capabilities.semanticTokensProvider = {
            full = true,
            legend = {
              tokenTypes = semantic.tokenTypes,
              tokenModifiers = semantic.tokenModifiers,
            },
            range = true,
          }
        end
        on_attach(client, bufnr)
      end,
      capabilities = capabilities,
      settings = {
        gopls = {
          semanticTokens = true,
          completeUnimported = true,
          usePlaceholders = true,
          staticcheck = true,
          analyses = {
            fieldalignment = true,
            nilness = true,
            unusedparams = true,
            unusedwrite = true,
            useany = true,
          },
          codelenses = {
            gc_details = false,
            generate = true,
            regenerate_cgo = true,
            run_govulncheck = true,
            test = true,
            tidy = true,
            upgrade_dependency = true,
            vendor = true,
          },
          hints = {
            assignVariableTypes = true,
            compositeLiteralFields = true,
            compositeLiteralTypes = true,
            constantValues = true,
            functionTypeParameters = true,
            parameterNames = true,
            rangeVariableTypes = true,
          },
        },
      },
    },

    jsonls = {
      on_attach = function(client, bufnr)
        client.server_capabilities.documentFormattingProvider = false
        client.server_capabilities.documentRangeFormattingProvider = false
        on_attach(client, bufnr)
      end,
      capabilities = capabilities,
      settings = {
        json = {
          schemas = require("schemastore").json.schemas(),
          format = {
            enable = true,
          },
          validate = { enable = true },
        },
      },
    },

    lua_ls = {
      on_attach = on_attach,
      capabilities = capabilities,
      settings = {
        Lua = {
          workspace = {
            checkThirdParty = false,
            library = {
              "${3rd}/luv/library",
              vim.env.VIMRUNTIME,
            },
          },
          codeLens = {
            enable = true,
          },
          completion = {
            callSnippet = "Replace",
          },
          doc = {
            privateName = { "^_" },
          },
          hint = {
            enable = true,
            setType = false,
            paramType = true,
            paramName = "Disable",
            semicolon = "Disable",
            arrayIndex = "Disable",
          },
        },
      },
    },

    tailwindcss = {
      capabilities = vim.tbl_deep_extend("force", capabilities, {
        textDocument = {
          colorProvider = { dynamicRegistration = false },
        },
      }),
      on_attach = on_attach,
      settings = {
        tailwindCSS = {
          emmetCompletions = true,
          includeLanguages = {
            elixir = "html-eex",
            eelixir = "html-eex",
            heex = "html-eex",
          },
        },
      },
    },
  }

  return configs[server_name]
end

return M

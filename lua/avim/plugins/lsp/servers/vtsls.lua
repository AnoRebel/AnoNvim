---@class avim.lsp.servers.vtsls
---@field setup fun(opts: table): table
local M = {}

local lsp_utils = require("avim.utilities.lsp")

---Get VTSLS (TypeScript) server configuration
---@param opts table
---@return table
function M.setup(opts)
  local on_attach = opts.on_attach
  local capabilities = opts.capabilities

  return {
    capabilities = capabilities,
    on_attach = function(client, bufnr)
      -- Disable formatting to save memory
      client.server_capabilities.documentFormattingProvider = false
      client.server_capabilities.documentRangeFormattingProvider = false
      lsp_utils.move_to_file_refactor(client, bufnr)
      on_attach(client, bufnr)
    end,
    filetypes = {
      "typescript",
      "javascript",
      "javascriptreact",
      "typescriptreact",
      "javascript.jsx",
      "typescript.tsx",
      "vue",
    },
    settings = {
      complete_function_calls = true,
      vtsls = {
        tsserver = {
          globalPlugins = {
            {
              name = "@vue/typescript-plugin",
              location = lsp_utils.get_pkg_path("vue-language-server", "/node_modules/@vue/language-server"),
              languages = { "vue" },
              configNamespace = "typescript",
              enableForWorkspaceTypeScriptVersions = true,
            },
            {
              name = "typescript-svelte-plugin",
              location = lsp_utils.get_pkg_path(
                "svelte-language-server",
                "/node_modules/typescript-svelte-plugin"
              ),
              enableForWorkspaceTypeScriptVersions = true,
            },
          },
          -- Memory optimizations
          maxTsServerMemory = 4096, -- Limit to 4GB
        },
        enableMoveToFileCodeAction = true,
        autoUseWorkspaceTsdk = true,
        experimental = {
          maxInlayHintLength = 20, -- Reduced from 30 for memory
          completion = {
            enableServerSideFuzzyMatch = false, -- Disabled for memory
          },
        },
      },
      javascript = {
        updateImportsOnFileMove = { enabled = "always" },
        suggest = {
          completeFunctionCalls = true,
        },
        inlayHints = {
          enumMemberValues = { enabled = false }, -- Disabled for memory
          functionLikeReturnTypes = { enabled = false }, -- Disabled for memory
          parameterNames = { enabled = "none" }, -- Disabled for memory
          parameterTypes = { enabled = false }, -- Disabled for memory
          propertyDeclarationTypes = { enabled = false }, -- Disabled for memory
          variableTypes = { enabled = false },
        },
      },
      typescript = {
        tsserver = {
          pluginPaths = {
            lsp_utils.get_pkg_path("vue-language-server", "node_modules/@vue/language-server"),
            lsp_utils.get_pkg_path("svelte-language-server", "/node_modules/typescript-svelte-plugin"),
          },
        },
        -- Memory optimizations
        disableAutomaticTypeAcquisition = true, -- Disable automatic @types downloads
        updateImportsOnFileMove = { enabled = "always" },
        suggest = {
          completeFunctionCalls = true,
        },
        inlayHints = {
          parameterNames = { enabled = "none" }, -- Disabled for memory
          parameterTypes = { enabled = false }, -- Disabled for memory
          variableTypes = { enabled = false }, -- Disabled for memory
          propertyDeclarationTypes = { enabled = false }, -- Disabled for memory
          functionLikeReturnTypes = { enabled = false }, -- Disabled for memory
          enumMemberValues = { enabled = false }, -- Disabled for memory
        },
        format = {
          indentSize = vim.o.shiftwidth,
          convertTabsToSpaces = vim.o.expandtab,
          tabSize = vim.o.tabstop,
        },
      },
    },
  }
end

return M

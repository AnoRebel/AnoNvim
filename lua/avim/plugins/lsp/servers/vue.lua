---@class avim.lsp.servers.vue
---@field setup fun(opts: table): table
local M = {}

---Get Vue Language Server configuration
---@param opts table
---@return table
function M.setup(opts)
  local on_attach = opts.on_attach
  local capabilities = opts.capabilities

  return {
    on_attach = function(client, bufnr)
      -- Disable formatting to reduce memory usage
      client.server_capabilities.documentFormattingProvider = false
      client.server_capabilities.documentRangeFormattingProvider = false
      on_attach(client, bufnr)
    end,
    capabilities = capabilities,
    filetypes = { "vue" },
    init_options = {
      vue = {
        hybridMode = true, -- Use TypeScript plugin for better performance
      },
      documentFeatures = {
        documentColor = false, -- Disable for memory optimization
      },
      languageFeatures = {
        semanticTokens = false, -- Disable for memory optimization
        -- Only enable essential features
        completion = {
          defaultTagNameCase = "both",
          defaultAttrNameCase = "kebabCase",
        },
      },
    },
    settings = {
      completeFunctionCalls = true,
    },
  }
end

return M

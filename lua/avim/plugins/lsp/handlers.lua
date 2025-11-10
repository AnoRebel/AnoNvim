---@class avim.lsp.handlers
---@field setup fun(): nil
local M = {}

---Setup LSP handlers
function M.setup()
  local lsp = vim.lsp

  -- Hover handler with rounded border
  lsp.handlers["textDocument/hover"] = function(_, result, ctx, config)
    if not (result and result.contents) then
      return
    end
    config = config or {}
    config.border = "rounded"
    lsp.handlers.hover(_, result, ctx, config)
  end

  -- Signature help handler with rounded border
  lsp.handlers["textDocument/signatureHelp"] = lsp.with(lsp.handlers.signature_help, {
    border = "rounded",
  })

  -- Diagnostics handler with TypeScript error translation
  lsp.handlers["textDocument/publishDiagnostics"] = function(err, result, ctx, config)
    local ts_lsp = { "deno", "vtsls", "volar", "vue_ls", "svelte", "astro" }
    local clients = lsp.get_clients({ id = ctx.client_id })

    if #clients > 0 and vim.tbl_contains(ts_lsp, clients[1].name) then
      -- Filter to only show errors for TypeScript servers to reduce noise
      local filtered_result = {
        diagnostics = vim.tbl_filter(function(d)
          return d.severity == 1
        end, result.diagnostics),
      }
      require("ts-error-translator").translate_diagnostics(err, filtered_result, ctx, config)
    end

    vim.lsp.diagnostic.on_publish_diagnostics(err, result, ctx, config)
  end
end

return M

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

  -- Diagnostics handler with filtering for noisy servers
  -- Note: ts-error-translator now uses auto_attach for translation (configured in lsp.lua)
  lsp.handlers["textDocument/publishDiagnostics"] = function(err, result, ctx, config)
    -- Just use the default handler - ts-error-translator handles translation via auto_attach
    vim.lsp.diagnostic.on_publish_diagnostics(err, result, ctx, config)
  end
end

return M

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
end

return M

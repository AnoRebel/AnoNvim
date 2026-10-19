---@class avim.lsp.handlers
---@field setup fun(): nil
local M = {}
local defaults = require("avim.core.defaults")

---Setup LSP handlers
function M.setup()
  local lsp = vim.lsp

  -- Hover handler with rounded border
  lsp.handlers["textDocument/hover"] = function(_, result, ctx, config)
    if not (result and result.contents) then
      return
    end
    config = config or {}
    config.border = defaults.ui.border
    lsp.handlers.hover(_, result, ctx, config)
  end

  -- Signature help handler with rounded border
  lsp.handlers["textDocument/signatureHelp"] = function(_, result, ctx, config)
    config = config or {}
    config.border = defaults.ui.border
    return lsp.handlers.signature_help(_, result, ctx, config)
  end
end

return M

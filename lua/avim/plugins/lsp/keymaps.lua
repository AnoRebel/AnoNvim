---@class avim.lsp.keymaps
---@field setup fun(client: table, bufnr: number): nil
local M = {}

local utilities = require("avim.utilities")
local lsp_utils = require("avim.utilities.lsp")

---Setup LSP keymaps for the given buffer
---@param client table LSP client
---@param bufnr number Buffer number
function M.setup(client, bufnr)
  local lsp = vim.lsp

  -- TypeScript-like filetypes
  local ts_fts = {
    "typescript",
    "javascript",
    "javascriptreact",
    "typescriptreact",
    "vue",
  }

  -- General LSP keymaps (buffer-local)
  utilities.map("n", "<leader>l", "<cmd>LspInfo<cr>", { desc = "Lsp Info", buffer = bufnr })

  if lsp_utils.has(bufnr, "signatureHelp") then
    utilities.map("i", "<c-k>", lsp.buf.signature_help, { desc = "Signature Help", buffer = bufnr })
    utilities.map("n", "gk", lsp.buf.signature_help, { desc = "Signature Help", buffer = bufnr })
  end

  utilities.map("n", "<leader>D", lsp.buf.type_definition, { desc = "Type Definitions", buffer = bufnr })

  if lsp_utils.has(bufnr, "codeAction") then
    utilities.map(
      { "n", "v" },
      "<leader>ca",
      "<cmd>lua require('actions-preview').code_actions()<CR>",
      { desc = "Code Actions", buffer = bufnr }
    )
  end

  -- Diagnostics (buffer-local)
  utilities.map("n", "ge", vim.diagnostic.open_float, { desc = "Floating Diagnostics", buffer = bufnr })
  utilities.map("n", "gF", "<cmd>lua Snacks.picker.diagnostics()<CR>", { desc = "Snacks Diagnostics", buffer = bufnr })
  utilities.map("n", "[d", vim.diagnostic.goto_prev, { desc = "Previous Diagnostics", buffer = bufnr })
  utilities.map("n", "]d", vim.diagnostic.goto_next, { desc = "Next Diagnostics", buffer = bufnr })

  -- Formatting (buffer-local)
  utilities.map("n", "<leader>cf", function()
    lsp.buf.format({ timeout_ms = 3000 })
  end, { desc = "Format Document", buffer = bufnr })

  if lsp_utils.has(bufnr, "codeLens") then
    utilities.map({ "n", "v" }, "<leader>cc", lsp.codelens.run, { desc = "Run Codelens", buffer = bufnr })
  end

  -- Elixir-specific keymaps (buffer-local)
  if lsp_utils.is_enabled("elixirls") then
    utilities.map("n", "<leader>cp", function()
      local params = lsp.util.make_position_params()
      lsp_utils.execute({
        command = "manipulatePipes:serverid",
        arguments = { "toPipe", params.textDocument.uri, params.position.line, params.position.character },
      })
    end, { desc = "To Pipe", buffer = bufnr })

    utilities.map("n", "<leader>cP", function()
      local params = lsp.util.make_position_params()
      lsp_utils.execute({
        command = "manipulatePipes:serverid",
        arguments = { "fromPipe", params.textDocument.uri, params.position.line, params.position.character },
      })
    end, { desc = "From Pipe", buffer = bufnr })
  end

  -- TypeScript-specific keymaps (buffer-local)
  if vim.tbl_contains(ts_fts, vim.bo[bufnr].filetype) then
    utilities.map("n", "gD", function()
      local params = lsp.util.make_position_params()
      lsp_utils.execute({
        command = "typescript.goToSourceDefinition",
        arguments = { params.textDocument.uri, params.position },
        open = true,
      })
    end, { desc = "Goto Source Definition", buffer = bufnr })

    utilities.map("n", "gR", function()
      lsp_utils.execute({
        command = "typescript.findAllFileReferences",
        arguments = { vim.uri_from_bufnr(0) },
        open = true,
      })
    end, { desc = "File References", buffer = bufnr })

    utilities.map("n", "<leader>co", lsp_utils.action["source.organizeImports"], { desc = "Organize Imports", buffer = bufnr })
    utilities.map("n", "<leader>cM", lsp_utils.action["source.addMissingImports.ts"], { desc = "Add missing imports", buffer = bufnr })
    utilities.map("n", "<leader>cu", lsp_utils.action["source.removeUnused.ts"], { desc = "Remove unused imports", buffer = bufnr })
    utilities.map("n", "<leader>cD", lsp_utils.action["source.fixAll.ts"], { desc = "Fix all diagnostics", buffer = bufnr })
    utilities.map("n", "<leader>cV", function()
      lsp_utils.execute({ command = "typescript.selectTypeScriptVersion" })
    end, { desc = "Select TS workspace version", buffer = bufnr })
  end

  -- Goto keymaps (buffer-local)
  utilities.map("n", "g", nil, { name = "goto", buffer = bufnr })

  if lsp_utils.has(bufnr, "definition") then
    utilities.map("n", "gd", lsp.buf.definition, { desc = "Goto Definition", buffer = bufnr })
  end

  utilities.map("n", "gr", lsp.buf.references, { desc = "References", nowait = true, buffer = bufnr })
  utilities.map("n", "gi", lsp.buf.implementation, { desc = "Goto Implementation", buffer = bufnr })
  utilities.map("n", "gI", Snacks.picker.lsp_implementations, { desc = "Snack Implementation", buffer = bufnr })
  utilities.map("n", "gy", lsp.buf.type_definition, { desc = "Goto T[y]pe Definition", buffer = bufnr })

  -- Note: gD is overridden for TypeScript above, but we need a fallback for other languages
  if not vim.tbl_contains(ts_fts, vim.bo[bufnr].filetype) then
    utilities.map("n", "gD", lsp.buf.declaration, { desc = "Goto Declaration", buffer = bufnr })
  end

  if lsp_utils.has(bufnr, "rename") then
    utilities.map("n", "<leader>cr", lsp.buf.rename, { desc = "Rename", buffer = bufnr })
  end

  -- Peek keymaps (buffer-local)
  utilities.map("n", "gp", nil, { name = "󰍉 Peek", buffer = bufnr })
  utilities.map(
    "n",
    "gpd",
    "<cmd>lua require('avim.utilities.peek').Peek('definition')<CR>",
    { desc = "[Peek] Definition(s)", buffer = bufnr }
  )
  utilities.map(
    "n",
    "gpt",
    "<cmd>lua require('avim.utilities.peek').Peek('typeDefinition')<CR>",
    { desc = "[Peek] Type Definition(s)", buffer = bufnr }
  )
  utilities.map(
    "n",
    "gpI",
    "<cmd>lua require('avim.utilities.peek').Peek('implementation')<CR>",
    { desc = "[Peek] Implementation(s)", buffer = bufnr }
  )
end

return M

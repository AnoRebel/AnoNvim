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

  -- General LSP keymaps
  utilities.map("n", "<leader>l", "<cmd>LspInfo<cr>", { desc = "Lsp Info" })

  if lsp_utils.has(bufnr, "signatureHelp") then
    utilities.map("i", "<c-k>", lsp.buf.signature_help, { desc = "Signature Help" })
    utilities.map("n", "gk", lsp.buf.signature_help, { desc = "Signature Help" })
  end

  utilities.map("n", "<leader>D", lsp.buf.type_definition, { desc = "Type Definitions" })

  if lsp_utils.has(bufnr, "codeAction") then
    utilities.map(
      { "n", "v" },
      "<leader>ca",
      "<cmd>lua require('actions-preview').code_actions()<CR>",
      { desc = "Code Actions" }
    )
  end

  -- Diagnostics
  utilities.map("n", "ge", vim.diagnostic.open_float, { desc = "Floating Diagnostics" })
  utilities.map("n", "gF", "<cmd>lua Snacks.picker.diagnostics()<CR>", { desc = "Snacks Diagnostics" })
  utilities.map("n", "[d", vim.diagnostic.goto_prev, { desc = "Previous Diagnostics" })
  utilities.map("n", "]d", vim.diagnostic.goto_next, { desc = "Next Diagnostics" })

  -- Formatting
  utilities.map("n", "<leader>cf", function()
    lsp.buf.format({ timeout_ms = 3000 })
  end, { desc = "Format Document" })

  if lsp_utils.has(bufnr, "codeLens") then
    utilities.map({ "n", "v" }, "<leader>cc", lsp.codelens.run, { desc = "Run Codelens" })
  end

  -- Elixir-specific keymaps
  if lsp_utils.is_enabled("elixirls") then
    utilities.map("n", "<leader>cp", function()
      local params = lsp.util.make_position_params()
      lsp_utils.execute({
        command = "manipulatePipes:serverid",
        arguments = { "toPipe", params.textDocument.uri, params.position.line, params.position.character },
      })
    end, { desc = "To Pipe" })

    utilities.map("n", "<leader>cP", function()
      local params = lsp.util.make_position_params()
      lsp_utils.execute({
        command = "manipulatePipes:serverid",
        arguments = { "fromPipe", params.textDocument.uri, params.position.line, params.position.character },
      })
    end, { desc = "From Pipe" })
  end

  -- TypeScript-specific keymaps
  if vim.tbl_contains(ts_fts, vim.bo.filetype) then
    utilities.map("n", "gD", function()
      local params = lsp.util.make_position_params()
      lsp_utils.execute({
        command = "typescript.goToSourceDefinition",
        arguments = { params.textDocument.uri, params.position },
        open = true,
      })
    end, { desc = "Goto Source Definition" })

    utilities.map("n", "gR", function()
      lsp_utils.execute({
        command = "typescript.findAllFileReferences",
        arguments = { vim.uri_from_bufnr(0) },
        open = true,
      })
    end, { desc = "File References" })

    utilities.map("n", "<leader>co", lsp_utils.action["source.organizeImports"], { desc = "Organize Imports" })
    utilities.map("n", "<leader>cM", lsp_utils.action["source.addMissingImports.ts"], { desc = "Add missing imports" })
    utilities.map("n", "<leader>cu", lsp_utils.action["source.removeUnused.ts"], { desc = "Remove unused imports" })
    utilities.map("n", "<leader>cD", lsp_utils.action["source.fixAll.ts"], { desc = "Fix all diagnostics" })
    utilities.map("n", "<leader>cV", function()
      lsp_utils.execute({ command = "typescript.selectTypeScriptVersion" })
    end, { desc = "Select TS workspace version" })
  end

  -- Goto keymaps
  utilities.map("n", "g", nil, { name = "goto" })

  if lsp_utils.has(bufnr, "definition") then
    utilities.map("n", "gd", lsp.buf.definition, { desc = "Goto Definition" })
  end

  utilities.map("n", "gr", lsp.buf.references, { desc = "References", nowait = true })
  utilities.map("n", "gi", lsp.buf.implementation, { desc = "Goto Implementation" })
  utilities.map("n", "gI", Snacks.picker.lsp_implementations, { desc = "Snack Implementation" })
  utilities.map("n", "gy", lsp.buf.type_definition, { desc = "Goto T[y]pe Definition" })
  utilities.map("n", "gD", lsp.buf.declaration, { desc = "Goto Declaration" })

  if lsp_utils.has(bufnr, "rename") then
    utilities.map("n", "<leader>cr", lsp.buf.rename, { desc = "Rename" })
  end

  -- Peek keymaps
  utilities.map("n", "gp", nil, { name = "󰍉 Peek" })
  utilities.map(
    "n",
    "gpd",
    "<cmd>lua require('avim.utilities.peek').Peek('definition')<CR>",
    { desc = "[Peek] Definition(s)" }
  )
  utilities.map(
    "n",
    "<leader>gpt",
    "<cmd>lua require('avim.utilities.peek').Peek('typeDefinition')<CR>",
    { desc = "[Peek] Type Definition(s)" }
  )
  utilities.map(
    "n",
    "<leader>gpI",
    "<cmd>lua require('avim.utilities.peek').Peek('implementation')<CR>",
    { desc = "[Peek] Implementation(s)" }
  )
end

return M

---@class avim.utilities.snippet
---@field add_missing_snippet_docs fun(window: any)
---@field auto_brackets fun(entry: any): nil
---@field confirm fun(opts?: {select: boolean, behavior: any})
---@field expand fun(snippet: any)
---@field snippet_preview fun(snippet: string): string
local M = {}

---@alias Placeholder {n:number, text:string}

---@param snippet string
---@param fn fun(placeholder: Placeholder): string
---@return string
local function snippet_replace(snippet, fn)
  return snippet:gsub("%$%b{}", function(m)
    local n, name = m:match("^%${(%d+):(.+)}$")
    return n and fn({ n = n, text = name }) or m
  end) or snippet
end

-- This function resolves nested placeholders in a snippet.
---@param snippet string
---@return string
function M.snippet_preview(snippet)
  local ok, parsed = pcall(function()
    return vim.lsp._snippet_grammar.parse(snippet)
  end)
  return ok and tostring(parsed)
    or snippet_replace(snippet, function(placeholder)
      return M.snippet_preview(placeholder.text)
    end):gsub("%$0", "")
end

-- This function replaces nested placeholders in a snippet with LSP placeholders.
local function snippet_fix(snippet)
  local texts = {} ---@type table<number, string>
  return snippet_replace(snippet, function(placeholder)
    texts[placeholder.n] = texts[placeholder.n] or M.snippet_preview(placeholder.text)
    return "${" .. placeholder.n .. ":" .. texts[placeholder.n] .. "}"
  end)
end

---@param entry any blink.cmp entry
function M.auto_brackets(entry)
  local item = entry.completion_item or entry
  local kind = item.kind

  -- Check if it's a function or method (LSP CompletionItemKind values)
  if kind == 3 or kind == 2 then -- Function or Method
    local cursor = vim.api.nvim_win_get_cursor(0)
    local prev_char = vim.api.nvim_buf_get_text(0, cursor[1] - 1, cursor[2], cursor[1] - 1, cursor[2] + 1, {})[1]
    if prev_char ~= "(" and prev_char ~= ")" then
      local keys = vim.api.nvim_replace_termcodes("()<left>", false, false, true)
      vim.api.nvim_feedkeys(keys, "i", true)
    end
  end
end

-- Enhanced for blink.cmp - adds documentation to snippet items
---@param items table list of completion items
function M.add_missing_snippet_docs(items)
  for _, item in ipairs(items or {}) do
    if item.kind == 15 then -- Snippet kind
      if not item.documentation and item.insertText then
        item.documentation = {
          kind = "markdown",
          value = string.format("```%s\n%s\n```", vim.bo.filetype, M.snippet_preview(item.insertText)),
        }
      elseif not item.documentation and item.textEdit and item.textEdit.newText then
        item.documentation = {
          kind = "markdown",
          value = string.format("```%s\n%s\n```", vim.bo.filetype, M.snippet_preview(item.textEdit.newText)),
        }
      end
    end
  end
  return items
end

-- Enhanced confirm function for blink.cmp
---@param opts? {select: boolean, behavior: any}
function M.confirm(opts)
  opts = vim.tbl_extend("force", {
    select = true,
  }, opts or {})

  return function(fallback)
    local blink = require("blink.cmp")
    if blink.is_visible() then
      blink.accept(opts)
    else
      fallback()
    end
  end
end

-- Enhanced expand function with better error handling and session management
function M.expand(snippet)
  -- Native sessions don't support nested snippet sessions.
  -- Always use the top-level session.
  -- Otherwise, when on the first placeholder and selecting a new completion,
  -- the nested session will be used instead of the top-level session.
  local session = vim.snippet.active() and vim.snippet._session or nil

  local snip_ok, luasnip = pcall(require, "luasnip")
  local snip = snip_ok and luasnip.lsp_expand or vim.snippet.expand

  local ok, err = pcall(snip, snippet)
  if not ok then
    local fixed = snippet_fix(snippet)
    ok = pcall(snip, fixed)

    local msg = ok and "Failed to parse snippet,\nbut was able to fix it automatically."
      or ("Failed to parse snippet.\n" .. tostring(err))

    vim.notify(
      ([[%s
        ```%s
        %s
        ```]]):format(msg, vim.bo.filetype, snippet),
      ok and vim.log.levels.WARN or vim.log.levels.ERROR,
      { title = "vim.snippet" }
    )
  end

  -- Restore top-level session when needed
  if session then
    vim.snippet._session = session
  end
end

return M

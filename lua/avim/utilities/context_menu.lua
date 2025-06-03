---@class avim.utilities.context_menu
---@field buf_has_lsp fun(): boolean
---@field buf_has_dap fun(): boolean
---@field buf_is_package_json fun(): boolean
---@field buf_is_file fun(): boolean
---@field get_buf_size fun(): {width: number, height: number}
---@field uiselect_context_menu fun(prompt: string, strings: table[string], funcs: table[function]): nil
---@field clear_menu fun(menu: string): nil
---@field format_menu_label fun(label: string): string
---@field create_menu_entry fun(menu: string, label: string, action: string): nil
---@field rclick_context_menu fun(menu: string, label: string, action: string): nil
---@field set_rclick_submenu fun(menu_name: string, submenu_label: string, items: table[{string, string}], bindif: function?): nil
---@field set_doc_rclick_menu fun(): nil
---@field set_lsp_rclick_menu fun(): nil
---@field set_manager_rclick_menu fun(): nil
---@field set_explorer_rclick_menu fun(): nil
---@field set_picker_rclick_menu fun(): nil
---@field set_venv_rclick_menu fun(): nil
---@field set_git_rclick_menu fun(): nil
---@field set_diff_rclick_menu fun(): nil
---@field set_dap_rclick_menu fun(): nil
---@field setup_rclick_menu_autocommands fun(): nil
---@field set_rclick_menu fun(): nil
---@field set_rclick_menu_autocommands fun(): nil
---@field set_dap_rclick_menu_autocommands fun(): nil
---@field set_doc_rclick_menu_autocommands fun(): nil
---@field set_lsp_rclick_menu_autocommands fun(): nil
---@field set_manager_rclick_menu_autocommands fun(): nil
---@field set_explorer_rclick_menu_autocommands fun(): nil
---@field set_picker_rclick_menu_autocommands fun(): nil
---@field set_venv_rclick_menu_autocommands fun(): nil
---@field set_git_rclick_menu_autocommands fun(): nil
---@field set_diff_rclick_menu_autocommands fun(): nil
local M = {}
-- Copied from https://gitlab.com/gabmus/nvpunk/-/raw/master/lua/nvpunk/internals/context_menu.lua
local constants = require("avim.utilities.constants")

--- Checks if current buf has LSPs attached
---@return boolean
M.buf_has_lsp = function()
  return not vim.tbl_isempty(vim.lsp.get_clients({ bufnr = vim.api.nvim_get_current_buf() }))
end

--- Checks if current buf is package.json
---@return boolean
M.buf_is_package_json = function()
  local bufnr = vim.api.nvim_get_current_buf()
  local bufname = vim.api.nvim_buf_get_name(bufnr)
  local filename = vim.fn.fnamemodify(bufname, ":t")
  return filename == "package.json"
end

--- Get current buffer size
---@return {width: number, height: number}
M.get_buf_size = function()
  local cbuf = vim.api.nvim_get_current_buf()
  local bufinfo = vim.tbl_filter(function(buf)
    return buf.bufnr == cbuf
  end, vim.fn.getwininfo(vim.api.nvim_get_current_win()))[1]
  if bufinfo == nil then
    return { width = -1, height = -1 }
  end
  return { width = bufinfo.width, height = bufinfo.height }
end

--- Checks if current buf is a file
---@return boolean
M.buf_is_file = function()
  return not vim.tbl_contains(constants.nonfile_bufs, vim.bo.filetype)
end

--- Checks if current buf has DAP support
---@return boolean
M.buf_has_dap = function()
  return M.buf_is_file()
end

--- Create a context menu
---@deprecated
---@param prompt string
---@param strings table[string]
---@param funcs table[function]
M.uiselect_context_menu = function(prompt, strings, funcs)
  vim.ui.select(strings, { prompt = prompt }, function(_, idx)
    vim.schedule(funcs[idx])
  end)
end

-- TODO: Add menu for visual mode
local MODES = { "i", "n" }

--- Clear all entries from the given menu
---@param menu string
M.clear_menu = function(menu)
  pcall(function()
    vim.cmd("aunmenu " .. menu)
  end)
end

--- Formats the label of a menu entry to avoid errors
---@param label string
---@return string
M.format_menu_label = function(label)
  local res = string.gsub(label, " ", [[\ ]])
  res = string.gsub(res, "<", [[\<]])
  res = string.gsub(res, ">", [[\>]])
  return res
end

--- Create an entry for the right click menu
---@param menu string
---@param label string
---@param action string
M.rclick_context_menu = function(menu, label, action)
  for _, m in ipairs(MODES) do
    vim.cmd(m .. "menu " .. menu .. "." .. M.format_menu_label(label) .. " " .. action)
  end
end

--- Set up a right click submenu
---@param menu_name string
---@param submenu_label string
---@param items table[{string, string}]
---@param bindif function?
M.set_rclick_submenu = function(menu_name, submenu_label, items, bindif)
  M.clear_menu(menu_name)
  M.clear_menu("PopUp." .. M.format_menu_label(submenu_label))
  if bindif ~= nil then
    if not bindif() then
      return
    end
  end
  for _, i in ipairs(items) do
    M.rclick_context_menu(menu_name, i[1], i[2])
  end
  M.rclick_context_menu("PopUp", submenu_label, "<cmd>popup " .. menu_name .. "<cr>")
end

M.set_doc_rclick_menu = function()
  M.set_rclick_submenu("AvimDocMenu", "Document      ", {
    { "Copy Line        ", "<Esc>yy" },
    { "Copy Page        ", "<C-a>y" },
    { "Cut              ", "<Esc><S-v>x" },
    { "Cut Page         ", "<C-c>x" },
    { "Paste Above      ", "<Esc>P" },
    { "Paste Below      ", "<Esc>p" },
    { "Undo             ", "<Esc>u" },
    { "Redo             ", "<C-r>" },
    { "Repeat Action    ", "." },
    { "Comment Line     ", "<Esc><C-/>" },
    { "Search File      ", "<Esc>/" },
    { "Search Word      ", "<Esc><space>fw" },
    { "Search Project   ", "<Esc><space>fa" },
    { "Delete           ", "<Esc>dd" },
    { "Select All       ", "<C-c>" },
    { "Format           ", "<Esc><space>cf" },
    { "Files            ", "<C-n>" },
    { "Right Terminal   ", "<Esc><space>tr" },
    { "Bottom Terminal  ", "<Esc><space>tb" },
    { "Save             ", "<C-s>" },
    { "Close            ", "<Esc><space>q" },
    { "Quit             ", "<C-q>" },
  })
end

M.set_lsp_rclick_menu = function()
  M.set_rclick_submenu("AvimLspMenu", "LSP        ", {
    { "Code Actions           <space>la", "<space>la" },
    { "Code Lens              <space>ll", "<space>ll" },
    { "Go to Declaration             gD", "gD" },
    { "Go to Definition              gd", "gd" },
    { "Go to File                    gf", "gf" },
    { "Go to Implementation          gI", "gI" },
    { "Signature Help                gk", "gk" },
    { "Rename                 <space>ra", "<space>ra" },
    { "Float Diagnostics             gF", "gF" },
    { "References                    gr", "gr" },
    { "Expand Diagnostics            ge", "ge" },
    { "Format                 <space>lm", "<space>lm" },
  }, M.buf_has_lsp)
end

M.set_dap_rclick_menu = function()
  M.set_rclick_submenu("AvimDapMenu", "Debug    ", {
    { "Show DAP UI           <space>bu", "<space>bu" },
    { "Toggle Breakpoint     <space>bb", "<space>bb" },
    { "Continue              <space>bc", "<space>bc" },
    { "Terminate             <space>bk", "<space>bk" },
  }, M.buf_has_dap)
end

M.set_explorer_rclick_menu = function()
  M.set_rclick_submenu("AvimFileTreeMenu", "File        ", {
    { "New File/Folder            a", "a" },
    { "Rename                     r", "r" },
    { "Cut                        x", "x" },
    { "Copy                       c", "c" },
    { "Copy Name                  y", "y" },
    { "Copy Path                  Y", "Y" },
    { "Paste                      p", "p" },
    { "Edit                       o", "o" },
    { "Delete                     d", "d" },
    { "Trash                      D", "D" },
    { "Preview                <Tab>", "<Tab>" },
    { "Refresh                    R", "R" },
    { "Split Horizontally         h", "h" },
    { "Split Vertically           v", "v" },
    { "Search                     S", "S" },
    { "Find File                 tf", "tf" },
    { "Find Word                 tg", "tg" },
    { "Filter                     f", "f" },
    { "Show Hidden                H", "H" },
    { "File Info                  K", "K" },
  }, function()
    return vim.bo.filetype == "NvimTree" or vim.bo.filetype == "neo-tree"
  end)
end

M.set_manager_rclick_menu = function()
  M.set_rclick_submenu("AvimManagerMenu", "Manager    ", {
    { "Toggle treeview     Neotree", "Neotree source=filesystem action=focus position=left reveal=true toggle=true" },
    { "Toggle netrw        Neotree", "Neotree position=current toggle=true" },
    { "Toggle buffers      Neotree", "Neotree source=buffers action=focus position=right reveal=true toggle=true" },
    {
      "Toggle git status      Neotree",
      "Neotree source=git_status action=focus position=bottom reveal=true toggle=true",
    },
    {
      "Toggle document symbols      Neotree",
      "Neotree source=document_symbols action=focus position=right toggle=true",
    },
    { "Toggle previous     Neotree", "Neotree source=last toggle=true" },
    { "Toggle manager      Oil", "Oil" },
  })
end

M.set_picker_rclick_menu = function()
  M.set_rclick_submenu("AvimPickerMenu", "Picker   ", {
    { "Find File             <space>ff", "<space>ff" },
    { "All File              <space>fa", "<space>fa" },
    { "Live Grep             <space>fw", "<space>fw" },
    { "Recent Files          <space>fo", "<space>fo" },
    {
      "Git Status                     ",
      "<CMD>Snacks.picker.git_status()<CR>",
    },
    { "Git Commits           <space>fC", "<space>fC" },
    { "Buffers               <space>fb", "<space>fb" },
    { "Keymaps               <space>fk", "<space>fk" },
  })
end

M.set_git_rclick_menu = function()
  M.set_rclick_submenu("AvimGitMenu", "Git         ", {
    { "Preview Changes       <space>g?", "<space>g?" },
    { "Prev Hunk             <space>g[", "<space>g[" },
    { "Next Hunk             <space>g]", "<space>g]" },
    { "Blame Line            <space>gb", "<space>gb" },
    { "Git UI                <space>gl", "<space>gl" },
    { "Blame Line            <space>gb", "<space>gb" },
    { "Blame Code            <space>gm", "<space>gm" },
    { "Git Commits           <space>fC", "<space>fC" },
    {
      "Git Status                     ",
      "<CMD>Snacks.picker.git_status()<CR>",
    },
  }, M.buf_is_file)
end

M.set_diff_rclick_menu = function()
  M.set_rclick_submenu("AvimDiffMenu", "Diffview     ", {
    { "Open           <space>go", "<space>go" },
    { "Close          <space>gc", "<space>gc" },
    { "Refresh        <space>gr", "<space>gr" },
    { "Files          <space>gf", "<space>gf" },
    { "History        <space>gh", "<space>gh" },
    { "Next            Conflict", "GitConflictNextConflict" },
    { "Previous        Conflict", "GitConflictPrevConflict" },
    { "Choose Ours     Conflict", "GitConflictChooseOurs" },
    { "Choose Theirs   Conflict", "GitConflictChooseTheirs" },
    { "Choose Both     Conflict", "GitConflictChooseBoth" },
    { "Choose None     Conflict", "GitConflictChooseNone" },
  }, M.buf_is_file)
end

M.set_venv_rclick_menu = function()
  M.set_rclick_submenu("AvimVenvMenu", "Venv     ", {
    { "Select Venv           ", "VenvSelect" },
    { "Show Current Venv     ", "VenvSelectCurrent" },
    { "Set Previous Venv     ", "VenvSelectCached" },
  }, function()
    return os.getenv("VIRTUAL_ENV") ~= nil or vim.bo.filetype == "python"
  end)
end

-- Sets up an autocommand for the right click menu
M.setup_rclick_menu_autocommands = function()
  vim.api.nvim_create_autocmd({ "BufEnter", "LspAttach" }, {
    callback = function()
      M.set_doc_rclick_menu()
      M.set_lsp_rclick_menu()
      M.set_manager_rclick_menu()
      M.set_explorer_rclick_menu()
      M.set_picker_rclick_menu()
      M.set_venv_rclick_menu()
      M.set_git_rclick_menu()
      M.set_diff_rclick_menu()
      M.set_dap_rclick_menu()
    end,
  })
end

M.clear_menu("PopUp")

return M

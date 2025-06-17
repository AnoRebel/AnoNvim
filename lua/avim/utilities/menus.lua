local M = {}

M.gitsigns = {
  {
    name = "Open",
    cmd = "lua Snacks.lazygit()",
    rtxt = "<leader>gl",
  },

  { name = "separator" },

  {
    name = "Stage Hunk",
    cmd = "Gitsigns stage_hunk",
    rtxt = "sh",
  },
  {
    name = "Reset Hunk",
    cmd = "Gitsigns reset_hunk",
    rtxt = "rh",
  },

  {
    name = "Stage Buffer",
    cmd = "Gitsigns stage_buffer",
    rtxt = "sb",
  },
  {
    name = "Undo Stage Hunk",
    cmd = "Gitsigns undo_stage_hunk",
    rtxt = "us",
  },
  {
    name = "Reset Buffer",
    cmd = "Gitsigns reset_buffer",
    rtxt = "rb",
  },
  {
    name = "Preview Hunk",
    cmd = "Gitsigns preview_hunk",
    rtxt = "hp",
  },

  { name = "separator" },

  {
    name = "Blame Line",
    cmd = 'lua require"gitsigns".blame_line{full=true}',
    rtxt = "gb",
  },
  {
    name = "Blame Code",
    cmd = "GitMessenger",
    rtxt = "gm",
  },
  {
    name = "Toggle Current Line Blame",
    cmd = "Gitsigns toggle_current_line_blame",
    rtxt = "tb",
  },

  { name = "separator" },

  {
    name = "Diff This",
    cmd = "Gitsigns diffthis",
    rtxt = "dt",
  },
  {
    name = "Diff Last Commit",
    cmd = 'lua require"gitsigns".diffthis("~")',
    rtxt = "dc",
  },
  {
    name = "Toggle Deleted",
    cmd = "Gitsigns toggle_deleted",
    rtxt = "td",
  },
}

M.lsp = {
  {
    name = "Goto Definition",
    cmd = vim.lsp.buf.definition,
    rtxt = "gd",
  },

  {
    name = "Goto Declaration",
    cmd = vim.lsp.buf.declaration,
    rtxt = "gD",
  },

  {
    name = "Goto Implementation",
    cmd = vim.lsp.buf.implementation,
    rtxt = "gi",
  },
  {
    name = "Peek",
    rtxt = "gp",
    items = {
      { name = "Definition", cmd = "lua require('avim.utilities.peek').Peek('definition')", rtxt = "d" },
      { name = "Implementation", cmd = "lua require('avim.utilities.peek').Peek('implementation')", rtxt = "I" },
      { name = "Type Definition", cmd = "lua require('avim.utilities.peek').Peek('typeDefinition')", rtxt = "t" },
    },
  },

  { name = "separator" },

  {
    name = "Show signature help",
    cmd = vim.lsp.buf.signature_help,
    rtxt = "gk",
  },

  {
    name = "Show References",
    cmd = vim.lsp.buf.references,
    rtxt = "gr",
  },

  {
    name = "Show Diagnostics",
    cmd = "lua Snacks.picker.diagnostics()",
    rtxt = "gF",
  },

  { name = "separator" },

  {
    name = "Rename",
    cmd = vim.lsp.buf.rename,
    rtxt = "<leader>cr",
  },
  {
    name = "Format Buffer",
    cmd = vim.lsp.buf.format,
    rtxt = "<leader>cf",
  },

  {
    name = "Code Actions",
    cmd = "lua require('actions-preview').code_actions()",
    rtxt = "<leader>ca",
  },

  { name = "separator" },

  {
    name = "Info",
    cmd = "LspInfo",
    rtxt = "<leader>l",
  },
}

-- Get neo-tree state.
local function get_state()
  local manager = require("neo-tree.sources.manager")
  local state = manager.get_state_for_window()
  assert(state)
  state.config = state.config or {}
  return state
end

-- Call arbitrary neo-tree action.
local function call(what)
  local cc = require("neo-tree.sources.common.commands")
  return vim.schedule_wrap(function()
    local state = get_state()
    local cb = require("neo-tree.sources." .. state.name .. ".commands")[what] or cc[what]
    cb(state)
  end)
end

-- Copy path to clipboard. How is fnamemodify argument.
local function copy_path(how)
  return function()
    local node = get_state().tree:get_node()
    if node.type == "message" then
      return
    end
    vim.fn.setreg('"', vim.fn.fnamemodify(node.path, how))
    vim.fn.setreg("+", vim.fn.fnamemodify(node.path, how))
  end
end

-- Open the path to currently selected item in the terminal.
local function open_in_terminal()
  return function()
    local node = get_state().tree:get_node()
    if node.type == "message" then
      return
    end
    local path = node.path
    local node_type = vim.uv.fs_stat(path).type
    local dir = node_type == "directory" and path or vim.fn.fnamemodify(path, ":h")
    Snacks.terminal.open(
      { vim.o.shell, "-c", "cd " .. dir .. " ; " .. vim.o.shell },
      { win = { relative = "editor", position = "bottom" } }
    )
    -- vim.cmd("enew")
    -- vim.fn.termopen({ vim.o.shell, "-c", "cd " .. dir .. " ; " .. vim.o.shell })
  end
end

M.neo_tree = {
  -- NAVIGATION
  { name = "  Open in window", cmd = call("open"), rtxt = "o" },
  { name = "  Open in vertical split", cmd = call("open_vsplit"), rtxt = "<C-v>" },
  { name = "  Open in horizontal split", cmd = call("open_split"), rtxt = "<C-h>" },
  { name = "󰓪  Open in new tab", cmd = call("open_tabnew"), rtxt = "<C-t>" },
  { name = "󰓪  Open in system", cmd = call("open_tabnew"), rtxt = "<C-o>" },
  { name = "separator" },
  -- FILE ACTIONS
  { name = "  New file", cmd = call("add"), rtxt = "a" },
  { name = "  New folder", cmd = call("add_directory"), rtxt = "A" },
  { name = "  Trash", cmd = call("trash"), rtxt = "dd" },
  { name = "  Delete", hl = "ExRed", cmd = call("Delete"), rtxt = "dD" },
  { name = "   File details", cmd = call("show_file_details"), rtxt = "K" },
  { name = "  Rename", cmd = call("rename"), rtxt = "r" },
  { name = "  Rename basename", cmd = call("rename"), rtxt = "b" },
  { name = "  Copy", cmd = call("copy_to_clipboard"), rtxt = "y" },
  { name = "  Cut", cmd = call("cut_to_clipboard"), rtxt = "x" },
  { name = "  Paste", cmd = call("paste_from_clipboard"), rtxt = "p" },
  { name = "  Move", cmd = call("move"), rtxt = "m" },
  { name = "separator" },
  -- VIEW CHANGES
  { name = "Toggle hidden", cmd = call("toggle_hidden"), rtxt = "H" },
  { name = "Refresh", cmd = call("refresh"), rtxt = "R" },
  { name = " Search and Replace", cmd = call("grug_far_replace"), rtxt = "<C-r>" },
  {
    name = "Picker",
    rtxt = "g",
    items = {
      { name = "Find", cmd = call("order_by_created"), rtxt = "f" },
      { name = "Grep", cmd = call("order_by_diagnostics"), rtxt = "w" },
    },
  },
  -- FILTER
  { name = "Fuzzy finder", cmd = call("fuzzy_finder"), rtxt = "/" },
  { name = "Fuzzy finder directory", cmd = call("fuzzy_finder_directory"), rtxt = "S" },
  { name = "Fuzzy sorter", cmd = call("fuzzy_sorter"), rtxt = "#" },
  { name = "separator" },
  -- others
  { name = "Next source", cmd = call("next_source"), rtxt = ">" },
  { name = "Previous source", cmd = call("prev_source"), rtxt = "<" },
  { name = "󰴠  Copy absolute path", cmd = copy_path(":p"), rtxt = "gy" },
  { name = "  Copy relative path", cmd = copy_path(":~:."), rtxt = "Y" },
  { name = "  Run command", cmd = call("run_command"), rtxt = "<M-r>" },
  { name = "  Open in terminal", hl = "ExBlue", cmd = open_in_terminal() },
}

M.diff = {
  { name = "Open Diffview", cmd = "DiffviewOpen", rtxt = "<leader>go" },
  { name = "separator" },
  { name = "Next Conflict", cmd = "GitConflictNextConflict" },
  { name = "Previous Conflict", cmd = "GitConflictPrevConflict" },
  { name = "separator" },
  { name = "Refresh", cmd = "DiffviewRefresh", rtxt = "<leader>gr" },
  { name = "Files Diff", cmd = "DiffviewToggleFiles", rtxt = "<leader>gf" },
  { name = "Diff History", cmd = "DiffviewFileHistory", rtxt = "<leader>gh" },
  { name = "separator" },
  { name = "Choose Ours", cmd = "GitConflictChooseOurs" },
  { name = "Choose Theirs", cmd = "GitConflictChooseTheirs" },
  { name = "Choose Both", cmd = "GitConflictChooseBoth" },
  { name = "Choose None", cmd = "GitConflictChooseNone" },
  { name = "separator" },
  { name = "Close", cmd = "DiffviewClose", rtxt = "<leader>gc" },
}

-- return os.getenv("VIRTUAL_ENV") ~= nil or vim.bo.filetype == "python"
M.venv = {
  { name = "Select Venv", cmd = "VenvSelect" },
  { name = "Show Current Venv", cmd = "VenvSelectCurrent" },
  { name = "Set Previous Venv", cmd = "VenvSelectCached" },
}

M.default = {
  {
    name = "Format Buffer",
    cmd = vim.lsp.buf.format,
    rtxt = "<leader>cf",
  },

  {
    name = "Code Actions",
    cmd = "lua require('actions-preview').code_actions()",
    rtxt = "<leader>ca",
  },

  { name = "separator" },

  {
    name = "  Lsp Actions",
    hl = "Exblue",
    items = M.lsp,
  },

  { name = "separator" },

  {
    name = " Git",
    hl = "Exgreen",
    items = M.gitsigns,
  },

  { name = "separator" },

  {
    name = "View in explorer",
    cmd = "Neotree toggle=true",
    rtxt = "<leader>e",
  },

  {
    name = "Edit Config",
    cmd = function()
      vim.cmd("tabnew")
      vim.cmd("cd " .. _G.get_avim_base_dir() .. " | e init.lua")
    end,
    rtxt = "ed",
  },

  {
    name = "Copy Content",
    cmd = "%y+",
    rtxt = "<C-c>",
  },

  {
    name = "Delete Content",
    cmd = "%d",
    rtxt = "dc",
  },

  { name = "separator" },

  {
    name = " Diff",
    hl = "Exyellow",
    items = M.diff,
  },

  { name = "separator" },

  {
    name = "Smart Search",
    cmd = "lua Snacks.picker.smart()",
    rtxt = "<leader>fs",
  },
  {
    name = "Search Word",
    cmd = "lua Snacks.picker.grep()",
    rtxt = "<leader>fw",
  },
  {
    name = "Search File",
    cmd = "lua Snacks.picker.files()",
    rtxt = "<leader>ff",
  },
  {
    name = "Search Project",
    cmd = "lua Snacks.picker.files({ hidden = true, follow = true })",
    rtxt = "<leader>fa",
  },

  { name = "separator" },

  {
    name = "  Open in terminal",
    hl = "ExRed",
    cmd = function()
      local old_buf = require("menu.state").old_data.buf
      local old_bufname = vim.api.nvim_buf_get_name(old_buf)
      local old_buf_dir = vim.fn.fnamemodify(old_bufname, ":h")

      local cmd = "cd " .. old_buf_dir

      Snacks.terminal.open(
        { vim.o.shell, "-c", cmd .. " ; " .. vim.o.shell },
        { win = { relative = "editor", position = "bottom" } }
      )
      -- Snacks.terminal.open(cmd, { win = { relative = "editor", position = "float" } })
      -- vim.cmd("enew")
      -- vim.fn.termopen({ vim.o.shell, "-c", cmd .. " ; " .. vim.o.shell })
    end,
  },

  { name = "separator" },

  {
    name = "  Color Picker",
    cmd = function()
      require("minty.huefy").open()
    end,
  },
}

return M

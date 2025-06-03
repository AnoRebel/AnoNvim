local utilities = require("avim.utilities")

local function get_picker_opts(state, path)
  return {
    cwd = path,
    dirs = { path },
    confirm = function(picker, item)
      picker:close()
      -- any way to open the file without triggering auto-close event of neo-tree?
      if item then
        vim.schedule(function()
          require("neo-tree.sources.filesystem").navigate(state, state.path, item.file)
          if item.pos then
            vim.cmd(string.format("edit %s", item.file))
            vim.api.nvim_win_set_cursor(0, item.pos) -- Column is 0-based in Lua
          else
            vim.cmd("e " .. item.file)
          end
        end)
      end
      -- vim.notify(vim.inspect(item))
    end,
  }
end

local go_sibling = function(state, node, direction)
  local current_node_id = node.id
  local parent_id = node:get_parent_id()
  local children = state.tree:get_nodes(parent_id)
  local idx = -1
  for i, child in ipairs(children) do
    if child.id == current_node_id then
      idx = i
      break
    end
  end
  if idx == -1 then
    return
  end
  idx = direction == "next" and idx + 1 or idx - 1
  if idx < 1 or idx > #children then
    return
  end
  require("neo-tree.ui.renderer").focus_node(state, children[idx]:get_id())
end

---@class avim.utilities.explorer
---@field child_or_open fun(state: any)
---@field close_node_or_go_parent fun(state: any)
---@field copy_selector fun(state: any)
---@field diff_files fun(state: any)
---@field go_first_sibling fun(state: any)
---@field go_last_sibling fun(state: any)
---@field go_parent_sibling fun(state: any)
---@field open_and_clear_filter fun(state: any)
---@field open_node_or_go_child fun(state: any)
---@field open_or_focus fun(state: any)
---@field open_or_preview fun(state: any)
---@field parent_or_close fun(state: any)
---@field run_command fun(state: any)
---@field system_open fun(state: any)
---@field picker_find fun(state: any)
---@field picker_grep fun(state: any)
---@field trash fun(state: any)
---@field trash_visual fun(state: any)
local global_commands = {
  system_open = function(state)
    utilities.system_open(state.tree:get_node():get_id())
  end,
  picker_find = function(state)
    local node = state.tree:get_node()
    local path = node:get_id()
    Snacks.picker.files(get_picker_opts(state, path))
  end,
  picker_grep = function(state)
    local node = state.tree:get_node()
    local path = node:get_id()
    Snacks.picker.grep(get_picker_opts(state, path))
  end,
  -- https://github.com/nvim-neo-tree/neo-tree.nvim/discussions/220
  go_first_sibling = function(state)
    local node = state.tree:get_node()
    local parent_id = node:get_parent_id()
    local siblings = state.tree:get_nodes(parent_id)
    require("neo-tree.ui.renderer").focus_node(state, siblings[1]:get_id())
  end,
  go_last_sibling = function(state)
    local node = state.tree:get_node()
    local parent_id = node:get_parent_id()
    local siblings = state.tree:get_nodes(parent_id)
    require("neo-tree.ui.renderer").focus_node(state, siblings[#siblings]:get_id())
  end,
  go_parent_sibling = function(state)
    local node = state.tree:get_node()
    local parent_node = state.tree:get_node(node:get_parent_id())
    go_sibling(state, parent_node, "next")
  end,
  parent_or_close = function(state)
    local node = state.tree:get_node()
    if (node.type == "directory" or node:has_children()) and node:is_expanded() then
      state.commands.toggle_node(state)
    else
      require("neo-tree.ui.renderer").focus_node(state, node:get_parent_id())
    end
  end,
  child_or_open = function(state)
    local node = state.tree:get_node()
    if node.type == "directory" or node:has_children() then
      if not node:is_expanded() then -- if unexpanded, expand
        state.commands.toggle_node(state)
      else -- if expanded and has children, select the next child
        require("neo-tree.ui.renderer").focus_node(state, node:get_child_ids()[1])
      end
    else -- if not a directory just open it
      state.commands.open(state)
    end
  end,
  close_node_or_go_parent = function(state) -- Go to parent or close node
    local node = state.tree:get_node()
    if node.type == "directory" and node:is_expanded() then
      require("neo-tree.sources.filesystem").toggle_directory(state, node)
    else
      require("neo-tree.ui.renderer").focus_node(state, node:get_parent_id())
    end
  end,
  open_node_or_go_child = function(state) -- Go to first child or open node
    local node = state.tree:get_node()
    if node.type == "directory" then
      if not node:is_expanded() then
        require("neo-tree.sources.filesystem").toggle_directory(state, node)
      elseif node:has_children() then
        require("neo-tree.ui.renderer").focus_node(state, node:get_child_ids()[1])
      end
    else
      -- open or focus
      local file_win_id = nil
      local node_path = node.path
      local win_ids = vim.api.nvim_list_wins()
      for _, win_id in pairs(win_ids) do
        local buf_id = vim.api.nvim_win_get_buf(win_id)
        local path = vim.api.nvim_buf_get_name(buf_id)
        if node_path == path then
          file_win_id = win_id
        end
      end
      if file_win_id then
        vim.api.nvim_set_current_win(file_win_id)
      else
        state.commands["open"](state)
        vim.cmd("Neotree reveal")
      end
    end
  end,
  run_command = function(state)
    local node = state.tree:get_node()
    local path = node:get_id()
    vim.api.nvim_input(": " .. path .. "<Home>")
  end,
  open_and_clear_filter = function(state)
    local node = state.tree:get_node()
    if node and node.type == "file" then
      local file_path = node:get_id()
      -- reuse built-in commands to open and clear filter
      local cmds = require("neo-tree.sources.filesystem.commands")
      cmds.open(state)
      cmds.clear_filter(state)
      -- reveal the selected file without focusing the tree
      require("neo-tree.sources.filesystem").navigate(state, state.path, file_path)
    end
  end,
  -- https://github.com/nvim-neo-tree/neo-tree.nvim/wiki/Tips#open-file-without-losing-sidebar-focus
  open_or_preview = function(state)
    local node = state.tree:get_node()
    if require("neo-tree.utils").is_expandable(node) then
      state.commands["toggle_node"](state)
    else
      state.commands["toggle_preview"](state)
    end
  end,
  open_or_focus = function(state)
    local node = state.tree:get_node()
    local node_path = node.path
    local win_ids = vim.api.nvim_list_wins()
    for _, win_id in pairs(win_ids) do
      local buf_id = vim.api.nvim_win_get_buf(win_id)
      local path = vim.api.nvim_buf_get_name(buf_id)
      if node_path == path then
        vim.api.nvim_set_current_win(win_id)
        vim.notify(path)
        return
      end
    end
  end,
  copy_selector = function(state)
    local node = state.tree:get_node()
    local filepath = node:get_id()
    local filename = node.name
    local modify = vim.fn.fnamemodify

    local results = {
      e = { val = modify(filename, ":e"), msg = "Extension only" },
      f = { val = filename, msg = "Filename" },
      F = { val = modify(filename, ":r"), msg = "Filename w/o extension" },
      h = { val = modify(filepath, ":~"), msg = "Path relative to Home" },
      p = { val = modify(filepath, ":."), msg = "Path relative to CWD" },
      P = { val = filepath, msg = "Absolute path" },
    }

    local messages = {
      { "\nChoose to copy to clipboard:\n", "Normal" },
    }
    for i, result in pairs(results) do
      if result.val and result.val ~= "" then
        vim.list_extend(messages, {
          { ("%s."):format(i), "Identifier" },
          { (" %s: "):format(result.msg) },
          { result.val, "String" },
          { "\n" },
        })
      end
    end
    vim.api.nvim_echo(messages, false, {})
    local result = results[vim.fn.getcharstr()]
    if result and result.val and result.val ~= "" then
      vim.notify("Copied: " .. result.val)
      vim.fn.setreg("+", result.val)
    end
  end,
  diff_files = function(state)
    local node = state.tree:get_node()
    local log = require("neo-tree.log")
    state.clipboard = state.clipboard or {}
    if diff_Node and diff_Node ~= tostring(node.id) then
      local current_Diff = node.id
      require("neo-tree.utils").open_file(state, diff_Node, open)
      vim.cmd("vert diffs " .. current_Diff)
      log.info("Diffing " .. diff_Name .. " against " .. node.name)
      diff_Node = nil
      current_Diff = nil
      state.clipboard = {}
      require("neo-tree.ui.renderer").redraw(state)
    else
      local existing = state.clipboard[node.id]
      if existing and existing.action == "diff" then
        state.clipboard[node.id] = nil
        diff_Node = nil
        require("neo-tree.ui.renderer").redraw(state)
      else
        state.clipboard[node.id] = { action = "diff", node = node }
        diff_Name = state.clipboard[node.id].node.name
        diff_Node = tostring(state.clipboard[node.id].node.id)
        log.info("Diff source file " .. diff_Name)
        require("neo-tree.ui.renderer").redraw(state)
      end
    end
  end,
  -- Trash the target
  trash = function(state)
    local inputs = require("neo-tree.ui.inputs")
    local tree = state.tree
    local node = tree:get_node()
    if node.type == "message" then
      return
    end
    local _, name = require("neo-tree.utils").split_path(node.path)
    local msg = string.format("Are you sure you want to trash '%s'?", name)
    inputs.confirm(msg, function(confirmed)
      if not confirmed then
        return
      end
      vim.api.nvim_command("silent !trash -f " .. node.path)
      require("neo-tree.sources.filesystem.commands").refresh(state)
    end)
  end,

  -- Trash the selections (visual mode)
  trash_visual = function(state, selected_nodes)
    local inputs = require("neo-tree.ui.inputs")
    local paths_to_trash = {}
    for _, node in ipairs(selected_nodes) do
      if node.type ~= "message" then
        table.insert(paths_to_trash, node.path)
      end
    end
    local msg = "Are you sure you want to trash " .. #paths_to_trash .. " items?"
    inputs.confirm(msg, function(confirmed)
      if not confirmed then
        return
      end
      for _, path in ipairs(paths_to_trash) do
        vim.api.nvim_command("silent !trash -f " .. path)
      end
      require("neo-tree.sources.filesystem.commands").refresh(state)
    end)
  end,
  grug_far_replace = function(state)
    local node = state.tree:get_node()
    local prefills = {
      -- get the current path and get the parent directory if a file is selected
      paths = node.type == "directory" and node:get_id() or vim.fn.fnamemodify(node:get_id(), ":h"),
    }

    local grug_far = require("grug-far")
    -- instance check
    if not grug_far.has_instance("explorer") then
      grug_far.open({
        instanceName = "explorer",
        prefills = prefills,
        staticTitle = "Find and Replace from Explorer",
      })
    else
      grug_far.open_instance("explorer")
      -- updating the prefills without clearing the search and other fields
      grug_far.update_instance_prefills("explorer", prefills, false)
    end
  end,
}

return global_commands

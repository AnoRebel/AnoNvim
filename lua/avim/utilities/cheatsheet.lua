---@class avim.utilities.cheatsheet
---@field open fun(): nil # Show every described mapping, grouped by the first word of its description
local M = {}

local api = vim.api
local defaults = require("avim.core.defaults")

local modes = { "n", "v", "i", "t", "c" }
local ns = api.nvim_create_namespace("avim_cheatsheet")

local function width(s)
  return vim.fn.strdisplaywidth(s)
end

--- Pad or truncate `s` to exactly `w` display cells.
local function fit(s, w)
  local len = width(s)
  if len <= w then
    return s .. (" "):rep(w - len)
  end
  local out, acc = "", 0
  for _, ch in ipairs(vim.fn.split(s, "\\zs")) do
    local cw = width(ch)
    if acc + cw > w - 1 then
      break
    end
    out, acc = out .. ch, acc + cw
  end
  return out .. "…" .. (" "):rep(math.max(0, w - acc - 1))
end

local function display_lhs(lhs)
  if lhs:sub(1, 1) == " " then
    return "<leader>" .. lhs:sub(2)
  elseif lhs:sub(1, 7) == "<Space>" then
    return "<leader>" .. lhs:sub(8)
  end
  return lhs
end

--- Group mappings by the first word of their description, like NvChad's cheatsheet.
--- Descriptions without a second word (":bnext", "vim.lsp.buf.rename()", single
--- letters) do not name a section and are skipped.
---@return table<string, table[]>
function M.collect()
  local groups, seen = {}, {}

  local function add(maps)
    for _, map in ipairs(maps) do
      local desc = map.desc
      local id = map.lhs .. (desc or "")
      if desc and desc ~= "" and not desc:find("\n") and not map.lhs:find("<Plug>") and not seen[id] then
        seen[id] = true
        local head, rest = desc:match("^(%S+)%s+(.+)$")
        -- only "Git Hunk" / "[Git] Hunk" style descriptions name a section
        if head and #head > 1 and head:match("^[%[%u]") then
          head = head:gsub(":$", "")
          head = head:sub(1, 1):upper() .. head:sub(2)
          if map.mode ~= "n" and map.mode ~= " " then
            head = head .. " (" .. map.mode .. ")"
          end
          groups[head] = groups[head] or {}
          table.insert(groups[head], {
            lhs = display_lhs(map.lhs),
            desc = rest:sub(1, 1):upper() .. rest:sub(2),
          })
        end
      end
    end
  end

  for _, mode in ipairs(modes) do
    add(api.nvim_get_keymap(mode))
    add(api.nvim_buf_get_keymap(0, mode))
  end
  return groups
end

--- Balance the sections over as many columns as the width allows.
---@param groups table<string, table[]>
---@param available number usable cells, the editor width minus its margins
local function layout(groups, available)
  local entries = {}
  for head, items in pairs(groups) do
    table.sort(items, function(a, b)
      return a.lhs < b.lhs
    end)
    entries[#entries + 1] = { head = head, items = items, height = #items + 2 }
  end
  table.sort(entries, function(a, b)
    return a.height > b.height
  end)

  local keyw, descw = 0, 0
  for _, entry in ipairs(entries) do
    for _, item in ipairs(entry.items) do
      keyw = math.max(keyw, width(item.lhs))
      descw = math.max(descw, width(item.desc))
    end
  end
  keyw = math.min(keyw, 18)

  local cols = math.max(1, math.min(#entries, math.floor(available / 60)))
  local colw = math.min(math.floor(available / cols), keyw + descw + 6)

  local columns, heights = {}, {}
  for i = 1, cols do
    columns[i], heights[i] = {}, 0
  end
  for _, entry in ipairs(entries) do
    local target = 1
    for i = 2, cols do
      if heights[i] < heights[target] then
        target = i
      end
    end
    table.insert(columns[target], entry)
    heights[target] = heights[target] + entry.height
  end

  return columns, colw, keyw, math.max(unpack(heights))
end

---@return string[] rows, table[] marks
local function build(columns, colw, keyw, height)
  local cells, marks = {}, {}
  for c, entries in ipairs(columns) do
    local start = (c - 1) * colw
    local row = 1
    cells[c] = {}
    for _, entry in ipairs(entries) do
      local pad = math.max(0, colw - 1 - width(entry.head))
      local left = math.floor(pad / 2)
      cells[c][row] = (" "):rep(left) .. entry.head .. (" "):rep(pad - left)
      table.insert(marks, { row - 1, start + left, start + left + width(entry.head), "Title" })
      row = row + 1
      for _, item in ipairs(entry.items) do
        local key = "  " .. fit(item.lhs, keyw) .. "  "
        cells[c][row] = fit(key .. item.desc, colw)
        table.insert(marks, { row - 1, start + 2, start + 2 + width(item.lhs), "Special" })
        row = row + 1
      end
      row = row + 1
    end
  end

  local rows = {}
  for r = 1, height do
    local parts = {}
    for c = 1, #columns do
      parts[#parts + 1] = cells[c][r] or (" "):rep(colw)
    end
    rows[#rows + 1] = (table.concat(parts):gsub("%s+$", ""))
  end
  return rows, marks
end

function M.open()
  local groups = M.collect()
  if vim.tbl_isempty(groups) then
    vim.notify("No described mappings in this buffer", vim.log.levels.WARN)
    return
  end

  local buf = api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].swapfile = false
  vim.bo[buf].modifiable = false

  local win

  local function draw()
    if not api.nvim_buf_is_valid(buf) then
      return
    end
    local columns, colw, keyw, height = layout(groups, vim.o.columns - 4)
    local rows, marks = build(columns, colw, keyw, height)

    local w = math.min(vim.o.columns - 2, colw * #columns)
    local h = math.min(vim.o.lines - 4, height)

    vim.bo[buf].modifiable = true
    api.nvim_buf_set_lines(buf, 0, -1, false, rows)
    api.nvim_buf_clear_namespace(buf, ns, 0, -1)
    for _, mark in ipairs(marks) do
      api.nvim_buf_add_highlight(buf, ns, mark[4], mark[1], mark[2], mark[3])
    end
    vim.bo[buf].modifiable = false

    local config = {
      relative = "editor",
      style = "minimal",
      border = defaults.ui.border,
      width = w,
      height = h,
      row = math.max(0, math.floor((vim.o.lines - h) / 2) - 1),
      col = math.max(0, math.floor((vim.o.columns - w) / 2)),
      title = " Cheatsheet ",
      title_pos = "center",
    }
    if win and api.nvim_win_is_valid(win) then
      api.nvim_win_set_config(win, config)
    else
      win = api.nvim_open_win(buf, true, config)
    end
    vim.wo[win].winhighlight = "Normal:NormalFloat,FloatBorder:FloatBorder"
  end

  local function close()
    if win and api.nvim_win_is_valid(win) then
      api.nvim_win_close(win, true)
    end
  end

  local augroup = api.nvim_create_augroup("avim_cheatsheet", { clear = true })
  api.nvim_create_autocmd("VimResized", { group = augroup, callback = draw })
  api.nvim_create_autocmd("BufWipeout", {
    group = augroup,
    buffer = buf,
    callback = function()
      api.nvim_del_augroup_by_name("avim_cheatsheet")
    end,
  })

  vim.keymap.set("n", "q", close, { buffer = buf, nowait = true })
  vim.keymap.set("n", "<Esc>", close, { buffer = buf, nowait = true })

  draw()
end

return M

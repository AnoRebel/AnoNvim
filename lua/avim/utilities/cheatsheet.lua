---@class avim.utilities.cheatsheet
---@field open fun(): nil # Show every described mapping as cards, grouped by the first word of its description
local M = {}

local api = vim.api
local defaults = require("avim.core.defaults")

local modes = { "n", "v", "i", "t", "c" }
local ns = api.nvim_create_namespace("avim_cheatsheet")

-- Badge colors, read from the active theme so the sheet follows a theme switch.
local badge_sources = {
  "DiagnosticError",
  "DiagnosticWarn",
  "DiagnosticInfo",
  "DiagnosticHint",
  "Function",
  "String",
  "Type",
  "Keyword",
  "Constant",
  "Special",
}
local badges = 0

local art = {
  "█▀▀ █░█ █▀▀ ▄▀█ ▀█▀ █▀ █░█ █▀▀ █▀▀ ▀█▀",
  "█▄▄ █▀█ ██▄ █▀█ ░█░ ▄█ █▀█ ██▄ ██▄ ░█░",
}

local function hl(name)
  return api.nvim_get_hl(0, { name = name, link = false })
end

--- Mix `fg` into `bg` by `amount` (0..1), both as 0xRRGGBB.
local function blend(bg, fg, amount)
  local function channel(color, shift)
    return math.floor(bit.band(bit.rshift(color, shift), 0xff))
  end
  local parts = {}
  for _, shift in ipairs({ 16, 8, 0 }) do
    local a, b = channel(bg, shift), channel(fg, shift)
    parts[#parts + 1] = math.floor(a + (b - a) * amount)
  end
  return parts[1] * 65536 + parts[2] * 256 + parts[3]
end

--- One flat card color and one color per section badge, from the theme.
local function setup_highlights()
  local float, normal = hl("NormalFloat"), hl("Normal")
  local bg = float.bg or normal.bg
  local fg = float.fg or normal.fg
  if not bg or not fg then
    return
  end

  local card = blend(bg, fg, 0.08)
  api.nvim_set_hl(0, "AvimCheatCard", { fg = fg, bg = card })
  api.nvim_set_hl(0, "AvimCheatTitle", { fg = hl("DiagnosticInfo").fg or fg, bold = true })

  badges = 0
  for _, name in ipairs(badge_sources) do
    local color = hl(name).fg
    if color then
      badges = badges + 1
      api.nvim_set_hl(0, "AvimCheatBadge" .. badges, { fg = card, bg = color, bold = true })
    end
  end
end

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

--- Balance whole cards over as many columns as the width allows.
---@param groups table<string, table[]>
---@param available number usable cells, the editor width minus its margins
local function layout(groups, available)
  local entries = {}
  for head, items in pairs(groups) do
    table.sort(items, function(a, b)
      return a.lhs < b.lhs
    end)
    entries[#entries + 1] = {
      head = head,
      items = items,
      badge = items[1] and items[1].badge,
      height = #items + 3,
    }
  end
  table.sort(entries, function(a, b)
    if a.height == b.height then
      return a.head < b.head
    end
    return a.height > b.height
  end)

  local keyw, descw = 0, 0
  for _, entry in ipairs(entries) do
    for _, item in ipairs(entry.items) do
      keyw = math.max(keyw, width(item.lhs))
      descw = math.max(descw, width(item.desc))
    end
  end
  keyw = math.min(keyw, 20)
  descw = math.min(descw, 40)

  local needed = descw + keyw + 5 -- 2 left pad, 1 gap, 2 right pad
  local cols = math.max(1, math.min(4, math.floor(available / (needed + 2))))
  local cardw = math.min(needed, math.floor((available - 2 * (cols - 1)) / cols))

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

  return columns, cardw, math.max(unpack(heights))
end

local function entry_line(item, cardw)
  local left = "  " .. item.desc
  local room = cardw - 2 - width(item.lhs)
  if width(left) + 1 > room then
    return fit(left, room - 1) .. " " .. item.lhs .. "  "
  end
  return left .. (" "):rep(room - width(left)) .. item.lhs .. "  "
end

--- One card per section: centered badge, entries, bottom padding, gap.
local function card(entry, cardw)
  local label = " " .. entry.head .. " "
  local left = math.max(0, math.floor((cardw - width(label)) / 2))
  local lines = {
    {
      text = fit((" "):rep(left) .. label, cardw),
      bg = true,
      marks = { { left, left + width(label), entry.badge } },
    },
    { text = (" "):rep(cardw), bg = true },
  }

  for _, item in ipairs(entry.items) do
    lines[#lines + 1] = { text = entry_line(item, cardw), bg = true }
  end

  lines[#lines + 1] = { text = (" "):rep(cardw), bg = true }
  lines[#lines + 1] = { text = (" "):rep(cardw) }
  return lines
end

---@return string[] rows, table[] marks
local function build(columns, cardw, height)
  local cells = {}
  for c, entries in ipairs(columns) do
    cells[c] = {}
    for _, entry in ipairs(entries) do
      vim.list_extend(cells[c], card(entry, cardw))
    end
  end

  local rows, marks = {}, {}
  for r = 1, height do
    local parts = {}
    for c = 1, #columns do
      local start = (c - 1) * (cardw + 2)
      local line = cells[c][r]
      parts[#parts + 1] = line and line.text or (" "):rep(cardw)
      if c < #columns then
        parts[#parts + 1] = "  "
      end
      if line and line.bg then
        table.insert(marks, { r - 1, start, start + cardw, "AvimCheatCard" })
      end
      for _, mark in ipairs(line and line.marks or {}) do
        table.insert(marks, { r - 1, start + mark[1], start + mark[2], mark[3] })
      end
    end
    rows[#rows + 1] = table.concat(parts)
  end

  return rows, marks
end

--- Center the block-letter title over the whole sheet.
local function header(sheet)
  local lines, marks = {}, {}
  for _, line in ipairs(art) do
    local left = math.max(0, math.floor((sheet - width(line)) / 2))
    lines[#lines + 1] = (" "):rep(left) .. line
    table.insert(marks, { #lines - 1, left, left + width(line), "AvimCheatTitle" })
  end
  lines[#lines + 1] = ""
  table.insert(lines, 1, "")
  for _, mark in ipairs(marks) do
    mark[1] = mark[1] + 1
  end
  return lines, marks
end

---@param groups table<string, table[]>
local function assign_badges(groups)
  local names = vim.tbl_keys(groups)
  table.sort(names)
  for i, name in ipairs(names) do
    for _, entry in ipairs(groups[name]) do
      entry.badge = "AvimCheatBadge" .. ((i - 1) % math.max(badges, 1) + 1)
    end
  end
end

function M.open()
  local groups = M.collect()
  if vim.tbl_isempty(groups) then
    vim.notify("No described mappings in this buffer", vim.log.levels.WARN)
    return
  end

  setup_highlights()
  assign_badges(groups)

  local buf = api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].swapfile = false
  vim.bo[buf].modifiable = false

  local win

  local function draw()
    if not api.nvim_buf_is_valid(buf) then
      return
    end
    setup_highlights()
    local columns, cardw, height = layout(groups, vim.o.columns - 4)
    local sheet = cardw * #columns + 2 * (#columns - 1)
    local body, marks = build(columns, cardw, height)

    local head, head_marks = header(sheet)
    local offset = #head
    local rows = {}
    vim.list_extend(rows, head)
    vim.list_extend(rows, body)
    for _, mark in ipairs(marks) do
      mark[1] = mark[1] + offset
    end
    vim.list_extend(marks, head_marks)

    local w = math.min(vim.o.columns - 2, sheet)
    local h = math.min(vim.o.lines - 4, #rows)

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
  api.nvim_create_autocmd({ "VimResized", "ColorScheme" }, { group = augroup, callback = draw })
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

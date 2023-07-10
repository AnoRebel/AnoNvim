local utils = require("avim.core.utils")
local git = require("avim.plugins.git")
local Log = require("avim.core.log")

local M = {}
local fn = vim.fn
local api = vim.api

local config = {
  keymaps = {
    quit_blame = "q",
    blame_commit = "<CR>"
  }
}

local blame_state = {
  file = "",
  temp_file = "",
  starting_win = "",
  relative_path = "",
  git_root = "",
}

local function blameLinechars()
  return fn.strlen(fn.getline ".")
end

local function create_blame_win()
  api.nvim_command "topleft vnew"
  local win = api.nvim_get_current_win()
  local buf = api.nvim_get_current_buf()

  api.nvim_buf_set_option(buf, "buftype", "nofile")
  api.nvim_buf_set_option(buf, "swapfile", false)
  api.nvim_buf_set_option(buf, "bufhidden", "wipe")
  api.nvim_buf_set_option(buf, "filetype", "git")
  api.nvim_buf_set_option(buf, "buflisted", false)

  api.nvim_win_set_option(win, "number", true)
  api.nvim_win_set_option(win, "foldcolumn", "0")
  api.nvim_win_set_option(win, "foldenable", false)
  api.nvim_win_set_option(win, "foldenable", false)
  api.nvim_win_set_option(win, "winfixwidth", true)
  api.nvim_win_set_option(win, "signcolumn", "no")
  api.nvim_win_set_option(win, "wrap", false)

  return win, buf
end

local function blame_syntax()
  local seen = {}
  local hash_colors = {}
  for lnum = 1, fn.line "$" do
    local orig_hash = fn.matchstr(fn.getline(lnum), [[^\^\=[*?]*\zs\x\{6\}]])
    local hash = orig_hash
    hash = fn.substitute(hash, [[\(\x\)\x]], [[\=submatch(1).printf("%x", 15-str2nr(submatch(1),16))]], "g")
    hash = fn.substitute(hash, [[\(\x\x\)]], [[\=printf("%02x", str2nr(submatch(1),16)*3/4+32)]], "g")
    if hash ~= "" and orig_hash ~= "000000" and seen[hash] == nil then
      seen[hash] = 1
      if vim.wo.t_Co == "256" then
        local colors = fn.map(fn.matchlist(orig_hash, [[\(\x\)\x\(\x\)\x\(\x\)\x]]), "str2nr(v:val,16)")
        local r = colors[2]
        local g = colors[3]
        local b = colors[4]
        local color = 16 + (r + 1) / 3 * 36 + (g + 1) / 3 * 6 + (b + 1) / 3
        if color == 16 then
          color = 235
        elseif color == 231 then
          color = 255
        end
        hash_colors[hash] = " ctermfg=" .. tostring(color)
      else
        hash_colors[hash] = ""
      end
      local pattern = fn.substitute(orig_hash, [[^\(\x\)\x\(\x\)\x\(\x\)\x$]], [[\1\\x\2\\x\3\\x]], "") .. [[*\>]]
      vim.cmd("syn match GitNvimBlameHash" .. hash .. [[       "\%(^\^\=[*?]*\)\@<=]] .. pattern .. [[" skipwhite]])
    end

    for hash_value, cterm in pairs(hash_colors) do
      if cterm ~= nil or fn.has "gui_running" or fn.hash "termguicolors" and vim.wo.termguicolors then
        vim.cmd("hi GitNvimBlameHash" .. hash_value .. " guifg=#" .. hash_value .. cterm)
      else
        vim.cmd("hi link GitNvimBlameHash" .. hash_value .. " Identifier")
      end
    end
  end
end

local function on_blame_done(lines)
  local starting_win = api.nvim_get_current_win()
  local current_top = fn.line "w0" + vim.wo.scrolloff
  local current_pos = fn.line "."

  -- Save the state
  blame_state.file = api.nvim_buf_get_name(0)
  blame_state.starting_win = starting_win

  local blame_win, blame_buf = create_blame_win()

  api.nvim_buf_set_lines(blame_buf, 0, -1, true, lines)
  api.nvim_buf_set_option(blame_buf, "modifiable", false)
  api.nvim_win_set_width(blame_win, blameLinechars() + 1)

  vim.cmd("execute " .. tostring(current_top))
  vim.cmd "normal! zt"
  vim.cmd("execute " .. tostring(current_pos))

  -- We should call cursorbind, scrollbind here to avoid unexpected behavior
  api.nvim_win_set_option(blame_win, "cursorbind", true)
  api.nvim_win_set_option(blame_win, "scrollbind", true)

  api.nvim_win_set_option(starting_win, "scrollbind", true)
  api.nvim_win_set_option(starting_win, "cursorbind", true)

  -- Keymaps
  local options = {
    noremap = true,
    silent = true,
    expr = false,
  }

  api.nvim_buf_set_keymap(0, "n", config.keymaps.quit_blame, "<CMD>q<CR>", options)
  api.nvim_buf_set_keymap(
    0,
    "n",
    config.keymaps.blame_commit,
    "<CMD>lua require('avim.plugins.blame').blame_commit()<CR>",
    options
  )
  api.nvim_command "autocmd BufWinLeave <buffer> lua require('avim.plugins.blame').blame_quit()"

  blame_syntax()
end

local function on_blame_commit_done(commit_hash, lines)
  -- TODO: Find a better way to handle this case
  local idx = 1
  while idx <= #lines and not utils.starts_with(lines[idx], "diff") do
    idx = idx + 1
  end
  table.insert(lines, idx, "")

  local temp_file = fn.tempname()
  blame_state.temp_file = temp_file
  fn.writefile(lines, temp_file)

  -- Close blame window
  local win = api.nvim_get_current_win()
  api.nvim_win_close(win, true)

  api.nvim_command("silent! e" .. temp_file)

  local buf = api.nvim_get_current_buf()
  api.nvim_buf_set_name(buf, commit_hash)
  api.nvim_buf_set_option(buf, "buftype", "nofile")
  api.nvim_buf_set_option(buf, "bufhidden", "delete")
  api.nvim_buf_set_option(buf, "filetype", "git")
  api.nvim_command "autocmd BufLeave <buffer> lua require('avim.plugins.blame').blame_commit_quit()"

  fn.search([[^diff .* b/\M]] .. fn.escape(blame_state.relative_path, "\\") .. "$", "W")
end

function M.blame_commit_quit()
  local buf = api.nvim_get_current_buf()
  api.nvim_command(buf .. "bdelete")
  fn.delete(blame_state.temp_file)
end

function M.blame_commit()
  local line = fn.getline "."
  local commit = fn.matchstr(line, [[^\^\=[?*]*\zs\x\+]])
  if string.match(commit, "^0+$") then
    Log:warn("Not Committed Yet", "Git")
    return
  end

  local commit_hash = git.run_git_cmd(
    "git -C " .. blame_state.git_root .. " --literal-pathspecs rev-parse --verify " .. commit .. " --"
  )
  if commit_hash == nil then
    Log:warn("Commit hash not found", "Git")
    return
  end

  commit_hash = string.gsub(commit_hash, "\n", "")
  local diff_cmd = "git -C "
    .. blame_state.git_root
    .. " --literal-pathspecs --no-pager show --no-color "
    .. commit_hash
    .. " -- "
    .. blame_state.file

  local lines = {}
  local function on_event(_, data, event)
    -- TODO: Handle error data
    if event == "stdout" or event == "stderr" then
      data = utils.handle_job_data(data)
      if not data then
        return
      end

      for i = 1, #data do
        if data[i] ~= "" then
          table.insert(lines, data[i])
        end
      end
    end

    if event == "exit" then
      on_blame_commit_done(commit_hash, lines)
    end
  end

  fn.jobstart(diff_cmd, {
    on_stderr = on_event,
    on_stdout = on_event,
    on_exit = on_event,
    stdout_buffered = true,
    stderr_buffered = true,
  })
end

function M.blame_quit()
  api.nvim_win_set_option(blame_state.starting_win, "scrollbind", false)
  api.nvim_win_set_option(blame_state.starting_win, "cursorbind", false)
end

function M.open()
  local fpath = api.nvim_buf_get_name(0)
  if fpath == "" or fpath == nil then
    return
  end

  local git_root = git.get_git_repo()
  if git_root == "" then
    return
  end
  blame_state.git_root = git_root
  blame_state.relative_path = fn.fnamemodify(fn.expand "%", ":~:.")

  local blame_cmd = "git -C "
    .. git_root
    .. " --literal-pathspecs --no-pager -c blame.coloring=none -c blame.blankBoundary=false blame --show-number -- "
    .. fpath

  local lines = {}
  local has_error = false

  local function on_event(_, data, event)
    if event == "stdout" then
      data = utils.handle_job_data(data)
      if not data then
        return
      end

      for i = 1, #data do
        if data[i] ~= "" then
          local commit = fn.matchstr(data[i], [[^\^\=[?*]*\zs\x\+]])
          local commit_info = data[i]:match "%((.-)%)"
          commit_info = string.match(commit_info, "(.-)%s(%S+)$")
          table.insert(lines, commit .. " " .. commit_info)
        end
      end
    elseif event == "stderr" then
      data = utils.handle_job_data(data)
      if not data then
        return
      end

      has_error = true
      local error_message = ""
      for _, line in ipairs(data) do
        error_message = error_message .. line
      end
      Log:warn("Failed to open git blame window: " .. error_message, "Git")
    elseif event == "exit" then
      if not has_error then
        on_blame_done(lines)
      end
    end
  end

  fn.jobstart(blame_cmd, {
    on_stderr = on_event,
    on_stdout = on_event,
    on_exit = on_event,
    stdout_buffered = true,
    stderr_buffered = true,
  })
end

return M

---@class avim.update
---@field check fun(): UpdateInfo # Check for updates
---@field execute fun(opts?: UpdateOptions): boolean # Execute the update
---@field get_current_version fun(): string # Get current version
---@field get_latest_version fun(): string # Get latest version from remote
local M = {}

---@class UpdateInfo
---@field current_version string # Current installed version
---@field latest_version string # Latest available version
---@field has_update boolean # Whether an update is available
---@field changes table<string> # List of changes between versions
---@field last_checked number # Timestamp of last check

---@class UpdateOptions
---@field interactive boolean? # Whether to run in interactive mode
---@field force boolean? # Whether to force update even if up to date
---@field backup boolean? # Whether to create backup before updating
---@field branch string? # Which branch to update from
---@field show_changes boolean? # Whether to show changelog

local Log = require("avim.core.log")
local utilities = require("avim.utilities")

-- Constants
local BACKUP_DIR = utilities.join_paths(utilities.get_cache_dir(), "backup")
local UPDATE_LOCKFILE = utilities.join_paths(utilities.get_cache_dir(), "update.json")
local REPO_URL = "https://github.com/AnoRebel/AnoNvim.git"
local DEFAULT_BRANCH = "main"

---Read data from the update lockfile
---@return table data Update data
local function read_update_data()
  if not vim.uv.fs_stat(UPDATE_LOCKFILE) then
    return {}
  end

  local content = vim.fn.readfile(UPDATE_LOCKFILE)
  if vim.tbl_isempty(content) then
    return {}
  end

  return vim.json.decode(content[1]) or {}
end

---Write data to the update lockfile
---@param data table Data to write
local function write_update_data(data)
  local content = vim.json.encode(data)
  vim.fn.writefile({ content }, UPDATE_LOCKFILE)
end

---Create a backup of the current installation
---@return boolean success Whether backup was successful
local function create_backup()
  Log:debug("Creating backup")

  -- Create backup directory
  local backup_path = utilities.join_paths(BACKUP_DIR, os.date("%Y%m%d_%H%M%S"))
  local ok = vim.fn.mkdir(backup_path, "p")
  if ok ~= 1 then
    Log:error("Failed to create backup directory: " .. backup_path)
    return false
  end

  -- Copy current installation
  local base_dir = utilities.get_avim_base_dir()
  local rsync = vim.fn.executable("rsync") == 1

  if rsync then
    local cmd = string.format("rsync -a --exclude '.git' %s/ %s/", base_dir, backup_path)
    local output = vim.fn.system(cmd)
    if vim.v.shell_error ~= 0 then
      Log:error("Backup failed: " .. output)
      return false
    end
  else
    -- Fallback to cp
    local cmd = string.format("cp -r %s/* %s/", base_dir, backup_path)
    local output = vim.fn.system(cmd)
    if vim.v.shell_error ~= 0 then
      Log:error("Backup failed: " .. output)
      return false
    end
  end

  Log:info("Created backup at: " .. backup_path)
  return true
end

---Get changes between versions
---@param current string Current version
---@param latest string Latest version
---@return table<string> changes List of changes
local function get_changes(current, latest)
  local cmd =
    string.format("git -C %s log --pretty=format:'%%h %%s' %s..%s", utilities.get_avim_base_dir(), current, latest)

  local handle = io.popen(cmd)
  if not handle then
    return {}
  end

  local output = handle:read("*a")
  handle:close()

  local changes = {}
  for line in output:gmatch("[^\r\n]+") do
    table.insert(changes, line)
  end

  return changes
end

---Show update dialog
---@param info UpdateInfo Update information
---@return boolean proceed Whether to proceed with update
local function show_dialog(info)
  local dialog = string.format(
    [[
  AnoNvim Update Available
  -----------------------
  Current version: %s
  Latest version:  %s
  
  Changes:
  %s
  
  Do you want to update? (y/n): ]],
    info.current_version,
    info.latest_version,
    table.concat(info.changes, "\n  ")
  )

  vim.ui.input({ prompt = dialog }, function(input)
    return input and input:lower() == "y"
  end)
end

---Get current installed version
---@return string version Current version
function M.get_current_version()
  local cmd = string.format("git -C %s rev-parse --short HEAD", utilities.get_avim_base_dir())
  local handle = io.popen(cmd)
  if not handle then
    return "unknown"
  end

  local output = handle:read("*a")
  handle:close()

  return output:gsub("%s+", "")
end

---Get latest version from remote
---@param branch? string Branch to check
---@return string version Latest version
function M.get_latest_version(branch)
  branch = branch or DEFAULT_BRANCH
  local cmd = string.format("git ls-remote %s %s", REPO_URL, branch)

  local handle = io.popen(cmd)
  if not handle then
    return "unknown"
  end

  local output = handle:read("*a")
  handle:close()

  return output:match("(%w+)"):sub(1, 7)
end

---Check for updates
---@return UpdateInfo info Update information
function M.check()
  Log:debug("Checking for updates")

  local current = M.get_current_version()
  local latest = M.get_latest_version()
  local has_update = current ~= latest

  local info = {
    current_version = current,
    latest_version = latest,
    has_update = has_update,
    changes = has_update and get_changes(current, latest) or {},
    last_checked = os.time(),
  }

  write_update_data(info)
  return info
end

---Execute the update
---@param opts? UpdateOptions Update options
---@return boolean success Whether update was successful
function M.execute(opts)
  opts = vim.tbl_deep_extend("force", {
    interactive = true,
    force = false,
    backup = true,
    branch = DEFAULT_BRANCH,
    show_changes = true,
  }, opts or {})

  -- Check for updates
  local info = M.check()

  -- Check if update is needed
  if not info.has_update and not opts.force then
    utilities.notify("AnoNvim is already up to date!")
    return true
  end

  -- Show dialog in interactive mode
  if opts.interactive then
    if not show_dialog(info) then
      utilities.notify("Update cancelled")
      return false
    end
  end

  -- Create backup if requested
  if opts.backup then
    if not create_backup() then
      if opts.interactive then
        utilities.notify("Failed to create backup, continue? (y/n)", "warn")
        if not vim.fn.input("") == "y" then
          return false
        end
      else
        Log:warn("Failed to create backup, continuing anyway")
      end
    end
  end

  -- Perform update
  Log:info("Updating AnoNvim")
  local cmd = string.format("git -C %s pull origin %s", utilities.get_avim_base_dir(), opts.branch)

  local output = vim.fn.system(cmd)
  if vim.v.shell_error ~= 0 then
    Log:error("Update failed: " .. output)
    return false
  end

  -- Update lazy.nvim and plugins
  require("lazy").sync()

  -- Show completion message
  local msg = string.format("AnoNvim updated successfully!\nFrom %s to %s", info.current_version, info.latest_version)
  utilities.notify(msg, "info")

  -- Show changes if requested
  if opts.show_changes and not vim.tbl_isempty(info.changes) then
    vim.schedule(function()
      vim.ui.select(info.changes, {
        prompt = "Changes in this update:",
        format_item = function(item)
          return "  " .. item
        end,
      }, function() end)
    end)
  end

  return true
end

return M

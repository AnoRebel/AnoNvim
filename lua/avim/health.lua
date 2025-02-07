---@class avim.health
---@field check fun(): nil # Performs health checks
---@field check_program fun(program: ProgramSpec): boolean # Checks a program's availability
---@field check_version fun(version: string, min: string): boolean # Validates version requirements

---@class ProgramSpec
---@field cmd string|string[] # Command name or alternatives
---@field type "error"|"warn"|"info" # Message type
---@field msg string # Description message
---@field version_cmd? string # Command to get version
---@field min_version? string # Minimum required version

local M = {}

-- Program specifications
local programs = {
  {
    cmd = "git",
    type = "error",
    msg = "Required for git functionality",
    version_cmd = "git --version",
    min_version = "2.19.0",
  },
  {
    cmd = "node",
    type = "warn",
    msg = "Required for LSP and formatting",
    version_cmd = "node --version",
    min_version = "20.18.0",
  },
  {
    cmd = "lazygit",
    type = "warn",
    msg = "Used for git TUI (Optional)",
    version_cmd = "lazygit --version",
  },
  {
    cmd = "go",
    type = "warn",
    msg = "Required for Go development",
    version_cmd = "go version",
    min_version = "1.23.0",
  },
  {
    cmd = "rg",
    type = "warn",
    msg = "Used for searching files and folders",
    version_cmd = "rg --version",
  },
  {
    cmd = { "fd", "fd-find" },
    type = "warn",
    msg = "Used for searching files and folders",
    version_cmd = "fd --version",
  },
  {
    cmd = { "python", "python3" },
    type = "warn",
    msg = "Required for Python development",
    version_cmd = "python3 --version",
    min_version = "3.10.0",
  },
}

---Get clean version string from command output
---@param cmd string Command to execute
---@return string|nil version Version string or nil if failed
local function get_program_version(cmd)
  local handle = io.popen(cmd .. " 2>&1")
  if not handle then
    return nil
  end

  local output = handle:read("*a")
  handle:close()

  -- Extract version number (assumes format like X.Y.Z)
  local version = output:match("[%d]+%.[%d]+%.[%d]+")
  return version
end

---Check if version meets minimum requirement
---@param current string Current version
---@param required string Required version
---@return boolean meets_requirement
local function version_meets_requirement(current, required)
  if not current or not required then
    return true
  end

  local function parse_version(v)
    local major, minor, patch = v:match("(%d+)%.(%d+)%.(%d+)")
    return {
      tonumber(major) or 0,
      tonumber(minor) or 0,
      tonumber(patch) or 0,
    }
  end

  local cur = parse_version(current)
  local req = parse_version(required)

  for i = 1, 3 do
    if cur[i] > req[i] then
      return true
    end
    if cur[i] < req[i] then
      return false
    end
  end

  return true
end

---Format error message for program check
---@param program ProgramSpec Program specification
---@param reason string Reason for failure
---@return string message Formatted error message
local function format_error(program, reason)
  local name = type(program.cmd) == "table" and program.cmd[1] or program.cmd
  local msg = string.format("`%s` %s: %s", name, reason, program.msg)
  if program.min_version then
    msg = msg .. string.format(" (minimum version: %s)", program.min_version)
  end
  return msg
end

---Check if a program meets requirements
---@param program ProgramSpec Program to check
---@return boolean success Whether program meets requirements
function M.check_program(program)
  -- Normalize command to array
  local cmds = type(program.cmd) == "string" and { program.cmd } or program.cmd

  -- Check for executable
  local found = false
  local found_cmd
  for _, cmd in ipairs(cmds) do
    if vim.fn.executable(cmd) == 1 then
      found = true
      found_cmd = cmd
      break
    end
  end

  if not found then
    vim.health[program.type](format_error(program, "is not installed"))
    return false
  end

  -- Check version if required
  if program.version_cmd and program.min_version then
    local version = get_program_version(program.version_cmd)
    if not version then
      vim.health.warn(format_error(program, "version check failed"))
      return false
    end

    if not version_meets_requirement(version, program.min_version) then
      vim.health[program.type](format_error(program, "version is too old"))
      return false
    end

    vim.health.ok(string.format("`%s` is installed (version %s)", found_cmd, version))
  else
    vim.health.ok(string.format("`%s` is installed: %s", found_cmd, program.msg))
  end

  return true
end

---Perform health checks
function M.check()
  vim.health.start("AnoNvim Health Check")

  -- Version information
  local v = vim.version()
  local version_str = string.format("%d.%d.%d", v.major, v.minor, v.patch)
  vim.health.info("AnoNvim Version: " .. _G.avim.version)
  vim.health.info("Neovim Version: v" .. version_str)

  -- Check Neovim version
  if v.prerelease then
    vim.health.warn("Neovim nightly is not officially supported and may have breaking changes")
  elseif vim.fn.has("nvim-0.10") == 1 then
    vim.health.ok("Using stable Neovim >= 0.10")
  else
    vim.health.error("Neovim >= 0.10 is required")
  end

  -- Check XDG directories
  local xdg_vars = {
    ["XDG_DATA_HOME"] = vim.env.XDG_DATA_HOME or vim.fn.expand("~/.local/share"),
    ["XDG_CONFIG_HOME"] = vim.env.XDG_CONFIG_HOME or vim.fn.expand("~/.config"),
    ["XDG_STATE_HOME"] = vim.env.XDG_STATE_HOME or vim.fn.expand("~/.local/state"),
    ["XDG_CACHE_HOME"] = vim.env.XDG_CACHE_HOME or vim.fn.expand("~/.cache"),
  }

  for name, path in pairs(xdg_vars) do
    if vim.fn.isdirectory(path) == 1 then
      vim.health.ok(string.format("%s: %s", name, path))
    else
      vim.health.warn(string.format("%s directory does not exist: %s", name, path))
    end
  end

  -- Check required programs
  for _, program in ipairs(programs) do
    M.check_program(program)
  end
end

return M

local M = {}

function M.check()
  vim.health.start("AnoNvim")

  vim.health.info("AnoNvim Version: " .. _G.avim.version)
  vim.health.info("Neovim Version: v" .. vim.fn.matchstr(vim.fn.execute("version"), "NVIM v\\zs[^\n]*"))

  if vim.version().prerelease then
    vim.health.warn("Neovim nightly is not officially supported and may have breaking changes")
  elseif vim.fn.has("nvim-0.10") == 1 then
    vim.health.ok("Using stable Neovim >= 0.10")
  else
    vim.health.error("Neovim >= 0.10 is recommended")
  end

  local programs = {
    { cmd = "git", type = "error", msg = "Used for git functionality" },
    { cmd = "lazygit", type = "warn", msg = "Used for mappings to pull up git TUI (Optional)" },
    { cmd = "go", type = "warn", msg = "Used for mappings for golang stuff (Optional)" },
    { cmd = "node", type = "warn", msg = "Used for mappings to pull up node REPL (Optional)" },
    { cmd = "rg", type = "warn", msg = "Used for searching files and folders" },
    { cmd = { "fd", "fd-find" }, type = "warn", msg = "Used for searching files and folders" },
    { cmd = { "python", "python3" }, type = "warn", msg = "Used for mappings to pull up python REPL (Optional)" },
  }

  for _, program in ipairs(programs) do
    if type(program.cmd) == "string" then
      program.cmd = { program.cmd }
    end
    local name = program.cmd[1] -- table.concat(program.cmd, "/")
    local found = false
    for _, cmd in ipairs(program.cmd) do
      if vim.fn.executable(cmd) == 1 then
        name = cmd
        found = true
        break
      end
    end

    if found then
      vim.health.ok(("`%s` is installed: %s"):format(name, program.msg))
    else
      vim.health[program.type](("`%s` is not installed: %s"):format(name, program.msg))
    end
  end
end

return M

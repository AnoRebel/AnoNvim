-- Applies locally-maintained patches to third-party plugins.
--
-- Patches live in `patches/<name>.patch` at the config root and are applied by a
-- lazy.nvim `build` hook, which runs on install and on every update. Patching is
-- idempotent: an already-patched tree is detected via reverse-apply and skipped,
-- so re-running is always safe.
--
-- Failure is loud and non-destructive. If upstream moves the patched lines the
-- patch is refused outright rather than written as conflict markers, because a
-- Lua source file containing `<<<<<<<` breaks Neovim at startup, far from the
-- cause. On refusal the plugin is left at pristine upstream and the patch needs
-- rebasing against the new source.

local M = {}

local uv = vim.uv or vim.loop

---Root of the avim config (parent of `lua/`), where `patches/` lives.
---@return string
local function config_root()
  local this = debug.getinfo(1, "S").source:sub(2)
  -- .../lua/avim/utilities/patch.lua -> ...
  return vim.fs.normalize(vim.fs.dirname(vim.fs.dirname(vim.fs.dirname(vim.fs.dirname(this)))))
end

---@param path string
---@return boolean
local function exists(path)
  return uv.fs_stat(path) ~= nil
end

---Run git in `cwd`, returning success and combined output.
---@param cwd string
---@param args string[]
---@return boolean ok
---@return string output
local function git(cwd, args)
  local res = vim.system(vim.list_extend({ "git", "-C", cwd }, args), { text = true }):wait()
  return res.code == 0, (res.stdout or "") .. (res.stderr or "")
end

---Apply `patches/<name>.patch` to the plugin checked out at `plugin_dir`.
---@param name string patch basename, without the `.patch` suffix
---@param plugin_dir string absolute path to the plugin's git checkout
---@return boolean applied true if the tree ends up patched
function M.apply(name, plugin_dir)
  local patch = vim.fs.joinpath(config_root(), "patches", name .. ".patch")

  if not exists(patch) then
    vim.notify(("patch: no such patch file: %s"):format(patch), vim.log.levels.ERROR)
    return false
  end
  if not exists(vim.fs.joinpath(plugin_dir, ".git")) then
    vim.notify(("patch[%s]: %s is not a git checkout"):format(name, plugin_dir), vim.log.levels.ERROR)
    return false
  end

  -- Already patched? A clean reverse-apply means the changes are present.
  if git(plugin_dir, { "apply", "--reverse", "--check", patch }) then
    return true
  end

  if not git(plugin_dir, { "apply", "--check", patch }) then
    vim.notify(
      ("patch[%s]: REFUSED — does not apply to the current source.\n"):format(name)
        .. ("Upstream likely changed the patched lines. %s is left unpatched at pristine\n"):format(name)
        .. ("upstream; the fix it carried is NOT active. Rebase %s against the new source.")
          :format(vim.fn.fnamemodify(patch, ":~")),
      vim.log.levels.ERROR
    )
    return false
  end

  local ok, out = git(plugin_dir, { "apply", patch })
  if not ok then
    vim.notify(("patch[%s]: apply failed after passing --check:\n%s"):format(name, out), vim.log.levels.ERROR)
    return false
  end

  vim.notify(("patch[%s]: applied"):format(name), vim.log.levels.INFO)
  return true
end

---Build a lazy.nvim `build` function that applies the named patch.
---lazy.nvim invokes it with the plugin spec, whose `dir` is the checkout path.
---@param name string
---@return fun(plugin: table)
function M.builder(name)
  return function(plugin)
    M.apply(name, plugin.dir)
  end
end

return M

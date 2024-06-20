local base_dir = vim.env.ANONVIM_BASE_DIR
  or (function()
    local init_path = debug.getinfo(1, "S").source
    return init_path:sub(2):match("(.*[/\\])"):sub(1, -2)
  end)()

if not vim.tbl_contains(vim.opt.rtp:get(), base_dir) then
  vim.opt.rtp:append(base_dir)
end

vim.uv = vim.uv or vim.loop
require("avim.core"):init(base_dir)

local Log = require("avim.core.log")
Log:configure_notifications(vim.notify)
Log:debug("Starting AnoNvim")

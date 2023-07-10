local base_dir = vim.env.ANONVIM_BASE_DIR
	or (function()
		local init_path = debug.getinfo(1, "S").source
		return init_path:sub(2):match("(.*[/\\])"):sub(1, -2)
	end)()

if not vim.tbl_contains(vim.opt.rtp:get(), base_dir) then
	vim.opt.rtp:append(base_dir)
end

require("avim.core"):init(base_dir)
require("avim.core.settings")
require("avim.lazy"):init()
require("avim.lazy").load()

local Log = require("avim.core.log")
Log:debug("Starting AnoNvim")

require("avim.autocmds")
vim.api.nvim_create_autocmd("User", {
	pattern = "VeryLazy",
	callback = function()
		require("avim.utils").load_keymaps()
	end,
})

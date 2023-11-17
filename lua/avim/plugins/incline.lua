local M = {
	"b0o/incline.nvim",
	event = "BufReadPre",
	dependencies = { "nvim-tree/nvim-web-devicons" },
}

local mode_color = {
	n = "green",
	i = "red",
	v = "cyan",
	V = "cyan",
	[""] = "cyan",
	-- ["\22"] =  "cyan",
	c = "magenta",
	no = "purple",
	s = "orange",
	S = "orange",
	[""] = "orange",
	-- ["\19"] =  "purple",
	ic = "yellow",
	R = "violet",
	Rv = "violet",
	cv = "red",
	ce = "red",
	r = "blue",
	rm = "blue",
	["r?"] = "blue",
	["!"] = "red",
	t = "red",
}

function M.config()
	local get_buf_option = vim.api.nvim_buf_get_option
	require("incline").setup({
		debounce_threshold = { falling = 500, rising = 250 },
		-- hide = {
		-- 	cursorline = true,
		-- },
		render = function(props)
			local bufname = vim.api.nvim_buf_get_name(props.buf)
			local filename = vim.fn.fnamemodify(bufname, ":t")
			local status = require("avim.utils").get_status(filename)
			local modified = get_buf_option(props.buf, "modified") and "" or "" -- "⦁"
			local fg = mode_color[vim.fn.mode()]
			local readonly = (vim.bo.readonly and vim.bo ~= "help") and require("avim.icons").ui.Lock or ""
			return {
				status,
				{ " " },
				readonly,
				{ readonly == "" and "" or " " },
				{ filename, guifg = fg },
				{ " " },
				{ modified, guifg = "#A3BA5E" },
			}
		end,
	})
end

return M

local M = {
	"NvChad/nvim-colorizer.lua",
	event = "BufReadPre",
}

local options = {
	filetypes = { "*", "!lazy" },
	buftype = { "*", "!prompt", "!nofile" },
	user_default_options = {
		RRGGBBAA = true, -- #RRGGBBAA hex codes
		AARRGGBB = true, -- #RRGGBBAA hex codes
		css = true, -- Enable all CSS features: rgb_fn, hsl_fn, names, RGB, RRGGBB
		css_fn = true, -- Enable all CSS *functions*: rgb_fn, hsl_fn

		-- Available modes: foreground, background
		mode = "background", -- Set the display mode.
		tailwind = true, -- Enable tailwind colors
		-- parsers can contain values used in |user_default_options|
		sass = { enable = true, parsers = { css } },
	},
}

function M.config()
	-- require("colorizer").setup(options["filetypes"], options["user_default_options"])
	require("colorizer").setup(nil, options["user_default_options"])
	-- vim.cmd "ColorizerReloadAllBuffers"
end

return M

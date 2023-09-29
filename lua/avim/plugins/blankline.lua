local M = {
	"lukas-reineke/indent-blankline.nvim",
	-- event = "BufRead",
	main = "ibl",
}

local options = {
	char = "▏",
	exclude = {
		--  filetypes = {
		--  "help",
		--  "terminal",
		--  "alpha",
		--  "packer",
		--  "lazy",
		--  "lspinfo",
		--  "TelescopePrompt",
		--  "TelescopeResults",
		--  "lsp-installer",
		--  "",
		-- },
		-- buftypes = { "terminal", "nofile" },
	},
}

function M.config()
	require("ibl").setup(options)
end

return M

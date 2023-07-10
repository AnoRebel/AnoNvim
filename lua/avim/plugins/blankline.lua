local M = {
	"lukas-reineke/indent-blankline.nvim",
	event = "BufRead",
}

local options = {
	use_treesitter = true,
	show_current_context = true,
	show_current_context_start = true,
	indentLine_enabled = 1,
	char = "▏",
	filetype_exclude = {
		"help",
		"terminal",
		"alpha",
		"packer",
		"lazy",
		"lspinfo",
		"TelescopePrompt",
		"TelescopeResults",
		"lsp-installer",
		"",
	},
	buftype_exclude = { "terminal", "nofile" },
	show_trailing_blankline_indent = false,
	show_first_indent_level = false,
	-- context_highlight_list = { "Blue" },
	context_patterns = {
		-- NOTE: indent-blankline's defaults
		"class",
		"function",
		"return",
		"^func",
		"method",
		"^if",
		"while",
		"^while",
		"for",
		"with",
		"try",
		"except",
		"arguments",
		"argument_list",
		"object",
		"dictionary",
		"element",
		"table",
		"tuple",
		"block",
		"if_statement",
		"else_clause",
		"catch_clause",
		"try_statement",
		"import_statement",
		"operation_type",
		-- NOTE: better Javascript/Typescript support
		"return_statement",
		"statement_block",
	},
	char_highlight_list = { "VertSplit" },
	-- NOTE: alternating indentation highlight
	space_char_hughlight_list = { "MsgSeparator", "Normal" },
}

function M.config()
	require("indent_blankline").setup(options)
end

return M

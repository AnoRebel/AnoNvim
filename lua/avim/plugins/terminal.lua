local M = {
	"akinsho/toggleterm.nvim",
	version = "*",
	event = "BufWinEnter",
}

local options = {
	-- size can be a number or function which is passed the current terminal
	size = function(term) -- 25,
		if term.direction == "horizontal" then
			return 20
		elseif term.direction == "vertical" then
			return vim.o.columns * 0.3
		end
	end,
	-- open_mapping = [[<c-t>]], -- [[<c-`]]
	open_mapping = [[<c-\>]],
	hide_numbers = true, -- hide the number column in toggleterm buffers
	shade_filetypes = {},
	shade_terminals = true,
	shading_factor = 2, -- the degree by which to darken to terminal colour, default: 1 for dark backgrounds, 3 for light
	start_in_insert = true,
	insert_mappings = true, -- whether or not the open mapping applies in insert mode
	-- terminal_mappings = true, -- whether or not the open mapping applies in the opened terminals
	persist_size = false,
	-- direction = 'vertical' | 'horizontal' | 'window' | 'float' | 'tab',
	direction = "tab",
	close_on_exit = true, -- close the terminal window when the process exits
	shell = vim.o.shell, -- change the default shell
	-- This field is only relevant if direction is set to 'float'
	float_opts = {
		-- The border key is *almost* the same as 'nvim_win_open'
		-- see :h nvim_win_open for details on borders however
		-- the 'curved' border is a custom border type
		-- not natively supported but implemented in this plugin.
		-- border = 'single' | 'double' | 'shadow' | 'curved' | ... other options supported by win open
		border = "curved",
		-- width = <value>,
		-- height = <value>,
		winblend = 0,
		highlights = {
			border = "Normal",
			background = "Normal",
		},
	},
}

function M.config()
	local terminal = require("toggleterm")

	terminal.setup(options)

	local Terminal = require("toggleterm.terminal").Terminal

	local floatTerm = Terminal:new({
		hidden = true,
		direction = "float",
		float_opts = {
			border = "curved",
		},
	})

	local bottomTerm = Terminal:new({
		hidden = true,
		direction = "horizontal",
	})

	local rightTerm = Terminal:new({
		hidden = true,
		direction = "vertical",
	})

	local lazyGit = Terminal:new({
		cmd = "lazygit",
		hidden = true,
		direction = "float",
		float_opts = {
			border = "curved",
		},
	})
	local gitUI = Terminal:new({
		cmd = "gitui",
		hidden = true,
		direction = "float",
		float_opts = {
			border = "curved",
		},
	})

	terminal.float_toggle = function()
		floatTerm:toggle()
	end
	terminal.lazygit_toggle = function()
		lazyGit:toggle()
	end
	terminal.gitui_toggle = function()
		gitUI:toggle()
	end

	terminal.bottom_toggle = function()
		bottomTerm:toggle(20) -- options.size
	end
	terminal.right_toggle = function()
		rightTerm:toggle(vim.o.columns * 0.25)
	end
end

return M

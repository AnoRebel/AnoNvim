local M = {
	"stevearc/dressing.nvim",
	event = "VeryLazy",
	dependencies = { "MunifTanjim/nui.nvim" },
}

local options = {
	input = {
		enabled = true,

		-- Default prompt string
		default_prompt = "➤ ",

		-- Can be 'left', 'right', or 'center'
		prompt_align = "center",

		-- When true, <Esc> will close the modal
		insert_only = true,

		-- These are passed to nvim_open_win
		override = function(conf)
			-- This is the config that will be passed to nvim_open_win.
			-- Change values here to customize the layout
			conf.col = -1
			conf.row = 0
			conf.anchor = "SW"
			return conf
		end,
		-- 'editor' and 'win' will default to being centered
		relative = "cursor",
		border = "rounded",

		-- These can be integers or a float between 0 and 1 (e.g. 0.4 for 40%)
		prefer_width = 40,
		width = nil,
		-- min_width and max_width can be a list of mixed types.
		-- min_width = {20, 0.2} means "the greater of 20 columns or 20% of total"
		max_width = { 140, 0.9 },
		min_width = { 20, 0.2 },

		-- Window transparency (0-100)
		win_options = { winblend = 10 },
	},
	select = {
		enabled = true,

		-- Priority list of preferred vim.select implementations
		backend = { "telescope", "nui", "fzf", "builtin" },

		-- Options for telescope selector
		telescope = nil, -- {
		-- -- can be 'dropdown', 'cursor', or 'ivy'
		-- theme = "dropdown",
		-- },

		-- Options for fzf selector
		fzf = {
			window = {
				width = 0.5,
				height = 0.4,
			},
		},

		-- Options for nui Menu
		nui = {
			--position = {
			--  row = 1,
			--  col = 0,
			--},
			position = "50%",
			size = nil,
			relative = "cursor", -- "editor"
			border = {
				style = "rounded",
				highlight = "NightflyRed",
				text = {
					top_align = "right",
				},
			},
			max_width = 80,
			max_height = 40,
		},

		-- Options for built-in selector
		builtin = {
			-- These are passed to nvim_open_win
			override = function(conf)
				conf.anchor = "NW"
				return conf
			end,
			-- 'editor' and 'win' will default to being centered
			relative = "cursor", -- "editor" | "win"
			border = "rounded",

			-- Window transparency (0-100)
			win_options = { winblend = 10 },

			-- These can be integers or a float between 0 and 1 (e.g. 0.4 for 40%)
			-- the min_ and max_ options can be a list of mixed types.
			-- max_width = {140, 0.8} means "the lesser of 140 columns or 80% of total"
			width = nil,
			max_width = { 140, 0.8 },
			min_width = { 40, 0.2 },
			height = nil,
			max_height = 0.9,
			min_height = { 10, 0.2 },
		},

		-- Used to override format_item. See :help dressing-format
		format_item_override = {},

		-- see :help dressing_get_config
		get_config = function(opts)
			if opts.kind == "codeaction" then
				return {
					backend = "nui",
					nui = {
						relative = "cursor",
						max_width = 80,
					},
				}
			end
		end,
	},
}

function M.config()
	require("dressing").setup(options)
end

return M

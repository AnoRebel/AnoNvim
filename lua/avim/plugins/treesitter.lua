local M = {
	"nvim-treesitter/nvim-treesitter",
	event = "BufReadPost",
	dependencies = {
		{
			"romgrk/nvim-treesitter-context",
			config = function()
				require("treesitter-context").setup({})
			end,
		},
		-- { "nvim-treesitter/nvim-treesitter-refactor" },
		{
			"nvim-treesitter/nvim-treesitter-textobjects",
			init = function()
				-- PERF: no need to load the plugin, if we only need its queries for mini.ai
				local plugin = require("lazy.core.config").spec.plugins["nvim-treesitter"]
				local opts = require("lazy.core.plugin").values(plugin, "opts", false)
				local enabled = false
				if opts.textobjects then
					for _, mod in ipairs({ "move", "select", "swap", "lsp_interop" }) do
						if opts.textobjects[mod] and opts.textobjects[mod].enable then
							enabled = true
							break
						end
					end
				end
				if not enabled then
					require("lazy.core.loader").disable_rtp_plugin("nvim-treesitter-textobjects")
				end
			end,
		},
		{ "JoosepAlviste/nvim-ts-context-commentstring" },
		{ "HiPhish/nvim-ts-rainbow2" },
		{ "windwp/nvim-ts-autotag" },
		{ "andymass/vim-matchup", branch = "master" },
	},
	-- :TSUpdate[Sync] doesn't exist until plugin/nvim-treesitter is loaded (i.e. not after first install); call update() directly
	-- build = ":TSUpdate",
	build = function()
		require("nvim-treesitter.install").update({ with_sync = true })
	end,
}

local options = {
	ensure_installed = require("avim.core.defaults").treesitter,
	highlight = {
		enable = true,
		use_languagetree = true,
		additional_vim_regex_highlighting = { "markdown" },
	},
	context_commentstring = {
		enable = true,
		enable_autocmd = false,
	},
	rainbow = {
		enable = true,
		-- query = "rainbow-parens",
		-- strategy = require("ts-rainbow").strategy.global,
		-- extended_mode = true, -- Also highlight non-bracket delimiters like html tags, boolean or table: lang -> boolean
		-- max_file_lines = nil, -- Do not enable for files with more than n lines, int
	},
	autotag = {
		enable = true,
	},
	matchup = {
		enable = true, -- mandatory, false will disable the whole extension
		enable_quotes = true,
		disable = { "lua", ".lua", "*.lua", "lua_ls" }, -- Buggy AF
		-- disable = { "c", "ruby" },  -- optional, list of language that will be disabled
		-- [options]
	},
	textobjects = {
		select = { enable = true, lookahead = true },
		swap = {
			enable = true,
			swap_next = {
				["<leader>pt"] = "@parameter.inner",
				["<leader>po"] = "@parameter.outer",
			},
			swap_previous = {
				["<leader>pT"] = "@parameter.inner",
				["<leader>pO"] = "@parameter.outer",
			},
		},
		move = { enable = true, set_jumps = true },
		lsp_interop = {
			enable = true,
			peek_definition_code = {
				["<leader>dt"] = "@function.outer",
				["<leader>dT"] = "@class.outer",
			},
		},
	},
	-- refactor = {
	-- 	highlight_definitions = {
	-- 		enable = true,
	-- 		-- Set to false if you have an `updatetime` of ~100.
	-- 		clear_on_cursor_move = true,
	-- 	},
	-- 	highlight_current_scope = {
	-- 		enable = false,
	-- 	},
	-- 	smart_rename = {
	-- 		enable = true,
	-- 		keymaps = {
	-- 			smart_rename = "<leader>rr",
	-- 		},
	-- 	},
	-- 	navigation = {
	-- 		enable = false,
	-- 		keymaps = {
	-- 			goto_definition = "gnd",
	-- 			list_definitions = "gnD",
	-- 			list_definitions_toc = "gO",
	-- 			goto_next_usage = "<a-*>",
	-- 			goto_previous_usage = "<a-#>",
	-- 		},
	-- 	},
	-- },
}

function M.config()
	require("nvim-treesitter.configs").setup(options)
end

return M

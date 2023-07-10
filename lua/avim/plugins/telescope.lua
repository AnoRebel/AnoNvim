local M = {
	"nvim-telescope/telescope.nvim",
	cmd = "Telescope",
	dependencies = {
		{ "nvim-lua/plenary.nvim" },
		{ "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
		{ "xiyaowong/telescope-emoji.nvim" },
		{ "nvim-telescope/telescope-media-files.nvim" },
	},
}

function M.config()
	local telescope = require("telescope")
	local trouble = require("trouble.providers.telescope")
	local ok, actions = pcall(require, "telescope.actions")
	if not ok then
		return
	end
	local action_state = require("telescope.actions.state")
	local options = {
		defaults = {
			mappings = {
				i = { ["<c-t>"] = trouble.open_with_trouble },
				n = { ["<c-t>"] = trouble.open_with_trouble },
			},
			vimgrep_arguments = {
				"rg",
				"--color=never",
				"--no-heading",
				"--with-filename",
				"--line-number",
				"--column",
				"--smart-case",
				"--hidden",
				"--glob=!.git/",
			},
			pickers = {
				find_files = {
					hidden = true,
					find_command = { "fd", "--type=file", "--hidden", "--smart-case" },
					on_input_filter_cb = function(prompt)
						local find_colon = string.find(prompt, ":")
						if find_colon then
							local ret = string.sub(prompt, 1, find_colon - 1)
							vim.schedule(function()
								local prompt_bufnr = vim.api.nvim_get_current_buf()
								local picker = action_state.get_current_picker(prompt_bufnr)
								local lnum = tonumber(prompt:sub(find_colon + 1))
								if type(lnum) == "number" then
									local win = picker.previewer.state.winid
									local bufnr = picker.previewer.state.bufnr
									local line_count = vim.api.nvim_buf_line_count(bufnr)
									vim.api.nvim_win_set_cursor(win, { math.max(1, math.min(lnum, line_count)), 0 })
								end
							end)
							return { prompt = ret }
						end
					end,
					attach_mappings = function()
						actions.select_default:enhance({
							post = function()
								-- if we found something, got to line
								local prompt = action_state.get_current_line()
								local find_colon = string.find(prompt, ":")
								if find_colon then
									local lnum = tonumber(prompt:sub(find_colon + 1))
									vim.api.nvim_win_set_cursor(0, { lnum, 0 })
								end
							end,
						})
						return true
					end,
				},
				live_grep = {
					--@usage don't include the filename in the search results
					only_sort_text = true,
				},
				buffers = {
					initial_mode = "normal",
					mappings = {
						i = {
							["<C-d>"] = actions.delete_buffer,
						},
						n = {
							["dd"] = actions.delete_buffer,
						},
					},
				},
				planets = {
					show_pluto = true,
					show_moon = true,
				},
				git_files = {
					hidden = true,
					show_untracked = true,
				},
				colorscheme = {
					enable_preview = true,
				},
			},
			prompt_prefix = " ", -- "   ",
			selection_caret = " ", -- " ",
			entry_prefix = "  ",
			initial_mode = "insert",
			selection_strategy = "reset",
			sorting_strategy = "ascending", -- "descending",
			layout_strategy = "horizontal",
			-- layout_config = {
			--    horizontal = {
			--       prompt_position = "top",
			--       preview_width = 0.55,
			--       results_width = 0.8,
			--    },
			--    vertical = {
			--       mirror = false,
			--    },
			--    width = 0.87,
			--    height = 0.80,
			--    preview_cutoff = 120,
			-- },
			layout_config = {
				width = 0.75,
				preview_cutoff = 120,
				horizontal = {
					prompt_position = "top",
					preview_width = function(_, cols, _)
						if cols < 120 then
							return math.floor(cols * 0.5)
						end
						return math.floor(cols * 0.6)
					end,
					-- mirror = false,
				},
				vertical = { mirror = false },
			},
			file_sorter = require("telescope.sorters").get_fuzzy_file,
			file_ignore_patterns = { "node_modules" },
			generic_sorter = require("telescope.sorters").get_generic_fuzzy_sorter,
			path_display = { "smart" }, -- { shorten = 5 }, | { "truncate" },
			winblend = 0,
			border = {},
			borderchars = { "─", "│", "─", "│", "╭", "╮", "╯", "╰" },
			color_devicons = true,
			use_less = true,
			set_env = { ["COLORTERM"] = "truecolor" }, -- default = nil,
			file_previewer = require("telescope.previewers").vim_buffer_cat.new,
			grep_previewer = require("telescope.previewers").vim_buffer_vimgrep.new,
			qflist_previewer = require("telescope.previewers").vim_buffer_qflist.new,
			-- Developer configurations: Not meant for general override
			buffer_previewer_maker = require("telescope.previewers").buffer_previewer_maker,
		},
		extensions = {
			fzf = {
				fuzzy = true, -- false will only do exact matching
				override_generic_sorter = true, -- override the generic sorter
				override_file_sorter = true, -- override the file sorter
				case_mode = "smart_case", -- or "ignore_case" or "respect_case"
				-- the default case_mode is "smart_case"
			},
			media_files = {
				-- TODO: pip3 install --upgrade ueberzug && aptinstall sxiv ffmpegthumbnailer
				-- git clone https://github.com/sdushantha/fontpreview
				filetypes = { "png", "webp", "jpg", "jpeg", "webm", "mp4", "pdf" },
				find_cmd = "fd", -- | "rg" -- find command (defaults to 'fd')
			},
		},
	}

	telescope.setup(options)

	local extensions = {
		"fzf",
		"persisted",
		"emoji",
		"media_files",
		"notify",
		"neoclip",
		"noice",
		"themes",
		"flutter",
		"refactoring",
		"terms",
	} -- "dap"
	pcall(function()
		for _, ext in ipairs(extensions) do
			telescope.load_extension(ext)
		end
	end)
end

return M

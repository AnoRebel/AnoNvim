return {
	-- Enhance nvim
	{ "nathom/filetype.nvim", lazy = false },
	{
		"Tastyep/structlog.nvim",
		lazy = false,
	},
	{
		"luukvbaal/stabilize.nvim",
		lazy = false,
		config = function()
			require("stabilize").setup()
		end,
	},
	{ "lambdalisue/suda.vim", cmd = { "SudaRead", "SudaWrite" } },
	{
		"jbyuki/instant.nvim",
		enabled = false,
		cmd = {
			"InstantStartSingle",
			"InstantStartSession",
			"InstantJoinSingle",
			"InstantJoinSession",
			"InstantStatus",
			"InstantStop",
			"InstantFollow",
			"InstantStopFollow",
			"InstantOpenAll",
			"InstantSaveAll",
		},
	},
	{
		"chipsenkbeil/distant.nvim", -- NOTE: Requires `cargo install distant`
		cmd = { "DistantLaunch", "DistantOpen", "DistantInstall" },
		enabled = false,
		config = function()
			require("distant").setup({
				-- Applies Chip's personal settings to every machine you connect to
				--
				-- 1. Ensures that distant servers terminate with no connections
				-- 2. Provides navigation bindings for remote directories
				-- 3. Provides keybinding to jump into a remote file's parent directory
				["*"] = require("distant.settings").chip_default(),
			})
		end,
	},
	-- DotEnv
	{ "tpope/vim-dotenv" },
	-- UI
	{ "MunifTanjim/nui.nvim" },
	{ "nvim-lua/plenary.nvim" },
	{ "nvim-lua/popup.nvim" },
	{ "DanilaMihailov/beacon.nvim", lazy = false },
	{
		"shortcuts/no-neck-pain.nvim",
		cmd = "NoNeckPain",
		config = function()
			require("no-neck-pain").setup({
				buffers = {
					blend = -0.2,
					scratchPad = {
						enabled = true,
						location = "~/Documents/Obsidian Vault/notes/",
						fileName = "scratch",
					},
					bo = {
						filetype = "md",
					},
				},
			})
		end,
	},
	-- LSP
	{ "weilbith/nvim-code-action-menu", event = "LspAttach", dependencies = { "neovim/nvim-lspconfig" } },
	{
		"zbirenbaum/neodim",
		event = "LspAttach",
		config = function()
			require("neodim").setup({
				alpha = 0.75,
				blend_color = "#000000",
				update_in_insert = {
					enable = true,
					delay = 100,
				},
				hide = {
					virtual_text = false,
					signs = false,
					underline = false,
				},
			})
		end,
	},
	{
		"folke/lsp-colors.nvim",
		event = "LspAttach",
		config = true,
	},
	{
		"kosayoda/nvim-lightbulb",
		branch = "master",
		event = "LspAttach",
		dependencies = {
			"antoinemadec/FixCursorHold.nvim",
		},
		opts = { autocmd = { enabled = true } },
	},
	-- Tests
	{
		"nvim-neotest/neotest",
		enabled = false,
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-treesitter/nvim-treesitter",
			"antoinemadec/FixCursorHold.nvim",
			-- Adapters
			"nvim-neotest/neotest-python",
			"nvim-neotest/neotest-go",
			"sidlatau/neotest-dart",
			"marilari88/neotest-vitest",
			"haydenmeade/neotest-jest",
			"Issafalcon/neotest-dotnet",
			"jfpedroza/neotest-elixir",
			"MarkEmmons/neotest-deno",
		},
		opts = {
			adapters = {
				-- 		require("neotest-python")({
				-- 			dap = { justMyCode = false },
				-- 		}),
				-- 		require("neotest-go"),
				-- 		require("neotest-vitest"),
				-- 		require("neotest-jest"),
				-- 		require("neotest-dart"),
				-- 		require("neotest-dotnet"),
				-- 		require("neotest-elixir"),
				-- 		require("neotest-deno"),
			},
		},
	},
	-- Git
	{
		"akinsho/git-conflict.nvim",
		cmd = {
			"GitConflictChooseOurs",
			"GitConflictChooseTheirs",
			"GitConflictChooseBoth",
			"GitConflictChooseNone",
			"GitConflictNextConflict",
			"GitConflictPrevConflict",
			"GitConflictListQf",
		},
		config = true,
	},
	{ "rhysd/committia.vim", lazy = false },
	{
		"rhysd/git-messenger.vim",
		lazy = true,
		event = { "BufRead" },
	},
	-- Code Helpers
	{
		"stevearc/oil.nvim",
		cmd = { "Oil" },
		opts = {
			columns = {
				"icon",
				-- "permissions",
				"size",
				"mtime",
				-- "atime",
			},
			-- Deleted files will be removed with the trash_command (below).
			delete_to_trash = true,
			-- Change this to customize the command used when deleting to trash
			trash_command = "trash-put",
			keymaps = {
				["-"] = false,
				["g."] = false,
				["<C-l>"] = false,
				["<C-p>"] = false,
				["C"] = "actions.parent",
				["K"] = "actions.preview",
				["R"] = "actions.refresh",
				["<C-q>"] = "actions.close",
				["H"] = "actions.toggle_hidden",
			},
		},
		-- Optional dependencies
		dependencies = { "nvim-tree/nvim-web-devicons" },
	},
	{
		"Exafunction/codeium.vim",
		enabled = false,
		event = "BufRead",
		config = function()
			local whichkey_exists, wk = pcall(require, "which-key")
			if whichkey_exists then
				wk.register({
					["<M-p>"] = {
						function()
							return vim.fn["codeium#CycleCompletions"](-1)
						end,
						"Codeium: Previous Suggestion",
					},
				}, { mode = "i" })
				wk.register({
					["<M-n>"] = {
						function()
							return vim.fn["codeium#CycleCompletions"](1)
						end,
						"Codeium: Next Suggestion",
					},
				}, { mode = "i" })
				wk.register({
					["<M-a>"] = {
						function()
							return vim.fn["codeium#Accept"]()
						end,
						"Codeium: Accept Suggestion",
					},
				}, { mode = "i" })
				wk.register({
					["<M-Space>"] = {
						function()
							return vim.fn["codeium#Complete"]()
						end,
						"Codeium: Trigger Suggestions",
					},
				}, { mode = "i" })
				wk.register({
					["<M-Bslash>"] = {
						function()
							return vim.fn["codeium#Clear"]()
						end,
						"Codeium: Clear Suggestions",
					},
				}, { mode = "i" })
			else
				-- Change '<C-g>' here to any keycode you like.
				vim.keymap.set("i", "<M-a>", function()
					return vim.fn["codeium#Accept"]()
				end, { expr = true, desc = "Codeium: Accept Suggestion" })
				vim.keymap.set("i", "<M-n>", function()
					return vim.fn["codeium#CycleCompletions"](1)
				end, { expr = true, desc = "Codeium: Next Suggestion" })
				vim.keymap.set("i", "<M-p>", function()
					return vim.fn["codeium#CycleCompletions"](-1)
				end, { expr = true, desc = "Codeium: Previous Suggestion" })
				vim.keymap.set("i", "<M-Space>", function()
					return vim.fn["codeium#Complete"]()
				end, { expr = true, desc = "Codeium: Trigger Suggestions" })
				vim.keymap.set("i", "<M-Bslash>", function()
					return vim.fn["codeium#Clear"]()
				end, { expr = true, desc = "Codeium: Clear Suggestions" })
			end
		end,
	},
	{
		"metakirby5/codi.vim",
		cmd = { "Codi", "CodiNew", "CodiSelect" },
	},
	{
		"toppair/peek.nvim",
		build = "deno task --quiet build:fast",
		init = function()
			vim.api.nvim_create_user_command("Peek", function()
				local peek = require("peek")
				if peek.is_open() then
					peek.close()
				else
					peek.open()
				end
			end, {})
		end,
		config = true,
	},
	{
		"rmagatti/goto-preview",
		event = "LspAttach",
		config = true,
	},
	{
		"ggandor/leap.nvim",
		dependencies = { "tpope/vim-repeat" },
	},
	{
		"ggandor/flit.nvim",
		keys = function()
			local ret = {}
			for _, key in ipairs({ "f", "F", "t", "T" }) do
				ret[#ret + 1] = { key, mode = { "n", "x", "o" }, desc = key }
			end
			return ret
		end,
		opts = { labeled_modes = "nx" },
	},
	{
		"nvim-pack/nvim-spectre",
		dependencies = { "nvim-lua/plenary.nvim" },
		cmd = "Spectre",
		opts = { open_cmd = "noswapfile vnew" },
	},
	{
		"AckslD/muren.nvim",
		config = true,
		cmd = {
			"MurenOpen",
			"MurenClose",
			"MurenToggle",
			"MurenFresh",
			"MurenUnique",
		},
	},
	{
		"ThePrimeagen/refactoring.nvim",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-treesitter/nvim-treesitter",
		},
		config = true,
	},
	{
		"barrett-ruth/import-cost.nvim",
		enabled = false, -- NOTE: Seems resource intensive
		event = "VeryLazy",
		build = "sh install.sh yarn",
		opts = {
			filetypes = {
				"javascript",
				"javascriptreact",
				"typescript",
				"typescriptreact",
				"vue",
			},
		},
	},
	{
		"mattn/emmet-vim",
		event = "VeryLazy",
		dependencies = { "mattn/webapi-vim", lazy = false },
	},
	{
		"kylechui/nvim-surround",
		version = "*", -- Use for stability; omit to use `main` branch for the latest features
		event = "VeryLazy",
		config = true,
	},
	{ "tpope/vim-repeat", event = "VeryLazy" },
	{ "tpope/vim-abolish", event = "VeryLazy" },
	{
		"mbbill/undotree",
		cmd = { "UndotreeShow", "UndotreeToggle" },
	},
	{
		"simrat39/symbols-outline.nvim",
		cmd = { "SymbolsOutline" },
		opts = { show_numbers = true, show_relative_numbers = true, auto_preview = true },
	},
	{ "editorconfig/editorconfig-vim", event = "BufReadPre" },
	{
		"mg979/vim-visual-multi",
		enabled = true,
		branch = "master",
	},
	-- DB
	{
		"kndndrj/nvim-dbee",
		dependencies = {
			"MunifTanjim/nui.nvim",
		},
		build = function()
			-- Install tries to automatically detect the install method
			-- If it fails, try calling it with one of these paramaters:
			--    "curl", "wget", "bitsadmin", "go"
			require("dbee").install()
		end,
		config = function()
			require("dbee").setup({
				sources = {
					require("dbee.sources").FileSource:new(get_cache_dir() .. "/dbee/persistence.json"),
					require("dbee.sources").EnvSource:new("DBEE_CONNECTIONS"),
				},
			})
		end,
	},
	{
		"tpope/vim-dadbod",
		enabled = false,
		dependencies = {
			"kristijanhusak/vim-dadbod-ui",
			"kristijanhusak/vim-dadbod-completion",
		},
		cmd = { "DB", "DBUI", "DBUIToggle", "DBUIAddConnection", "DBUIFindBuffer", "DBUIRenameBuffer" },
	},
	-- Session Management
	{
		"olimorris/persisted.nvim",
		lazy = false,
		dependencies = { "nvim-telescope/telescope.nvim" },
		config = function()
			require("persisted").setup({
				save_dir = _G.SESSIONDIR,
				autoload = true,
				use_git_branch = true,
				should_autosave = function()
					-- do not autosave if the alpha dashboard is the current filetype
					if vim.bo.filetype == "alpha" then
						return false
					end
					return true
				end,
			})
		end,
		-- opts = {
		-- 	save_dir = _G.SESSIONDIR,
		-- 	autoload = true,
		-- 	use_git_branch = true,
		-- 	should_autosave = function()
		-- 		-- do not autosave if the alpha dashboard is the current filetype
		-- 		if vim.bo.filetype == "alpha" then
		-- 			return false
		-- 		end
		-- 		return true
		-- 	end,
		-- },
	},
	-- Editor Visuals
	{
		"max397574/better-escape.nvim",
		event = "BufRead",
		config = true,
	},
	{
		"windwp/nvim-autopairs",
		event = "BufRead",
		opts = {
			fast_wrap = {},
			disable_filetype = { "TelescopePrompt", "vim", "guihua", "guihua_rust", "clap_input" },
		},
	},
	{
		"numToStr/Comment.nvim",
		event = "BufRead",
		dependencies = { "JoosepAlviste/nvim-ts-context-commentstring" },
		config = function()
			require("Comment").setup({
				mappings = {
					basic = false,
					extra = false,
					extended = false,
				},
				pre_hook = require("ts_context_commentstring.integrations.comment_nvim").create_pre_hook(),
			})
		end,
	},
	{
		"folke/todo-comments.nvim",
		cmd = { "TodoTrouble", "TodoTelescope" },
		event = "BufReadPost",
		dependencies = { "nvim-lua/plenary.nvim" },
		config = true,
	},
	{
		"Wansmer/treesj",
		cmd = { "TSJToggle", "TSJSplit", "TSJJoin" },
		opts = {
			use_default_keymaps = false,
		},
	},
	{
		"tversteeg/registers.nvim",
		cmd = { "Registers" },
		config = true,
	},
	{
		"kensyo/nvim-scrlbkun",
		-- "petertriho/nvim-scrollbar",
		-- dependencies = { "kevinhwang91/nvim-hlslens" },
		event = "VeryLazy",
		-- config = function()
		-- local scroll_ok, scrollbar = pcall(require, "scrollbar")
		-- scrollbar.setup()
		-- require("scrlbkun").setup({
		-- 	width = 1,
		-- })
		-- If you also want to configure `hlslens`
		-- require("scrollbar.handlers.search").setup()
		-- end,
		opts = { width = 1 },
	},
	{ "RRethy/vim-illuminate", event = "BufReadPost" },
	-- Misc
	{
		"max397574/colortils.nvim",
		cmd = "Colortils",
		opts = {
			default_format = "hex", -- "rgb" || "hsl"
		},
	},
	{ "szw/vim-maximizer", cmd = { "MaximizerToggle" } },
	{
		"sindrets/winshift.nvim",
		cmd = "WinShift",
		config = true,
	},
	{
		"jackMort/ChatGPT.nvim",
		enabled = false,
		cmd = { "ChatGPT", "ChatGPTActAs", "ChatGPTEditWithInstructions" },
		config = true,
		dependencies = {
			"MunifTanjim/nui.nvim",
			"nvim-lua/plenary.nvim",
			"nvim-telescope/telescope.nvim",
		},
	},
	{
		"Bryley/neoai.nvim",
		enabled = false,
		dependencies = {
			"MunifTanjim/nui.nvim",
		},
		cmd = {
			"NeoAI",
			"NeoAIOpen",
			"NeoAIClose",
			"NeoAIToggle",
			"NeoAIContext",
			"NeoAIContextOpen",
			"NeoAIContextClose",
			"NeoAIInject",
			"NeoAIInjectCode",
			"NeoAIInjectContext",
			"NeoAIInjectContextCode",
		},
		config = true,
	},
	{
		"RishabhRD/nvim-cheat.sh",
		dependencies = { "RishabhRD/popfix" },
		cmd = { "Cheat", "CheatWithoutComments", "CheatList", "CheatListWithoutComments" },
	},
	{
		"ziontee113/icon-picker.nvim",
		cmd = { "IconPickerNormal", "IconPickerInsert", "IconPickerYank" },
		opts = {
			disable_legacy_commands = true,
		},
	},
	{ "eandrju/cellular-automaton.nvim", cmd = "CellularAutomaton" },
	{
		"tamton-aquib/zone.nvim",
		enabled = false,
		opts = {
			style = "vanish",
			after = 60,
		},
	},
	-- Themes
	{
		"folke/styler.nvim",
		event = "VeryLazy",
		opts = {
			themes = {
				markdown = { colorscheme = "oxocarbon" },
				gitcommit = { colorscheme = "tokyodark" },
				gitrebase = { colorscheme = "rose-pine" },
				help = { colorscheme = "catppuccin", background = "dark" },
			},
		},
	},
	{
		"catppuccin/nvim",
		priority = 999,
		lazy = false,
		name = "catppuccin",
		config = function()
			local ctpcn_ok, ctpcn = pcall(require, "catppuccin")
			if ctpcn_ok then
				ctpcn.setup({
					flavour = "mocha",
					no_italic = false,
					no_bold = false,
					-- Awesome dark variant I got from https://github.com/nullchilly/nvim/blob/nvim/lua/config/catppuccin.lua
					-- But I couldn't get the time to research how to make NvimTree Context match it so, commented out for now
					-- color_overrides = {
					-- 	mocha = {
					-- 		base = "#000000",
					-- 	},
					-- },
					dim_inactive = {
						enabled = true,
					},
					styles = {
						types = { "italic" },
						booleans = { "italic" },
					},
					term_colors = true,
					integrations = {
						alpha = true,
						beacon = true,
						cmp = true,
						fidget = true,
						gitgutter = true,
						gitsigns = true,
						illuminate = true,
						indent_blankline = { enabled = true },
						notify = true,
						mason = true,
						mini = true,
						navic = true,
						native_lsp = {
							enabled = true,
							underlines = {
								errors = { "undercurl" },
								hints = { "undercurl" },
								warnings = { "undercurl" },
								information = { "undercurl" },
							},
						},
						neotest = true,
						noice = true,
						nvimtree = true,
						semantic_tokens = true,
						telescope = true,
						treesitter = true,
						treesitter_context = true,
						ts_rainbow = true,
						symbols_outline = true,
						lsp_trouble = true,
						which_key = true,
					},
					native_lsp = {
						enabled = true,
						virtual_text = {
							errors = { "italic" },
							hints = { "italic" },
							warnings = { "italic" },
							information = { "italic" },
						},
						underlines = {
							errors = { "underline" },
							hints = { "underline" },
							warnings = { "underline" },
							information = { "underline" },
						},
					},
					highlight_overrides = {
						mocha = function(C)
							return {
								TabLineSel = { bg = C.pink },
								NvimTreeNormal = { bg = C.none },
								CmpBorder = { fg = C.surface2 },
								Pmenu = { bg = C.none },
								NormalFloat = { bg = C.none },
							}
						end,
					},
				})
			else
				vim.notify("Theme Error", vim.log.levels.WARN)
			end
		end,
	},
	{
		"tiagovla/tokyodark.nvim",
		priority = 999,
		lazy = false,
	},
	{
		"rose-pine/neovim",
		priority = 999,
		lazy = false,
		name = "rose-pine",
		config = function()
			local rp_ok, rp = pcall(require, "rose-pine")
			if rp_ok then
				rp.setup()
			else
				vim.notify("Theme Error", vim.log.levels.WARN)
			end
		end,
	},
	{
		"rebelot/kanagawa.nvim",
		priority = 999,
		lazy = false,
		config = function()
			local kngw_ok, kngw = pcall(require, "kanagawa")
			if kngw_ok then
				kngw.setup({
					compile = true,
					theme = "dragon",
					background = {
						dark = "dragon",
						light = "wave",
					},
				})
			else
				vim.notify("Theme Error", vim.log.levels.WARN)
			end
		end,
	},
	{
		"nyoom-engineering/oxocarbon.nvim",
		priority = 999,
		lazy = false,
	},
}

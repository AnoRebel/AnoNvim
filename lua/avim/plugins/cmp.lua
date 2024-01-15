local M = {
	"hrsh7th/nvim-cmp",
	event = "InsertEnter",
	dependencies = {
		{ "rafamadriz/friendly-snippets" },
		{ "saadparwaiz1/cmp_luasnip" },
		{ "L3MON4D3/LuaSnip" },
		{ "hrsh7th/cmp-nvim-lua" },
		{ "hrsh7th/cmp-nvim-lsp" },
		{ "hrsh7th/cmp-buffer" },
		{ "hrsh7th/cmp-path" },
		{ "hrsh7th/cmp-calc" },
		{ "hrsh7th/cmp-cmdline" },
		{ "lukas-reineke/cmp-under-comparator" },
		{ "hrsh7th/cmp-nvim-lsp-signature-help" },
		{ "dmitmel/cmp-cmdline-history" },
		{ "David-Kunz/cmp-npm" },
		{
			"tzachar/cmp-tabnine",
			build = "./install.sh",
			enabled = require("avim.utils").get_os()[2] ~= "arm",
		},
		{ "roobert/tailwindcss-colorizer-cmp.nvim", opts = { color_square_width = 2 } },
		{
			"Exafunction/codeium.nvim",
			enabled = true,
			dependencies = {
				"nvim-lua/plenary.nvim",
				"hrsh7th/nvim-cmp",
			},
			config = function()
				require("codeium").setup({
					config_path = _G.get_config_dir() .. "/codeium/config.json",
					bin_path = _G.get_runtime_dir() .. "/codeium/bin",
				})
			end,
		},
		{
			"Exafunction/codeium.vim",
			enabled = true,
			event = "BufEnter",
			config = function()
				local whichkey_exists, wk = pcall(require, "which-key")
				if whichkey_exists then
					wk.register({
						["<A-p>"] = {
							function()
								return vim.fn["codeium#CycleCompletions"](-1)
							end,
							"Codeium: Previous Suggestion",
						},
					}, { mode = "i" })
					wk.register({
						["<A-n>"] = {
							function()
								return vim.fn["codeium#CycleCompletions"](1)
							end,
							"Codeium: Next Suggestion",
						},
					}, { mode = "i" })
					wk.register({
						["<A-a>"] = {
							function()
								-- NOTE: Hack fix for this mapping always being set to nil
								-- return vim.fn["codeium#Accept"]()
								return vim.fn.feedkeys(
									vim.api.nvim_replace_termcodes(vim.fn["codeium#Accept"](), true, true, true),
									""
								)
							end,
							"Codeium: Accept Suggestion",
						},
					}, { mode = "i" })
					wk.register({
						["<A-Space>"] = {
							function()
								return vim.fn["codeium#Complete"]()
							end,
							"Codeium: Trigger Suggestions",
						},
					}, { mode = "i" })
					wk.register({
						["<A-Bslash>"] = {
							function()
								return vim.fn["codeium#Clear"]()
							end,
							"Codeium: Clear Suggestions",
						},
					}, { mode = "i" })
				else
					-- Change '<C-g>' here to any keycode you like.
					vim.keymap.set("i", "<A-a>", function()
						-- NOTE: Hack fix for this mapping always being set to nil
						-- return vim.fn["codeium#Accept"]()
						return vim.fn.feedkeys(
							vim.api.nvim_replace_termcodes(vim.fn["codeium#Accept"](), true, true, true),
							""
						)
					end, { expr = true, silent = true, desc = "Codeium: Accept Suggestion" })
					vim.keymap.set("i", "<A-n>", function()
						return vim.fn["codeium#CycleCompletions"](1)
					end, { expr = true, silent = true, desc = "Codeium: Next Suggestion" })
					vim.keymap.set("i", "<A-p>", function()
						return vim.fn["codeium#CycleCompletions"](-1)
					end, { expr = true, silent = true, desc = "Codeium: Previous Suggestion" })
					vim.keymap.set("i", "<A-Space>", function()
						return vim.fn["codeium#Complete"]()
					end, { expr = true, silent = true, desc = "Codeium: Trigger Suggestions" })
					vim.keymap.set("i", "<A-Bslash>", function()
						return vim.fn["codeium#Clear"]()
					end, { expr = true, silent = true, desc = "Codeium: Clear Suggestions" })
				end
			end,
		},
	},
}

function M.config()
	local cmp = require("cmp")
	local icons = require("avim.icons")

	-- Utils
	local check_backspace = function()
		local col = vim.fn.col(".") - 1
		return col == 0 or vim.fn.getline("."):sub(col, col):match("%s")
	end

	-- Info Window Scroll Management
	-- local cmp_window = require "cmp.utils.window"
	-- cmp_window.info_ = cmp_window.info
	-- cmp_window.info = function(self)
	--   local info = self:info_()
	--   info.scrollable = false
	--   return info
	-- end
	-- function cmp_window:has_scrollbar()
	--    return false
	-- end

	local snip_ok, luasnip = pcall(require, "luasnip")
	if not snip_ok then
		vim.notify("Luasnip Error", vim.log.levels.WARN)
		return
	end
	luasnip.config.set_config({
		history = true,
		delete_check_events = "TextChanged",
		updateevents = "TextChanged,TextChangedI",
	})
	require("luasnip.loaders.from_vscode").lazy_load()

	local source_mapping = {
		buffer = "[BUF]", -- icons.buffer .. "[BUF]",
		calc = "[CLC]", -- icons.calculator .. "[CLC]",
		cmp_tabnine = "[TB9]", -- icons.light .. "[TB9]",
		codeium = "[CODE]", -- icons.rocket .. "[CODE]",
		luasnip = "[SNP]", -- icons.snippet .. "[SNP]",
		npm = "[NPM]", -- icons.terminal .. "[NPM]",
		nvim_lsp = "[LSP]", -- icons.paragraph .. "[LSP]",
		nvim_lua = "[LUA]", -- icons.bomb .. "[LUA]",
		path = "[PTH]", -- icons.folderOpen2 .. "[PTH]",
		treesitter = "[TST]", -- icons.tree .. "[TST]",
		zsh = "[ZSH]", -- icons.terminal .. "[ZSH]",
	}

	local options = {
		window = {
			completion = {
				winhighlight = "Normal:NormalFloat,NormalFloat:Pmenu,Pmenu:NormalFloat", -- "Normal:Pmenu,FloatBorder:Pmenu,Search:None",
				col_offset = -3,
				side_padding = 1,
				border = "none", -- require("avim.core.defaults").options.border_chars,
			},
			documentation = {
				border = require("avim.core.defaults").options.border_chars,
			},
		},
		snippet = {
			expand = function(args)
				luasnip.lsp_expand(args.body)
			end,
		},
		formatting = {
			fields = { "kind", "abbr", "menu" },
			format = function(entry, vim_item)
				local menu = source_mapping[entry.source.name]
				local label = vim_item.abbr
				local kind = icons.kind_icons[vim_item.kind]
				local maxwidth = 50

				if entry.source.name == "cmp_tabnine" then
					if entry.completion_item.data ~= nil and entry.completion_item.data.detail ~= nil then
						menu = menu .. "[" .. entry.completion_item.data.detail .. "]"
					end
				end

				vim_item.menu = menu
				vim_item.kind = string.format("%s", kind)
				local truncated_label = vim.fn.strcharpart(label, 0, maxwidth)
				if truncated_label ~= label then
					vim_item.abbr = truncated_label .. "..."
				else
					vim_item.abbr = string.sub(vim_item.abbr, 1, maxwidth)
				end
				vim_item = require("tailwindcss-colorizer-cmp").formatter(entry, vim_item)
				return vim_item
			end,
		},
		duplicates = {
			buffer = 1,
			path = 1,
			nvim_lsp = 1,
			luasnip = 1,
			cmp_tabnine = 1,
			codeium = 1,
			treesitter = 1,
		},
		duplicates_default = 0,
		mapping = cmp.mapping.preset.insert({
			["<C-p>"] = cmp.mapping.select_prev_item(),
			["<C-n>"] = cmp.mapping.select_next_item(),
			["<C-d>"] = cmp.mapping(cmp.mapping.scroll_docs(-2), { "i", "c" }),
			["<C-f>"] = cmp.mapping(cmp.mapping.scroll_docs(2), { "i", "c" }),
			["<C-Space>"] = cmp.mapping(cmp.mapping.complete(), { "i", "c" }),
			["<C-y>"] = cmp.config.disable, -- Specify `cmp.config.disable` if you want to remove the default `<C-y>` mapping.
			["<C-e>"] = cmp.mapping({
				i = cmp.mapping.abort(),
				c = cmp.mapping.close(),
			}),
			["<CR>"] = cmp.mapping({
				i = function(fallback)
					if cmp.visible() and cmp.get_active_entry() then
						cmp.confirm({ behavior = cmp.ConfirmBehavior.Insert, select = false }) -- prevent overwriting brackets
					else
						fallback()
					end
				end,
				s = cmp.mapping.confirm({ select = true }),
				c = cmp.mapping.confirm({ behavior = cmp.ConfirmBehavior.Replace, select = true }),
			}),
			["<Tab>"] = cmp.mapping(function(fallback)
				local has_words_before = function()
					unpack = unpack or table.unpack
					local line, col = unpack(vim.api.nvim_win_get_cursor(0))
					return col ~= 0
						and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") == nil
				end
				if cmp.visible() then
					cmp.select_next_item()
				elseif luasnip.expandable() then
					luasnip.expand()
				elseif luasnip.expand_or_jumpable() then
					luasnip.expand_or_jump()
				elseif has_words_before() then
					cmp.complete()
				elseif check_backspace() then
					fallback()
				else
					fallback()
				end
			end, {
				"i",
				"s",
				"c",
			}),
			["<S-Tab>"] = cmp.mapping(function(fallback)
				if cmp.visible() then
					cmp.select_prev_item()
				elseif luasnip.jumpable(-1) then
					luasnip.jump(-1)
				else
					fallback()
				end
			end, {
				"i",
				"s",
				"c",
			}),
		}),
		-- You should specify your *installed* sources.
		sources = {
			{ name = "nvim_lsp" },
			{ name = "nvim_lsp_signature_help" },
			{ name = "codeium" },
			{ name = "luasnip" },
			{ name = "buffer", keyword_length = 3 },
			{ name = "path" },
			{ name = "cmp_tabnine" }, -- max_item_count = 3
			{ name = "nvim_lua" },
			{ name = "calc" },
			{ name = "npm", keyword_length = 3 },
		},
		-- don't sort double underscore things first
		sorting = {
			comparators = {
				require("cmp_tabnine.compare"),
				cmp.config.compare.offset,
				cmp.config.compare.exact,
				cmp.config.compare.score,
				-- cmp.config.compare.scopes,
				require("cmp-under-comparator").under,
				cmp.config.compare.recently_used,
				cmp.config.compare.locality,
				cmp.config.compare.kind,
				-- cmp.config.compare.sort_text,
				cmp.config.compare.length,
				cmp.config.compare.order,
			},
		},
		confirm_opts = {
			behavior = cmp.ConfirmBehavior.Replace,
			-- behavior = cmp.ConfirmBehavior.Insert,
			select = false,
		},
		view = {
			entries = { name = "custom", selection_order = "near_cursor" }, -- "wildmenu" | "native",
		},
		experimental = {
			-- native_menu = false,
			ghost_text = true,
		},
	}

	local npm_ok, npm = pcall(require, "cmp-npm")
	if npm_ok then
		npm.setup({})
	else
		vim.notify("Cmp Npm Error", vim.log.levels.WARN)
	end

	cmp.setup(options)

	if require("avim.utils").get_os()[2] ~= "arm" then
		require("cmp_tabnine.config"):setup({
			max_lines = 1000,
			max_num_results = 3,
			sort = true,
			show_prediction_strength = true,
			run_on_every_keystroke = true,
			snipper_placeholder = "..",
			ignored_file_types = {},
		})
	end

	-- Use buffer source for `/` (if you enabled `native_menu`, this won't work anymore).
	cmp.setup.cmdline("/", {
		mapping = cmp.mapping.preset.cmdline(),
		sources = {
			{ name = "buffer" },
			{ name = "cmdline_history" },
		},
	})

	-- Use cmdline & path source for ':' (if you enabled `native_menu`, this won't work anymore).
	cmp.setup.cmdline(":", {
		mapping = cmp.mapping.preset.cmdline(),
		sources = cmp.config.sources({
			{ name = "path" },
			{ name = "cmdline_history" },
		}, {
			{ name = "cmdline" },
		}),
	})

	local cmp_autopairs = require("nvim-autopairs.completion.cmp")
	local auto_pairs = require("nvim-autopairs.completion.handlers")
	cmp.event:on(
		"confirm_done",
		cmp_autopairs.on_confirm_done({
			filetypes = {
				-- "*" is a alias to all filetypes
				["*"] = {
					["("] = {
						kind = {
							cmp.lsp.CompletionItemKind.Function,
							cmp.lsp.CompletionItemKind.Method,
						},
						handler = auto_pairs["*"],
					},
				},
				lua = {
					["("] = {
						kind = {
							cmp.lsp.CompletionItemKind.Function,
							cmp.lsp.CompletionItemKind.Method,
						},
						---@param char string
						---@param item item completion
						---@param bufnr buffer number
						handler = function(char, item, bufnr)
							-- Your handler function. Inpect with print(vim.inspect{char, item, bufnr})
						end,
					},
				},
				-- Disable for tex
				tex = false,
			},
		})
	)

	-- History
	-- I dont like it for now, until I implement it better
	-- for _, cmd_type in ipairs({ '?', '@' }) do
	--   cmp.setup.cmdline(cmd_type, {
	--     mapping = cmp.mapping.preset.cmdline(),
	--     sources = {
	--       { name = 'cmdline_history' },
	--     },
	--   })
	-- end
end

return M

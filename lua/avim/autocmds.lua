local autocmd = vim.api.nvim_create_autocmd
local augroup = vim.api.nvim_create_augroup

vim.api.nvim_create_user_command("AvimUpdate", function()
	require("avim.core.updater")()
end, { force = true })

autocmd({ "FocusGained", "TermClose", "TermLeave" }, { command = "checktime" })

local vim_ui, _ = pcall(vim.api.nvim_get_autocmds, { group = "vim-ui_cmds" })
if not vim_ui then
	augroup("vim-ui_cmds", { clear = true })
end
autocmd("User", {
	pattern = "LazyDone",
	group = "vim-ui_cmds",
	once = true,
	callback = require("avim.utils.vim-ui").load,
})

local d_theme, _ = pcall(vim.api.nvim_get_autocmds, { group = "_dynamic_theme" })
if not d_theme then
	augroup("_dynamic_theme", { clear = true })
end
autocmd("VimEnter", {
	group = "_dynamic_theme",
	desc = "",
	pattern = "*",
	callback = function()
		local _time = os.date("*t")
		if (_time.hour >= 21 and _time.hour < 24) or (_time.hour >= 0 and _time.hour < 1) then
			vim.cmd([[colorscheme catppuccin]])
			avim.theme = vim.g.colors_name
		elseif (_time.hour >= 16 and _time.hour < 21) or (_time.hour >= 0 and _time.hour < 1) then
			vim.cmd([[colorscheme rose-pine]])
			avim.theme = vim.g.colors_name
		elseif _time.hour >= 1 and _time.hour < 5 then
			vim.cmd([[colorscheme kanagawa]])
			avim.theme = vim.g.colors_name
		elseif _time.hour >= 5 and _time.hour < 11 then
			vim.cmd([[colorscheme tokyodark]])
			avim.theme = vim.g.colors_name
		elseif _time.hour >= 11 and _time.hour < 16 then
			vim.cmd([[colorscheme oxocarbon]])
			avim.theme = vim.g.colors_name
		else
			vim.cmd([[colorscheme tokyodark]])
			avim.theme = vim.g.colors_name
		end
	end,
})

autocmd("BufEnter", {
	desc = "Open Neo-Tree on startup with directory",
	group = augroup("neotree_start", { clear = true }),
	callback = function()
		if package.loaded["neo-tree"] then
			vim.api.nvim_del_augroup_by_name("neotree_start")
		else
			local stats = vim.loop.fs_stat(vim.api.nvim_buf_get_name(0))
			if stats and stats.type == "directory" then
				require("neo-tree")
				vim.api.nvim_del_augroup_by_name("neotree_start")
				vim.api.nvim_exec_autocmds("BufEnter", {})
			end
		end
	end,
})

---- Hmmm, with winbar, i doubt that i need this though 🤔
local illum, _ = pcall(vim.api.nvim_get_autocmds, { group = "_illuminate_settings" })
if not illum then
	augroup("_illuminate_settings", { clear = true })
end
autocmd("VimEnter", {
	group = "_illuminate_settings",
	desc = "Change Cursor word highlight group",
	pattern = "*",
	callback = function()
		-- Fix Highlight group instead of underline, highlight
		vim.api.nvim_set_hl(0, "IlluminatedWordText", { link = "Visual" }) -- underline = false
		vim.api.nvim_set_hl(0, "IlluminatedWordRead", { link = "Visual" })
		vim.api.nvim_set_hl(0, "IlluminatedWordWrite", { link = "Visual" })
		vim.api.nvim_set_hl(0, "IlluminatedCurWord", { italic = true })
	end,
})

-- Disable statusline in dashboard
---- Hmmm, with winbar, i doubt that i need this though 🤔
local dash, _ = pcall(vim.api.nvim_get_autocmds, { group = "_dashboard_settings" })
if not dash then
	augroup("_dashboard_settings", {})
end
autocmd("FileType", {
	group = "_dashboard_settings",
	desc = "Hide statusline on Alpha",
	pattern = "alpha",
	-- command = "set showtabline=0 | autocmd BufLeave <buffer> set showtabline=" .. vim.opt.showtabline._value,
	command = "set laststatus=0 | autocmd BufUnload <buffer> set laststatus=" .. vim.opt.laststatus._value,
})

-- Deno and Volar vs Typescript conflict
local lsp_conficts, _ = pcall(vim.api.nvim_get_autocmds, { group = "LspAttach_conflicts" })
if not lsp_conficts then
	augroup("LspAttach_conflicts", {})
end
autocmd("LspAttach", {
	group = "LspAttach_conflicts",
	desc = "Prevent tsserver and volar/denols from competing",
	callback = function(args)
		if not (args.data and args.data.client_id) then
			return
		end
		local active_clients = vim.lsp.get_active_clients()
		local client = vim.lsp.get_client_by_id(args.data.client_id)
		-- prevent tsserver and denols competing
		-- if client.name == "denols" then
		-- 	for _, client_ in pairs(active_clients) do
		-- 		-- stop tsserver if denols is already active
		-- 		if client_.name == "tsserver" then
		-- 			client_.stop()
		-- 		end
		-- 	end
		-- elseif client.name == "tsserver" then
		-- 	for _, client_ in pairs(active_clients) do
		-- 		-- prevent tsserver from starting if denols is already active
		-- 		if client_.name == "denols" then
		-- 			client.stop()
		-- 		end
		-- 	end
		-- end
		-- -- prevent tsserver and volar competing
		-- if require("lspconfig").util.root_pattern("nuxt.config.ts")(vim.fn.getcwd()) then
		-- 	if client.name == "tsserver" then
		-- 		client.stop()
		-- 	end
		-- end
		-- prevent tsserver and volar competing
		-- if client.name == "volar" or/and require("lspconfig").util.root_pattern("nuxt.config.ts")(vim.fn.getcwd()) then
		if client.name == "volar" then
			for _, client_ in pairs(active_clients) do
				-- stop tsserver if volar is already active
				if client_.name == "tsserver" or client_.name == "denols" then
					client_.stop()
				end
			end
		elseif client.name == "tsserver" then
			for _, client_ in pairs(active_clients) do
				-- prevent tsserver from starting if volar is already active
				if client_.name == "volar" or client_.name == "denols" then
					client.stop()
				end
			end
		end
		-- elseif client.name == "denols" then
		-- 	for _, client_ in pairs(active_clients) do
		-- 		-- prevent tsserver from starting if denols is already active
		-- 		if client_.name == "volar" or client_.name == "tsserver" then
		-- 			client.stop()
		-- 		end
		-- 	end
		-- end
	end,
})

-- Inlay hints
local inlayhints, _ = pcall(vim.api.nvim_get_autocmds, { group = "LspAttach_inlayhints" })
if not inlayhints then
	augroup("LspAttach_inlayhints", {})
end
autocmd("LspAttach", {
	group = "LspAttach_inlayhints",
	desc = "Add inlay hints for supported LSP on attach",
	callback = function(args)
		if not (args.data and args.data.client_id) then
			return
		end
		local bufnr = args.buf
		local client = vim.lsp.get_client_by_id(args.data.client_id)
		vim.cmd("hi link LspInlayHint Comment")
		-- vim.cmd("hi LspInlayHint guifg=#d8d8d8 guibg=#3a3a3a")
		require("lsp-inlayhints").on_attach(client, bufnr)
	end,
})

-- Dim Windows
local win_dim, _ = pcall(vim.api.nvim_get_autocmds, { group = "_window_dim" })
if not win_dim then
	augroup("_window_dim", {})
end
autocmd("WinEnter", {
	group = "_window_dim",
	desc = "Dim inactive windows",
	pattern = "*",
	command = 'lua require("avim.utils").toggle_dim_windows()',
})

local win_res, _ = pcall(vim.api.nvim_get_autocmds, { group = "_window_resize" })
if not win_res then
	augroup("_window_resize", {})
end
-- autocmd({ "WinEnter", "FocusGained" }, {
--   group = "_window_resize",
--   desc = "Automaximize windows",
--   pattern = "*",
--   command = 'lua require("avim.utils").auto_maximize_window()',
-- })

-- Dim Windows
local num_tog, _ = pcall(vim.api.nvim_get_autocmds, { group = "_number_toggle" })
if not num_tog then
	augroup("_number_toggle", { clear = true })
end
local fts = {
	"qf",
	"help",
	"man",
	"lspinfo",
	"mason",
	"messages",
	"chatgpt",
	"dap-float",
	"DressingSelect",
	"alpha",
	"toggleterm",
	"terminal",
	"telescope",
	"Telescope",
	"TelescopePrompt",
	"spectre_panel",
	"startuptime",
	"NvimTree",
	"Neotree",
	"NeoTree",
	"neo-tree",
	"notify",
	"nui",
	"noice",
	"prompt",
	"Prompt",
	"popup",
	"code-action-menu-menu",
	"code-action-menu-diff",
	"code-action-menu-details",
	"code-action-menu-warning",
}
autocmd({ "BufEnter", "FocusGained", "InsertLeave", "CmdlineLeave", "WinEnter" }, {
	pattern = "*",
	group = "_number_toggle",
	callback = function()
		local bufnr = vim.api.nvim_get_current_buf()
		local buf_type = vim.bo[bufnr].buftype
		local buf_filetype = vim.bo[bufnr].filetype
		-- Skip if the filetype is on the list of exclusions.
		if
			vim.b.buftype == "messages"
			or vim.tbl_contains(fts, buf_filetype)
			or vim.tbl_contains(fts, buf_type)
			or vim.tbl_contains(fts, vim.api.nvim_buf_get_option(0, "buftype"))
		then
			return
		end
		if vim.o.nu and vim.api.nvim_get_mode().mode ~= "i" then
			vim.opt.relativenumber = true
			vim.cmd("redraw")
		end
	end,
})
autocmd({ "BufLeave", "FocusLost", "InsertEnter", "CmdlineEnter", "WinLeave" }, {
	pattern = "*",
	group = "_number_toggle",
	callback = function()
		local bufnr = vim.api.nvim_get_current_buf()
		local buf_type = vim.bo[bufnr].buftype
		local buf_filetype = vim.bo[bufnr].filetype
		-- Skip if the filetype is on the list of exclusions.
		if vim.tbl_contains(fts, buf_filetype) then
			return
		end
		if vim.tbl_contains(fts, buf_type) then
			return
		end
		if vim.tbl_contains(fts, vim.api.nvim_buf_get_option(0, "buftype")) then
			return
		end
		if vim.o.nu then
			vim.opt.relativenumber = false
			vim.cmd("redraw")
		end
	end,
})

local bufferlist, _ = pcall(vim.api.nvim_get_autocmds, { group = "bufferlist" })
if not bufferlist then
	augroup("bufferlist", { clear = true })
end
autocmd({ "BufAdd", "BufEnter" }, {
	desc = "Update buffers when adding new buffers",
	group = "bufferlist",
	callback = function(args)
		if not vim.t.bufs then
			vim.t.bufs = {}
		end
		local bufs = vim.t.bufs
		if not vim.tbl_contains(bufs, args.buf) then
			table.insert(bufs, args.buf)
			vim.t.bufs = bufs
		end
		vim.t.bufs = vim.tbl_filter(require("avim.utils").is_valid, vim.t.bufs)
		require("avim.utils").event("BufsUpdated")
	end,
})
autocmd("BufDelete", {
	desc = "Update buffers when deleting buffers",
	group = "bufferlist",
	callback = function(args)
		for _, tab in ipairs(vim.api.nvim_list_tabpages()) do
			local bufs = vim.t[tab].bufs
			if bufs then
				for i, bufnr in ipairs(bufs) do
					if bufnr == args.buf then
						table.remove(bufs, i)
						vim.t[tab].bufs = bufs
						break
					end
				end
			end
		end
		vim.t.bufs = vim.tbl_filter(require("avim.utils").is_valid, vim.t.bufs)
		require("avim.utils").event("BufsUpdated")
		vim.cmd.redrawtabline()
	end,
})

-- Add DB Completions
autocmd("FileType", {
	pattern = { "sql", "mysql", "plsql" },
	command = "lua require('cmp').setup.buffer({ sources = {{ name = 'vim-dadbod-completion' }} })",
})

-- Autopairs
autocmd("FileType", {
	pattern = { "guihua", "guihua_rust" },
	command = "lua require('cmp').setup.buffer({ enabled = false })",
})

-- Barbecue
local barbecue_updater, _ = pcall(vim.api.nvim_get_autocmds, { group = "barbecue.updater" })
if not barbecue_updater then
	augroup("barbecue.updater", {})
end
autocmd({
	"WinScrolled", -- or WinResized on NVIM-v0.9 and higher
	"WinResized",
	"BufWinEnter",
	"CursorHold",
	"InsertLeave",

	-- include this if you have set `show_modified` to `true`
	"BufModifiedSet",
}, {
	group = "barbecue.updater",
	callback = function()
		require("barbecue.ui").update()
	end,
})

-- vim-multi-visual and hlslens
-- vim.cmd([[
--   aug VMlens
--     au!
--     au User visual_multi_start lua require('avim.utils.vmlens').start()
--     au User visual_multi_exit lua require('avim.utils.vmlens').exit()
--   aug END
-- ]])
-- local vml_ok, _ = pcall(vim.api.nvim_get_autocmds, { group = "VMlens" })
-- if not vml_ok then
--   augroup("VMlens", { clear = true })
-- end
-- autocmd("visual_multi_start", {
--   group = "VMlens",
--   command = "lua require('avim.utils.vmlens').start()"
-- })
-- autocmd("visual_multi_exit", {
--   group = "VMlens",
--   command = "lua require('avim.utils.vmlens').exit()"
-- })

-- Luasnip
autocmd("InsertLeave", {
	callback = function()
		if
			require("luasnip").session.current_nodes[vim.api.nvim_get_current_buf()]
			and not require("luasnip").session.jump_active
		then
			require("luasnip").unlink_current()
		end
	end,
})

-- Trying to fix ufo closing all folds on escape insert mode
autocmd("BufEnter", {
	pattern = "*",
	command = "silent! setlocal foldlevel=99",
})

-- Don't autocomment new lines
local formopt, _ = pcall(vim.api.nvim_get_autocmds, { group = "_format_options" })
if not formopt then
	augroup("_format_options", {})
end
autocmd({ "BufWinEnter", "BufRead", "BufNewFile" }, {
	group = "_format_options",
	pattern = "*",
	command = "setlocal formatoptions-=c formatoptions-=r formatoptions-=o",
})

-- Misc from LunarVim
local resizin, _ = pcall(vim.api.nvim_get_autocmds, { group = "_auto_resize" })
if not resizin then
	augroup("_auto_resize", {})
end
autocmd("VimResized", {
	group = "_auto_resize",
	pattern = "*",
	command = "tabdo wincmd =",
})

-- Goto last location when opening a buffer
autocmd("BufReadPost", {
	callback = function()
		local mark = vim.api.nvim_buf_get_mark(0, '"')
		local lcount = vim.api.nvim_buf_line_count(0)
		if mark[1] > 0 and mark[1] <= lcount then
			pcall(vim.api.nvim_win_set_cursor, 0, mark)
		end
	end,
})

-- Highlight yanked text
local yankin, _ = pcall(vim.api.nvim_get_autocmds, { group = "_general_settings" })
if not yankin then
	augroup("_general_settings", {})
end
autocmd("TextYankPost", {
	group = "_general_settings",
	pattern = "*",
	desc = "Highlight text on yank",
	callback = function()
		vim.highlight.on_yank({ higroup = "Search", timeout = 200 })
	end,
})

-- FileType Options
local ftopt, _ = pcall(vim.api.nvim_get_autocmds, { group = "_filetype_settings" })
if not ftopt then
	augroup("_filetype_settings", {})
end
-- Enable spellchecking in markdown, text and gitcommit files
autocmd("FileType", {
	group = "_filetype_settings",
	pattern = { "gitcommit", "gitrebase", "svg", "hgcommit", "markdown", "text" },
	command = "setlocal wrap spell",
	-- callback = function()
	--   vim.opt_local.spell = true
	-- end,
})
autocmd("FileType", {
	group = "_filetype_settings",
	pattern = "qf",
	command = "set nobuflisted",
})

-- FileType Options
local bufopt, _ = pcall(vim.api.nvim_get_autocmds, { group = "_buffer_mappings" })
if not bufopt then
	augroup("_buffer_mappings", {})
end
autocmd("FileType", {
	group = "_buffer_mappings",
	pattern = {
		"PlenaryTestPopup",
		"notify",
		"spectre_panel",
		"tsplayground",
		"neotest-output",
		"checkhealth",
		"neotest-summary",
		"neotest-output-panel",
		"qf",
		"help",
		"man",
		"floaterm",
		"lspinfo",
		"dap-float",
		"null-ls-info",
	},
	-- command = "nnoremap <silent> <buffer> q :close<CR>",
	callback = function(event)
		vim.bo[event.buf].buflisted = false
		vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = event.buf, silent = true, nowait = true })
	end,
})

local bcon, _ = pcall(vim.api.nvim_get_autocmds, { group = "_beacon_cursor_line" })
if not bcon then
	augroup("_beacon_cursor_line", {})
end
autocmd("WinEnter", {
	group = "_beacon_cursor_line",
	pattern = "*",
	desc = "Hide cursor line on inactive windows",
	command = "setlocal cursorline",
})
autocmd("WinLeave", {
	group = "_beacon_cursor_line",
	pattern = "*",
	desc = "Hide cursor line on inactive windows",
	command = "setlocal nocursorline",
})

-- Auto create dir when saving a file, in case some intermediate directory does not exist
local auto_create, _ = pcall(vim.api.nvim_get_autocmds, { group = "auto_create_dir" })
if not auto_create then
	augroup("auto_create_dir", {})
end
autocmd({ "BufWritePre" }, {
	group = "auto_create_dir",
	callback = function(event)
		if event.match:match("^%w%w+://") then
			return
		end
		local file = vim.loop.fs_realpath(event.match) or event.match
		vim.fn.mkdir(vim.fn.fnamemodify(file, ":p:h"), "p")
	end,
})

-- TODO: This looks good, needs a rewrite to make it work
-- autocmd({ 'ModeChanged' }, {
--     desc = 'Stop snippets when you leave to normal mode',
--     pattern = '*',
--     callback = function()
--         if
--             ((vim.v.event.old_mode == 's' and vim.v.event.new_mode == 'n') or vim.v.event.old_mode == 'i')
--             and require('luasnip').session.current_nodes[vim.api.nvim_get_current_buf()]
--             and not require('luasnip').session.jump_active
--         then
--             require('luasnip').unlink_current()
--         end
--     end,
-- })

-- Open a file from its last left off position
-- autocmd("BufReadPost", {
--    callback = function()
--       if not vim.fn.expand("%:p"):match ".git" and vim.fn.line "'\"" > 1 and vim.fn.line "'\"" <= vim.fn.line "$" then
--          vim.cmd "normal! g'\""
--          vim.cmd "normal zz"
--       end
--    end,
-- })

-- Custom Filetypes
autocmd({ "BufNewFile", "BufRead" }, { pattern = { "*.rasi", "rasi" }, command = "setf css" })
autocmd({ "BufNewFile", "BufRead" }, { pattern = { "*.ejs", "ejs" }, command = "setf html" })
autocmd({ "BufNewFile", "BufRead" }, { pattern = { "*.sh", "sh" }, command = "setf sh" })
autocmd({ "BufNewFile", "BufRead" }, { pattern = { "*.conf", "conf" }, command = "setf dosini" })

local comp_hl = {
	PmenuSel = { bg = "#282C34", fg = "NONE" },
	Pmenu = { fg = "#C5CDD9", bg = "#22252A" },

	CmpItemAbbrDeprecated = { fg = "#7E8294", bg = "NONE", strikethrough = true },
	CmpItemAbbrMatch = { fg = "#82AAFF", bg = "NONE", bold = true },
	CmpItemAbbrMatchFuzzy = { fg = "#82AAFF", bg = "NONE", bold = true },
	CmpItemMenu = { fg = "#C792EA", bg = "NONE", italic = true },

	CmpItemKindField = { fg = "#EED8DA", bg = "#B5585F" },
	CmpItemKindProperty = { fg = "#EED8DA", bg = "#B5585F" },
	CmpItemKindEvent = { fg = "#EED8DA", bg = "#B5585F" },

	CmpItemKindText = { fg = "#C3E88D", bg = "#9FBD73" },
	CmpItemKindEnum = { fg = "#C3E88D", bg = "#9FBD73" },
	CmpItemKindKeyword = { fg = "#C3E88D", bg = "#9FBD73" },

	CmpItemKindConstant = { fg = "#FFE082", bg = "#D4BB6C" },
	CmpItemKindConstructor = { fg = "#FFE082", bg = "#D4BB6C" },
	CmpItemKindReference = { fg = "#FFE082", bg = "#D4BB6C" },

	CmpItemKindFunction = { fg = "#EADFF0", bg = "#A377BF" },
	CmpItemKindStruct = { fg = "#EADFF0", bg = "#A377BF" },
	CmpItemKindClass = { fg = "#EADFF0", bg = "#A377BF" },
	CmpItemKindModule = { fg = "#EADFF0", bg = "#A377BF" },
	CmpItemKindOperator = { fg = "#EADFF0", bg = "#A377BF" },

	CmpItemKindVariable = { fg = "#C5CDD9", bg = "#7E8294" },
	CmpItemKindFile = { fg = "#C5CDD9", bg = "#7E8294" },

	CmpItemKindUnit = { fg = "#F5EBD9", bg = "#D4A959" },
	CmpItemKindSnippet = { fg = "#F5EBD9", bg = "#D4A959" },
	CmpItemKindFolder = { fg = "#F5EBD9", bg = "#D4A959" },

	CmpItemKindMethod = { fg = "#DDE5F5", bg = "#6C8ED4" },
	CmpItemKindValue = { fg = "#DDE5F5", bg = "#6C8ED4" },
	CmpItemKindEnumMember = { fg = "#DDE5F5", bg = "#6C8ED4" },

	CmpItemKindInterface = { fg = "#D8EEEB", bg = "#58B5A8" },
	CmpItemKindColor = { fg = "#D8EEEB", bg = "#58B5A8" },
	CmpItemKindTypeParameter = { fg = "#D8EEEB", bg = "#58B5A8" },
}
for grp, hls in pairs(comp_hl) do
	vim.api.nvim_set_hl(0, grp, hls)
end

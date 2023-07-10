-- Modes
-- n, v, i, t = mode names
--   normal_mode = 'n',
--   insert_mode = 'i',
--   visual_mode = 'v',
--   visual_bloCk_mode = 'x',
--   term_mode = 't',
--   Command_mode = 'c',
--   all_mode = ' ',

local function termcodes(str)
	return vim.api.nvim_replace_termcodes(str, true, true, true)
end

local M = {}

-- NOTE: Prefer using : over <cmd> as the latter avoids going back in normal-mode.
-- see https://neovim.io/doc/user/map.html#:map-cmd
M.v = {
	-- Don't copy the replaced text after pasting in visual mode
	["p"] = { "p:let @+=@0<CR>", "Paste" },
	["<leader>/"] = { "<esc><cmd> :lua require('Comment.api').toggle.linewise(vim.fn.visualmode())<CR>", "Comment" },
	["<leader>s"] = { ":lua require('spectre').open_visual()<CR>", "Spectre" },
	["E"] = { "<end>", "End" },
	["H"] = { "<home>", "Home" },
	["<C-s>"] = { "<ESC> :w<CR>", "Save File" },
	-- ["<C-W>"] = { "<ESC>:wa<CR>", "Save All" },
	-- ["<A-k>"] = { ":move '<-2<CR>gv-gv", opts = { noremap = true, silent = true } },
	-- ["<A-j>"] = { ":move '>+1<CR>gv-gv", opts = { noremap = true, silent = true } },
	-- Allow moving the cursor through wrapped lines with j, k, <Up> and <Down>
	-- http<cmd> ://www.reddit.com/r/vim/comments/2k4cbr/problem_with_gj_and_gk/
	["<"] = { "<gv", "Tab Backwards" },
	[">"] = { ">gv", "Tab Forward" },
	["<Tab>"] = { ">gv", "Tab Forward" },
	["<S-Tab>"] = { "<gv", "Tab Backwards" },
	-- Refactoring
	["<leader>r"] = { name = " Refactoring" },
	["<leader>re"] = {
		"<ESC><Cmd>lua require('refactoring').refactor('Extract Function')<CR>",
		"Extract Function",
		opts = { noremap = true, silent = true, expr = false },
	},
	["<leader>rf"] = {
		"<ESC><Cmd>lua require('refactoring').refactor('Extract Function To File')<CR>",
		"Extract Function to File",
		opts = { noremap = true, silent = true, expr = false },
	},
	["<leader>rv"] = {
		"<ESC><Cmd>lua require('refactoring').refactor('Extract Variable')<CR>",
		"Extract Variable",
		opts = { noremap = true, silent = true, expr = false },
	},
	["<leader>ri"] = {
		"<ESC><Cmd>lua require('refactoring').refactor('Inline Variable')<CR>",
		"Inline Variable",
		opts = { noremap = true, silent = true, expr = false },
	},
	["<leader>rr"] = {
		"<ESC><Cmd>lua require('telescope').extensions.refactoring.refactors()<CR>",
		"Telescope Refactor",
		opts = { noremap = true },
	},
}
M.i = {
	["<A-j>"] = { "<Esc>:move .+1<CR>==gi", "Move Line Down" },
	["<A-k>"] = { "<Esc>:move .-2<CR>==gi", "Move Line Up" },
	["<C-s>"] = { "<ESC> :w<CR>", "Save File" },
	["<A-u>"] = { "<ESC>viwUi", "Uppercase", opts = { noremap = true } },
	["<C-h>"] = { termcodes("<C-\\><C-n><C-w>h"), "Move to Left Window", opts = { silent = true } },
	["<C-j>"] = { termcodes("<C-\\><C-n><C-w>j"), "Move to Bottom Window", opts = { silent = true } },
	["<C-k>"] = { termcodes("<C-\\><C-n><C-w>k"), "Move to Top Window", opts = { silent = true } },
	["<C-l>"] = { termcodes("<C-\\><C-n><C-w>l"), "Move to Right Window", opts = { silent = true } },
	["kj"] = { "<ESC>", "Escape Insert Mode" }, -- { noremap = true, silent = true }
	["<C-c>"] = { "<ESC>ggVGy`.i", "Copy All Text" },
	-- ["<C-W>"] = { "<ESC>:wa<CR>", "Save All" },
	-- Notify
	-- ["<C-c>"] = {
	-- 	"<ESC>:lua require('notify').dismiss()<CR>i",
	-- 	"Dismiss Notifications",
	-- 	opts = { silent = true, noremap = true },
	-- },

	-- Cellular Automaton
	["<A-;>"] = { "<ESC><CMD>CellularAutomaton make_it_rain<CR>", "Make it Rain" },
	["<A-l>"] = { "<ESC><CMD>CellularAutomaton game_of_life<CR>", "Game of Life" },
}
M.t = {
	["<C-h>"] = { termcodes("<C-\\><C-n><C-w>h"), "Terminal Move Left", opts = { silent = true } },
	["<C-j>"] = { termcodes("<C-\\><C-n><C-w>j"), "Terminal Move Down", opts = { silent = true } },
	["<C-k>"] = { termcodes("<C-\\><C-n><C-w>k"), "Terminal Move Up", opts = { silent = true } },
	["<C-l>"] = { termcodes("<C-\\><C-n><C-w>l"), "Terminal Move Right", opts = { silent = true } },
	["jk"] = { termcodes("<C-\\><C-n>"), "Escape Terminal Mode", opts = { silent = true } },
}
M.x = {
	-- ["<C-Up>"] = { ":move '<-2<CR>gv-gv", "Move Line Up", opts = { noremap = true }, },
	-- ["<C-Down>"] = { ":move '>+1<CR>gv-gv", "Move Line Down", opts = { noremap= true }, },
	["<A-k>"] = { ":move '<-2<CR>gv-gv", "Move Selection Up" },
	["<A-j>"] = { ":move '>+1<CR>gv-gv", "Move Selection Down" },
	["K"] = { ":move '<-2<CR>gv-gv", "Move Selection Up" },
	["J"] = { ":move '>+1<CR>gv-gv", "Move Selection Down" },
	["<C-s>"] = { "<ESC> :w<CR>", "Save File" },
	-- ["<C-W>"] = { "<ESC>:wa<CR>", "Save All" },
	-- Searchbox
	["<leader>f"] = { name = "󰍉 Search" },
	["<leader>fs"] = { ":SearchBoxIncSearch visual_mode=true<CR>", "Search Visual" },
	["<leader>fr"] = { ":SearchBoxReplace confirm=menu visual_mode=true<CR>", "Replace Visual" },
	["<leader>fu"] = { ":lua require('ssr').open()<CR>", "Super Search and Replace" },
	["n"] = {
		"<Cmd>lua require('avim.utils').nN('n')<CR>",
		"Next Search Item",
		opts = { noremap = true, silent = true },
	},
	["N"] = {
		"<Cmd>lua require('avim.utils').nN('N')<CR>",
		"Previous Search Item",
		opts = { noremap = true, silent = true },
	},
	-- Refactoring
	["<leader>r"] = { name = " Refactoring" },
	["<leader>re"] = {
		"<ESC><Cmd>lua require('refactoring').refactor('Extract Function')<CR>",
		"Extract Function",
		opts = { noremap = true, silent = true, expr = false },
	},
	["<leader>rf"] = {
		"<ESC><Cmd>lua require('refactoring').refactor('Extract Function To File')<CR>",
		"Extract Function to File",
		opts = { noremap = true, silent = true, expr = false },
	},
	["<leader>rv"] = {
		"<ESC><Cmd>lua require('refactoring').refactor('Extract Variable')<CR>",
		"Extract Variable",
		opts = { noremap = true, silent = true, expr = false },
	},
	["<leader>ri"] = {
		"<ESC><Cmd>lua require('refactoring').refactor('Inline Variable')<CR>",
		"Inline Variable",
		opts = { noremap = true, silent = true, expr = false },
	},
	["<leader>rr"] = {
		"<ESC><Cmd>lua require('telescope').extensions.refactoring.refactors()<CR>",
		"Telescope Refactor",
		opts = { noremap = true },
	},
}
M.n = {
	-- Hlslens
	-- ["n"] = { "[[<Cmd>execute('normal! ' . v:count1 . 'n')<CR><Cmd>lua require('hlslens').start()<CR>]]", "Next Search Item", opts = { noremap = true, silent = true }},
	-- ["N"] = { "[[<Cmd>execute('normal! ' . v:count1 . 'N')<CR><Cmd>lua require('hlslens').start()<CR>]]", "Previous Search Item", opts = { noremap = true, silent = true }},
	["n"] = {
		"<Cmd>lua require('avim.utils').nN('n')<CR>",
		"Next Search Item",
		opts = { noremap = true, silent = true },
	},
	["N"] = {
		"<Cmd>lua require('avim.utils').nN('N')<CR>",
		"Previous Search Item",
		opts = { noremap = true, silent = true },
	},
	["*"] = {
		"[[*<Cmd>lua require('hlslens').start()<CR>]]",
		"Start * Search",
		opts = { noremap = true, silent = true },
	},
	["#"] = {
		"[[#<Cmd>lua require('hlslens').start()<CR>]]",
		"Start # Search",
		opts = { noremap = true, silent = true },
	},
	["g*"] = {
		"[[g*<Cmd>lua require('hlslens').start()<CR>]]",
		"Start g* Search",
		opts = { noremap = true, silent = true },
	},
	["g#"] = {
		"[[g#<Cmd>lua require('hlslens').start()<CR>]]",
		"Start g# Search",
		opts = { noremap = true, silent = true },
	},
	-- Window Move
	["<A-m>"] = { name = " Window Movement" },
	["<A-m><Tab>"] = { "<CMD>WinShift swap<CR>", "Swap Windows", opts = { noremap = true } },
	["<A-m>h"] = { "<CMD>WinShift left<CR>", "Shift Window Left", opts = { noremap = true } },
	["<A-m><Left>"] = { "<CMD>WinShift left<CR>", "Shift Window Left", opts = { noremap = true } },
	["<A-m>j"] = { "<CMD>WinShift down<CR>", "Shift Window Down", opts = { noremap = true } },
	["<A-m><Down>"] = { "<CMD>WinShift down<CR>", "Shift Window Down", opts = { noremap = true } },
	["<A-m>k"] = { "<CMD>WinShift up<CR>", "Shift Window Up", opts = { noremap = true } },
	["<A-m><Up>"] = { "<CMD>WinShift up<CR>", "Shift Window Up", opts = { noremap = true } },
	["<A-m>l"] = { "<CMD>WinShift right<CR>", "Shift Window Right", opts = { noremap = true } },
	["<A-m><Right>"] = { "<CMD>WinShift right<CR>", "Shift Window Right", opts = { noremap = true } },

	-- comment
	["<leader>/"] = { "<cmd> :lua require('Comment.api').toggle.linewise.current()<CR>", "Comment" },
	-- Cybu
	-- ["H"] = { "<Plug>(CybuPrev)", "", },
	-- ["L"] = { "<Plug>(CybuNext)", "", },
	-- lspconfig
	-- LSP Mappings
	["g"] = { name = "󰏖 LSP" },
	["gD"] = { "<cmd>lua vim.lsp.buf.declaration()<CR>", "Declaration(s)" },
	["gd"] = { "<cmd>lua vim.lsp.buf.definition()<CR>", "Definition(s)" },
	["K"] = { '<cmd>lua require("avim.utils").peek_or_hover()<CR>', "Peek or Hover" },
	["gi"] = { "<cmd>lua vim.lsp.buf.implementation()<CR>", "Implementation(s)" },
	["gk"] = { "<cmd>lua vim.lsp.buf.signature_help()<CR>", "Signature Help" },
	["<leader>w"] = { name = "󰓩 Workspace" },
	["<leader>wa"] = { "<cmd>lua vim.lsp.buf.add_workspace_folder()<CR>", "Add Folder to Workspace" },
	["<leader>wr"] = { "<cmd>lua vim.lsp.buf.remove_workspace_folder()<CR>", "Remove Folder From Workspace" },
	["<leader>wl"] = {
		"<cmd>lua print(vim.inspect(vim.lsp.buf.list_workspace_folders()))<CR>",
		"List Folders in Workspace",
	},
	["<leader>D"] = { "<cmd>lua vim.lsp.buf.type_definition()<CR>", "Type Definitions" },
	["<leader>ra"] = { "<cmd>lua vim.lsp.buf.rename()<CR>", "Rename" },
	["<leader>la"] = { ":CodeActionMenu<CR>", "Code Actions" },
	-- ["<leader>ca"] = { "<cmd>lua vim.lsp.buf.code_action()<CR>", "Code Actions", },
	["gr"] = { "<cmd>lua vim.lsp.buf.references()<CR>", "References" },
	["ge"] = { "<cmd>lua vim.diagnostic.open_float()<CR>", "Floating Diagnostics" },
	["gF"] = { "<cmd>Telescope diagnostics<CR>", "Telescope Diagnostics" },
	["[d"] = { "<cmd>lua vim.diagnostic.goto_prev()<CR>", "Previous Diagnostics" },
	["]d"] = { "<cmd>lua vim.diagnostic.goto_next()<CR>", "Next Diagnostics" },
	["<leader>sl"] = { "<cmd>lua vim.diagnostic.setloclist()<CR>", "Set Loclist" },
	["<leader>lm"] = { "<cmd>lua require('avim.utils').format()<CR>", "Format Document" },
	-- ["<leader>fm"] = { "<cmd>lua vim.lsp.buf.format {async = true}<CR>", "Format Document", },
	["<leader>l"] = { name = " System" },
	["<leader>li"] = { ":LspInfo<CR>", "Lsp Info" },
	["<leader>lI"] = { ":Mason<CR>", "Mason" },
	["<leader>ll"] = { ":lua vim.lsp.codelens.run()<CR>", "Codelens" },
	["<leader>lp"] = { name = "󰍉 Peek" },
	["<leader>lpd"] = { ":lua require('avim.lsp.peek').Peek('definition')<CR>", "Peek Definition(s)" },
	["<leader>lpt"] = { ":lua require('avim.lsp.peek').Peek('typeDefinition')<CR>", "Peek Type Definition(s)" },
	["<leader>lpi"] = { ":lua require('avim.lsp.peek').Peek('implementation')<CR>", "Peek Implementation(s)" },

	-- Package Manager
	["<leader>p"] = { name = "󰏖 Packages" },
	["<leader>pi"] = { "<cmd>Lazy install<CR>", "Install Packages" },
	["<leader>ps"] = { "<cmd>Lazy home<CR>", "Packages Status" },
	["<leader>pS"] = { "<cmd>Lazy sync<CR>", "Sync Packages" },
	["<leader>pc"] = { "<cmd>Lazy check<CR>", "Check Package Updates" },
	["<leader>pu"] = { "<cmd>Lazy update<CR>", "Update Packages" },
	["<leader>pm"] = { "<cmd>Mason<CR>", "Mason" },

	-- Movement
	["<C-h>"] = { "<C-n><C-w>h", "Move to Left Window", opts = { silent = true } },
	["<C-j>"] = { "<C-n><C-w>j", "Move to Bottom Window", opts = { silent = true } },
	["<C-k>"] = { "<C-n><C-w>k", "Move to Top Window", opts = { silent = true } },
	["<C-l>"] = { "<C-n><C-w>l", "Move to Right Window", opts = { silent = true } },

	-- File System
	["<leader>e"] = { "<cmd>Neotree toggle <CR>", "Neotree Toggle" },
	["<C-n>"] = { "<cmd>NvimTreeToggle <CR>", "Nvimtree Toggle" },
	["-"] = { "<cmd>Oil <CR>", "Open Parent on Oil" },
	["_"] = { "<cmd>Oil --float <CR>", "Open Parent on Floating Oil" },

	-- Rest API
	["<leader>a"] = { name = " Rest APIs" },
	["<leader>ar"] = { "<CMD><Plug>RestNvim<CR>", "Run Request" },
	["<leader>ap"] = { "<CMD><Plug>RestNvimPreview<CR>", "Preview Rest Command" },
	["<leader>al"] = { "<CMD><Plug>RestNvimLast<CR>", "Run Last Request" },

	-- telescope
	["<leader>f"] = { name = "󰍉 Telescope" },
	["<leader>te"] = { ":Telescope <CR>", "Telescope" },
	["<leader>fb"] = { "<cmd>Telescope buffers <CR>", "Buffer List" },
	["<leader>fB"] = { "<cmd>Telescope current_buffer_fuzzy_find <CR>", "Fuzzy Buffer List" },
	["<leader>ff"] = { "<cmd>Telescope find_files <CR>", "Find Files" },
	["<leader>fa"] = { "<cmd>Telescope find_files follow=true no_ignore=true hidden=true <CR>", "All Files" },
	["<leader>fc"] = { "<cmd>Telescope git_commits <CR>", "Git Commits" },
	["<leader>fC"] = { "<cmd>Telescope commands <CR>", "Commands" },
	["<leader>ft"] = { "<cmd>Telescope git_status <CR>", "Git Status" },
	["<leader>fh"] = { "<cmd>Telescope help_tags <CR>", "Help Tags" },
	["<leader>fw"] = { "<cmd>Telescope live_grep <CR>", "Live Search" },
	["<leader>fo"] = { "<cmd>Telescope oldfiles <CR>", "Old Files" },
	["<leader>fu"] = { ":lua require('avim.utils.theme_picker')()<CR>", "Themes" },
	["<leader>fk"] = { "<cmd>Telescope keymaps <CR>", "Key Mappings" },
	["<leader>fm"] = { ":Telescope media_files <CR>", "Media Files" },
	["<leader>fM"] = { ":Telescope man_pages <CR>", "Man Pages" },
	["<leader>fr"] = { ":Telescope resume <CR>", "Resume" },
	["<leader>fD"] = { ":Telescope lsp_document_symbols <CR>", "Document Symbols" },

	["<C-q>"] = { ":q <CR>", "Quit" },
	["<leader>q"] = { ":lua require('avim.utils').close_buffer()<CR>", "Close Buffers" },

	-- Flutter tools
	["<leader>fd"] = { ":Telescope flutter commands <CR>", "Flutter" },
	["<leader>to"] = { ":FlutterOutlineToggle<CR>", "Flutter Toggle Outline" },

	-- Todo-comments
	["<leader>tq"] = { ":TodoQuickFix<CR>", "Todo Quickfix" },
	["<leader>td"] = { ":TodoTelescope<CR>", "Telescope Todo" },
	["<leader>ts"] = { ":TodoTelescope keywords=TODO,FIX,FIXME<CR>", desc = "Todo/Fix/Fixme" },
	["<leader>tS"] = { ":TodoTrouble keywords=TODO,FIX,FIXME<CR>", desc = "Todo/Fix/Fixme (Trouble)" },

	-- Spectre
	-- run command :Spectre
	["<leader>S"] = { ":lua require('spectre').open()<CR>", "Spectre" },
	-- search current word
	["<leader>sw"] = { ":lua require('spectre').open_visual({select_word=true})<CR>", "Spectre Visual" },
	--  search in current file
	["<leader>sp"] = { "viw:lua require('spectre').open_file_search()<CR>", "Spectre File Search" },

	-- Muren Search
	["<leader>so"] = { ":MurenOpen<CR>", "Muren Search Open" },
	["<leader>sc"] = { ":MurenClose<CR>", "Muren Search Close" },
	["<leader>st"] = { ":MurenToggle<CR>", "Muren Search Toggle" },
	["<leader>sf"] = { ":MurenFresh<CR>", "Muren Search Fresh" },
	["<leader>su"] = { ":MurenUnique<CR>", "Muren Search Unique" },

	-- Trouble (Better Diagnostics and Errors)
	["<leader>x"] = { name = " Trouble" },
	["<leader>xx"] = { ":Trouble<CR>", "Trouble" },
	["<leader>xw"] = { ":Trouble workspace_diagnostics<CR>", "Trouble Workspace Diagnostics" },
	["<leader>xd"] = { ":Trouble document_diagnostics<CR>", "Trouble Document Diagnostics" },
	["<leader>xl"] = { ":Trouble loclist<CR>", "Trouble Loclist" },
	["<leader>xq"] = { ":Trouble quickfix<CR>", "Trouble Quickfix" },
	["gR"] = { ":Trouble lsp_references<CR>", "Trouble Lsp Reference(s)" },

	-- Toggle Line Blame
	["<leader>lb"] = { ":Gitsigns toggle_current_line_blame<CR>", "Blame Current Line" },

	-- Home and End
	["E"] = { "<end>", "End" },
	["H"] = { "<home>", "Home" },

	-- Cellular Automaton
	["<A-;>"] = { "<CMD>CellularAutomaton make_it_rain<CR>", "Make it Rain" },
	["<A-l>"] = { "<CMD>CellularAutomaton game_of_life<CR>", "Game of Life" },

	-- GoTo
	["gp"] = { name = "󰍉 Go To" },
	["gpd"] = {
		":lua require('goto-preview').goto_preview_definition()<CR>",
		"Preview Definition(s)",
		opts = { noremap = true },
	},
	["gpi"] = {
		":lua require('goto-preview').goto_preview_implementation()<CR>",
		"Preview Implementation(s)",
		opts = { noremap = true },
	},
	["gpc"] = { ":lua require('goto-preview').close_all_win()<CR>", "Close All", opts = { noremap = true } },
	-- Only set if you have telescope installed
	["gpr"] = {
		":lua require('goto-preview').goto_preview_references()<CR>",
		"Preview Reference(s)",
		opts = { noremap = true },
	},

	-- Move lines Up and Down
	["<A-j>"] = { ":move .+1<CR>==", "Move Line Up" },
	["<A-k>"] = { ":move .-2<CR>==", "Move Line Down" },

	-- Save file by CTRL-S
	-- ["<C-s>"] = { ":w<CR>", "Save File", opts = { noremap = true, silent = true }, },

	-- Keep visual mode indenting
	[">"] = { ":><CR>", "Tab Forwards" },
	["<"] = { ":<<CR>", "Tab Backward" },

	-- Folding
	["z"] = { name = "󰓩 Folds" },
	["zR"] = { '<cmd>lua require("ufo").openAllFolds()<CR>', "Open All Folds" },
	["zM"] = { '<cmd>lua require("ufo").closeAllFolds()<CR>', "Close All Folds" },

	-- Make word uppercase
	["<A-u>"] = { "viwU<ESC>", "Change To Uppercase", opts = { silent = true } },

	-- Undo Tree
	["<leader>u"] = { ":UndotreeShow<CR>", "Undo Tree", opts = { noremap = true, silent = true } },

	-- Symbol Outline
	["<F8>"] = { ":SymbolsOutline<CR>", "Symbols Outline", opts = { silent = true } },

	-- Illuminate
	["<A-n>"] = { '<cmd>lua require"illuminate".next_reference{wrap=true}<cr>', "Next Illuminated Reference" },
	["<A-p>"] = {
		'<cmd>lua require"illuminate".next_reference{reverse=true,wrap=true}<cr>',
		"Previous Illuminated Reference",
	},

	-- Glow
	["<leader>m"] = { ":Glow<CR>", "Markdown Preview", opts = { silent = true } },

	-- Refactoring
	["<leader>r"] = { name = " Refactoring" },
	["<leader>rb"] = {
		"<ESC><Cmd>lua require('refactoring').refactor('Extract Block')<CR>",
		"Extract Block",
		opts = { noremap = true, silent = true, expr = true },
	},
	["<leader>rf"] = {
		"<ESC><Cmd>lua require('refactoring').refactor('Extract Block To File')<CR>",
		"Extract Block To File",
		opts = { noremap = true, silent = true, expr = true },
	},
	["<leader>ri"] = {
		"<ESC><Cmd>lua require('refactoring').refactor('Inline Variable')<CR>",
		"Inline Variable",
		opts = { noremap = true, silent = true, expr = true },
	},

	-- Term rav
	["<leader>ta"] = { ":ToggleTermToggleAll<CR>", "Toggle All Terminals" },
	["<leader>rt"] = { ":lua require('toggleterm').right_toggle()<CR>", "Toggle Vertical Terminal" },
	["<leader>tt"] = { ":lua require('toggleterm').float_toggle()<CR>", "Toggle Floating Terminal" },
	["<leader>bt"] = { ":lua require('toggleterm').bottom_toggle()<CR>", "Toggle Horizontal Terminal" },
	["<leader>lg"] = { ":lua require('toggleterm').lazygit_toggle()<CR>", "Lazygit" },
	["<leader>gg"] = { ":lua require('toggleterm').gitui_toggle()<CR>", "Git UI" },

	-- Open file under cursor
	["gx"] = { require("avim.utils").system_open, "Open the file under cursor with system app" },

	-- Diffview
	["<leader>d"] = { name = " DiffView" },
	["<leader>do"] = { ":DiffviewOpen<CR>", "Open" },
	["<leader>dc"] = { ":DiffviewClose<CR>", "Close" },
	["<leader>dr"] = { ":DiffviewRefresh<CR>", "Refresh" },
	["<leader>df"] = { ":DiffviewToggleFiles<CR>", "Toggle Files" },
	["<leader>dh"] = { ":lua require('avim.utils').toggle_diff()<CR>", "Toggle History" },

	-- Alpha Home
	["<leader>h"] = { ":Alpha<CR>", " Home" },

	-- Misc
	["<C-c>"] = { "ggVG", "Select All Text", opts = { silent = true } },
	-- ["<C-A>"] = { "ggVGy`.", "Copy All Text", opts = { silent = true } },
	-- Resize
	["<A-Up>"] = { ":resize -2<CR>", "Decrease Window Height", opts = { silent = true } },
	["<A-Down>"] = { ":resize +2<CR>", "Increase Window Height", opts = { silent = true } },
	["<A-Left>"] = { ":vertical resize -2<CR>", "Decrease Window Width", opts = { silent = true } },
	["<A-Right>"] = { ":vertical resize +2<CR>", "Increase Window Width", opts = { silent = true } },

	-- Plugin Keymap temps
	["<Esc>"] = {
		function()
			-- TODO: Not sure about this one
			require("trouble").close() -- close trouble
			require("notify").dismiss() -- clear notifications
			vim.cmd.nohlsearch() -- clear highlights
			vim.cmd.echo() -- clear short-message
		end,
		"Clear Shit",
		opts = { silent = true },
	},
	["<C-s>"] = { ":w<CR>", "Save File", opts = { silent = true } },
	-- ["<C-W>"] = { ":wa<CR>", "Save All Files", opts = { silent = true } },

	-- ZenMode
	["<C-z>"] = { ":ZenMode<CR>", "Zen Mode", opts = { silent = true } },

	-- SSR
	-- ["<leader>sr"] = { ":lua require('ssr').open()<CR>", "Super Search and Replace" },

	-- Git Messenger
	["gm"] = { ":GitMessenger<CR>", "Git Messenger" },

	-- Sessions
	["<A-s>"] = { ":lua require('avim.utils').loadsession()<CR>", "Load Sessions" },

	-- Notify
	-- ["<C-c>"] = {
	-- 	":lua require('notify').dismiss()<CR>",
	-- 	"Dismiss Notification(s)",
	-- 	opts = { silent = true, noremap = true },
	-- },

	-- Bufferline
	["<Tab>"] = { ":BufferLineCycleNext<CR>", "Next Tab" },
	["<S-Tab>"] = { ":BufferLineCyclePrev<CR>", "Previous Tab" },
	["<leader>b"] = { name = "󰓩 Buffers" },
	["<leader>bl"] = { ":BufferLineMoveNext<CR>", "Move Tab Forward" },
	["<leader>br"] = { ":BufferLineMovePrev<CR>", "Move Tab Back" },
	["<leader>bh"] = { ":sp<CR>", "Split Horizontal", opts = { silent = true, noremap = true } },
	["<leader>bv"] = { ":vsp<CR>", "Split Vertical", opts = { silent = true, noremap = true } },
	["<leader>bq"] = { "<C-w>q", "Close Split", opts = { silent = true, noremap = true } },
	["<leader>bm"] = { ":MaximizerToggle!<CR>", "Toggle Maximize Tab" },
	-- Opt
	["<leader><Right>"] = { ":BufferLineCycleNext<CR>", "Next Tab" },
	["<leader><Left>"] = { ":BufferLineCyclePrev<CR>", "Previous Tab" },
}

for i = 1, 9 do
	M.n["<leader>" .. i] = { ":BufferLineGoToBuffer " .. i .. "<CR>", "Go to Tab " .. i }
end

return M

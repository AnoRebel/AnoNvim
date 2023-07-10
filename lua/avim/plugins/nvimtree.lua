local M = {
	"nvim-tree/nvim-tree.lua",
	version = "nightly",
	event = "VeryLazy",
	-- only set "after" if lazy load is disabled and vice versa for "cmd"
	-- cmd = { "NvimTreeOpen", "NvimTreeToggle", "NvimTreeFocus" },
	dependencies = { "nvim-tree/nvim-web-devicons" },
}

local function on_attach(bufnr)
	local api = require("nvim-tree.api")

	local function opts(desc)
		return { desc = "nvim-tree: " .. desc, buffer = bufnr, noremap = true, silent = true, nowait = true }
	end

	-- Default mappings. Feel free to modify or remove as you wish.
	--
	-- BEGIN_DEFAULT_ON_ATTACH
	vim.keymap.set("n", "<C-]>", api.tree.change_root_to_node, opts("CD"))
	vim.keymap.set("n", "<C-e>", api.node.open.replace_tree_buffer, opts("Open: In Place"))
	vim.keymap.set("n", "<C-k>", api.node.show_info_popup, opts("Info"))
	vim.keymap.set("n", "<C-r>", api.fs.rename_sub, opts("Rename: Omit Filename"))
	vim.keymap.set("n", "<C-t>", api.node.open.tab, opts("Open: New Tab"))
	vim.keymap.set("n", "<C-v>", api.node.open.vertical, opts("Open: Vertical Split"))
	vim.keymap.set("n", "<C-x>", api.node.open.horizontal, opts("Open: Horizontal Split"))
	vim.keymap.set("n", "<BS>", api.node.navigate.parent_close, opts("Close Directory"))
	vim.keymap.set("n", "<CR>", api.node.open.edit, opts("Open"))
	vim.keymap.set("n", "<Tab>", api.node.open.preview, opts("Open Preview"))
	vim.keymap.set("n", ">", api.node.navigate.sibling.next, opts("Next Sibling"))
	vim.keymap.set("n", "<", api.node.navigate.sibling.prev, opts("Previous Sibling"))
	vim.keymap.set("n", ".", api.node.run.cmd, opts("Run Command"))
	vim.keymap.set("n", "-", api.tree.change_root_to_parent, opts("Up"))
	vim.keymap.set("n", "a", api.fs.create, opts("Create"))
	vim.keymap.set("n", "bmv", api.marks.bulk.move, opts("Move Bookmarked"))
	vim.keymap.set("n", "B", api.tree.toggle_no_buffer_filter, opts("Toggle No Buffer"))
	vim.keymap.set("n", "c", api.fs.copy.node, opts("Copy"))
	vim.keymap.set("n", "C", api.tree.toggle_git_clean_filter, opts("Toggle Git Clean"))
	vim.keymap.set("n", "[c", api.node.navigate.git.prev, opts("Prev Git"))
	vim.keymap.set("n", "]c", api.node.navigate.git.next, opts("Next Git"))
	vim.keymap.set("n", "d", api.fs.remove, opts("Delete"))
	vim.keymap.set("n", "D", api.fs.trash, opts("Trash"))
	vim.keymap.set("n", "E", api.tree.expand_all, opts("Expand All"))
	vim.keymap.set("n", "e", api.fs.rename_basename, opts("Rename: Basename"))
	vim.keymap.set("n", "]e", api.node.navigate.diagnostics.next, opts("Next Diagnostic"))
	vim.keymap.set("n", "[e", api.node.navigate.diagnostics.prev, opts("Prev Diagnostic"))
	vim.keymap.set("n", "F", api.live_filter.clear, opts("Clean Filter"))
	vim.keymap.set("n", "f", api.live_filter.start, opts("Filter"))
	vim.keymap.set("n", "g?", api.tree.toggle_help, opts("Help"))
	vim.keymap.set("n", "gy", api.fs.copy.absolute_path, opts("Copy Absolute Path"))
	vim.keymap.set("n", "H", api.tree.toggle_hidden_filter, opts("Toggle Dotfiles"))
	vim.keymap.set("n", "I", api.tree.toggle_gitignore_filter, opts("Toggle Git Ignore"))
	vim.keymap.set("n", "J", api.node.navigate.sibling.last, opts("Last Sibling"))
	vim.keymap.set("n", "K", api.node.navigate.sibling.first, opts("First Sibling"))
	vim.keymap.set("n", "m", api.marks.toggle, opts("Toggle Bookmark"))
	vim.keymap.set("n", "o", api.node.open.edit, opts("Open"))
	vim.keymap.set("n", "O", api.node.open.no_window_picker, opts("Open: No Window Picker"))
	vim.keymap.set("n", "p", api.fs.paste, opts("Paste"))
	vim.keymap.set("n", "P", api.node.navigate.parent, opts("Parent Directory"))
	vim.keymap.set("n", "q", api.tree.close, opts("Close"))
	vim.keymap.set("n", "r", api.fs.rename, opts("Rename"))
	vim.keymap.set("n", "R", api.tree.reload, opts("Refresh"))
	vim.keymap.set("n", "s", api.node.run.system, opts("Run System"))
	vim.keymap.set("n", "S", api.tree.search_node, opts("Search"))
	vim.keymap.set("n", "U", api.tree.toggle_custom_filter, opts("Toggle Hidden"))
	vim.keymap.set("n", "W", api.tree.collapse_all, opts("Collapse"))
	vim.keymap.set("n", "x", api.fs.cut, opts("Cut"))
	vim.keymap.set("n", "y", api.fs.copy.filename, opts("Copy Name"))
	vim.keymap.set("n", "Y", api.fs.copy.relative_path, opts("Copy Relative Path"))
	vim.keymap.set("n", "<2-LeftMouse>", api.node.open.edit, opts("Open"))
	vim.keymap.set("n", "<2-RightMouse>", api.tree.change_root_to_node, opts("CD"))
	-- END_DEFAULT_ON_ATTACH

	-- Mappings migrated from view.mappings.list
	--
	-- You will need to insert "your code goes here" for any mappings with a custom action_cb
	vim.keymap.set("n", "C", api.tree.change_root_to_node, opts("CD"))
	vim.keymap.set("n", "v", api.node.open.vertical, opts("Open: Vertical Split"))
	vim.keymap.set("n", "h", api.node.open.horizontal, opts("Open: Horizontal Split"))
	vim.keymap.set("n", "t", api.node.open.tab, opts("Open: New Tab"))
	vim.keymap.set("n", "ga", function()
		require("avim.utils").tree_git_add()
	end, opts("Toggle git add"))

	vim.keymap.set("n", "<C-Space>", function()
		local node = api.tree.get_node_under_cursor()
		require("avim.utils.tree_actions").tree_actions_menu(node)
	end, opts("tree actions"))

	vim.keymap.set("n", "tf", function()
		require("avim.utils").start_telescope("find_files")
	end, opts("telescope_find_files"))

	vim.keymap.set("n", "tg", function()
		require("avim.utils").start_telescope("live_grep")
	end, opts("telescope_live_grep"))
end

function M.config()
	local function telescope_find_files(_)
		require("avim.utils").start_telescope("find_files")
	end

	local function telescope_live_grep(_)
		require("avim.utils").start_telescope("live_grep")
	end

	local function tree_actions_menu(node)
		require("avim.utils.tree_actions").tree_actions_menu(node)
	end

	local function tree_git(_)
		require("avim.utils").tree_git_add()
	end

	local options = {
		auto_reload_on_write = true,
		hijack_unnamed_buffer_when_opening = false,
		disable_netrw = true,
		hijack_netrw = true,
		respect_buf_cwd = true, -- false
		hijack_cursor = false,
		update_cwd = false,
		diagnostics = {
			enable = true,
			show_on_dirs = true,
		},
		update_focused_file = {
			enable = true,
			update_cwd = true,
			ignore_list = {},
		},
		git = {
			enable = true,
			ignore = false,
			timeout = 200,
		},
		on_attach = on_attach,
		view = {
			width = 30,
			hide_root_folder = false,
			mappings = {
				custom_only = false,
				list = {
					{ key = "C", action = "cd" },
					{ key = "v", action = "vsplit" },
					{ key = "h", action = "split" },
					{ key = "t", action = "tabnew" },
					-- { key = "K", action = "toggle_file_info" },
					{ key = "ga", action = "Toggle git add", action_cb = tree_git },
					{ key = "<C-Space>", action = "tree actions", action_cb = tree_actions_menu },
					{ key = "tf", action = "telescope_find_files", action_cb = telescope_find_files },
					{ key = "tg", action = "telescope_live_grep", action_cb = telescope_live_grep },
				},
			},
		},
		filters = {
			custom = { "node_modules", "\\.cache" },
		},
		trash = {
			cmd = "trash",
			-- require_confirm = true,
		},
		ui = {
			confirm = {
				remove = true,
				trash = true,
			},
		},
		renderer = {
			add_trailing = true, -- append a trailing slash to folder names
			highlight_git = true,
			highlight_opened_files = "all", -- "none" | "icon" | "name"
			root_folder_modifier = table.concat({ ":t:gs?$?/..", string.rep(" ", 1000), "?:gs?^??" }), -- default = ":~", prev = ":t"
			icons = {
				webdev_colors = true,
				git_placement = "before",
				padding = " ",
				symlink_arrow = " ➛ ",
				show = {
					git = true,
					folder = true,
					file = true,
					folder_arrow = true,
				},
				glyphs = {
					default = "", -- icons.default
					symlink = "",
					git = {
						unstaged = "", -- "✗",
						staged = "✓",
						unmerged = "",
						renamed = "➜",
						deleted = "",
						untracked = "★",
						ignored = "◌",
					},
					folder = {
						default = "",
						open = "",
						empty = "",
						empty_open = "",
						symlink = "",
						symlink_open = "",
						arrow_closed = "",
						arrow_open = "",
					},
				},
			},
			indent_markers = {
				enable = true,
			},
			symlink_destination = true,
			special_files = { "Cargo.toml", "README.md", "Readme.md", "readme.md", "Makefile", "MAKEFILE" }, -- " List of filenames that gets highlighted with NvimTreeSpecialFile
		},
		actions = {
			file_popup = {
				open_win_config = {
					col = 1,
					row = 1,
					relative = "cursor",
					border = "shadow",
					style = "minimal",
				},
			},
			open_file = {
				resize_window = true,
				window_picker = {
					enable = true,
					exclude = {
						filetype = { "notify", "lazy", "qf", "diff", "fugitive", "fugitiveblame" },
						buftype = { "nofile", "terminal", "help" },
					},
				},
			},
		},
	}

	local nvimtree = require("nvim-tree")
	nvimtree.setup(options)
end

return M

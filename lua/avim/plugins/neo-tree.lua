local M = {
	"nvim-neo-tree/neo-tree.nvim",
	-- branch = "v2.x",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-tree/nvim-web-devicons", -- not strictly required, but recommended
		"MunifTanjim/nui.nvim",
	},
	cmd = { "Neotree" },
	init = function()
		vim.g.neo_tree_remove_legacy_commands = true
	end,
}

local global_commands = {
	system_open = function(state)
		require("avim.utils").system_open(state.tree:get_node():get_id())
	end,
	parent_or_close = function(state)
		local node = state.tree:get_node()
		if (node.type == "directory" or node:has_children()) and node:is_expanded() then
			state.commands.toggle_node(state)
		else
			require("neo-tree.ui.renderer").focus_node(state, node:get_parent_id())
		end
	end,
	child_or_open = function(state)
		local node = state.tree:get_node()
		if node.type == "directory" or node:has_children() then
			if not node:is_expanded() then -- if unexpanded, expand
				state.commands.toggle_node(state)
			else -- if expanded and has children, select the next child
				require("neo-tree.ui.renderer").focus_node(state, node:get_child_ids()[1])
			end
		else -- if not a directory just open it
			state.commands.open(state)
		end
	end,
	copy_selector = function(state)
		local node = state.tree:get_node()
		local filepath = node:get_id()
		local filename = node.name
		local modify = vim.fn.fnamemodify

		local results = {
			e = { val = modify(filename, ":e"), msg = "Extension only" },
			f = { val = filename, msg = "Filename" },
			F = { val = modify(filename, ":r"), msg = "Filename w/o extension" },
			h = { val = modify(filepath, ":~"), msg = "Path relative to Home" },
			p = { val = modify(filepath, ":."), msg = "Path relative to CWD" },
			P = { val = filepath, msg = "Absolute path" },
		}

		local messages = {
			{ "\nChoose to copy to clipboard:\n", "Normal" },
		}
		for i, result in pairs(results) do
			if result.val and result.val ~= "" then
				vim.list_extend(messages, {
					{ ("%s."):format(i), "Identifier" },
					{ (" %s: "):format(result.msg) },
					{ result.val, "String" },
					{ "\n" },
				})
			end
		end
		vim.api.nvim_echo(messages, false, {})
		local result = results[vim.fn.getcharstr()]
		if result and result.val and result.val ~= "" then
			vim.notify("Copied: " .. result.val)
			vim.fn.setreg("+", result.val)
		end
	end,
}
local get_icon = require("avim.icons")

M.opts = function()
	-- TODO move after neo-tree improves (https://github.com/nvim-neo-tree/neo-tree.nvim/issues/707)
	return {
		auto_clean_after_session_restore = true,
		popup_border_style = "rounded",
		sources = {
			"filesystem",
			"buffers",
			"git_status",
			"document_symbols",
			-- "diagnostics",
		},
		source_selector = {
			winbar = true,
			statusline = true,
			content_layout = "center",
			sources = {
				{ source = "filesystem", display_name = get_icon["folderM"] .. " File" },
				{ source = "buffers", display_name = get_icon["fileNoLinesBg"] .. " Bufs" },
				{ source = "git_status", display_name = get_icon["gitM"] .. " Git" },
				{ source = "document_symbols", display_name = get_icon["treeDiagram"] .. " Symbols" },
				{ source = "diagnostics", display_name = get_icon["diagnostic"] .. " Diagnostic" },
			},
		},
		default_component_configs = {
			indent = {
				with_expanders = true, -- if nil and file nesting is enabled, will enable expanders
				padding = 0,
				indent_size = 2,
			},
			icon = {
				folder_closed = get_icon["folderM"],
				folder_open = get_icon["folderOpen"],
				folder_empty = get_icon["folderNoBg"],
				default = get_icon["fileNoBg"],
			},
			modified = { symbol = get_icon.ui["Circle"] },
			name = {
				trailing_slash = true,
				highlight_opened_files = true,
			},
			git_status = {
				symbols = {
					added = get_icon.gitA["Add"],
					deleted = get_icon.gitA["Remove"],
					modified = get_icon.gitA["Mod"],
					renamed = get_icon.gitA["Rename"],
					untracked = get_icon.git["untracked"],
					ignored = get_icon.gitA["Ignore"],
					unstaged = get_icon.git["unstaged"],
					staged = get_icon.git["staged"],
					conflict = get_icon.gitA["Diff"],
				},
			},
		},
		window = {
			width = 30,
			position = "right", -- "float" | "left" | "top/bottom" | "current"
			auto_expand_width = true,
			mappings = {
				["<space>"] = false, -- disable space until we figure out which-key disabling
				["[b"] = "prev_source",
				["]b"] = "next_source",
				a = {
					"add",
					config = {
						show_path = "relative", -- "none"
					},
				},
				o = "open",
				O = "system_open",
				h = "parent_or_close",
				l = "child_or_open",
				Y = "copy_selector",
			},
		},
		filesystem = {
			follow_current_file = { enabled = true },
			hijack_netrw_behavior = "open_current",
			use_libuv_file_watcher = true,
			commands = global_commands,
			window = {
				filtered_items = {
					hide_by_name = {
						".DS_Store",
						"thumbs.db",
						"node_modules",
						"\\.cache",
					},
				},
			},
		},
		buffers = { commands = global_commands },
		git_status = { commands = global_commands },
		diagnostics = { commands = global_commands },
		document_symbols = {
			follow_cursor = true,
		},
		event_handlers = {
			{
				event = "neo_tree_buffer_enter",
				handler = function(_)
					vim.opt_local.signcolumn = "auto"
				end,
			},
		},
	}
end

return M

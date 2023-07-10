local M = {}
local api = require("nvim-tree.api")

local tree_actions = {
	{
		name = "Create File/Folder",
		handler = api.fs.create,
	},
	{
		name = "Rename File/Folder",
		handler = api.fs.rename,
	},
	{
		name = "Fully Rename File/Folder",
		handler = api.fs.rename_sub,
	},
	{
		name = "Copy",
		handler = api.fs.copy.node,
	},
	{
		name = "Copy Name",
		handler = api.fs.copy.filename,
	},
	{
		name = "Copy Path",
		handler = api.fs.copy.relative_path,
	},
	{
		name = "Cut",
		handler = api.fs.cut,
	},
	{
		name = "Paste",
		handler = api.fs.paste,
	},
	{
		name = "Toggle Git Add",
		handler = require("avim.utils").tree_git_add,
	},
	{
		name = "Remove File/Folder",
		handler = api.fs.remove,
	},
	{
		name = "Trash File/Folder",
		handler = api.fs.trash,
	},
}

M.tree_actions_menu = function(node)
	local entry_maker = function(menu_item)
		return {
			value = menu_item,
			ordinal = menu_item.name,
			display = menu_item.name,
		}
	end

	local finder = require("telescope.finders").new_table({
		results = tree_actions,
		entry_maker = entry_maker,
	})

	local sorter = require("telescope.sorters").get_generic_fuzzy_sorter()

	local default_options = {
		finder = finder,
		sorter = sorter,
		attach_mappings = function(prompt_buffer_number)
			local actions = require("telescope.actions")

			-- On item select
			actions.select_default:replace(function()
				local state = require("telescope.actions.state")
				local selection = state.get_selected_entry()
				-- Closing the picker
				actions.close(prompt_buffer_number)
				-- Executing the callback
				selection.value.handler(node)
			end)

			-- The following actions are disabled in this example
			-- You may want to map them too depending on your needs though
			actions.add_selection:replace(function() end)
			actions.remove_selection:replace(function() end)
			actions.toggle_selection:replace(function() end)
			actions.select_all:replace(function() end)
			actions.drop_all:replace(function() end)
			actions.toggle_all:replace(function() end)

			return true
		end,
	}

	-- Opening the menu
	require("telescope.pickers").new({ prompt_title = "Tree menu" }, default_options):find()
end

return M

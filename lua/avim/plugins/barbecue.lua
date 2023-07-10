local M = {
	"utilyre/barbecue.nvim",
	name = "barbecue",
	version = "*",
	dependencies = {
		"SmiteshP/nvim-navic",
		"nvim-tree/nvim-web-devicons", -- optional dependency
	},
	opts = {
		create_autocmd = false, -- prevent barbecue from updating itself automatically
		attach_navic = false, -- prevent barbecue from automatically attaching nvim-navic
		---Filetypes not to enable winbar in.
		---
		---@type string[]
		exclude_filetypes = { "toggleterm", "NvimTree" },
		---Whether to display path to file.
		---
		---@type boolean
		show_dirname = false,

		---Whether to display file name.
		---
		---@type boolean
		show_basename = false,
	},
}

return M

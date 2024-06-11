local M = {
	"sindrets/diffview.nvim",
	cmd = {
    "DiffviewOpen",
    "DiffviewClose",
    "DiffviewRefresh",
    "DiffviewToggleFiles",
    "DiffviewFocusFiles",
    "DiffviewFileHistory"
  },
	dependencies = { "nvim-lua/plenary.nvim", "nvim-tree/nvim-web-devicons", },
  opts = {
    use_icons = true, -- Requires nvim-web-devicons
		icons = { -- Only applies when use_icons is true.
			folder_closed = "",
			folder_open = "",
		},
		signs = {
			fold_closed = "",
			fold_open = "",
		},
  },
}

return M

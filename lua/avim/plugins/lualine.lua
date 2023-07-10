local M = {
	"nvim-lualine/lualine.nvim",
	enabled = true,
	lazy = false,
	dependencies = { "nvim-tree/nvim-web-devicons" },
}

local icons = require("avim.icons")

local modes = {
	["n"] = "NORMAL",
	["no"] = "  OP  ",
	["nov"] = "  OP  ",
	["noV"] = "  OP  ",
	["no"] = "  OP  ",
	["niI"] = "NORMAL",
	["niR"] = "NORMAL",
	["niV"] = "NORMAL",
	["v"] = "VISUAL",
	["V"] = "LINES ",
	[""] = "BLOCK ",
	["s"] = "SELECT",
	["S"] = "SELECT",
	[""] = "BLOCK ",
	["i"] = "INSERT",
	["ic"] = "INSERT",
	["ix"] = "INSERT",
	["R"] = "REPLACE",
	["Rc"] = "REPLACE",
	["Rv"] = "V-REPLACE",
	["Rx"] = "REPLACE",
	["c"] = "COMMAND",
	["cv"] = "COMMAND",
	["ce"] = "COMMAND",
	["r"] = "ENTER ",
	["rm"] = " MORE ",
	["r?"] = "CONFIRM",
	["!"] = "SHELL ",
	["t"] = " TERM ",
	["nt"] = " TERM ",
	["null"] = " NONE ",
}

-- mode_icon = ''

local mode_color = {
	["n"] = "#00FF00", --"green",
	["i"] = "#FF0000", -- "red",
	["v"] = "#00FFFF", -- "cyan",
	["V"] = "#00FFFF", -- "cyan",
	[""] = "#00FFFF", -- "cyan",
	-- ["\22"] =  "#00FFFF",-- "cyan",
	["c"] = "#FF00FF", --"magenta",
	["no"] = "#800080", --"purple",
	["s"] = "#FFC300", -- "orange",
	["S"] = "#FFC300", -- "orange",
	[""] = "#FFC300", --"orange",
	-- ["\19"] =  "#800080",--"purple",
	["ic"] = "#FFFF00", --"yellow",
	["R"] = "#EE82EE", --"violet",
	["Rv"] = "#EE82EE", --"violet",
	["cv"] = "#FF0000", --"red",
	["ce"] = "#FF0000", --"red",
	["r"] = "#008080", --"blue",
	["rm"] = "#008080", --"blue",
	["r?"] = "#008080", --"blue",
	["!"] = "#FF0000", --"red",
	["t"] = "#FF0000", --"red",
}

local function mode()
	return modes[vim.api.nvim_get_mode().mode]
end

local function dir_name()
	local _name = vim.fn.fnamemodify(vim.fn.getcwd(), ":t")
	return icons.folderD .. _name .. " "
	-- right_sep = { str = "", hl = { fg = "#141414" } },
end

local diff = {
	add = {
		icon = " ",
		hl = {
			fg = "#A3BA5E",
			bg = "line_bg",
		},
	},

	change = {
		icon = "  ",
		hl = {
			fg = "#EFB839",
			bg = "line_bg",
		},
	},

	remove = {
		icon = "  ",
		hl = {
			fg = "#EC5241",
			bg = "line_bg",
		},
	},
}

local diag = {
	error = {
		icon = "  ",
		hl = {
			fg = "#EC5241",
			bg = "line_bg",
		},
	},

	warn = {
		icon = "  ",
		hl = {
			fg = "#EFB839",
			bg = "line_bg",
		},
	},

	hint = {
		icon = "  ",
		hl = {
			fg = "#A3BA5E",
			bg = "line_bg",
		},
	},

	info = {
		icon = "  ",
		hl = {
			fg = "#7EA9A7",
			bg = "line_bg",
		},
	},
}

local function sessions()
	if vim.g.persisting then
		return " "
	elseif vim.g.persisting == false or vim.g.persisting == nil then
		return " "
	end
end

local function venv()
	local name_with_path = os.getenv("VIRTUAL_ENV")
	local _venv = {}
	for match in (name_with_path .. "/"):gmatch("(.-)" .. "/") do
		table.insert(_venv, match)
	end
	return _venv[#_venv]
end

-- Clock
local function clock()
	return vim.fn.strftime("%H:%M")
end

local function osinfo()
	local os = vim.bo.fileformat
	local icon
	if os == "unix" then
		icon = "  "
	elseif os == "mac" then
		icon = "  "
	else
		icon = "  "
	end
	return icon .. os
	-- left_sep = { str = "", hl = { fg = "#141414" } },
	-- right_sep = { str = "", hl = { fg = "#141414" } },
end

local function updates()
	return require("lazy.status").updates()
	-- hl = {
	-- 	fg = "#ff9e64",
	-- },
end

local function scrollbar()
	-- Another variant, because the more choice the better.
	-- local sbar = { "▁", "▂", "▃", "▄", "▅", "▆", "▇", "█" }
	local sbar = { "🭶", "🭷", "🭸", "🭹", "🭺", "🭻" }
	local curr_line = vim.api.nvim_win_get_cursor(0)[1]
	local lines = vim.api.nvim_buf_line_count(0)
	local i = math.floor((curr_line - 1) / lines * #sbar) + 1
	return string.rep(sbar[i], 2)
end

local function DAPMessages()
	-- condition = function()
	--     local session = require("dap").session()
	--     return session ~= nil
	-- end,
	return " " .. require("dap").status()
	-- hl = "Debug"
	-- see Click-it! section for clickable actions
end

--- @param trunc_width number trunctates component when screen width is less then trunc_width
--- @param trunc_len number truncates component to trunc_len number of chars
--- @param hide_width number hides component when window width is smaller then hide_width
--- @param no_ellipsis boolean whether to disable adding '...' at end after truncation
--- return function that can format the component accordingly
local function trunc(trunc_width, trunc_len, hide_width, no_ellipsis)
	return function(str)
		local win_width = vim.fn.winwidth(0)
		if hide_width and win_width < hide_width then
			return ""
		elseif trunc_width and trunc_len and win_width < trunc_width and #str > trunc_len then
			return str:sub(1, trunc_len) .. (no_ellipsis and "" or "...")
		end
		return str
	end
end

local conditions = {
	buffer_not_empty = function()
		return vim.fn.empty(vim.fn.expand("%:t")) ~= 1
	end,
	hide_in_width = function()
		return vim.fn.winwidth(0) > 80
	end,
	has_updates = function()
		return require("lazy.status").has_updates()
	end,
	has_venv = function()
		return os.getenv("VIRTUAL_ENV") ~= nil
	end,
	is_flutter = function()
		return vim.g.flutter_tools_decorations and vim.g.flutter_tools_decorations.device ~= nil or false
	end,
	has_session = function()
		return require("avim.utils").using_session()
	end,
	has_file_type = function()
		local f_type = vim.bo.filetype
		if not f_type or f_type == "" then
			return false
		end
		return true
	end,
}

local config = {
	options = {
		icons_enabled = true,
		theme = "auto",
		globalstatus = true,
		always_divide_middle = true, -- false,
		component_separators = "", -- "|",
		section_separators = { left = "", right = "" }, -- { left = "", right = "" },
	},
	sections = {
		lualine_a = {
			{
				mode,
				color = {
					fg = mode_color[vim.api.nvim_get_mode().mode],
					gui = "bold",
					bg = "line_bg",
				},
			},
			{
				dir_name,
				cond = conditions.hide_in_width,
				color = { fg = mode_color[vim.fn.mode()], bg = "line_bg" },
				separator = { right = "" },
				on_click = function()
					vim.cmd("NvimTreeToggle")
				end,
			},
		},
		lualine_b = {
			{
				"diagnostics",
				colored = true,
				sources = { "nvim_diagnostic", "nvim_lsp" },
				sections = { "error", "warn", "hint", "info" },
				separator = { right = "" },
				symbols = {
					error = diag.error.icon,
					warn = diag.warn.icon,
					hint = diag.hint.icon,
					info = diag.info.icon,
				},
				diagnostics_color = {
					error = "DiagnosticError", -- Changes diagnostics' error color.
					warn = "DiagnosticWarn", -- Changes diagnostics' warn color.
					info = "DiagnosticInfo", -- Changes diagnostics' info color.
					hint = "DiagnosticHint", -- Changes diagnostics' hint color.
				},
				on_click = function()
					vim.cmd("Telescope diagnostics")
				end,
			},
		},
		lualine_c = {
			-- { "%=", color = { bg = "line_bg" } },
			-- {
			-- 	clock,
			-- 	icon = " ",
			-- 	color = { fg = mode_color[vim.fn.mode()], bg = "line_bg" },
			-- 	on_click = function()
			-- 		require("lualine").refresh()
			-- 	end,
			-- },
		},
		lualine_x = {
			{
				function()
					return vim.g.flutter_tools_decorations and vim.g.flutter_tools_decorations.device or ""
				end,
				cond = conditions.is_flutter,
				color = { bg = "line_bg" },
			},
			{ venv, cond = conditions.has_venv, color = { bg = "line_bg" } },
			{
				"diff",
				colored = true,
				diff_color = {
					added = "DiffAdd", -- Changes the diff's added color
					modified = "DiffChange", -- Changes the diff's modified color
					removed = "DiffDelete", -- Changes the diff's removed color you
				},
				color = { bg = "line_bg" },
				symbols = { added = diff.add.icon, modified = diff.change.icon, removed = diff.remove.icon }, -- Changes the symbols used by the diff.
				on_click = function()
					vim.cmd("DiffviewOpen")
				end,
			},
			{
				"branch",
				icon = "",
				cond = conditions.hide_in_width,
				color = { bg = "line_bg" },
				on_click = function(clicks, button, modifiers)
					require("toggleterm").lazygit_toggle()
				end,
			},
		},
		lualine_y = {
			{
				"filetype",
				colored = true,
				icon_only = false,
				icon = { align = "left" },
				color = { bg = "line_bg" },
				on_click = function(clicks, button, modifiers)
					if "l" == button then
						vim.cmd("Mason")
					end
				end,
			},
			{
				updates,
				cond = conditions.has_updates,
				on_click = function(clicks, button, modifiers)
					if "l" == button then
						vim.cmd("Lazy")
					end
					if "r" == button then
						vim.cmd("Lazy sync")
					end
				end,
			},
			{ osinfo, cond = conditions.hide_in_width, separator = { right = "" } }, -- "", "" } },
		},
		lualine_z = {
			{
				sessions,
				color = { fg = vim.g.persisting and "#7EA9A7" or "#EFB839", bg = "line_bg" },
				cond = conditions.has_session,
				separator = { left = "" }, -- "" },
				on_click = function(clicks, button, modifiers)
					require("avim.utils").loadsession()
				end,
			},
			{ "location", color = { fg = mode_color[vim.api.nvim_get_mode().mode], bg = "line_bg" } },
			{ "progress", color = { fg = mode_color[vim.api.nvim_get_mode().mode], bg = "line_bg" } },
			{ scrollbar, color = { fg = mode_color[vim.fn.mode()], bg = "line_bg" } },
		},
	},
	inactive_sections = {
		lualine_a = { { mode, color = { fg = mode_color[vim.fn.mode()], gui = "bold", bg = "line_bg" } } },
		lualine_b = {
			{
				dir_name,
				cond = conditions.hide_in_width,
				color = { fg = mode_color[vim.fn.mode()], bg = "line_bg" },
				separator = { right = "" },
			},
		},
		lualine_c = {
			-- { "%=", color = { bg = "line_bg" } },
			-- { clock, icon = " ", color = { fg = mode_color[vim.fn.mode()], bg = "line_bg" } },
		},
		lualine_x = {},
		lualine_y = {},
		lualine_z = {
			{
				sessions,
				color = { fg = vim.g.persisting and "#7EA9A7" or "#EFB839", bg = "line_bg" },
				cond = conditions.has_session,
			},
			{ "location", color = { fg = mode_color[vim.fn.mode()], bg = "line_bg" } },
			{ "progress", color = { fg = mode_color[vim.fn.mode()], bg = "line_bg" } },
			{
				clock,
				icon = " ",
				color = { fg = mode_color[vim.fn.mode()], bg = "line_bg" },
				on_click = function()
					require("lualine").refresh()
				end,
			},
		},
	},
}

M.opts = config

return M

local M = {
	"SmiteshP/nvim-navic",
	dependencies = { "neovim/nvim-lspconfig" },
}

local icons = require("avim.icons").kind

local options = {
	depth_limit = 5,
	highlight = true,
	icons = {
		["class-name"] = "%#CmpItemKindClass#" .. icons.Class .. "%*" .. " ",
		["function-name"] = "%#CmpItemKindFunction#" .. icons.Function .. "%*" .. " ",
		["method-name"] = "%#CmpItemKindMethod#" .. icons.Method .. "%*" .. " ",
		["container-name"] = "%#CmpItemKindProperty#" .. icons.Object .. "%*" .. " ",
		["tag-name"] = "%#CmpItemKindKeyword#" .. icons.Tag .. "%*" .. " ",
		["mapping-name"] = "%#CmpItemKindProperty#" .. icons.Object .. "%*" .. " ",
		["sequence-name"] = "%CmpItemKindProperty#" .. icons.Array .. "%*" .. " ",
		["null-name"] = "%CmpItemKindField#" .. icons.Field .. "%*" .. " ",
		["boolean-name"] = "%CmpItemKindValue#" .. icons.Boolean .. "%*" .. " ",
		["integer-name"] = "%CmpItemKindValue#" .. icons.Number .. "%*" .. " ",
		["float-name"] = "%CmpItemKindValue#" .. icons.Number .. "%*" .. " ",
		["string-name"] = "%CmpItemKindValue#" .. icons.String .. "%*" .. " ",
		["array-name"] = "%CmpItemKindProperty#" .. icons.Array .. "%*" .. " ",
		["object-name"] = "%CmpItemKindProperty#" .. icons.Object .. "%*" .. " ",
		["number-name"] = "%CmpItemKindValue#" .. icons.Number .. "%*" .. " ",
		["table-name"] = "%CmpItemKindProperty#" .. icons.Table .. "%*" .. " ",
		["date-name"] = "%CmpItemKindValue#" .. icons.Calendar .. "%*" .. " ",
		["date-time-name"] = "%CmpItemKindValue#" .. icons.Table .. "%*" .. " ",
		["inline-table-name"] = "%CmpItemKindProperty#" .. icons.Calendar .. "%*" .. " ",
		["time-name"] = "%CmpItemKindValue#" .. icons.Watch .. "%*" .. " ",
		["module-name"] = "%CmpItemKindModule#" .. icons.Module .. "%*" .. " ",
	},
}

function M.init()
	-- Highlights
	local api = vim.api
	api.nvim_set_hl(0, "NavicIconsFile", { default = true, fg = "#7E8294" }) -- bg = "#C5CDD9", })
	api.nvim_set_hl(0, "NavicIconsModule", { default = true, fg = "#A377BF" }) -- bg = "#EADFF0", })
	api.nvim_set_hl(0, "NavicIconsNamespace", { default = true, fg = "#58B5A8" }) -- bg = "#D8EEEB", })
	api.nvim_set_hl(0, "NavicIconsPackage", { default = true, fg = "#A377BF" }) -- bg = "#EADFF0", })
	api.nvim_set_hl(0, "NavicIconsClass", { default = true, fg = "#A377BF" }) -- bg = "#EADFF0", })
	api.nvim_set_hl(0, "NavicIconsMethod", { default = true, fg = "#6C8ED4" }) -- bg = "#DDE5F5", })
	api.nvim_set_hl(0, "NavicIconsProperty", { default = true, fg = "#B5585F" }) -- bg = "#EED8DA", })
	api.nvim_set_hl(0, "NavicIconsField", { default = true, fg = "#B5585F" }) -- bg = "#EED8DA", })
	api.nvim_set_hl(0, "NavicIconsConstructor", { default = true, fg = "#D4BB6C" }) -- bg = "#FFE082", })
	api.nvim_set_hl(0, "NavicIconsEnum", { default = true, fg = "#9FBD73" }) -- bg = "#C3E88D", })
	api.nvim_set_hl(0, "NavicIconsInterface", { default = true, fg = "#58B5A8" }) -- bg = "#D8EEEB", })
	api.nvim_set_hl(0, "NavicIconsFunction", { default = true, fg = "#A377BF" }) -- bg = "#EADFF0", })
	api.nvim_set_hl(0, "NavicIconsVariable", { default = true, fg = "#7E8294" }) -- bg = "#C5CDD9", })
	api.nvim_set_hl(0, "NavicIconsConstant", { default = true, fg = "#D4BB6C" }) -- bg = "#FFE082", })
	api.nvim_set_hl(0, "NavicIconsString", { default = true, fg = "#B5585F" }) -- bg = "#EED8DA", })
	api.nvim_set_hl(0, "NavicIconsNumber", { default = true, fg = "#B5585F" }) -- bg = "#EED8DA", })
	api.nvim_set_hl(0, "NavicIconsBoolean", { default = true, fg = "#B5585F" }) -- bg = "#EED8DA", })
	api.nvim_set_hl(0, "NavicIconsArray", { default = true, fg = "#A377BF" }) -- bg = "#EADFF0", })
	api.nvim_set_hl(0, "NavicIconsObject", { default = true, fg = "#A377BF" }) -- bg = "#EADFF0", })
	api.nvim_set_hl(0, "NavicIconsKey", { default = true, fg = "#9FBD73" }) -- bg = "#C3E88D", })
	api.nvim_set_hl(0, "NavicIconsNull", { default = true, fg = "#6C8ED4" }) -- bg = "#DDE5F5", })
	api.nvim_set_hl(0, "NavicIconsEnumMember", { default = true, fg = "#6C8ED4" }) -- bg = "#DDE5F5", })
	api.nvim_set_hl(0, "NavicIconsStruct", { default = true, fg = "#A377BF" }) -- bg = "#EADFF0", })
	api.nvim_set_hl(0, "NavicIconsEvent", { default = true, fg = "#B5585F" }) -- bg = "#EED8DA", })
	api.nvim_set_hl(0, "NavicIconsOperator", { default = true, fg = "#A377BF" }) -- bg = "#EADFF0", })
	api.nvim_set_hl(0, "NavicIconsTypeParameter", { default = true, fg = "#58B5A8" }) -- bg = "#D8EEEB", })
	api.nvim_set_hl(0, "NavicText", { default = true, fg = "#9FBD73" }) -- bg = "#C3E88D", })
	api.nvim_set_hl(0, "NavicSeparator", { default = true, fg = "#58B5A8" }) -- bg = "#D8EEEB", })
end

function M.config()
	require("nvim-navic").setup(options)
end

return M

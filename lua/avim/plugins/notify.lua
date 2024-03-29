local M = {
	"rcarriga/nvim-notify",
	event = "VeryLazy",
	-- lazy = false,
}

local options = {
	active = false,
	on_config_done = nil,
	---@usage Animation style one of { "fade", "slide", "fade_in_slide_out", "static" }
	stages = "slide",

	---@usage Function called when a new window is opened, use for changing win settings/config
	on_open = nil,

	---@usage Function called when a window is closed
	on_close = nil,

	---@usage timeout for notifications in ms, default 5000
	timeout = 5000,

	-- Render function for notifications. See notify-render()
	render = "default",

	-- ---@usage highlight behind the window for stages that change opacity
	background_colour = "Normal",

	---@usage minimum width for notification windows
	minimum_width = 50,

	---@usage Icons for the different levels
	icons = {
		ERROR = "",
		WARN = "",
		INFO = "",
		DEBUG = "",
		TRACE = "✎",
	},
}

function M.config()
	local notify = require("notify")
	local Log = require("avim.core.log")
	notify.setup(options)
	vim.notify = notify
	Log:configure_notifications(notify)
end

return M

---@class avim.utilities.dbee
---@field execute fun()
---@field save fun(rng: any)
local M = {}

local Input = require("nui.input")
local Menu = require("nui.menu")
local defaults = require("avim.core.defaults")
local event = require("nui.utils.autocmd").event

--- Calls a public dbee function, reporting failures instead of raising.
--- They raise for recoverable states (no connection selected, no result to
--- store) which would otherwise surface as a traceback in a nui callback.
local function call_dbee(name, ...)
	local ok, err = pcall(require("dbee")[name], ...)
	if not ok then
		vim.notify(tostring(err), vim.log.levels.WARN, { title = "Dbee" })
	end
end

local format = "json"
local op_type = "buffer"
local range = false
local ranges = {}

local file_name = Input({
	position = {
		col = "50%",
		row = "30%",
	},
	size = {
		width = 20,
	},
	border = {
		style = defaults.ui.border,
		text = {
			top = "File Name?",
			top_align = "center",
		},
	},
	win_options = {
		winhighlight = "Normal:NormalFloat,FloatBorder:FloatBorder",
	},
}, {
	prompt = "> ",
	default_value = "",
	on_close = function()
		vim.notify("Cancelled saving output", vim.log.levels.INFO, { title = "Dbee" })
	end,
	on_submit = function(value)
		local join_paths = require("avim.utilities").join_paths
		local save_path = join_paths(os.getenv("HOME"), "Downloads")
		local filename = "dbee_" .. os.date("%Y%m%d%H%M%S") .. "." .. format
		if value and value ~= "" then
			filename = vim.trim(value):gsub("%s+", "_") .. "." .. format
		else
			vim.notify("Empty name provided, using default", vim.log.levels.INFO, { title = "Dbee" })
		end
		if range then
			call_dbee("store", format, op_type, {
				from = ranges[1],
				to = ranges[2],
				extra_arg = op_type == "file" and join_paths(save_path, filename) or 0,
			})
		else
			call_dbee(
				"store",
				format,
				op_type,
				{ extra_arg = op_type == "file" and join_paths(save_path, filename) or 0 }
			)
		end
		vim.notify("Saved: " .. filename .. " to: " .. save_path, vim.log.levels.INFO, { title = "Dbee" })
	end,
})

local range_input = Input({
	position = {
		col = "50%",
		row = "30%",
	},
	size = {
		width = "50%",
		height = 3,
	},
	buf_options = {
		filetype = "csv",
	},
	border = {
		style = defaults.ui.border,
		text = {
			top = "Result Range(eg. 0,2)",
			top_align = "center",
		},
	},
	win_options = {
		winhighlight = "Normal:NormalFloat,FloatBorder:FloatBorder",
	},
}, {
	prompt = ": ",
	default_value = "",
	on_close = function()
		vim.notify("Range selection cancelled", vim.log.levels.INFO, { title = "Dbee" })
	end,
	on_submit = function(value)
		if value == "" then
			vim.notify("Range is empty, using all", vim.log.levels.INFO, { title = "Dbee" })
			range = false
			ranges = {}
		else
			-- dbee wants integer row indexes; the input is free text.
			local from, to = value:match("^%s*(%d+)%s*,%s*(%d+)%s*$")
			if not from then
				return vim.notify(
					"Invalid range format (eg. 0,2)",
					vim.log.levels.INFO,
					{ title = "Dbee" }
				)
			end
			ranges = { tonumber(from), tonumber(to) }
		end
		if op_type == "file" then
			-- deferred: mounting from inside this prompt's submit lets the previous
			-- prompt's unmount steal focus, so re-assert focus and insert mode
			vim.schedule(function()
				file_name:mount()
				vim.api.nvim_set_current_win(file_name.winid)
				vim.cmd("startinsert!")
			end)
		else
			if range then
				call_dbee("store", format, op_type, { from = ranges[1], to = ranges[2] })
			else
				call_dbee("store", format, op_type, { extra_arg = 0 })
			end
		end
	end,
})

local type_chooser = Menu({
	position = {
		col = "50%",
		row = "30%",
	},
	size = {
		width = 25,
		height = 3,
	},
	border = {
		style = defaults.ui.border,
		text = {
			top = "Save Type?",
			top_align = "center",
		},
	},
	win_options = {
		winhighlight = "Normal:NormalFloat,FloatBorder:FloatBorder",
	},
}, {
	lines = {
		Menu.item("BUFFER"),
		Menu.item("FILE"),
		Menu.item("YANK"),
		-- Menu.separator("Noble-Gases", {
		--   char = "-",
		--   text_align = "right",
		-- }),
	},
	max_width = 20,
	keymap = {
		focus_next = { "j", "<Down>", "<Tab>" },
		focus_prev = { "k", "<Up>", "<S-Tab>" },
		close = { "<Esc>", "<C-c>", "q" },
		submit = { "<CR>", "<Space>" },
	},
	on_close = function()
		vim.notify("Type selection cancelled", vim.log.levels.INFO, { title = "Dbee" })
	end,
	on_submit = function(item)
		op_type = item.text:lower()
		-- mount/open the component
		if range then
			-- the range is asked for first; a file name is asked afterwards
			range_input:mount()
		elseif op_type == "file" then
			file_name:mount()
		else
			call_dbee("store", format, op_type, { extra_arg = 0 })
		end
	end,
})

local format_chooser = Menu({
	position = {
		col = "50%",
		row = "30%",
	},
	size = {
		width = 25,
		height = 3,
	},
	border = {
		style = defaults.ui.border,
		text = {
			top = "Save Format?",
			top_align = "center",
		},
	},
	win_options = {
		winhighlight = "Normal:NormalFloat,FloatBorder:FloatBorder",
	},
}, {
	lines = {
		Menu.item("CSV"),
		Menu.item("JSON"),
		Menu.item("TABLE"),
		-- Menu.separator("Noble-Gases", {
		--   char = "-",
		--   text_align = "right",
		-- }),
	},
	max_width = 20,
	keymap = {
		focus_next = { "j", "<Down>", "<Tab>" },
		focus_prev = { "k", "<Up>", "<S-Tab>" },
		close = { "<Esc>", "<C-c>", "q" },
		submit = { "<CR>", "<Space>" },
	},
	on_close = function()
		vim.notify("Format selection cancelled", vim.log.levels.INFO, { title = "Dbee" })
	end,
	on_submit = function(item)
		format = item.text:lower()
		-- vim.notify("Format Selected: " .. item.text .. "(" .. format .. ")")
		-- mount/open the component
		type_chooser:mount()
	end,
})

local query = Input({
	position = {
		col = "50%",
		row = "30%",
	},
	size = {
		width = "50%",
		height = 3,
	},
	buf_options = {
		filetype = "sql",
	},
	border = {
		style = defaults.ui.border,
		text = {
			top = "SQL Query",
			top_align = "center",
		},
	},
	win_options = {
		winhighlight = "Normal:NormalFloat,FloatBorder:FloatBorder",
	},
}, {
	prompt = "> ",
	default_value = "",
	on_close = function()
		vim.notify("Query execution cancelled", vim.log.levels.INFO, { title = "Dbee" })
	end,
	on_submit = function(value)
		if value == "" then
			vim.notify("Query cannot be empty", vim.log.levels.INFO, { title = "Dbee" })
			return
		else
			local tmp_query = string.sub(value, -1) == ";" and value:gsub("^%s*(.-)%s*$", "%1")
				or value:gsub("^%s*(.-)%s*$", "%1") .. ";"
			call_dbee("execute", tmp_query)
		end
	end,
})

query:map("n", "<Esc>", function()
	query:unmount()
end, { noremap = true })
query:map("n", "q", function()
	query:unmount()
end, { noremap = true })

range_input:map("n", "<Esc>", function()
	range_input:unmount()
end, { noremap = true })
range_input:map("n", "q", function()
	range_input:unmount()
end, { noremap = true })

-- mount/open the component
M.execute = function()
	-- mount/open the component
	query:mount()
end

M.save = function(rng)
	range = rng or false
	-- mount/open the component
	format_chooser:mount()
end

-- unmount component when cursor leaves buffer
query:on(event.BufLeave, function()
	query:unmount()
end)

-- unmount component when cursor leaves buffer
file_name:on(event.BufLeave, function()
	file_name:unmount()
end)

type_chooser:on(event.BufLeave, function()
	type_chooser:unmount()
end)

format_chooser:on(event.BufLeave, function()
	format_chooser:unmount()
end)

return M

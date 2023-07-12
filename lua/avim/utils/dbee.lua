local M = {}

local Input = require("nui.input")
local Menu = require("nui.menu")
local event = require("nui.utils.autocmd").event

local format = "json"

local file_name = Input({
	position = {
		col = "50%",
		row = "30%",
	},
	size = {
		width = 20,
	},
	border = {
		style = "rounded",
		text = {
			top = "File Name?",
			top_align = "center",
		},
	},
	win_options = {
		winhighlight = "Normal:Normal,FloatBorder:Normal",
	},
}, {
	prompt = "> ",
	default_value = "",
	on_close = function()
		vim.notify("Cancelled saving output", vim.log.levels.INFO, { title = "Dbee" })
	end,
	on_submit = function(value)
		local join_paths = require("avim.utils").join_paths
		local save_path = join_paths(os.getenv("HOME"), "Downloads")
		local filename = "dbee_" .. os.date("%Y%m%d%H%M%S") .. "." .. format
		if value == "" then
			vim.notify("Empty name provided, using default", vim.log.levels.INFO, { title = "Dbee" })
			require("dbee").save(format, join_paths(save_path, filename))
			vim.notify("Saved: " .. filename .. " to: " .. save_path, vim.log.levels.INFO, { title = "Dbee" })
		else
			filename = value:gsub("^%s*", "")
			filename = value:gsub("^%s*", "")
			filename = value:gsub("%s+", "_") .. "." .. format
			require("dbee").save(format, join_paths(save_path, filename))
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
		style = "rounded",
		text = {
			top = "Save Format?",
			top_align = "center",
		},
	},
	win_options = {
		winhighlight = "Normal:Normal,FloatBorder:Normal",
	},
}, {
	lines = {
		Menu.item("CSV"),
		Menu.item("JSON"),
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
		file_name:mount()
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
		style = "rounded",
		text = {
			top = "SQL Query",
			top_align = "center",
		},
	},
	win_options = {
		winhighlight = "Normal:Normal,FloatBorder:Normal",
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
			require("dbee").execute(tmp_query)
		end
	end,
})

query:map("n", "<Esc>", function()
	query:unmount()
end, { noremap = true })
query:map("n", "q", function()
	query:unmount()
end, { noremap = true })

-- mount/open the component
M.execute = function()
	-- mount/open the component
	query:mount()
end

M.save = function()
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

format_chooser:on(event.BufLeave, function()
	format_chooser:unmount()
end)

return M

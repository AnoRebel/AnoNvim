local api = vim.api
local M = {
	floating_buf = nil,
	floating_win = nil,
	prev_result = nil,
}

local function create_floating_file(location, opts)
	vim.validate({
		location = { location, "t" },
		opts = { opts, "t", true },
	})

	-- Set some defaults
	opts = opts or {}
	local close_events = opts.close_events or { "CursorMoved", "CursorMovedI", "BufHidden", "InsertCharPre" }

	-- location may be LocationLink or Location
	local uri = location.targetUri or location.uri
	if uri == nil then
		return
	end
	local bufnr = vim.uri_to_bufnr(uri)
	if not api.nvim_buf_is_loaded(bufnr) then
		vim.fn.bufload(bufnr)
	end

	local range = location.targetRange or location.range

	local contents = api.nvim_buf_get_lines(
		bufnr,
		range.start.line,
		math.min(
			range["end"].line + 1 + (opts.context or require("avim.core.defaults").options.peek.max_height),
			range.start.line + (opts.max_height or require("avim.core.defaults").options.peek.max_height)
		),
		false
	)
	if next(contents) == nil then
		vim.notify("peek: Unable to get contents of the file!", vim.log.levels.WARN)
		return
	end
	local width, height = vim.lsp.util._make_floating_popup_size(contents, opts)
	local if_nil = vim.F.if_nil
	opts = vim.lsp.util.make_floating_popup_options(
		if_nil(width, require("avim.core.defaults").options.peek.max_width),
		if_nil(height, require("avim.core.defaults").options.peek.max_height),
		opts
	)
	-- Don't make it minimal as it is meant to be fully featured
	opts["style"] = nil

	api.nvim_buf_set_option(bufnr, "bufhidden", "wipe")

	local winnr = api.nvim_open_win(bufnr, false, opts)
	api.nvim_win_set_option(winnr, "winblend", 0)

	api.nvim_win_set_cursor(winnr, { range.start.line + 1, range.start.character })
	api.nvim_buf_set_var(bufnr, "lsp_floating_window", winnr)

	-- Set some autocmds to close the window
	table.unpack = table.unpack or unpack -- 5.1 compatibility
	api.nvim_command(
		string.format(
			"autocmd %s <buffer> ++once lua pcall(vim.api.nvim_win_close, %d, true)",
			table.unpack(close_events),
			winnr
		)
	)

	return bufnr, winnr
end

local function preview_location_callback(result)
	if result == nil or vim.tbl_isempty(result) then
		return nil
	end

	local opts = {
		border = "rounded",
		context = require("avim.core.defaults").options.peek.context,
	}

	if vim.tbl_islist(result) then
		M.prev_result = result[1]
		M.floating_buf, M.floating_win = create_floating_file(result[1], opts)
	else
		M.prev_result = result
		M.floating_buf, M.floating_win = create_floating_file(result, opts)
	end
end

local function preview_location_callback_new_signature(_, result)
	return preview_location_callback(result)
end

function M.open_file()
	-- Get the file currently open in the floating window
	local filepath = vim.fn.expand("%:.")

	if not filepath then
		vim.notify("peek: Unable to open the file!", vim.log.levels.ERROR)
		return
	end

	-- Close the floating window
	pcall(api.nvim_win_close, M.floating_win, true)

	-- Edit the file
	vim.cmd("edit " .. filepath)

	local winnr = api.nvim_get_current_win()

	-- Set the cursor at the right position
	M.set_cursor_to_prev_pos(winnr)
end

function M.set_cursor_to_prev_pos(winnr)
	-- Get position of the thing to peek at
	local location = M.prev_result
	local range = location.targetRange or location.range
	local cursor_pos = { range.start.line + 1, range.start.character }

	-- Set the winnr to the floating window if none was passed in
	winnr = winnr or M.floating_win
	-- Set the cursor at the correct position in the floating window
	api.nvim_win_set_cursor(winnr, cursor_pos)
end

function M.Peek(what)
	-- If a window already exists, focus it at the right position!
	if vim.tbl_contains(api.nvim_list_wins(), M.floating_win) then
		local success_1, _ = pcall(api.nvim_set_current_win, M.floating_win)
		if not success_1 then
			vim.notify("peek: You cannot edit the current file in a preview!", vim.log.levels.ERROR)
			return
		end

		-- Set the cursor at the correct position in the floating window
		M.set_cursor_to_prev_pos()

		api.nvim_buf_set_keymap(
			M.floating_buf,
			"n",
			"<CR>",
			":lua require('avim.utils.peek').open_file()<CR>",
			{ noremap = true, silent = true }
		)
	else
		-- Make a new request and then create the new window in the callback
		local params = vim.lsp.util.make_position_params()
		local preview_callback = preview_location_callback_new_signature
		local success, _ = pcall(vim.lsp.buf_request, 0, "textDocument/" .. what, params, preview_callback)
		if not success then
			vim.notify(
				'peek: Error calling LSP method "textDocument/'
					.. what
					.. '". The current language lsp might not support it.',
				vim.log.levels.ERROR
			)
		end
	end
end

------------------------------------------------------------
-- Nui Popup
M.PopupPeek = function(what)
	local popup = require("nui.popup")({
		enter = true,
		focusable = true,
		border = {
			style = "rounded",
		},
		position = "50%",
		size = {
			width = "70%",
			height = "40%",
		},
		buf_options = {
			modifiable = false,
			readonly = true,
		},
	})

	-- mount/open the popup
	popup:mount()

	-- unmount component when cursor leaves buffer
	local event = require("nui.utils.autocmd").event
	popup:on(event.BufLeave, function()
		popup:unmount()
	end)

	-- get contents
	-- location may be LocationLink or Location
	local location = M.prev_result
	local uri = location.targetUri or location.uri
	if uri == nil then
		return
	end
	local bufnr = vim.uri_to_bufnr(uri)
	if not api.nvim_buf_is_loaded(bufnr) then
		vim.fn.bufload(bufnr)
	end

	local range = location.targetRange or location.range
	local opts = {
		border = "rounded",
		context = require("avim.core.defaults").options.peek.context,
	}
	local contents = api.nvim_buf_get_lines(
		bufnr,
		range.start.line,
		math.min(
			range["end"].line + 1 + (opts.context or require("avim.core.defaults").options.peek.max_height),
			range.start.line + (opts.max_height or require("avim.core.defaults").options.peek.max_height)
		),
		false
	)
	if next(contents) == nil then
		vim.notify("peek: Unable to get contents of the file!", vim.log.levels.WARN)
		return
	end

	-- set contents
	api.nvim_buf_set_lines(popup.bufnr, 0, 1, false, contents)
end
------------------------------------------------------------

return M

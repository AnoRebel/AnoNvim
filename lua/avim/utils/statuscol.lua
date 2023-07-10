-- Option 1 (https://github.com/luukvbaal/statuscol.nvim)
local c = vim.cmd
local d = vim.diagnostic
local l = vim.lsp
local v = vim.v
local a = vim.api
local f = vim.fn
local o = vim.o
local O = vim.opt
local S = vim.schedule
local foldmarker
local signs = {}
local builtin = {}
local M = {}

-- Return line number in configured format.
function builtin.lnumfunc(number, relativenumber, thousands, relculright)
	if v.virtnum ~= 0 or (not relativenumber and not number) then
		return ""
	end
	local lnum = v.lnum

	if relativenumber then
		lnum = v.relnum > 0 and v.relnum or (number and lnum or 0)
	end

	if thousands and lnum > 999 then
		lnum = string.reverse(lnum):gsub("%d%d%d", "%1" .. thousands):reverse():gsub("^%" .. thousands, "")
	end

	if not relculright then
		if relativenumber then
			lnum = (v.relnum > 0 and "%=" or "") .. lnum .. (v.relnum > 0 and "" or "%=")
		else
			lnum = "%=" .. lnum
		end
	end

	return lnum
end

--- Create new fold by Ctrl-clicking the range.
local function create_fold(args)
	if foldmarker then
		c("norm! zf" .. foldmarker .. "G")
		foldmarker = nil
	else
		foldmarker = args.mousepos.line
	end
end

local function fold_click(args, open, empty)
	if not args.mods:find("c") then
		foldmarker = nil
	end
	-- Create fold on middle click
	if args.button == "m" then
		create_fold(args)
	end
	if empty then
		return
	end

	if args.button == "l" then -- Open/Close (recursive) fold on (Ctrl)-click
		if open then
			c("norm! z" .. (args.mods:find("c") and "O" or "o"))
		else
			c("norm! z" .. (args.mods:find("c") and "C" or "c"))
		end
	elseif args.button == "r" then -- Delete (recursive) fold on (Ctrl)-right click
		c("norm! z" .. (args.mods:find("c") and "D" or "d"))
	end
end

--- Handler for clicking '+' in fold column.
local function foldclose_click(args)
	fold_click(args, true)
end

--- Handler for clicking '-' in fold column.
local function foldopen_click(args)
	fold_click(args, false)
end

--- Handler for clicking ' ' in fold column.
local function foldempty_click(args)
	fold_click(args, false, true)
end

--- Handler for clicking a Diagnostc* sign.
local function diagnostic_click(args)
	if args.button == "l" then
		d.open_float() -- Open diagnostic float on left click
	elseif args.button == "m" then
		l.buf.code_action() -- Open code action on middle click
	end
end

--- Handler for clicking a GitSigns* sign.
local function gitsigns_click(args)
	if args.button == "l" then
		require("gitsigns").preview_hunk()
	elseif args.button == "m" then
		require("gitsigns").reset_hunk()
	elseif args.button == "r" then
		require("gitsigns").stage_hunk()
	end
end

--- Toggle a (conditional) DAP breakpoint.
local function toggle_breakpoint(args)
	local dap = vim.F.npcall(require, "dap")
	if not dap then
		return
	end
	if args.mods:find("c") then
		vim.ui.input({ prompt = "Breakpoint condition: " }, function(input)
			dap.set_breakpoint(input)
		end)
	else
		dap.toggle_breakpoint()
	end
end

--- Handler for clicking the line number.
local function lnum_click(args)
	if args.button == "l" then
		-- Toggle DAP (conditional) breakpoint on (Ctrl-)left click
		toggle_breakpoint(args)
	elseif args.button == "m" then
		c("norm! yy") -- Yank on middle click
	elseif args.button == "r" then
		if args.clicks == 2 then
			c("norm! dd") -- Cut on double right click
		else
			c("norm! p") -- Paste on right click
		end
	end
end

builtin.clickhandlers = {
	Lnum = lnum_click,
	FoldClose = foldclose_click,
	FoldOpen = foldopen_click,
	FoldEmpty = foldempty_click,
	DapBreakpointRejected = toggle_breakpoint,
	DapBreakpoint = toggle_breakpoint,
	DapBreakpointCondition = toggle_breakpoint,
	DiagnosticSignError = diagnostic_click,
	DiagnosticSignHint = diagnostic_click,
	DiagnosticSignInfo = diagnostic_click,
	DiagnosticSignWarn = diagnostic_click,
	GitSignsTopdelete = gitsigns_click,
	GitSignsUntracked = gitsigns_click,
	GitSignsAdd = gitsigns_click,
	GitSignsChangedelete = gitsigns_click,
	GitSignsDelete = gitsigns_click,
}

local cfg = {
	separator = " ",
	-- Builtin line number string options
	thousands = false,
	relculright = false,
	-- Custom line number string options
	lnumfunc = nil,
	reeval = false,
	-- Builtin 'statuscolumn' options
	setopt = false,
	order = "FSNs",
}

--- Store defined signs without whitespace.
local function update_sign_defined()
	for _, sign in ipairs(f.sign_getdefined()) do
		if sign.text then
			signs[sign.name] = sign.text:gsub("%s", "")
		end
	end
end

--- Store click args and fn.getmousepos() in table.
--- Set current window and mouse position to clicked line.
local function get_click_args(minwid, clicks, button, mods)
	local args = {
		minwid = minwid,
		clicks = clicks,
		button = button,
		mods = mods,
		mousepos = f.getmousepos(),
	}
	a.nvim_set_current_win(args.mousepos.winid)
	a.nvim_win_set_cursor(0, { args.mousepos.line, 0 })
	return args
end

--- Execute fold column click callback.
local function get_fold_action(minwid, clicks, button, mods)
	local foldopen = O.fillchars:get().foldopen or "-"
	local args = get_click_args(minwid, clicks, button, mods)
	local char = f.screenstring(args.mousepos.screenrow, args.mousepos.screencol)
	local type = char == " " and "FoldEmpty" or char == foldopen and "FoldOpen" or "FoldClose"

	S(function()
		cfg[type](args)
	end)
end

--- Execute sign column click callback.
local function get_sign_action(minwid, clicks, button, mods)
	local args = get_click_args(minwid, clicks, button, mods)
	local sign = f.screenstring(args.mousepos.screenrow, args.mousepos.screencol)
	-- If clicked on empty space in the sign column, try one cell to the left
	if sign == " " then
		sign = f.screenstring(args.mousepos.screenrow, args.mousepos.screencol - 1)
	end

	if not signs[sign] then
		update_sign_defined()
	end
	for name, text in pairs(signs) do
		if text == sign and cfg[name] then
			S(function()
				cfg[name](args)
			end)
			break
		end
	end
end

--- Execute line number click callback.
local function get_lnum_action(minwid, clicks, button, mods)
	local args = get_click_args(minwid, clicks, button, mods)
	S(function()
		cfg.Lnum(args)
	end)
end

--- Return custom or builtin line number string.
local function get_lnum_string()
	if cfg.lnumfunc then
		return cfg.lnumfunc()
	else
		return builtin.lnumfunc(o.number, o.relativenumber, cfg.thousands, cfg.relculright)
	end
end

-- Only return separator if the statuscolumn is non empty.
local function get_separator_string()
	local textoff = vim.fn.getwininfo(a.nvim_get_current_win())[1].textoff
	return tonumber(textoff) > 0 and cfg.separator or ""
end

-- Option 2 (https://www.reddit.com/r/neovim/comments/10fpqbp/comment/j4y8sd3/?utm_source=share&utm_medium=web2x&context=3)
local gitsigns_bar = "▌"

local gitsigns_hl_pool = {
	GitSignsAdd = "DiagnosticOk",
	GitSignsChange = "DiagnosticWarn",
	GitSignsChangedelete = "DiagnosticWarn",
	GitSignsDelete = "DiagnosticError",
	GitSignsTopdelete = "DiagnosticError",
	GitSignsUntracked = "NonText",
}

local diag_signs_icons = {
	DiagnosticSignError = " ",
	DiagnosticSignWarn = " ",
	DiagnosticSignInfo = " ",
	DiagnosticSignHint = "",
	DiagnosticSignOk = " ",
}

local function get_sign_name(cur_sign)
	if cur_sign == nil then
		return nil
	end

	cur_sign = cur_sign[1]

	if cur_sign == nil then
		return nil
	end

	cur_sign = cur_sign.signs

	if cur_sign == nil then
		return nil
	end

	cur_sign = cur_sign[1]

	if cur_sign == nil then
		return nil
	end

	return cur_sign["name"]
end

local function mk_hl(group, sym)
	return table.concat({ "%#", group, "#", sym, "%*" })
end

local function get_name_from_group(bufnum, lnum, group)
	local cur_sign_tbl = vim.fn.sign_getplaced(bufnum, {
		group = group,
		lnum = lnum,
	})

	return get_sign_name(cur_sign_tbl)
end

_G.get_statuscol_gitsign = function(bufnr, lnum)
	local cur_sign_nm = get_name_from_group(bufnr, lnum, "gitsigns_vimfn_signs_")

	if cur_sign_nm ~= nil then
		return mk_hl(gitsigns_hl_pool[cur_sign_nm], gitsigns_bar)
	else
		return " "
	end
end

_G.get_statuscol_diag = function(bufnum, lnum)
	local cur_sign_nm = get_name_from_group(bufnum, lnum, "*")

	if cur_sign_nm ~= nil and vim.startswith(cur_sign_nm, "DiagnosticSign") then
		return mk_hl(cur_sign_nm, diag_signs_icons[cur_sign_nm])
	else
		return " "
	end
end

_G.get_statuscol = function()
	local str_table = {}

	local parts = {
		["diagnostics"] = "%{%v:lua.get_statuscol_diag(bufnr(), v:lnum)%}",
		["fold"] = "%C",
		["gitsigns"] = "%{%v:lua.get_statuscol_gitsign(bufnr(), v:lnum)%}",
		["num"] = "%{v:relnum?v:relnum:v:lnum}",
		["sep"] = "%=",
		["signcol"] = "%s",
		["space"] = " ",
	}

	local order = {
		"diagnostics",
		"sep",
		"num",
		"space",
		"gitsigns",
		"fold",
		"space",
	}

	for _, val in ipairs(order) do
		table.insert(str_table, parts[val])
	end

	return table.concat(str_table)
end

-- Option 3 (https://www.reddit.com/r/neovim/comments/10fpqbp/comment/j50be6b/?utm_source=share&utm_medium=web2x&context=3)

---@return {name:string, text:string, texthl:string}[]
function M.get_signs()
	local buf = vim.api.nvim_win_get_buf(vim.g.statusline_winid)
	return vim.tbl_map(function(sign)
		return vim.fn.sign_getdefined(sign.name)[1]
	end, vim.fn.sign_getplaced(buf, { group = "*", lnum = vim.v.lnum })[1].signs)
end

function M.column()
	local sign, git_sign
	for _, s in ipairs(M.get_signs()) do
		if s.name:find("GitSign") then
			git_sign = s
		else
			sign = s
		end
	end
	local components = {
		sign and ("%#" .. sign.texthl .. "#" .. sign.text .. "%*") or " ",
		[[%=]],
		[[%{&nu?(&rnu&&v:relnum?v:relnum:v:lnum):''} ]],
		git_sign and ("%#" .. git_sign.texthl .. "#" .. git_sign.text .. "%*") or "  ",
	}
	return table.concat(components, "")
end

_G.Status = M
_G.ScFa = get_fold_action
_G.ScSa = get_sign_action
_G.ScLa = get_lnum_action
_G.ScLn = get_lnum_string
_G.ScSp = get_separator_string
cfg = vim.tbl_deep_extend("keep", cfg, builtin.clickhandlers)

-- O.statuscolumn = [[%!v:lua.Status.column()]] -- '%s%=%l %C%#Yellow#%{v:relnum == 0 ? ">" : ""} %#IdentBlankLineChar#%{v:relnum == 0 ? "" : "|"} '
-- o.statuscolumn = "%!v:lua.get_statuscol()" -- '%s%=%l %C%#Yellow#%{v:relnum == 0 ? ">" : ""} %#IdentBlankLineChar#%{v:relnum == 0 ? "" : "|"} '
if cfg.setopt then
	local reeval = cfg.reeval or cfg.relculright
	local stc = ""

	for i = 1, #cfg.order do
		local segment = cfg.order:sub(i, i)
		if segment == "F" then
			stc = stc .. "%@v:lua.ScFa@%C%T"
		elseif segment == "S" then
			stc = stc .. "%@v:lua.ScSa@%s%T"
		elseif segment == "N" then
			stc = stc .. "%@v:lua.ScLa@"
			stc = stc .. (reeval and "%=%{v:lua.ScLn()}" or "%{%v:lua.ScLn()%}")
			-- End the click execute label if separator is not next
			if cfg.order:sub(i + 1, i + 1) ~= "s" then
				stc = stc .. "%T"
			end
		elseif segment == "s" then
			-- Add click execute label if line number was not previous
			if cfg.order:sub(i - 1, i - 1) == "N" then
				stc = stc .. "%{v:lua.ScSp()}%T"
			else
				stc = stc .. "%@v:lua.ScLa@%{v:lua.ScSp()}%T"
			end
		end
	end

	o.statuscolumn = stc -- '%s%=%l %C%#Yellow#%{v:relnum == 0 ? ">" : ""} %#IdentBlankLineChar#%{v:relnum == 0 ? "" : "|"} '
end

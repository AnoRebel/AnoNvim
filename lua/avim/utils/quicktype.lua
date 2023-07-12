local M = {}

local is_notify_installed, notify = pcall(require, "notify")

local function should_notify()
	if is_notify_installed then
		return true
	end
	return false
end

function M.show_success(prefix, msg)
	local succ = "Success"
	if msg ~= nil then
		succ = msg
	end
	if should_notify() then
		notify(msg, "info", { title = prefix })
	else
		vim.api.nvim_echo({ { prefix, "Function" }, { " " .. succ } }, true, {})
	end
end

function M.show_error(prefix, msg)
	if should_notify() then
		notify(msg, "error", { title = prefix })
	else
		vim.api.nvim_echo({ { prefix, "ErrorMsg" }, { " " .. msg } }, true, {})
	end
end

function M.binary_exists(bin)
	if vim.fn.executable(bin) == 1 then
		return true
	end
	M.show_error(
		"No Binary",
		string.format("%s does not exist. Run `npm i -g quicktype or yarn add global quicktype`", bin)
	)
	-- vim.notify(
	-- 	string.format("%s not exists. Run `npm i -g quicktype or yarn add global quicktype`", bin),
	-- 	vim.log.levels.WARN,
	-- 	{ title = "AnoNvim" }
	-- )
	return false
end

function M.empty_output(data)
	if #data == 0 then
		return true
	end
	if #data == 1 and data[1] == "" then
		return true
	end

	return false
end

function M.quick_type(_, src, pkg_name, top_level)
	if not M.binary_exists("quicktype") then
		local cmd = { "npm", "install", "-g", "quicktype" }
		-- vim.api.nvim_echo({ { "Installing quicktype: quicktype ..." } }, true, {})
		vim.notify("Installing quicktype ...", vim.log.levels.INFO, { title = "AnoNvim" })
		vim.fn.jobstart(cmd, {
			on_exit = function(_, code, _)
				if code == 0 then
					M.show_success("AnoNvim", string.format("Installed %s", "quicktype"))
					-- vim.notify("Installed quicktype", vim.log.levels.INFO, { title = "AnoNvim" })
				end
			end,
			on_stderr = function(_, data, _)
				local results = table.concat(data, "\n")
				M.show_error("AnoNvim", results)
				-- vim.notify(results, vim.log.levels.WARN, { title = "AnoNvim" })
			end,
		})
	end
	local prefix = "GoQuickType"
	local cur_line = vim.fn.line(".")
	local cmd = {
		"quicktype",
		"--src",
		src,
		"--lang",
		"go",
		"--src-lang",
		"json",
	}
	if pkg_name ~= nil and #pkg_name > 0 then
		table.insert(cmd, "--package")
		table.insert(cmd, pkg_name)
	else
		-- auto detect package name
		local first_line = vim.fn.getline(1)
		local matches = vim.fn.matchlist(first_line, "^package\\s\\+\\(\\S\\+\\)$")
		if matches ~= nil and #matches >= 2 then
			pkg_name = matches[2]
			table.insert(cmd, "--package")
			table.insert(cmd, pkg_name)
		end
	end
	if top_level ~= nil and #top_level > 0 then
		table.insert(cmd, "--top-level")
		table.insert(cmd, top_level)
	end
	-- add extra args
	local opt = {
		quick_type_flags = { "--just-types" },
	}
	if opt.quick_type_flags ~= nil and opt.quick_type_flags then
		for _, flag in ipairs(opt.quick_type_flags) do
			table.insert(cmd, flag)
		end
	end

	vim.fn.jobstart(cmd, {
		on_exit = function(_, code, _)
			if code == 0 then
				M.show_success(prefix, "Success")
				-- vim.notify("Success", vim.log.levels.INFO, { title = prefix })
			end
		end,
		on_stdout = function(_, data, _)
			if data and #data > 0 then
				for i = 1, #data do
					vim.fn.append(cur_line, data[#data + 1 - i])
				end
			end
		end,
		on_stderr = function(_, data, _)
			local results = table.concat(data, "\n")
			M.show_error(prefix, results)
			-- vim.notify(results, vim.log.levels.WARN, { title = prefix })
		end,
	})
end

return M

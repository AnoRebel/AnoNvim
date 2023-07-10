-- An updating script copied from NvChad: `https://github.com/NvChad/extensions/blob/main/lua/nvchad/updater/update.lua`
-- @returns nil
local function update()
	local Log = require("avim.core.log")
	local name = "Avim Updater"
	local current_sha, backup_sha, remote_sha = "", "", ""
	local continue, skip_confirmation = false, false

	Log:debug("Updating AnoNvim")
	print("Updating AnoNvim")
	-- returns the latest commit message in the git history
	local result = vim.fn.system("git -C " .. _G.get_avim_base_dir() .. " log -1 --pretty=%B")
	if vim.api.nvim_get_vvar("shell_error") ~= 0 then
		vim.api.nvim_err_writeln(
			"Error running command:\n"
				.. "git -C "
				.. _G.get_avim_base_dir()
				.. " log -1 --pretty=%B"
				.. "\nError message:\n"
				.. result
		)
		return nil
	end
	if result then
		result = result:match("([%w\\_\\-.]*)")
	else
		result = ""
	end
	local valid = true
	local is_valid = true
	-- get the current sha of the local HEAD
	current_sha = vim.fn.system("git -C " .. _G.get_avim_base_dir() .. " rev-parse HEAD")
	if current_sha then
		current_sha = current_sha:match("([%w\\_\\-.]*)")
	else
		current_sha = ""
	end
	-- check if the base folder is a valid git directory
	if current_sha ~= "" then
		-- create a tmp snapshot of the current repo state
		vim.fn.system("git -C " .. _G.get_avim_base_dir() .. " commit -a -m 'tmp'")
		backup_sha = vim.fn.system("git -C " .. _G.get_avim_base_dir() .. " rev-parse HEAD")
		if backup_sha then
			backup_sha = backup_sha:match("([%w\\_\\-.]*)")
		else
			backup_sha = ""
		end
		if backup_sha == "" then
			valid = false
		end
	else
		valid = false
	end
	if not valid then
		vim.fn.system(
			"git -C "
				.. _G.get_avim_base_dir()
				.. " reset --hard "
				.. current_sha
				.. " ; git -C "
				.. _G.get_avim_base_dir()
				.. " cherry-pick -n "
				.. backup_sha
				.. " ; git reset"
		)
		-- replace any occurances of old_text in text_list with new_text
		local function list_text_replace(text_list, old_text, new_text)
			for i, v in ipairs(text_list) do
				if type(v) == "string" then
					text_list[i] = v:gsub(old_text, new_text)
				else
					list_text_replace(v, old_text, new_text)
				end
			end
			return text_list
		end

		-- replace any occurances of old_text in text_list with new_text
		local list_text_replacer = function(text_list, old_text, new_text)
			local new_tbl = vim.deepcopy(text_list)

			if type(old_text) == "table" and type(new_text) == "table" and #old_text == #new_text then
				for i, v in ipairs(old_text) do
					list_text_replace(new_tbl, v, new_text[i])
				end
			elseif type(old_text) == "string" and type(new_text) == "string" then
				list_text_replace(new_tbl, old_text, new_text)
			end
			return new_tbl
		end
		vim.notify(
			"Error: " .. _G.get_avim_base_dir() .. " is not a valid git directory.\n",
			vim.log.levels.ERROR,
			{ title = name }
		)
		vim.api.nvim_echo(
			list_text_replacer(
				{
					{ "Error: ", "ErrorMsg" },
					{ "<CONFIG_PATH>", "ErrorMsg" },
					{ " is not a valid git directory.\n", "ErrorMsg" },
				},
				"<CONFIG_PATH>",
				_G.get_avim_base_dir()
			),
			false,
			{}
		)
		is_valid = false
	end

	-- return if the directory is not a valid git directory
	if not is_valid then
		return
	end
	vim.notify("Checking for updates...", vim.log.levels.INFO, { title = name })
	vim.api.nvim_echo({ { "Checking for updates...", "String" } }, false, {})
	-- get the current sha of the remote HEAD
	remote_sha = vim.fn.system("git -C " .. _G.get_avim_base_dir() .. " ls-remote --heads origin main")

	if remote_sha then
		remote_sha = remote_sha:match("([%w\\_\\-.]*)")
	else
		remote_sha = ""
	end

	if remote_sha == "" then
		vim.fn.system(
			"git -C "
				.. _G.get_avim_base_dir()
				.. " reset --hard "
				.. current_sha
				.. " ; git -C "
				.. _G.get_avim_base_dir()
				.. " cherry-pick -n "
				.. backup_sha
				.. " ; git reset"
		)
		vim.notify("Error: Could not fetch remote HEAD sha.", vim.log.levels.ERROR, { title = name })
		vim.api.nvim_echo({ { "Error: Could not fetch remote HEAD sha.", "ErrorMsg" } }, false, {})
		return
	end
	-- continue, skip_confirmation = git.check_for_breaking_changes(current_sha, remote_sha)
	-- ask the user for confirmation to update because we are going to run git reset --hard
	if backup_sha ~= current_sha then
		-- prompt user that modifications outside of the custom directory will be lost
		vim.notify(
			"Warning\n  Modification to repo files detected.\n\n  Updater will run git reset --hard in base folder, so changes to existing repo files will be lost!\n",
			vim.log.levels.WARN,
			{ title = name }
		)
		vim.api.nvim_echo({
			{ "Warning\n  Modification to repo files detected.\n\n  Updater will run", "WarningMsg" },
			{ " git reset --hard " },
			{ "in base folder, so changes to existing repo files ", "WarningMsg" },
			{ " will be lost!\n", "WarningMsg" },
		}, false, {})
		skip_confirmation = false
	else
		vim.notify(
			"No conflicting changes outside of the custom folder, ready to update.",
			vim.log.levels.INFO,
			{ title = name }
		)
		vim.api.nvim_echo(
			{ { "No conflicting changes outside of the custom folder, ready to update.", "Title" } },
			false,
			{}
		)
	end
	-- print the passed symbol print_count amount of times or return a string
	local print_padding = function(symbol, repeat_count, return_string)
		local padding = ""

		while repeat_count > 0 do
			padding = padding .. symbol
			repeat_count = repeat_count - 1
		end

		if return_string then
			return padding
		else
			vim.api.nvim_echo({ { padding } }, false, {})
		end
	end
	if skip_confirmation then
		print_padding("\n", 1)
	else
		vim.notify("\nUpdate AnoNvim? [y/N]", vim.log.levels.WARN, { title = name })
		vim.api.nvim_echo({ { "\nUpdate AnoNvim? [y/N]", "WarningMsg" } }, false, {})
		local ans = string.lower(vim.fn.input("-> ")) == "y"

		print_padding("\n", 2)

		if not ans then
			vim.fn.system(
				"git -C "
					.. _G.get_avim_base_dir()
					.. " reset --hard "
					.. current_sha
					.. " ; git -C "
					.. _G.get_avim_base_dir()
					.. " cherry-pick -n "
					.. backup_sha
					.. " ; git reset"
			)
			vim.notify("Update cancelled!", vim.log.levels.INFO, { title = name })
			vim.api.nvim_echo({ { "Update cancelled!", "Title" } }, false, {})
			return
		end
	end
	-- prompt the user to execute Lazy sync
	local lazy_sync = function()
		vim.notify(
			"Would you like to run `Lazy sync` after the update has completed?\nNot running `Lazy sync` may break AnoNvim! [y/N]",
			vim.log.levels.WARN,
			{ title = name }
		)
		vim.api.nvim_echo({
			{ "Would you like to run ", "WarningMsg" },
			{ "Lazy sync" },
			{ " after the update has completed?\n", "WarningMsg" },
			{ "Not running ", "WarningMsg" },
			{ "Lazy sync" },
			{ " may break AnoNvim! ", "WarningMsg" },
			{ "[y/N]", "WarningMsg" },
		}, false, {})
		local ans = string.lower(vim.fn.input("-> ")) == "y"
		return ans
	end
	-- function that will executed when git commands are done
	local function update_exit(_, code)
		-- close the terminal buffer only if update was success, as in case of error, we need the
		-- error message
		if code == 0 then
			local summary = {}

			-- check if there are new commits
			local head_sha = vim.fn.system("git -C " .. _G.get_avim_base_dir() .. " rev-parse HEAD")

			if head_sha then
				head_sha = head_sha:match("([%w\\_\\-.]*)")
			else
				head_sha = ""
			end
			local applied_commit_list
			local commit_list_string = vim.fn.system(
				"git -C "
					.. _G.get_avim_base_dir()
					.. ' log --oneline --no-merges --decorate --date=short --pretty="format:%ad: %h %s" '
					.. current_sha
					.. ".."
					.. head_sha
			)
			if vim.api.nvim_get_vvar("shell_error") ~= 0 then
				vim.notify(
					"Error running command:\n"
						.. "git -C "
						.. _G.get_avim_base_dir()
						.. ' log --oneline --no-merges --decorate --date=short --pretty="format:%ad: %h %s" '
						.. current_sha
						.. ".."
						.. head_sha
						.. "\nError message:\n"
						.. commit_list_string,
					vim.log.levles.ERROR,
					{ title = name }
				)
				vim.api.nvim_err_writeln(
					"Error running command:\n"
						.. "git -C "
						.. _G.get_avim_base_dir()
						.. ' log --oneline --no-merges --decorate --date=short --pretty="format:%ad: %h %s" '
						.. current_sha
						.. ".."
						.. head_sha
						.. "\nError message:\n"
						.. commit_list_string
				)
			end

			if commit_list_string == nil then
				applied_commit_list = nil
			end

			applied_commit_list = vim.fn.split(commit_list_string, "\n")

			if applied_commit_list ~= nil and #applied_commit_list > 0 then
				vim.list_extend(summary, { { "Applied Commits:\n", "Title" } })
				local output = { { "" } }
				for _, line in ipairs(applied_commit_list) do
					-- split line into date hash and message. Expected format: "yyyy-mm-dd: hash message"
					local commit_date, commit_hash, commit_message =
						line:match("(%d%d%d%d%-%d%d%-%d%d): " .. "(%w+)(.*)")

					-- merge commit messages into one output array to minimize echo calls
					vim.list_extend(output, {
						{ "    " },
						{ tostring(commit_date) },
						{ " " },
						{ tostring(commit_hash), "WarningMsg" },
						{ tostring(commit_message), "String" },
						{ "\n" },
					})
				end
				vim.list_extend(summary, output)
			else -- no new commits
				vim.list_extend(summary, { { "Could not create a commit summary.\n", "WarningMsg" } })
			end

			vim.list_extend(summary, { { "\nAnoNvim succesfully updated.\n", "String" } })

			-- print the update summary
			vim.cmd("bd!")
			for _, summ in ipairs(summary) do
				vim.notify(summ[1], summ[2], { title = name })
			end
			vim.api.nvim_echo(summary, false, {})
			if lazy_sync then
				vim.cmd([[Lazy! sync]])
			end
		else
			vim.fn.system(
				"git -C "
					.. _G.get_avim_base_dir()
					.. " reset --hard "
					.. current_sha
					.. " ; git -C "
					.. _G.get_avim_base_dir()
					.. " cherry-pick -n "
					.. backup_sha
					.. " ; git reset"
			)
			vim.notify(
				"Error: AnoNvim Update failed.\n\nLocal changes were restored.",
				vim.log.levels.ERROR,
				{ title = name }
			)
			vim.api.nvim_echo(
				{ { "Error: NvChad Update failed.\n\n", "ErrorMsg" }, { "Local changes were restored." } },
				false,
				{}
			)
		end
	end

	-- reset in case config was modified
	local rest = vim.fn.system("git -C " .. _G.get_avim_base_dir() .. " reset --hard " .. current_sha)
	if vim.api.nvim_get_vvar("shell_error") ~= 0 then
		vim.notify(
			"Error running command:\n"
				.. "git -C "
				.. _G.get_avim_base_dir()
				.. " reset --hard "
				.. current_sha
				.. "\nError message:\n"
				.. rest,
			vim.log.levels.ERROR,
			{ title = name }
		)
		vim.api.nvim_err_writeln(
			"Error running command:\n"
				.. "git -C "
				.. _G.get_avim_base_dir()
				.. " reset --hard "
				.. current_sha
				.. "\nError message:\n"
				.. rest
		)
	end

	-- use --rebase, to not mess up if the local repo is outdated
	local update_script = { "git pull --set-upstream https://github.com/AnoRebel/AnoNvim main --rebase" }

	-- check if NvChad is running on windows and pipe the command through cmd.exe
	if vim.fn.has("win32") == 1 then
		update_script = { "cmd.exe", "/C", update_script }
	end

	-- open a new buffer
	vim.cmd("new")

	-- finally open the pseudo terminal buffer
	vim.fn.termopen(update_script, {

		-- change dir to config path so we don't need to move in script
		cwd = _G.get_avim_base_dir(),
		on_exit = update_exit,
	})
end

return update

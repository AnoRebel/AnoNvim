local ui_options = {
	icons = { expanded = "", collapsed = "", current_frame = "" },
	-- icons = { expanded = "▾", collapsed = "▸" },
	mappings = {
		-- Use a table to apply multiple mappings
		expand = { "<CR>", "<2-LeftMouse>" },
		open = "o",
		remove = "d",
		edit = "e",
		repl = "r",
		toggle = "t",
	},
	-- Expand lines larger than the window
	-- Requires >= 0.7
	expand_lines = vim.fn.has("nvim-0.7"),
	layouts = {
		{
			elements = {
				-- Provide as ID strings or tables with "id" and "size" keys
				{
					id = "scopes",
					size = 0.25, -- Can be float or integer > 1
				},
				{ id = "breakpoints", size = 0.25 },
				{ id = "stacks", size = 0.25 },
				{ id = "watches", size = 00.25 },
			},
			size = 40, -- 40 columns
			position = "right",
		},
		{
			elements = {
				"repl",
				"console",
			},
			size = 0.25, -- 25% of total lines
			position = "bottom",
		},
	},
	tray = { elements = { "repl" }, size = 10, position = "bottom" },
	floating = {
		max_height = nil,
		max_width = nil,
		border = require("avim.core.defaults").options.border_chars,
		mappings = { close = { "q", "<Esc>" } },
	},
	windows = { indent = 1 },
	render = {
		max_type_length = nil, -- Can be integer or nil.
	},
}

local M = {
	"mfussenegger/nvim-dap",
	enabled = vim.fn.has("win32") == 0,
	cmd = {
		"DapInstall",
		"DapShowLog",
		"DapStepOut",
		"DapContinue",
		"DapStepInto",
		"DapStepOver",
		"DapTerminate",
		"DapUninstall",
		"DapToggleRepl",
		"DapRestartFrame",
		"DapLoadLaunchJSON",
		"DapToggleBreakpoint",
	},
	dependencies = {
		{
			"rcarriga/nvim-dap-ui",
			opts = ui_options,
		},
		{
			"theHamsta/nvim-dap-virtual-text",
			config = true,
		},
	},
}

function M.config()
	local dap = require("dap")
	--- Dap Buddy ??? ---
	-- local dap = require("dap-install")
	--
	-- local debugger_list = require("dap-install.debuggers_list").debuggers
	--
	-- for debugger, _ in pairs(debugger_list) do
	--   dap.config(debugger, {})
	-- end
	---------------------
	local dapui = require("dapui")

	dap.listeners.after.event_initialized["dapui_config"] = function()
		dapui.open()
	end
	dap.listeners.after.event_terminated["dapui_config"] = function()
		dapui.close()
	end
	dap.listeners.after.event_exited["dapui_config"] = function()
		dapui.close()
	end

	vim.fn.sign_define("DapBreakpoint", { text = "🛑", texthl = "", linehl = "", numhl = "" })

	-- dap.adapters.coreclr = {
	-- 	type = "executable",
	-- 	command = "/path/to/dotnet/netcoredbg/netcoredbg",
	-- 	args = { "--interpreter=vscode" },
	-- }

	-- dap.configurations.cs = {
	-- 	{
	-- 		type = "coreclr",
	-- 		name = "launch - netcoredbg",
	-- 		request = "launch",
	-- 		program = function()
	-- 			return vim.fn.input("Path to dll", vim.fn.getcwd() .. "/bin/Debug/", "file")
	-- 		end,
	-- 	},
	-- }

	dap.configurations.c = dap.configurations.cpp

	dap.adapters.dart = {
		type = "executable",
		-- As of this writing, this functionality is open for review in https://github.com/flutter/flutter/pull/91802
		command = "flutter",
		args = { "debug_adapter" },
	}
	dap.configurations.dart = {
		{
			type = "dart",
			request = "launch",
			flutterMode = "profile", -- "debug",
			name = "Launch Flutter Program",
			-- The nvim-dap plugin populates this variable with the filename of the current buffer
			program = "${workspaceFolder}/lib/main.dart",
			-- program = "${file}",
			-- The nvim-dap plugin populates this variable with the editor's current working directory
			cwd = "${workspaceFolder}",
			-- This gets forwarded to the Flutter CLI tool, substitute `linux` for whatever device you wish to launch
			-- toolArgs = {"-d", "linux"}
		},
	}

	dap.adapters.go = function(callback, config)
		local stdout = vim.loop.new_pipe(false)
		local handle
		local pid_or_err
		local port = 38697
		local opts = {
			stdio = { nil, stdout },
			args = { "dap", "-l", "127.0.0.1:" .. port },
			detached = true,
		}
		handle, pid_or_err = vim.loop.spawn("dlv", opts, function(code)
			stdout:close()
			handle:close()
			if code ~= 0 then
				print("dlv exited with code", code)
			end
		end)
		assert(handle, "Error running dlv: " .. tostring(pid_or_err))
		stdout:read_start(function(err, chunk)
			assert(not err, err)
			if chunk then
				vim.schedule(function()
					require("dap.repl").append(chunk)
				end)
			end
		end)
		-- Wait for delve to start
		vim.defer_fn(function()
			callback({ type = "server", host = "127.0.0.1", port = port })
		end, 100)
	end
	-- https://github.com/go-delve/delve/blob/master/Documentation/usage/dlv_dap.md
	dap.configurations.go = {
		{ type = "go", name = "Debug", request = "launch", program = "${file}" },
		{
			type = "go",
			name = "Debug test", -- configuration for debugging test files
			request = "launch",
			mode = "test",
			program = "${file}",
		}, -- works with go.mod packages and sub packages
		{
			type = "go",
			name = "Debug test (go.mod)",
			request = "launch",
			mode = "test",
			program = "./${relativeFileDirname}",
		},
	}

	dap.adapters.python = {
		type = "executable",
		command = _G.get_runtime_dir() .. "/dapinstall/python/bin/python", -- "/usr/bin/python3",
		args = { "-m", "debugpy.adapter" },
	}
	dap.configurations.python = {
		{
			-- The first three options are required by nvim-dap
			type = "python", -- the type here established the link to the adapter definition: `dap.adapters.python`
			request = "launch",
			name = "Launch file",
			-- Options below are for debugpy, see https://github.com/microsoft/debugpy/wiki/Debug-configuration-settings for supported options

			program = "${file}", -- This configuration will launch the current file if used.
			pythonPath = function()
				-- debugpy supports launching an application with a different interpreter then the one used to launch debugpy itself.
				-- The code below looks for a `venv` or `.venv` folder in the current directly and uses the python within.
				-- You could adapt this - to for example use the `VIRTUAL_ENV` environment variable.
				-- local vdir = os.getenv('VIRTUAL_ENV')
				-- if vdir then
				--   return vdir .. "/bin/python"
				-- else
				--   return "/usr/bin/python3" -- "/usr/bin/python"
				-- end
				local cwd = vim.fn.getcwd()
				if vim.fn.executable(cwd .. "/venv/bin/python") == 1 then
					return cwd .. "/venv/bin/python"
				elseif vim.fn.executable(cwd .. "/.venv/bin/python") == 1 then
					return cwd .. "/.venv/bin/python"
				else
					return "/usr/bin/python"
				end
			end,
		},
	}
end

return M

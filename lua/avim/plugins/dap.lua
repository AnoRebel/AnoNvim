local features = require("avim.core.defaults").features

if features.dap then
    local dap = require("dap")
    local ui = require("dapui")
    -- Start debugging session
    vim.keymap.set("n", "<localleader>ds", function()
        dap.continue()
        ui.toggle({})
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-w>=", false, true, true), "n", false) -- Spaces buffers evenly
    end)

    -- Set breakpoints, get variable values, step into/out of functions, etc.
    vim.keymap.set("n", "<localleader>dl", require("dap.ui.widgets").hover)
    vim.keymap.set("n", "<localleader>dc", dap.continue)
    vim.keymap.set("n", "<localleader>db", dap.toggle_breakpoint)
    vim.keymap.set("n", "<localleader>dn", dap.step_over)
    vim.keymap.set("n", "<localleader>di", dap.step_into)
    vim.keymap.set("n", "<localleader>do", dap.step_out)
    vim.keymap.set("n", "<localleader>dC", function()
        dap.clear_breakpoints()
        require("notify")("Breakpoints cleared", "warn")
    end)

    -- Close debugger and clear breakpoints
    vim.keymap.set("n", "<localleader>de", function()
        dap.clear_breakpoints()
        ui.toggle({})
        dap.terminate()
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-w>=", false, true, true), "n", false)
        require("notify")("Debugger session ended", "warn")
    end)
end

return {
    "mfussenegger/nvim-dap",
    enabled = false,
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
    config = function()
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
        -- dap.listeners.after = {
        --   event_initialized = {
        --     ["dapui_config"] = function()
        --       dapui.open()
        --     end,
        --   },
        --   event_terminated = {
        --     ["dapui_config"] = function()
        --       dapui.close()
        --     end,
        --   },
        --   event_exited = {
        --     ["dapui_config"] = function()
        --       dapui.close()
        --     end,
        --   },
        -- }

        vim.fn.sign_define("DapBreakpoint", { text = "🛑", texthl = "", linehl = "", numhl = "" })
        -- vim.fn.sign_define("DapBreakpoint", { text = "🟥", texthl = "", linehl = "", numhl = "" })
        vim.fn.sign_define("DapStopped", { text = "▶️", texthl = "", linehl = "", numhl = "" })

        dap.adapters = {
            dart = {
                type = "executable",
                -- As of this writing, this functionality is open for review in https://github.com/flutter/flutter/pull/91802
                command = "flutter",
                args = { "debug_adapter" },
            },
            node2 = {
                type = "executable",
                command = "node",
                args = { _G.get_runtime_dir() .. "/mason/packages/node-debug2-adapter/out/src/nodeDebug.js" },
            },
            go = {
                type = "server",
                port = "${port}",
                executable = {
                    command = _G.get_runtime_dir() .. "/mason/bin/dlv",
                    args = { "dap", "-l", "127.0.0.1:${port}" },
                },
            },
            python = {
                type = "executable",
                command = os.getenv("VIRTUAL_ENV") and os.getenv("VIRTUAL_ENV") .. "/bin/python" or "/usr/bin/python3", -- _G.get_runtime_dir() .. "/dapinstall/python/bin/python", -- "/usr/bin/python3",
                args = { "-m", "debugpy.adapter" },
            },
        }
        dap.configurations = {
            dart = {
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
            },
            javascript = {
                {
                    type = "node2",
                    name = "Launch",
                    request = "launch",
                    program = "${file}",
                    cwd = vim.fn.getcwd(),
                    sourceMaps = true,
                    protocol = "inspector",
                    console = "integratedTerminal",
                },
                {
                    type = "node2",
                    name = "Attach",
                    request = "attach",
                    program = "${file}",
                    cwd = vim.fn.getcwd(),
                    sourceMaps = true,
                    protocol = "inspector",
                    console = "integratedTerminal",
                },
            },
            go = {
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
            },
            python = {
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
                        local vdir = os.getenv("VIRTUAL_ENV")
                        if vdir then
                            return vdir .. "/bin/python"
                        else
                            return "/usr/bin/python3" -- "/usr/bin/python"
                        end
                        -- local cwd = vim.fn.getcwd()
                        -- if vim.fn.executable(cwd .. "/venv/bin/python") == 1 then
                        --   return cwd .. "/venv/bin/python"
                        -- elseif vim.fn.executable(cwd .. "/.venv/bin/python") == 1 then
                        --   return cwd .. "/.venv/bin/python"
                        -- else
                        --   return "/usr/bin/python"
                        -- end
                    end,
                },
            },
        }
        -- If using `.vscode/launch.json`
        -- local vscode = require("dap.ext.vscode")
        -- local json = require("plenary.json")
        -- vscode.json_decode = function(str)
        --   return vim.json.decode(json.json_strip_comments(str))
        -- end
    end,
    dependencies = {
        {
            "rcarriga/nvim-dap-ui",
            opts = {
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
                            { id = "stacks",      size = 0.25 },
                            { id = "watches",     size = 00.25 },
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
            },
        },
        {
            "theHamsta/nvim-dap-virtual-text",
            config = true,
        },
    },
}

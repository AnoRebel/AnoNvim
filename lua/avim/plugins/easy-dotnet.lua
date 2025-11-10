--- the following functions are necessary to support semantic tokens with the roslyn
--- language server.

--- reference: https://github.com/seblyng/roslyn.nvim/wiki#semantic-tokens
--- this function should work with 0.10 and 0.11 of Neovim

--- NOTE: kept for reference, this is no longer needed. Beginning with version 5.0.0.1,
--- the roslyn LSP server supports semanticTokens/full and is therefore fully compatible
--- with Neovim.
--- @param client vim.lsp.ClientConfig
--- @diagnostic disable-next-line
local function fix_semantic_tokens(client)
  if client.is_patched then
    return
  end
  client.is_patched = true

  -- let the runtime know the server can do semanticTokens/full now
  client.server_capabilities = vim.tbl_deep_extend("force", client.server_capabilities, {
    semanticTokensProvider = {
      full = true,
    },
  })

  -- monkey patch the request proxy
  local request_inner = client.request

  if vim.fn.has("nvim-0.11") == 1 then
    function client:request(method, params, handler, req_bufnr)
      if method ~= vim.lsp.protocol.Methods.textDocument_semanticTokens_full then
        return request_inner(self, method, params, handler)
      end

      local target_bufnr = vim.uri_to_bufnr(params.textDocument.uri)
      local line_count = vim.api.nvim_buf_line_count(target_bufnr)
      local last_line = vim.api.nvim_buf_get_lines(target_bufnr, line_count - 1, line_count, true)[1]

      return request_inner(self, "textDocument/semanticTokens/range", {
        textDocument = params.textDocument,
        range = {
          ["start"] = {
            line = 0,
            character = 0,
          },
          ["end"] = {
            line = line_count - 1,
            character = string.len(last_line) - 1,
          },
        },
      }, handler, req_bufnr)
    end
  else
    client.request = function(method, params, handler, req_bufnr)
      if method ~= vim.lsp.protocol.Methods.textDocument_semanticTokens_full then
        return request_inner(method, params, handler, req_bufnr)
      end

      --local target_bufnr = find_buf_by_uri(params.textDocument.uri)
      local target_bufnr = vim.uri_to_bufnr(params.textDocument.uri)
      local line_count = vim.api.nvim_buf_line_count(target_bufnr)
      local last_line = vim.api.nvim_buf_get_lines(target_bufnr, line_count - 1, line_count, true)[1]

      return request_inner("textDocument/semanticTokens/range", {
        textDocument = params.textDocument,
        range = {
          ["start"] = {
            line = 0,
            character = 0,
          },
          ["end"] = {
            line = line_count - 1,
            character = string.len(last_line) - 1,
          },
        },
      }, handler, req_bufnr)
    end
  end
end

return {
  {
    "seblyng/roslyn.nvim",
    ft = { "cs", "razor", "cshtml" },
    init = function()
      -- We add the Razor file types before the plugin loads.
      vim.filetype.add({
        extension = {
          razor = "razor",
          cshtml = "razor",
        },
      })
      vim.api.nvim_create_autocmd({ "BufWritePost" }, {
        pattern = "*",
        callback = function()
          local clients = vim.lsp.get_clients({ name = "roslyn" })
          if not clients or #clients == 0 then
            return
          end

          local buffers = vim.lsp.get_buffers_by_client_id(clients[1].id)
          for _, buf in ipairs(buffers) do
            vim.lsp.util._refresh("textDocument/diagnostic", { bufnr = buf })
          end
        end,
      })
    end,
    dependencies = {
      {
        -- By loading as a dependencies, we ensure that we are available to set
        -- the handlers for Roslyn.
        "tris203/rzls.nvim",
        config = true,
      },
    },
    ---@module 'roslyn.config'
    ---@type RoslynNvimConfig
    opts = {},
  },
  {
    "GustavEikaas/easy-dotnet.nvim",
    -- 'nvim-telescope/telescope.nvim' or 'ibhagwan/fzf-lua' or 'folke/snacks.nvim'
    -- are highly recommended for a better experience
    dependencies = { "folke/snacks.nvim" },
    cmd = { "Dotnet" },
    build = "dotnet tool install -g EasyDotnet;dotnet tool install -g dotnet-outdated-tool;dotnet tool install -g dotnet-ef;",
    config = function()
      local function get_secret_path(secret_guid)
        local path = ""
        local home_dir = vim.fn.expand("~")
        if require("easy-dotnet.extensions").isWindows() then
          local secret_path = home_dir
            .. "\\AppData\\Roaming\\Microsoft\\UserSecrets\\"
            .. secret_guid
            .. "\\secrets.json"
          path = secret_path
        else
          local secret_path = home_dir .. "/.microsoft/usersecrets/" .. secret_guid .. "/secrets.json"
          path = secret_path
        end
        return path
      end

      local function get_sdk_path()
        local path = ""
        if require("easy-dotnet.extensions").isWindows() then
          local sdk_path = require("easy-dotnet.extensions").get_sdk_path()
          path = sdk_path
        else
          local sdk_path = "/usr/share/dotnet/sdk"
          path = sdk_path
        end
        return path
      end

      local dotnet = require("easy-dotnet")
      -- Options are not required
      dotnet.setup({
        --Optional function to return the path for the dotnet sdk (e.g C:/ProgramFiles/dotnet/sdk/8.0.0)
        -- easy-dotnet will resolve the path automatically if this argument is omitted, for a performance improvement you can add a function that returns a hardcoded string
        -- You should define this function to return a hardcoded path for a performance improvement 🚀
        get_sdk_path = get_sdk_path,
        ---@type TestRunnerOptions
        test_runner = {
          ---@type "split" | "vsplit" | "float" | "buf"
          viewmode = "float",
          ---@type number|nil
          vsplit_width = nil,
          ---@type string|nil "topleft" | "topright"
          vsplit_pos = nil,
          enable_buffer_test_execution = true, --Experimental, run tests directly from buffer
          noBuild = true,
          icons = {
            passed = "",
            skipped = "",
            failed = "",
            success = "",
            reload = "",
            test = "",
            sln = "󰘐",
            project = "󰘐",
            dir = "",
            package = "",
          },
          mappings = {
            run_test_from_buffer = { lhs = "<leader>r", desc = "run test from buffer" },
            filter_failed_tests = { lhs = "<leader>fe", desc = "filter failed tests" },
            debug_test = { lhs = "<leader>d", desc = "debug test" },
            go_to_file = { lhs = "g", desc = "go to file" },
            run_all = { lhs = "<leader>R", desc = "run all tests" },
            run = { lhs = "<leader>r", desc = "run test" },
            peek_stacktrace = { lhs = "<leader>p", desc = "peek stacktrace of failed test" },
            expand = { lhs = "o", desc = "expand" },
            expand_node = { lhs = "E", desc = "expand node" },
            expand_all = { lhs = "-", desc = "expand all" },
            collapse_all = { lhs = "W", desc = "collapse all" },
            close = { lhs = "q", desc = "close testrunner" },
            refresh_testrunner = { lhs = "<C-r>", desc = "refresh testrunner" },
          },
          --- Optional table of extra args e.g "--blame crash"
          additional_args = {},
        },
        new = {
          project = {
            prefix = "sln", -- "sln" | "none"
          },
        },
        ---@param action "test" | "restore" | "build" | "run"
        terminal = function(path, action, args)
          local commands = {
            run = function()
              return string.format("dotnet run --project %s %s", path, args)
            end,
            test = function()
              return string.format("dotnet test %s %s", path, args)
            end,
            restore = function()
              return string.format("dotnet restore %s %s", path, args)
            end,
            build = function()
              return string.format("dotnet build %s %s", path, args)
            end,
            watch = function()
              return string.format("dotnet watch --project %s %s", path, args)
            end,
          }

          local command = commands[action]() .. "\r"
          -- vim.cmd("vsplit")
          -- vim.cmd("term " .. command)
          Snacks.terminal.open(command, { win = { relative = "editor", position = "right" } })
        end,
        secrets = {
          path = get_secret_path,
        },
        csproj_mappings = true,
        fsproj_mappings = true,
        auto_bootstrap_namespace = {
          --block_scoped, file_scoped
          type = "block_scoped",
          enabled = true,
        },
        -- choose which picker to use with the plugin
        -- possible values are "telescope" | "fzf" | "snacks" | "basic"
        -- if no picker is specified, the plugin will determine
        -- the available one automatically with this priority:
        -- telescope -> fzf -> snacks ->  basic
        picker = "snacks",
        background_scanning = true,
        notifications = {
          --Set this to false if you have configured lualine to avoid double logging
          handler = function(start_event)
            local spinner = require("easy-dotnet.ui-modules.spinner").new()
            spinner:start_spinner(start_event.job.name)
            ---@param finished_event JobEvent
            return function(finished_event)
              spinner:stop_spinner(finished_event.result.text, finished_event.result.level)
            end
          end,
        },
      })

      -- Example command
      vim.api.nvim_create_user_command("Secrets", function()
        dotnet.secrets()
      end, {})

      -- Example keybinding
      vim.keymap.set("n", "<C-p>", function()
        dotnet.run_project()
      end)
    end,
  },
}

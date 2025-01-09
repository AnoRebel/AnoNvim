local defaults = require("avim.core.defaults")
local lsp_utils = require("avim.utilities.lsp")
local utilities = require("avim.utilities")

return {
  {
    "neovim/nvim-lspconfig",
    event = "BufReadPre",
    dependencies = {
      {
        "aznhe21/actions-preview.nvim",
        opts = function()
          local hl = require("actions-preview.highlight")
          return {
            backend = { "nui", "telescope" },
            diff = {
              algorithm = "patience",
              ignore_whitespace = true,
            },
            telescope = {
              sorting_strategy = "ascending",
              layout_strategy = "vertical",
              winblend = 10,
              layout_config = {
                width = 0.8,
                height = 0.9,
                prompt_position = "top",
                preview_cutoff = 20,
                preview_height = function(_, _, max_lines)
                  return max_lines - 15
                end,
              },
            },
            highlight_command = {
              -- Highlight diff using delta: https://github.com/dandavison/delta
              -- The argument is optional, in which case "delta" is assumed to be
              -- specified.
              hl.delta("delta --side-by-side"),
              -- You may need to specify "--no-gitconfig" since it is dependent on
              -- the gitconfig of the project by default.
              -- hl.delta("delta --no-gitconfig --side-by-side"),

              -- Highlight diff using diff-so-fancy: https://github.com/so-fancy/diff-so-fancy
              -- The arguments are optional, in which case ("diff-so-fancy", "less -R")
              -- is assumed to be specified. The existence of less is optional.
              -- hl.diff_so_fancy(),
            },
          }
        end,
      },
      {
        "kosayoda/nvim-lightbulb",
        opts = { autocmd = { enabled = true } },
      },
      {
        "akinsho/flutter-tools.nvim",
        cmd = {
          "FlutterRun",
          "FlutterDevices",
          "FlutterEmulators",
          "FlutterReload",
          "FlutterRestart",
          "FlutterQuit",
          "FlutterOutlineToggle",
          "FlutterDevTools",
          "FlutterDevToolsActivate",
          "FlutterDetach",
          "FlutterLspRestart",
          "FlutterSuper",
          "FlutterRename",
          "FlutterReanalyze",
        },
        dependencies = {
          "nvim-lua/plenary.nvim",
          -- optional for vim.ui.select
          "stevearc/dressing.nvim",
        },
      },
      {
        "olexsmir/gopher.nvim",
        dependencies = {
          "nvim-lua/plenary.nvim",
          "nvim-treesitter/nvim-treesitter",
        },
        ft = { "go", "gomod" },
        build = function()
          vim.cmd.GoInstallDeps()
        end,
        init = function()
          -- quick_type
          vim.api.nvim_create_user_command(
            "GoQuickType",
            'lua require("avim.utilities").quick_type(<count>, <f-args>)',
            {
              nargs = "*",
              complete = "file",
            }
          )
        end,
        config = true,
      },
      {
        "williamboman/mason.nvim",
        cmd = { "Mason", "MasonInstall", "MasonUninstall", "MasonUpdate", "MasonLog" },
        build = ":MasonUpdate", -- :MasonUpdate updates registry contents
        config = function(_, opts)
          require("mason").setup({
            -- automatic_installation = true,
            ui = {
              border = "none", -- "rounded",
              icons = {
                package_installed = "",
                package_pending = "",
                package_uninstalled = "ﮊ",
              },
            },
          })
          local mr = require("mason-registry")
          mr:on("package:install:success", function()
            vim.defer_fn(function()
              -- trigger FileType event to possibly load this newly installed LSP server
              require("lazy.core.handler.event").trigger({
                event = "FileType",
                buf = vim.api.nvim_get_current_buf(),
              })
            end, 100)
          end)

          mr.refresh(function()
            for _, tool in ipairs(vim.tbl_deep_extend("force", {}, opts.ensure_installed or {}, defaults.tools)) do
              local ok_mlsp, mlsp = pcall(require, "mason-lspconfig")
              local ok_mnls, mnls = pcall(require, "mason-null-ls.mappings.source")
              local ok_mdap, mdap = pcall(require, "mason-nvim-dap.mappings.source")
              if ok_mlsp then
                tool = mlsp.get_mappings().lspconfig_to_mason[tool] or tool
              end
              if ok_mnls then
                tool = mnls.getPackageFromNullLs(tool) or tool
              end
              if ok_mdap then
                tool = mdap.nvim_dap_to_package[tool] or tool
              end
              local p = mr.get_package(tool)
              if not p:is_installed() then
                p:install()
              end
            end
          end)
        end,
        keys = {
          { "<leader>pm", "<cmd>Mason<CR>", mode = { "n", "v" }, desc = "Mason" },
          -- { "<leader>pl", "<cmd>Mason<CR>", mode = { "n", "v" }, desc = "[Mason] Log" },
          -- { "<leader>pr", "<cmd>Mason<CR>", mode = { "n", "v" }, desc = "[Mason] Update" },
        },
      },
      {
        "williamboman/mason-lspconfig.nvim",
        opts = { ensure_installed = defaults.servers, automatic_installation = true },
        config = function(_, opts)
          require("mason-lspconfig").setup(opts)
        end,
      },
      {
        "jay-babu/mason-null-ls.nvim",
        cmd = { "NullLsInstall", "NoneLsInstall", "NullLsUninstall", "NoneLsUninstall" },
        opts = { ensure_installed = nil, automatic_installation = true },
        config = function(_, opts)
          require("mason-null-ls").setup(opts)
        end,
      },
      {
        "WhoIsSethDaniel/mason-tool-installer.nvim",
        cmd = {
          "MasonToolsInstall",
          "MasonToolsUpdate",
          "MasonToolsClean",
          "MasonToolsInstallSync",
          "MasonToolsUpdateSync",
        },
        config = function()
          require("mason-tool-installer").setup({
            ensure_installed = defaults.tools,
          })
        end,
      },
      {
        "dmmulroy/ts-error-translator.nvim",
        opts = {
          auto_override_publish_diagnostics = true,
        },
      },
      {
        "ray-x/lsp_signature.nvim",
        event = "LspAttach",
        config = function()
          require("lsp_signature").setup({
            bind = true,
            handler_opts = {
              border = "shadow", -- double, rounded, single, shadow, none, or a table of borders
            },
            transparency = 70,
            hint_prefix = " ",
            max_height = 22,
            max_width = 120, -- max_width of signature floating_window, line will be wrapped if exceed max_width
            floating_window_off_x = 5, -- adjust float windows x position.
            floating_window_off_y = function() -- adjust float windows y position. e.g. set to -2 can make floating window move up 2 lines
              local linenr = vim.api.nvim_win_get_cursor(0)[1] -- buf line number
              local pumheight = vim.o.pumheight
              local winline = vim.fn.winline() -- line number in the window
              local winheight = vim.fn.winheight(0)

              -- window top
              if winline - 1 < pumheight then
                return pumheight
              end

              -- window bottom
              if winheight - winline < pumheight then
                return -pumheight
              end
              return 0
            end,
          })
        end,
      },
      {
        "kevinhwang91/nvim-ufo",
        dependencies = { "kevinhwang91/promise-async" },
      },
      {
        "folke/lazydev.nvim",
        ft = "lua",
        cmd = "LazyDev",
        dependencies = { "Bilal2453/luvit-meta", lazy = true },
        opts = {
          library = {
            -- { path = "luvit-meta/library", words = { "vim%.uv" } },
            { path = "${3rd}/luv/library", words = { "vim%.uv" } },
            { path = "avim", words = { "avim" } },
            { path = "lazy.nvim", words = { "avim" } },
            { path = "snacks.nvim", words = { "Snacks" } },
            -- You can also add plugins you always want to have loaded.
            -- Useful if the plugin has globals or types you want to use
            -- vim.env.LAZY .. "/LazyVim", -- see below
          },
        },
      },
      { "microsoft/python-type-stubs" },
      {
        "linux-cultist/venv-selector.nvim",
        branch = "regexp",
        cmd = { "VenvSelect", "VenvSelectCached", "VenvSelectCurrent" },
        opts = {
          auto_refresh = true,
        },
      },
      {
        "b0o/schemastore.nvim",
        version = false, -- last release is way too old,
      },
      {
        "rmagatti/goto-preview",
        event = "LspAttach",
        opts = {
          width = 120, -- Width of the floating window
          height = 15, -- Height of the floating window
          border = "rounded", -- { "↖", "─", "┐", "│", "┘", "─", "└", "│" }, -- Border characters of the floating window
          opacity = nil, -- 0-100 opacity level of the floating window where 100 is fully transparent.
          resizing_mappings = false, -- Binds arrow keys to resizing the floating window.
          dismiss_on_move = true, -- Dismiss the floating window when moving the cursor.
          preview_window_title = { enable = true, position = "left" }, -- Whether to set the preview window title as the filename
        },
        keys = {
          {
            "gpd",
            "<cmd>lua require('goto-preview').goto_preview_definition()<CR>",
            desc = "Preview Definition(s)",
            noremap = true,
          },
          {
            "gpi",
            "<cmd>lua require('goto-preview').goto_preview_implementation()<CR>",
            desc = "Preview Implementation(s)",
            noremap = true,
          },
          -- Only set if you have telescope installed
          {
            "gpr",
            "<cmd>lua require('goto-preview').goto_preview_references()<CR>",
            desc = "Preview Reference(s)",
            noremap = true,
          },
        },
      },
      {
        "lewis6991/hover.nvim",
        config = function()
          require("hover").setup({
            init = function()
              -- Require providers
              require("hover.providers.lsp")
              require("hover.providers.diagnostic")
              require("hover.providers.fold_preview")
              require("hover.providers.man")
              require("hover.providers.dictionary")
            end,
            preview_opts = {
              border = "rounded",
            },
            -- Whether the contents of a currently open hover window should be moved
            -- to a :h preview-window when pressing the hover keymap.
            preview_window = true,
            title = true,
            mouse_providers = {
              "LSP",
            },
            mouse_delay = 1000,
          })
        end,
        keys = {
          { "K", "<cmd>lua require('hover').hover()<CR>", desc = "Peek or Hover", remap = true },
          { "gK", "<cmd>lua require('hover').hover_select()<cr>", desc = "[hover.nvim] Select" },
          -- { "K", lsp_utils.peek_or_hover,  desc = "Peek or Hover", remap = true },
          --     utilities.map("n", "gK", require("hover").hover_select, { desc = "[hover.nvim] Select" })
          --     { "<Up>", function()
          --         require("hover").hover_switch("previous")
          --     end, desc = "[hover.nvim] Previous Source" },
          --     {
          --         "<Down>",
          --         function()
          --             require("hover").hover_switch("next")
          --         end,
          --         desc = "[hover.nvim] Next Source"
          --     },
          --     {
          --         "<C-p>",
          --         function()
          --             require("hover").hover_switch("previous")
          --         end,
          --         desc = "[hover.nvim] Previous Source"
          --     },
          --     {
          --         "<C-n>",
          --         function()
          --             require("hover").hover_switch("next")
          --         end,
          --         desc = "[hover.nvim] Next Source"
          --     },

          --     -- Mouse support
          --     { "<MouseMove>", require("hover").hover_mouse, desc = "[hover.nvim] Mouse" },
          --     -- vim.o.mousemoveevent = true
        },
      },
      {
        "VidocqH/lsp-lens.nvim",
        event = "BufReadPost",
        config = function()
          local SymbolKind = vim.lsp.protocol.SymbolKind
          require("lsp-lens").setup({
            enable = true,
            include_declaration = true, -- Reference include declaration
            sections = { -- Enable / Disable specific request, formatter example looks 'Format Requests'
              definition = function(count)
                return "D: " .. count
              end,
              references = function(count)
                return "R: " .. count
              end,
              implements = function(count)
                return "I: " .. count
              end,
              git_authors = false,
            },
            target_symbol_kinds = {
              SymbolKind.Function,
              SymbolKind.Method,
              SymbolKind.Interface,
              SymbolKind.Class,
              SymbolKind.Struct,
            },
          })
        end,
      },
    },
    config = function()
      local fn = vim.fn
      local api = vim.api
      local lsp = vim.lsp

      local signs = { Error = " ", Warn = " ", Hint = " ", Info = " " }

      for type, icon in pairs(signs) do
        local hl = "DiagnosticSign" .. type
        fn.sign_define(hl, { text = icon, texthl = hl, numhl = hl })
      end

      local on_attach = function(client, bufnr)
        local function buf_set_option(...)
          api.nvim_buf_set_option(bufnr, ...)
        end
        if client.server_capabilities.completionProvider then
          buf_set_option("omnifunc", "v:lua.vim.lsp.omnifunc")
        end
        if client.server_capabilities.definitionProvider then
          buf_set_option("tagfunc", "v:lua.vim.lsp.tagfunc")
        end
        if client.server_capabilities.codeLensProvider then
          local lens, _ = pcall(api.nvim_get_autocmds, { group = "LspCodelens" })
          if not lens then
            api.nvim_create_augroup("LspCodelens", { clear = true })
          end
          api.nvim_create_autocmd({ "BufEnter", "InsertLeave" }, {
            group = "LspCodelens",
            desc = "Auto show code lenses",
            pattern = "<buffer>",
            command = "silent! lua vim.lsp.codelens.refresh()",
          })
        end
        if client.server_capabilities.documentHighlightProvider then
          api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
            buffer = bufnr,
            -- command = "lua vim.lsp.buf.document_highlight()",
            callback = lsp.buf.document_highlight,
            -- group = vim.g.colors_name ~= "oxocarbon" and "LspHighlight" or nil,
            -- group = "lsp_document_highlight",
            desc = "Document Highlight",
          })
          api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
            buffer = bufnr,
            -- command = "lua vim.lsp.buf.clear_references()",
            callback = lsp.buf.clear_references,
            -- group = vim.g.colors_name ~= "oxocarbon" and "LspHighlight" or nil,
            -- group = "lsp_document_highlight",
            desc = "Clear All the References",
          })
        end
        -- Fix startup error by modifying/disabling semantic tokens for omnisharp
        --[[ if require("lspconfig").util.root_pattern("deno.json", "deno.jsonc")(vim.fn.getcwd()) then
                    if client.name == "vtsls" or client.name == "volar" then
                        client.stop()
                    end
                end ]]
        if lsp_utils.is_enabled("denols") and lsp_utils.is_enabled("vtsls") then
          local is_deno = require("lspconfig.util").root_pattern("deno.json", "deno.jsonc")
          lsp_utils.disable("vtsls", is_deno)
          lsp_utils.disable("denols", function(root_dir, config)
            if not is_deno(root_dir) then
              config.settings.deno.enable = false
            end
            return false
          end)
        end
        -------------------------------------------------------------------------------
        --- Keymaps
        -------------------------------------------------------------------------------
        local fts = {
          "typescript",
          "javascript",
          "javascriptreact",
          "typescriptreact",
          "vue",
        }
        utilities.map("n", "<leader>l", "<cmd>LspInfo<cr>", { desc = "Lsp Info" })
        if lsp_utils.has(bufnr, "signatureHelp") then
          utilities.map("i", "<c-k>", lsp.buf.signature_help, { desc = "Signature Help" })
          utilities.map("n", "gk", "<cmd>lua vim.lsp.buf.signature_help()<CR>", { desc = "Signature Help" })
        end
        utilities.map("n", "<leader>D", "<cmd>lua vim.lsp.buf.type_definition()<CR>", { desc = "Type Definitions" })
        utilities.map("n", "<leader>ra", "<cmd>lua vim.lsp.buf.rename()<CR>", { desc = "Rename" })
        if lsp_utils.has(bufnr, "codeAction") then
          utilities.map(
            { "n", "v" },
            "<leader>ca",
            "<cmd>lua require('actions-preview').code_actions()<CR>",
            { desc = "Code Actions" }
          )
          -- utilities.map({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, { desc = "Code Action" })
        end
        utilities.map("n", "ge", "<cmd>lua vim.diagnostic.open_float()<CR>", { desc = "Floating Diagnostics" })
        utilities.map("n", "gF", "<cmd>Telescope diagnostics<CR>", { desc = "Telescope Diagnostics" })
        utilities.map("n", "[d", "<cmd>lua vim.diagnostic.goto_prev()<CR>", { desc = "Previous Diagnostics" })
        utilities.map("n", "]d", "<cmd>lua vim.diagnostic.goto_next()<CR>", { desc = "Next Diagnostics" })
        utilities.map(
          "n",
          "<leader>cf",
          "<cmd>lua vim.lsp.buf.format({ timeout_ms = 3000 })<CR>",
          { desc = "Format Document" }
        )
        if lsp_utils.has(bufnr, "codeLens") then
          utilities.map({ "n", "v" }, "<leader>cc", "<cmd>lua vim.lsp.codelens.run()<CR>", { desc = "Run Codelens" })
        end
        if lsp_utils.is_enabled("elixirls") then
          utilities.map("n", "<leader>cp", function()
            local params = lsp.util.make_position_params()
            lsp_utils.execute({
              command = "manipulatePipes:serverid",
              arguments = { "toPipe", params.textDocument.uri, params.position.line, params.position.character },
            })
          end, { desc = "To Pipe" })
          utilities.map("n", "<leader>cP", function()
            local params = lsp.util.make_position_params()
            lsp_utils.execute({
              command = "manipulatePipes:serverid",
              arguments = { "fromPipe", params.textDocument.uri, params.position.line, params.position.character },
            })
          end, { desc = "From Pipe" })
        end
        if vim.tbl_contains(fts, vim.bo.filetype) then
          utilities.map("n", "gD", function()
            local params = lsp.util.make_position_params()
            lsp_utils.execute({
              command = "typescript.goToSourceDefinition",
              arguments = { params.textDocument.uri, params.position },
              open = true,
            })
          end, { desc = "Goto Source Definition" })
          utilities.map("n", "gR", function()
            lsp_utils.execute({
              command = "typescript.findAllFileReferences",
              arguments = { vim.uri_from_bufnr(0) },
              open = true,
            })
          end, { desc = "File References" })
          --if lsp_utils.is_enabled("ruff") or lsp_utils.is_enabled("svelte") then
          utilities.map("n", "<leader>co", lsp_utils.action["source.organizeImports"], { desc = "Organize Imports" })
          --end
          utilities.map(
            "n",
            "<leader>cM",
            lsp_utils.action["source.addMissingImports.ts"],
            { desc = "Add missing imports" }
          )
          utilities.map(
            "n",
            "<leader>cu",
            lsp_utils.action["source.removeUnused.ts"],
            { desc = "Remove unused imports" }
          )
          utilities.map("n", "<leader>cD", lsp_utils.action["source.fixAll.ts"], { desc = "Fix all diagnostics" })
          utilities.map("n", "<leader>cV", function()
            lsp_utils.execute({ command = "typescript.selectTypeScriptVersion" })
          end, { desc = "Select TS workspace version" })
        end
        utilities.map("n", "g", nil, { name = "goto" })
        if lsp_utils.has(bufnr, "definition") then
          utilities.map("n", "gd", lsp.buf.definition, { desc = "Goto Definition" })
        end
        utilities.map("n", "gr", lsp.buf.references, { desc = "References", nowait = true })
        utilities.map("n", "gi", lsp.buf.implementation, { desc = "Goto Implementation" })
        utilities.map("n", "gy", lsp.buf.type_definition, { desc = "Goto T[y]pe Definition" })
        utilities.map("n", "gD", lsp.buf.declaration, { desc = "Goto Declaration" })
        if lsp_utils.has(bufnr, "rename") then
          utilities.map("n", "<leader>cr", lsp.buf.rename, { desc = "Rename" })
        end
        ---
        utilities.map("n", "gp", nil, { name = "󰍉 Peek" })
        utilities.map(
          "n",
          "gpd",
          "<cmd>lua require('avim.utilities.peek').Peek('definition')<CR>",
          { desc = "[Peek] Definition(s)" }
        )
        utilities.map(
          "n",
          "<leader>gpt",
          "<cmd>lua require('avim.utilities.peek').Peek('typeDefinition')<CR>",
          { desc = "[Peek] Type Definition(s)" }
        )
        utilities.map(
          "n",
          "<leader>gpI",
          "<cmd>lua require('avim.utilities.peek').Peek('implementation')<CR>",
          { desc = "[Peek] Implementation(s)" }
        )
        -------------------------------------------------------------------------------
      end

      -- Lsp Handlers
      lsp.handlers["textDocument/hover"] = function(_, result, ctx, config)
        if not (result and result.contents) then
          return
        end
        config = config or {}
        config.border = "rounded"
        lsp.handlers.hover(_, result, ctx, config)
        -- lsp.handlers["textDocument/hover"](_, result, ctx, config)
      end
      lsp.handlers["textDocument/signatureHelp"] = lsp.with(lsp.handlers.signature_help, {
        border = "rounded", -- "single",
      })
      lsp.handlers["textDocument/publishDiagnostics"] = function(err, result, ctx, config)
        local ts_lsp = { "deno", "vtsls", "volar", "svelte", "astro" }
        local clients = lsp.get_clients({ id = ctx.client_id })
        if vim.tbl_contains(ts_lsp, clients[1].name) then
          local filtered_result = {
            diagnostics = vim.tbl_filter(function(d)
              return d.severity == 1
            end, result.diagnostics),
          }
          require("ts-error-translator").translate_diagnostics(err, filtered_result, ctx, config)
        end
        -- local filtered = api.filter_diagnostics({
        --       80006, -- This may be converted to an async function...
        --       80001, -- File is a CommonJS module; it may be converted to an ES module...
        --     })(err, result, ctx, config)
        vim.lsp.diagnostic.on_publish_diagnostics(err, result, ctx, config)
      end

      local capabilities = vim.tbl_deep_extend("force", {}, lsp.protocol.make_client_capabilities())
      local fileOps, file_operations = pcall(require, "lsp-file-operations")
      if fileOps then
        capabilities = vim.tbl_deep_extend("force", {}, capabilities, file_operations.default_capabilities())
      end
      local status_ok, cmp_nvim_lsp = pcall(require, "cmp_nvim_lsp")
      if status_ok then
        capabilities = vim.tbl_deep_extend("force", {}, capabilities, cmp_nvim_lsp.default_capabilities())
      end
      capabilities.workspace.didChangeWatchedFiles.dynamicRegistration = true
      capabilities.workspace.didChangeWorkspaceFolders = {
        dynamicRegistration = true,
      }
      -- capabilities.textDocument.foldingRange = {
      --   dynamicRegistration = false,
      --   lineFoldingOnly = true,
      -- }
      capabilities.textDocument.completion.completionItem = {
        documentationFormat = { "markdown", "plaintext" },
        snippetSupport = true,
        preselectSupport = true,
        insertReplaceSupport = true,
        labelDetailsSupport = true,
        deprecatedSupport = true,
        commitCharactersSupport = true,
        tagSupport = { valueSet = { 1 } },
        resolveSupport = {
          properties = {
            "documentation",
            "detail",
            "additionalTextEdits",
          },
        },
      }

      local mason_lsp = require("mason-lspconfig")

      local lspconfig = require("lspconfig")

      require("flutter-tools").setup({
        widget_guides = {
          enabled = true,
        },
        dev_log = {
          enabled = true,
          notify_errors = true, -- if there is an error whilst running then notify the user
        },
        dev_tools = {
          autostart = true, -- autostart devtools server if not detected
        },
        lsp = {
          color = { -- show the derived colours for dart variables
            enabled = true, -- whether or not to highlight color variables at all, only supported on flutter >= 2.10
            background = false, -- highlight the background
            background_color = nil, -- required, when background is transparent (i.e. background_color = { r = 19, g = 17, b = 24},)
            foreground = true, -- highlight the foreground
            virtual_text = false, -- show the highlight using virtual text
            virtual_text_str = "■", -- the virtual text character to highlight
          },
          on_attach = on_attach,
          capabilities = capabilities, -- e.g. lsp_status capabilities
          --- OR you can specify a function to deactivate or change or control how the config is created
          -- capabilities = function(config)
          -- 	config.specificThingIDontWant = false
          -- 	return config
          -- end,
          -- see the link below for details on each option:
          -- https://github.com/dart-lang/sdk/blob/master/pkg/analysis_server/tool/lsp_spec/README.md#client-workspace-configuration
          settings = {
            showTodos = true,
            completeFunctionCalls = true,
            -- analysisExcludedFolders = { "<path-to-flutter-sdk-packages>" },
            renameFilesWithClasses = "prompt", -- "always"
            enableSnippets = true,
          },
        },
        decorations = {
          statusline = {
            -- set to true to be able use the 'flutter_tools_decorations.app_version' in your statusline
            -- this will show the current version of the flutter app from the pubspec.yaml file
            app_version = true,
            -- set to true to be able use the 'flutter_tools_decorations.device' in your statusline
            -- this will show the currently running device if an application was started with a specific
            -- device
            device = true,
          },
        },
        -- debugger = {
        --   enabled = defaults.features.dap,
        --   run_via_dap = defaults.features.dap,
        -- },
      })
      require("telescope").load_extension("flutter")

      -- See `:h mason-lspconfig.setup_handlers()`
      -- @param handlers table<string, fun(server_name: string)>
      mason_lsp.setup_handlers({
        function(servr)
          lspconfig[servr].setup({
            on_attach = on_attach,
            capabilities = capabilities,
          })
        end,
        ["basedpyright"] = function()
          lspconfig.basedpyright.setup({
            on_attach = on_attach,
            capabilities = capabilities,
            settings = {
              basedpyright = {
                disableOrganizeImports = true,
                typeCheckingMode = "standard",
              },
              pyright = {
                -- Using Ruff's import organizer
                disableOrganizeImports = true,
                typeCheckingMode = "standard",
              },
              python = {
                analysis = {
                  -- Ignore all files for analysis to exclusively use Ruff for linting
                  ignore = { "*" },
                },
              },
            },
          })
        end,
        ["elixirls"] = function()
          lspconfig.elixirls.setup({
            cmd = { _G.get_runtime_dir() .. "/mason/packages/elixir-ls/language_server.sh" },
            on_attach = on_attach,
            capabilities = capabilities,
            filetypes = { "elixir", "eelixir", "heex", "surface", "exs" },
          })
        end,
        ["emmet_language_server"] = function()
          lspconfig.emmet_language_server.setup({
            on_attach = on_attach,
            capabilities = capabilities,
            -- Read more about this options in the [vscode docs](https://code.visualstudio.com/docs/editor/emmet#_emmet-configuration).
            -- **Note:** only the options listed in the table are supported.
            init_options = {
              --- @type string[]
              showAbbreviationSuggestions = true,
              --- @type "always" | "never" Defaults to `"always"`
              showExpandedAbbreviation = "always",
              --- @type boolean Defaults to `false`
              showSuggestionsAsSnippets = true,
            },
            filetypes = {
              "html",
              "css",
              "scss",
              "htmldjango",
              "sass",
              "javascriptreact",
              "typescriptreact",
              "vue",
              "svelte",
              "astro",
            },
          })
        end,
        -- eslint
        ["eslint"] = function()
          lspconfig.eslint.setup({
            settings = {
              workingDirectories = { mode = "auto" },
              -- packageManager = "yarn",
              experimental = {
                useFlatConfig = true,
              },
              useFlatConfig = true,
            },
            -- on_attach = function(client, bufnr)
            -- 	if client.server_capabilities.documentFormattingProvider then
            -- 		vim.api.nvim_create_autocmd("BufWritePre", {
            -- 			buffer = bufnr,
            -- 			command = "EslintFixAll",
            -- 		})
            -- 	end
            -- end,
            on_attach = on_attach,
            capabilities = capabilities,
          })
        end,
        ["gopls"] = function()
          lspconfig.gopls.setup({
            on_attach = function(client, bufnr)
              if not client.server_capabilities.semanticTokensProvider then
                local semantic = client.config.capabilities.textDocument.semanticTokens
                client.server_capabilities.semanticTokensProvider = {
                  full = true,
                  legend = {
                    tokenTypes = semantic.tokenTypes,
                    tokenModifiers = semantic.tokenModifiers,
                  },
                  range = true,
                }
              end
              on_attach(client, bufnr)
            end,
            capabilities = capabilities,
            settings = {
              gopls = {
                -- gofumpt = true,
                semanticTokens = true,
                completeUnimported = true,
                usePlaceholders = true,
                staticcheck = true,
                analyses = {
                  fieldalignment = true,
                  nilness = true,
                  unusedparams = true,
                  unusedwrite = true,
                  useany = true,
                },
                codelenses = {
                  gc_details = false,
                  generate = true,
                  regenerate_cgo = true,
                  run_govulncheck = true,
                  test = true,
                  tidy = true,
                  upgrade_dependency = true,
                  vendor = true,
                },
                hints = {
                  assignVariableTypes = true,
                  compositeLiteralFields = true,
                  compositeLiteralTypes = true,
                  constantValues = true,
                  functionTypeParameters = true,
                  parameterNames = true,
                  rangeVariableTypes = true,
                },
              },
            },
          })
        end,
        ["jsonls"] = function()
          lspconfig.jsonls.setup({
            on_attach = function(client, bufnr)
              client.server_capabilities.documentFormattingProvider = false
              client.server_capabilities.documentRangeFormattingProvider = false
              on_attach(client, bufnr)
            end,
            capabilities = capabilities,
            settings = {
              json = {
                schemas = require("schemastore").json.schemas(),
                format = {
                  enable = true,
                },
                validate = { enable = true },
              },
            },
          })
        end,
        ["lua_ls"] = function()
          lspconfig.lua_ls.setup({
            on_attach = on_attach,
            capabilities = capabilities,
            settings = {
              Lua = {
                workspace = {
                  checkThirdParty = false,
                },
                codeLens = {
                  enable = true,
                },
                completion = {
                  callSnippet = "Replace",
                },
                doc = {
                  privateName = { "^_" },
                },
                hint = {
                  enable = true,
                  setType = false,
                  paramType = true,
                  paramName = "Disable",
                  semicolon = "Disable",
                  arrayIndex = "Disable",
                },
              },
            },
          })
        end,
        ["ruff"] = function()
          lspconfig.ruff.setup({
            on_attach = function(client, bufnr)
              -- Disable hover in favor of Pyright
              client.server_capabilities.hoverProvider = false
              on_attach(client, bufnr)
            end,
            capabilities = capabilities,
          })
          -- 		before_init = function(_, config)
          -- 			config.settings.python.analysis.stubPath = path.concat({
          -- 				_G.get_runtime_dir(),
          -- 				"lazy",
          -- 				"python-type-stubs",
          -- 			})
          -- 		end,
        end,
        ["tailwindcss"] = function()
          capabilities.textDocument.colorProvider = { dynamicRegistration = false }
          lspconfig.tailwindcss.setup({
            capabilities = capabilities,
            on_attach = on_attach,
            settings = {
              tailwindCSS = {
                emmetCompletions = true,
                includeLanguages = {
                  elixir = "html-eex",
                  eelixir = "html-eex",
                  heex = "html-eex",
                },
                -- root_dir = function(fname)
                --   local util = require "lspconfig.util"
                --   return util.root_pattern("tailwind.config.js", "tailwind.config.cjs", "tailwind.js", "tailwind.cjs")(fname)
                -- end,
              },
            },
          })
        end,
        ["vtsls"] = function()
          lspconfig.vtsls.setup({
            capabilities = capabilities,
            on_attach = function(client, bufnr)
              client.server_capabilities.documentFormattingProvider = false
              client.server_capabilities.documentRangeFormattingProvider = false
              lsp_utils.move_to_file_refactor(client, bufnr)
              on_attach(client, bufnr)
            end,
            filetypes = {
              "typescript",
              "javascript",
              "javascriptreact",
              "typescriptreact",
              "javascript.jsx",
              "typescript.tsx",
              "vue",
            },
            settings = {
              complete_function_calls = true,
              vtsls = {
                tsserver = {
                  globalPlugins = {
                    {
                      name = "@vue/typescript-plugin",
                      location = lsp_utils.get_pkg_path("vue-language-server", "/node_modules/@vue/language-server"),
                      languages = { "vue" },
                      configNamespace = "typescript",
                      enableForWorkspaceTypeScriptVersions = true,
                    },
                    {
                      name = "typescript-svelte-plugin",
                      location = lsp_utils.get_pkg_path(
                        "svelte-language-server",
                        "/node_modules/typescript-svelte-plugin"
                      ),
                      enableForWorkspaceTypeScriptVersions = true,
                    },
                  },
                },
                enableMoveToFileCodeAction = true,
                autoUseWorkspaceTsdk = true,
                experimental = {
                  maxInlayHintLength = 30,
                  completion = {
                    enableServerSideFuzzyMatch = true,
                  },
                },
              },
              javascript = {
                updateImportsOnFileMove = { enabled = "always" },
                suggest = {
                  completeFunctionCalls = true,
                },
                inlayHints = {
                  enumMemberValues = { enabled = true },
                  functionLikeReturnTypes = { enabled = true },
                  parameterNames = { enabled = "literals" },
                  parameterTypes = { enabled = true },
                  propertyDeclarationTypes = { enabled = true },
                  variableTypes = { enabled = false },
                },
              },
              typescript = {
                tsserver = {
                  pluginPaths = {
                    -- "@vue/typescript-plugin",
                    lsp_utils.get_pkg_path("vue-language-server", "node_modules/@vue/language-server"),
                    lsp_utils.get_pkg_path("svelte-language-server", "/node_modules/typescript-svelte-plugin"),
                  },
                },
                updateImportsOnFileMove = { enabled = "always" },
                suggest = {
                  completeFunctionCalls = true,
                },
                inlayHints = {
                  parameterNames = { enabled = "literals" },
                  parameterTypes = { enabled = true },
                  variableTypes = { enabled = true },
                  propertyDeclarationTypes = { enabled = true },
                  functionLikeReturnTypes = { enabled = true },
                  enumMemberValues = { enabled = true },
                },
                format = {
                  indentSize = vim.o.shiftwidth,
                  convertTabsToSpaces = vim.o.expandtab,
                  tabSize = vim.o.tabstop,
                },
              },
            },
          })
          -- end
        end,
        ["volar"] = function()
          lspconfig.volar.setup({
            on_attach = function(client, bufnr)
              client.server_capabilities.documentFormattingProvider = false
              client.server_capabilities.documentRangeFormattingProvider = false
              on_attach(client, bufnr)
            end,
            capabilities = capabilities,
            filetypes = { "vue" },
            -- filetypes = has_vue and { "typescript", "javascript", "javascriptreact", "typescriptreact", "vue", "json" } or { "vue" },
            init_options = {
              vue = {
                hybridMode = true,
              },
              -- typescript = {
              --   tsdk = vim.fn.getcwd() .. "/node_modules/typescript/lib",
              -- },
              documentFeatures = {
                documentColor = true,
              },
              languageFeatures = {
                semanticTokens = true,
              },
            },
            settings = {
              completeFunctionCalls = true,
            },
          })
        end,
      })

      local ftMap = {
        vim = "indent",
        vue = { "treesitter", "indent" },
      }
      require("ufo").setup({
        provider_selector = function(bufnr, filetype, buftype)
          return ftMap[filetype] or { "lsp", "indent" } -- 'lsp' | 'treesitter' | 'indent'
        end,
        fold_virt_text_handler = require("avim.utilities").fold_handler,
      })
      require("avim.utilities.lsp").setup()

      -- This setup() function is exactly the same as lspconfig's setup function (:help lspconfig-quickstart)
      vim.cmd([[ do User LspAttachBuffers ]])
    end,
  },
}

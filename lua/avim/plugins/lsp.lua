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
            backend = { "snacks", "nui", "telescope" },
            diff = {
              algorithm = "patience",
              ignore_whitespace = true,
            },
            highlight_command = {
              hl.delta("delta --side-by-side"),
            },
          }
        end,
      },
      {
        "kosayoda/nvim-lightbulb",
        opts = { autocmd = { enabled = true } },
      },
      {
        "nvim-flutter/flutter-tools.nvim",
        dependencies = {
          "nvim-lua/plenary.nvim",
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
          require("gopher").install_deps()
        end,
        init = function()
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
        "mason-org/mason.nvim",
        cmd = { "Mason", "MasonInstall", "MasonUninstall", "MasonUpdate", "MasonLog" },
        build = ":MasonUpdate",
        opts = {
          registries = {
            "github:mason-org/mason-registry",
            "github:Crashdummyy/mason-registry",
          },
        },
        keys = {
          { "<leader>pm", "<cmd>Mason<CR>", mode = { "n", "v" }, desc = "Mason" },
        },
      },
      {
        "mason-org/mason-lspconfig.nvim",
        opts = { ensure_installed = defaults.servers },
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
            integrations = {
              ["mason-nvim-dap"] = false,
            },
          })
        end,
      },
      { "Issafalcon/lsp-overloads.nvim" },
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
              border = "shadow",
            },
            transparency = 70,
            hint_prefix = " ",
            max_height = 22,
            max_width = 120,
            floating_window_off_x = 5,
            floating_window_off_y = function()
              local pumheight = vim.o.pumheight
              local winline = vim.fn.winline()
              local winheight = vim.fn.winheight(0)

              if winline - 1 < pumheight then
                return pumheight
              end

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
        opts = {
          library = {
            { path = "${3rd}/luv/library", words = { "vim%.uv" } },
            vim.env.VIMRUNTIME,
          },
        },
      },
      { "microsoft/python-type-stubs" },
      {
        "linux-cultist/venv-selector.nvim",
        ft = "python",
        cmd = { "VenvSelect", "VenvSelectCached" },
        opts = {
          options = {
            notify_user_on_venv_activation = true,
            picker = "snacks",
          },
        },
      },
      {
        "b0o/schemastore.nvim",
        version = false,
      },
      {
        "rmagatti/goto-preview",
        dependencies = { "rmagatti/logger.nvim" },
        event = "BufEnter",
        opts = {
          width = 120,
          height = 15,
          border = "rounded",
          opacity = nil,
          resizing_mappings = false,
          dismiss_on_move = true,
          preview_window_title = { enable = true, position = "left" },
          references = {
            provider = "snacks",
          },
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
          require("hover").config({
            providers = {
              "hover.providers.lsp",
              "hover.providers.diagnostic",
              "hover.providers.fold_preview",
              "hover.providers.man",
              "hover.providers.dictionary",
            },
            preview_opts = {
              border = "rounded",
            },
            preview_window = true,
            title = true,
            mouse_providers = {
              "hover.providers.lsp",
            },
            mouse_delay = 1000,
          })
        end,
        keys = {
          { "K", "<cmd>lua require('hover').hover()<CR>", desc = "Peek or Hover", remap = true },
          { "gK", "<cmd>lua require('hover').enter()<cr>", desc = "[hover.nvim] Enter" },
        },
      },
      {
        "VidocqH/lsp-lens.nvim",
        event = "BufReadPost",
        config = function()
          local SymbolKind = vim.lsp.protocol.SymbolKind
          require("lsp-lens").setup({
            enable = true,
            include_declaration = true,
            sections = {
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
      local api = vim.api
      local lsp = vim.lsp

      ---On attach callback for LSP servers
      ---@param client table LSP client
      ---@param bufnr number Buffer number
      local function on_attach(client, bufnr)
        -- Set buffer options
        if client.server_capabilities.completionProvider then
          vim.bo[bufnr].omnifunc = "v:lua.vim.lsp.omnifunc"
        end
        if client.server_capabilities.definitionProvider then
          vim.bo[bufnr].tagfunc = "v:lua.vim.lsp.tagfunc"
        end

        -- Setup code lens
        if client.server_capabilities.codeLensProvider then
          local lens_group = pcall(api.nvim_get_autocmds, { group = "LspCodelens" })
          if not lens_group then
            api.nvim_create_augroup("LspCodelens", { clear = true })
          end
          api.nvim_create_autocmd({ "BufEnter", "InsertLeave" }, {
            group = "LspCodelens",
            desc = "Auto show code lenses",
            buffer = bufnr,
            callback = function()
              vim.lsp.codelens.refresh({ bufnr = bufnr })
            end,
          })
        end

        -- Setup document highlight
        if client.server_capabilities.documentHighlightProvider then
          api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
            buffer = bufnr,
            callback = lsp.buf.document_highlight,
            desc = "Document Highlight",
          })
          api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
            buffer = bufnr,
            callback = lsp.buf.clear_references,
            desc = "Clear All the References",
          })
        end

        -- Setup signature help overloads
        if client.server_capabilities.signatureHelpProvider then
          require("lsp-overloads").setup(client, {
            ui = { border = "rounded" },
            keymaps = {
              next_signature = "<C-j>",
              previous_signature = "<C-k>",
              next_parameter = "<C-l>",
              previous_parameter = "<C-h>",
              close_signature = "<C-e>",
            },
          })
          vim.keymap.set({ "i", "n" }, "<A-s>", ":LspOverloadsSignature<CR>", {
            buffer = bufnr,
            noremap = true,
            silent = true,
            desc = "LSP Overloads Signature",
          })
        end

        -- Handle deno vs vtsls conflict
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

        -- Setup keymaps
        require("avim.plugins.lsp.keymaps").setup(client, bufnr)
      end

      -- Setup handlers
      require("avim.plugins.lsp.handlers").setup()

      -- Setup capabilities
      local capabilities = vim.tbl_deep_extend("force", {}, lsp.protocol.make_client_capabilities())

      -- Add file operations support
      local fileOps, file_operations = pcall(require, "lsp-file-operations")
      if fileOps then
        capabilities = vim.tbl_deep_extend("force", capabilities, file_operations.default_capabilities())
      end

      -- Add cmp_nvim_lsp support if available (backward compat)
      local status_ok, cmp_nvim_lsp = pcall(require, "cmp_nvim_lsp")
      if status_ok then
        capabilities = vim.tbl_deep_extend("force", capabilities, cmp_nvim_lsp.default_capabilities())
      end

      -- Add blink.cmp capabilities
      capabilities = require("blink.cmp").get_lsp_capabilities(capabilities)

      -- Enhanced capabilities
      capabilities.workspace.didChangeWatchedFiles.dynamicRegistration = true
      capabilities.workspace.didChangeWorkspaceFolders = {
        dynamicRegistration = true,
      }
      capabilities.textDocument.foldingRange = {
        dynamicRegistration = false,
        lineFoldingOnly = true,
      }
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

      -- Setup Flutter tools separately (special handling required)
      require("flutter-tools").setup({
        ui = {
          notification_style = "plugin",
        },
        widget_guides = {
          enabled = true,
        },
        dev_log = {
          enabled = true,
          notify_errors = true,
        },
        dev_tools = {
          autostart = true,
        },
        lsp = {
          color = {
            enabled = true,
            background = false,
            background_color = nil,
            foreground = true,
            virtual_text = false,
            virtual_text_str = "■",
          },
          on_attach = on_attach,
          capabilities = capabilities,
          settings = {
            showTodos = true,
            completeFunctionCalls = true,
            renameFilesWithClasses = "prompt",
            enableSnippets = true,
          },
        },
        decorations = {
          statusline = {
            app_version = true,
            device = true,
          },
        },
      })

      -- Common setup options
      local setup_opts = {
        on_attach = on_attach,
        capabilities = capabilities,
      }

      -- Check if using new vim.lsp.config API (Neovim 0.10+)
      if vim.lsp.config then
        -- Use new API
        vim.lsp.config("*", setup_opts)

        -- Setup specialized servers
        local roslyn_config = require("avim.plugins.lsp.servers.roslyn").setup(setup_opts)
        vim.lsp.config("roslyn", roslyn_config)

        local vue_config = require("avim.plugins.lsp.servers.vue").setup(setup_opts)
        vim.lsp.config("vue_ls", vue_config)

        local vtsls_config = require("avim.plugins.lsp.servers.vtsls").setup(setup_opts)
        vim.lsp.config("vtsls", vtsls_config)

        -- Setup common servers
        local common_servers = require("avim.plugins.lsp.servers.common")
        local common_server_names = {
          "basedpyright",
          "ruff",
          "elixirls",
          "emmet_language_server",
          "eslint",
          "gopls",
          "jsonls",
          "lua_ls",
          "tailwindcss",
        }

        for _, server_name in ipairs(common_server_names) do
          local config = common_servers.get_config(server_name, setup_opts)
          if config then
            vim.lsp.config(server_name, config)
          end
        end
      else
        -- Fallback for older Neovim versions
        local roslyn_config = require("avim.plugins.lsp.servers.roslyn").setup(setup_opts)
        require("roslyn").setup({
          cmd = roslyn_config.cmd,
          config = {
            handlers = roslyn_config.handlers,
            filetypes = roslyn_config.filetypes,
            root_markers = roslyn_config.root_markers,
            settings = roslyn_config.settings,
          },
        })

        lspconfig.vue_ls.setup(require("avim.plugins.lsp.servers.vue").setup(setup_opts))
        lspconfig.vtsls.setup(require("avim.plugins.lsp.servers.vtsls").setup(setup_opts))

        -- Setup common servers
        local common_servers = require("avim.plugins.lsp.servers.common")
        local common_server_names = {
          "basedpyright",
          "ruff",
          "elixirls",
          "emmet_language_server",
          "eslint",
          "gopls",
          "jsonls",
          "lua_ls",
          "tailwindcss",
        }

        for _, server_name in ipairs(common_server_names) do
          local config = common_servers.get_config(server_name, setup_opts)
          if config then
            lspconfig[server_name].setup(config)
          end
        end
      end

      -- Setup mason-lspconfig
      mason_lsp.setup()

      -- Setup UFO for folding with optimized configuration
      local ftMap = {
        vim = "indent",
        vue = { "treesitter", "indent" },
        python = { "indent" },
        git = "",
      }

      require("ufo").setup({
        open_fold_hl_timeout = 150,
        close_fold_kinds_for_ft = {
          default = { "imports", "comment" },
          json = { "array" },
          c = { "comment", "region" },
        },
        provider_selector = function(bufnr, filetype, buftype)
          return ftMap[filetype] or { "lsp", "indent" }
        end,
        fold_virt_text_handler = require("avim.utilities").fold_handler,
      })

      -- Prevent UFO from closing all folds on buffer enter
      vim.api.nvim_create_autocmd("BufReadPost", {
        group = vim.api.nvim_create_augroup("ufo_preserve_folds", { clear = true }),
        callback = function(event)
          -- Set fold level to a high value to keep folds open by default
          vim.schedule(function()
            if vim.bo[event.buf].filetype ~= "" and vim.bo[event.buf].buftype == "" then
              pcall(function()
                require("ufo").openAllFolds()
              end)
            end
          end)
        end,
      })

      -- Setup LSP utilities
      require("avim.utilities.lsp").setup()

      -- Trigger LspAttachBuffers event
      vim.cmd([[ do User LspAttachBuffers ]])
    end,
  },
}

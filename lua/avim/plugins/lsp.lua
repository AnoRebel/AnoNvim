local M = {
	"neovim/nvim-lspconfig",
	event = "BufReadPre",
	branch = "master",
	dependencies = {
		{
			"aznhe21/actions-preview.nvim",
			opts = {
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
			},
		},
		{
			"akinsho/flutter-tools.nvim",
			dependencies = { "nvim-lua/plenary.nvim" },
		},
		{
			"olexsmir/gopher.nvim",
			enabled = true,
			ft = "go",
			build = ":GoInstallDeps",
			init = function()
				-- require("gopher.dap").setup()
				-- quick_type
				vim.api.nvim_create_user_command(
					"GoQuickType",
					'lua require("avim.utils.quicktype").quick_type(<count>, <f-args>)',
					{
						nargs = "*",
						complete = "file",
					}
				)
			end,
			dependencies = {
				"nvim-lua/plenary.nvim",
				"nvim-treesitter/nvim-treesitter",
			},
			config = true,
		},
		{
			"williamboman/mason.nvim",
			build = ":MasonUpdate", -- :MasonUpdate updates registry contents
			config = function()
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
			end,
		},
		{ "williamboman/mason-lspconfig.nvim" },
		{
			"WhoIsSethDaniel/mason-tool-installer.nvim",
			config = function()
				require("mason-tool-installer").setup({
					ensure_installed = require("avim.core.defaults").packages,
					-- Default: false
					auto_update = false,
					-- Use `:MasonToolsUpdate` to install and/or update. Default: true
					run_on_start = true,
					-- Default: 0
					start_delay = 3000, -- 3 second delay
				})
			end,
		},
		{ "ray-x/lsp_signature.nvim" },
		{
			"lvimuser/lsp-inlayhints.nvim",
			branch = "main", -- "anticonceal"
			config = true,
		},
		{
			"kevinhwang91/nvim-ufo",
			dependencies = { "kevinhwang91/promise-async" },
		},
		{ "folke/neodev.nvim" },
		{ "Hoffs/omnisharp-extended-lsp.nvim", enabled = false },
		{ "microsoft/python-type-stubs" },
		{
			"b0o/schemastore.nvim",
			version = false, -- last release is way too old,
		},
	},
}

local fn = vim.fn
local api = vim.api
local lsp = vim.lsp

function M.config()
	-- require("avim.utils.pylance")

	local sign_opts = {
		bind = true,
		transparency = 70,
		-- fix_pos = function(signatures, lspclient)
		--  if signatures[1].activeParameter >= 0 and #signatures[1].parameters == 1 then
		--    return false
		--  end
		--  if lspclient.name == 'lua_ls' then
		--    return true
		--  end
		--  return false
		-- end,
		hint_prefix = " ",
		max_height = 22,
		max_width = 120, -- max_width of signature floating_window, line will be wrapped if exceed max_width
	}
	require("lsp_signature").setup(sign_opts)

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
			local lens, _ = pcall(vim.api.nvim_get_autocmds, { group = "LspCodelens" })
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
		if client.server_capabilities.documentSymbolProvider then
			require("nvim-navic").attach(client, bufnr)
		end
		if client.server_capabilities.documentHighlightProvider then
			api.nvim_create_autocmd("CursorHold", {
				buffer = bufnr,
				command = "lua vim.lsp.buf.document_highlight()",
				group = "LspHighlight",
			})
			api.nvim_create_autocmd("CursorMoved", {
				buffer = bufnr,
				command = "lua vim.lsp.buf.clear_references()",
				group = "LspHighlight",
			})
		end
		-- Fix startup error by modifying/disabling semantic tokens for omnisharp
		if client.name == "omnisharp" then
			local function toSnakeCase(str)
				return string.gsub(str, "%s*[- ]%s*", "_")
			end
			local tokenModifiers = client.server_capabilities.semanticTokensProvider.legend.tokenModifiers
			for i, v in ipairs(tokenModifiers) do
				tokenModifiers[i] = toSnakeCase(v)
			end
			local tokenTypes = client.server_capabilities.semanticTokensProvider.legend.tokenTypes
			for i, v in ipairs(tokenTypes) do
				tokenTypes[i] = toSnakeCase(v)
			end
		end
		if require("lspconfig").util.root_pattern("deno.json", "deno.jsonc")(vim.fn.getcwd()) then
			if client.name == "tsserver" or client.name == "volar" then
				client.stop()
			end
		end
	end

	-- Handlers???
	lsp.handlers["textDocument/hover"] = lsp.with(lsp.handlers.hover, {
		border = "none", -- "single",
	})
	lsp.handlers["textDocument/signatureHelp"] = lsp.with(lsp.handlers.signature_help, {
		border = "none", -- "single",
	})

	-- Enable update on insert
	-- lsp.handlers["textDocument/publishDiagnostics"] = lsp.with(
	--   lsp.diagnostic.on_publish_diagnostics,
	--   {
	--     underline = true,
	--     virtual_text = {
	--       spacing = 5,
	--       severity_limit = 'Warning',
	--     },
	--     update_in_insert = true,
	--   }
	-- )

	-- Diagnostic config
	vim.diagnostic.config({
		virtual_text = {
			prefix = "",
		},
		float = {
			focusable = true,
			source = "always",
			border = "rounded",
			style = "minimal",
			format = function(diagnostic)
				local code = diagnostic.code or (diagnostic.user_data and diagnostic.user_data.lsp.code)
				if not diagnostic.source then
					return string.format("%s [%s]", diagnostic.message, code)
				end

				if diagnostic.source == "eslint_d" then
					return string.format("%s [%s]", diagnostic.message, diagnostic.user_data.lsp.code)
				end

				if diagnostic.source == "eslint" then
					return string.format("%s [%s]", diagnostic.message, diagnostic.user_data.lsp.code)
				end

				return string.format("%s [%s]", diagnostic.message, diagnostic.source)
			end,
		},
		severity_sort = true,
		signs = true,
		underline = true,
		update_in_insert = false,
	})

	local handlers = {
		["textDocument/hover"] = lsp.with(lsp.handlers.hover, { border = "rounded" }),
		["textDocument/signatureHelp"] = lsp.with(lsp.handlers.signature_help, { border = "rounded" }),
	}

	local capabilities = lsp.protocol.make_client_capabilities()
	local status_ok, cmp_nvim_lsp = pcall(require, "cmp_nvim_lsp")
	if status_ok then
		capabilities = cmp_nvim_lsp.default_capabilities(capabilities)
	end
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
	-- local path = require("mason-core.path")
	mason_lsp.setup({
		ensure_installed = require("avim.core.defaults").servers,
		automatic_installation = false,
	})

	local lspconfig = require("lspconfig")
	require("flutter-tools").setup({
		widget_guides = {
			enabled = true,
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
			handlers = handlers,
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
		debugger = {
			enabled = true,
			run_via_dap = false,
			register_configurations = function(_)
				local dap = require("dap")
				dap.configurations.dart = {
					{
						type = "dart",
						request = "launch",
						flutterMode = "debug", -- "profile",
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
				require("dap.ext.vscode").load_launchjs()
				-- require("dap.ext.vscode").load_launchjs(vim.lsp.buf.list_workspace_folders()[1] .. "/.vscode/launch.json")
			end,
		},
	})
	local has_vue = require("avim.utils").is_npm_package_installed("vue")
		or require("avim.utils").is_npm_package_installed("nuxt")
	--
	-- See `:h mason-lspconfig.setup_handlers()`
	-- @param handlers table<string, fun(server_name: string)>
	mason_lsp.setup_handlers({
		function(servr)
			lspconfig[servr].setup({
				on_attach = on_attach,
				capabilities = capabilities,
				handlers = handlers,
			})
		end,
		["elixirls"] = function()
			lspconfig.elixirls.setup({
				cmd = { _G.get_runtime_dir() .. "/mason/packages/elixir-ls/language_server.sh" },
				on_attach = on_attach,
				capabilities = capabilities,
				handlers = handlers,
				filetypes = { "elixir", "eelixir", "heex", "surface", "exs" },
			})
		end,
		["emmet_ls"] = function()
			lspconfig.emmet_ls.setup({
				on_attach = on_attach,
				capabilities = capabilities,
				handlers = handlers,
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
		["emmet_language_server"] = function()
			lspconfig.emmet_language_server.setup({
				on_attach = on_attach,
				capabilities = capabilities,
				handlers = handlers,
				filetypes = { "html", "css", "scss", "javascriptreact", "typescriptreact", "vue", "svelte", "astro" },
			})
		end,
		-- eslint
		["eslint"] = function()
			lspconfig.eslint.setup({
				settings = {
					packageManager = "yarn",
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
				handlers = handlers,
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
				handlers = handlers,
				settings = {
					gopls = {
						semanticTokens = true,
						completeUnimported = true,
						usePlaceholders = true,
						analyses = {
							unusedparams = true,
							unusedvariable = true,
							nilness = true,
							-- shadow = true,
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
				handlers = handlers,
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
		-- python
		-- ["pylance"] = function()
		-- 	lspconfig.pylance.setup({
		-- 		capabilities = capabilities,
		-- 		on_init = function(client)
		-- 			client.config.settings.python.pythonPath = (function(workspace)
		-- 				if vim.env.VIRTUAL_ENV then
		-- 					return path.join(vim.env.VIRTUAL_ENV, "bin", "python")
		-- 				end
		-- 				if vim.fn.filereadable(path.concat({ workspace, "Pipfile.lock" })) then
		-- 					local venv = vim.fn.trim(vim.fn.system("pipenv --venv"))
		-- 					return path.concat({ venv, "bin", "python" })
		-- 				end
		-- 				if vim.fn.filereadable(path.concat({ workspace, "poetry.lock" })) then
		-- 					local venv = vim.fn.trim(vim.fn.system("poetry env info -p"))
		-- 					return path.concat({ venv, "bin", "python" })
		-- 				end
		-- 				return vim.fn.exepath("python3") or vim.fn.exepath("python") or "python"
		-- 			end)(client.config.root_dir)
		-- 		end,
		-- 		before_init = function(_, config)
		-- 			config.settings.python.analysis.stubPath = path.concat({
		-- 				_G.get_runtime_dir(),
		-- 				"lazy",
		-- 				"python-type-stubs",
		-- 			})
		-- 		end,
		-- 	})
		-- end,
		["lua_ls"] = function()
			require("neodev").setup()
			lspconfig.lua_ls.setup({
				on_attach = on_attach,
				capabilities = capabilities,
				handlers = handlers,
				settings = {
					Lua = {
						hint = {
							enable = true,
						},
						diagnostics = {
							enable = true,
							globals = { "vim", "use", "bit", "avim" },
						},
						workspace = {
							library = {
								[fn.expand("$VIMRUNTIME/lua")] = true,
								[fn.expand("$VIMRUNTIME/lua/vim/lsp")] = true,
							},
							maxPreload = 100000,
							preloadFileSize = 10000,
						},
					},
				},
			})
		end,
		["omnisharp"] = function()
			handlers["textDocument/definition"] = require("omnisharp_extended").handler
			lspconfig.omnisharp.setup({
				cmd = { "dotnet", _G.get_runtime_dir() .. "/mason/packages/omnisharp/libexec/OmniSharp.dll" },
				on_attach = on_attach,
				handlers = handlers,
				capabilities = capabilities,
				enable_editorconfig_support = true,
				sdk_include_prereleases = true,
				flags = {
					debounce_text_changes = 150,
				},
			})
		end,
		["sourcery"] = function()
			lspconfig.sourcery.setup({
				on_attach = on_attach,
				capabilities = capabilities,
				handlers = handlers,
				init_options = {
					--- The Sourcery token for authenticating the user.
					--- This is retrieved from the Sourcery website and must be
					--- provided by each user. The extension must provide a
					--- configuration option for the user to provide this value.
					-- token = nil, -- Either add here or will be checked if `sourcery login` is done

					--- The extension's name and version as defined by the extension.
					extension_version = "vim.lsp",

					--- The editor's name and version as defined by the editor.
					editor_version = "avim",
				},
			})
		end,
		["tailwindcss"] = function()
			capabilities.textDocument.colorProvider = { dynamicRegistration = false }
			lspconfig.tailwindcss.setup({
				handlers = handlers,
				capabilities = capabilities,
				on_attach = function(client, bufnr)
					if client.server_capabilities.colorProvider then
						require("avim.utils.documentcolors").buf_attach(bufnr)
					end
				end,
				settings = {
					tailwindCSS = {
						emmetCompletions = true,
						-- root_dir = function(fname)
						--   local util = require "lspconfig.util"
						--   return util.root_pattern("tailwind.config.js", "tailwind.config.cjs", "tailwind.js", "tailwind.cjs")(fname)
						-- end,
					},
				},
			})
		end,
		["tsserver"] = function()
			if not has_vue then
				lspconfig.tsserver.setup({
					capabilities = capabilities,
					on_attach = function(client, bufnr)
						client.server_capabilities.documentFormattingProvider = false
						client.server_capabilities.documentRangeFormattingProvider = false
						on_attach(client, bufnr)
					end,
					handlers = handlers,
					settings = {
						typescript = {
							inlayHints = {
								includeInlayParameterNameHints = "all", -- 'none' | 'literals' | 'all';
								includeInlayParameterNameHintsWhenArgumentMatchesName = false,
								includeInlayFunctionParameterTypeHints = true,
								includeInlayVariableTypeHints = true, -- false
								includeInlayVariableTypeHintsWhenTypeMatchesName = false,
								includeInlayPropertyDeclarationTypeHints = true,
								includeInlayFunctionLikeReturnTypeHints = true,
								includeInlayEnumMemberValueHints = true,
							},
							format = {
								indentSize = vim.o.shiftwidth,
								convertTabsToSpaces = vim.o.expandtab,
								tabSize = vim.o.tabstop,
							},
						},
						javascript = {
							inlayHints = {
								includeInlayParameterNameHints = "all", -- 'none' | 'literals' | 'all';
								includeInlayParameterNameHintsWhenArgumentMatchesName = false,
								includeInlayFunctionParameterTypeHints = true,
								includeInlayVariableTypeHints = true, -- false
								includeInlayVariableTypeHintsWhenTypeMatchesName = false,
								includeInlayPropertyDeclarationTypeHints = true,
								includeInlayFunctionLikeReturnTypeHints = true,
								includeInlayEnumMemberValueHints = true,
							},
							format = {
								indentSize = vim.o.shiftwidth,
								convertTabsToSpaces = vim.o.expandtab,
								tabSize = vim.o.tabstop,
							},
						},
						completions = {
							completeFunctionCalls = true,
						},
					},
				})
			end
		end,
		["volar"] = function()
			lspconfig.volar.setup({
				on_attach = function(client, bufnr)
					client.server_capabilities.documentFormattingProvider = false
					client.server_capabilities.documentRangeFormattingProvider = false
					on_attach(client, bufnr)
				end,
				capabilities = capabilities,
				handlers = handlers,
				-- filetypes = { "vue" },
				filetypes = has_vue
						and { "typescript", "javascript", "javascriptreact", "typescriptreact", "vue", "json" }
					or { "vue" },
				documentFeatures = {
					documentColor = true,
				},
				languageFeatures = {
					semanticTokens = true,
				},
				init_options = {
					documentFeatures = {
						documentColor = true,
					},
					languageFeatures = {
						semanticTokens = true,
					},
				},
				settings = {
					typescript = {
						inlayHints = {
							includeInlayParameterNameHints = "all", -- 'none' | 'literals' | 'all';
							includeInlayParameterNameHintsWhenArgumentMatchesName = false,
							includeInlayFunctionParameterTypeHints = true,
							includeInlayVariableTypeHints = true, -- false
							includeInlayVariableTypeHintsWhenTypeMatchesName = false,
							includeInlayPropertyDeclarationTypeHints = true,
							includeInlayFunctionLikeReturnTypeHints = true,
							includeInlayEnumMemberValueHints = true,
						},
						format = {
							indentSize = vim.o.shiftwidth,
							convertTabsToSpaces = vim.o.expandtab,
							tabSize = vim.o.tabstop,
						},
					},
					javascript = {
						inlayHints = {
							includeInlayParameterNameHints = "all", -- 'none' | 'literals' | 'all';
							includeInlayParameterNameHintsWhenArgumentMatchesName = false,
							includeInlayFunctionParameterTypeHints = true,
							includeInlayVariableTypeHints = true, -- false
							includeInlayVariableTypeHintsWhenTypeMatchesName = false,
							includeInlayPropertyDeclarationTypeHints = true,
							includeInlayFunctionLikeReturnTypeHints = true,
							includeInlayEnumMemberValueHints = true,
						},
						format = {
							indentSize = vim.o.shiftwidth,
							convertTabsToSpaces = vim.o.expandtab,
							tabSize = vim.o.tabstop,
						},
					},
					completions = {
						completeFunctionCalls = true,
					},
				},
			})
		end,
	})

	require("ufo").setup({ fold_virt_text_handler = require("avim.utils").fold_handler })
	require("telescope").load_extension("flutter")

	-- This setup() function is exactly the same as lspconfig's setup function (:help lspconfig-quickstart)
	vim.cmd([[ do User LspAttachBuffers ]])
end

return M

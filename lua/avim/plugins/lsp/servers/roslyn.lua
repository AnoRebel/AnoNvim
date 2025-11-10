---@class avim.lsp.servers.roslyn
---@field setup fun(opts: table): table
local M = {}

local utilities = require("avim.utilities")

---Get Roslyn server configuration
---@param opts table
---@return table
function M.setup(opts)
  local on_attach = opts.on_attach
  local capabilities = opts.capabilities

  return {
    cmd = {
      "roslyn",
      "--stdio",
      "--logLevel=Information",
      "--extensionLogDirectory=" .. vim.fs.dirname(vim.lsp.get_log_path()),
      "--razorSourceGenerator=" .. vim.fs.joinpath(
        utilities.lsp.get_pkg_path("rzls", "libexec"),
        "Microsoft.CodeAnalysis.Razor.Compiler.dll"
      ),
      "--razorDesignTimePath=" .. vim.fs.joinpath(
        utilities.lsp.get_pkg_path("rzls", "libexec"),
        "Targets",
        "Microsoft.NET.Sdk.Razor.DesignTime.targets"
      ),
      "--extension",
      vim.fs.joinpath(
        utilities.lsp.get_pkg_path("rzls", "libexec"),
        "RazorExtension",
        "Microsoft.VisualStudioCode.RazorExtension.dll"
      ),
    },
    handlers = require("rzls.roslyn_handlers"),
    on_attach = on_attach,
    capabilities = capabilities,
    filetypes = { "cs", "razor" },
    root_markers = { ".sln", ".csproj", ".fsproj" },
    settings = {
      -- Memory optimized settings
      ["csharp|background_analysis"] = {
        dotnet_analyzer_diagnostics_scope = "openFiles", -- Changed from fullSolution for memory
        dotnet_compiler_diagnostics_scope = "openFiles", -- Changed from fullSolution for memory
      },
      ["csharp|completion"] = {
        dotnet_provide_regex_completions = false,
        dotnet_show_completion_items_from_unimported_namespaces = true,
        dotnet_show_name_completion_suggestions = false,
      },
      ["csharp|inlay_hints"] = {
        -- Minimal inlay hints for performance
        csharp_enable_inlay_hints_for_implicit_object_creation = false,
        csharp_enable_inlay_hints_for_implicit_variable_types = false, -- Disabled for memory
        csharp_enable_inlay_hints_for_lambda_parameter_types = false,
        csharp_enable_inlay_hints_for_types = false,
        dotnet_enable_inlay_hints_for_indexer_parameters = false,
        dotnet_enable_inlay_hints_for_literal_parameters = false, -- Disabled for memory
        dotnet_enable_inlay_hints_for_object_creation_parameters = false,
        dotnet_enable_inlay_hints_for_other_parameters = false,
        dotnet_enable_inlay_hints_for_parameters = false,
        dotnet_suppress_inlay_hints_for_parameters_that_differ_only_by_suffix = false,
        dotnet_suppress_inlay_hints_for_parameters_that_match_argument_name = false,
        dotnet_suppress_inlay_hints_for_parameters_that_match_method_intent = false,
      },
      ["csharp|code_lens"] = {
        dotnet_enable_references_code_lens = false, -- Disabled for memory
      },
    },
  }
end

return M

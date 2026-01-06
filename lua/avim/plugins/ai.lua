-- Ensure buffer is treated as markdown by treesitter despite being codecompanion filetype
vim.treesitter.language.register("markdown", "codecompanion")

return {
  {
    "olimorris/codecompanion.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
      "ravitemer/mcphub.nvim",
      "ravitemer/codecompanion-history.nvim",
      {
        "nvim-mini/mini.diff",
        config = function()
          local diff = require("mini.diff")
          diff.setup({
            -- Disabled by default
            source = diff.gen_source.none(),
          })
        end,
      },
      {
        "HakonHarnes/img-clip.nvim",
        opts = {
          filetypes = {
            codecompanion = {
              prompt_for_file_name = false,
              template = "[Image]($FILE_PATH)",
              use_absolute_path = true,
            },
          },
        },
      },
    },
    cmd = { "CodeCompanion", "CodeCompanionCmd", "CodeCompanionChat", "CodeCompanionActions" },
    opts = {
      -- ACP Adapters (Agent Client Protocol) for coding agents
      adapters = {
        acp = {
          opts = {
            show_presets = false,
          },
          -- Claude Code - via OAuth or API key
          claude_code = function()
            return require("codecompanion.adapters").extend("claude_code", {
              env = {
                -- Uses CLAUDE_CODE_OAUTH_TOKEN or ANTHROPIC_API_KEY from environment
                CLAUDE_CODE_OAUTH_TOKEN = "cmd:cat " .. _G.get_config_dir() .. "/claude.key",
                -- ANTHROPIC_API_KEY = "cmd:cat " .. _G.get_config_dir() .. "/anthropic.key",
              },
            })
          end,
          -- Gemini CLI - via OAuth or API key
          gemini_cli = function()
            return require("codecompanion.adapters").extend("gemini_cli", {
              defaults = {
                auth_method = "gemini-api-key", -- or "oauth-personal", "vertex-ai"
              },
              env = {
                GEMINI_API_KEY = "cmd:cat " .. _G.get_config_dir() .. "/google.key",
              },
            })
          end,
          -- Codex (OpenAI) - via API key or ChatGPT auth
          codex = function()
            return require("codecompanion.adapters").extend("codex", {
              defaults = {
                auth_method = "chatgpt", -- or "codex-api-key", "openai-api-key"
              },
              env = {
                OPENAI_API_KEY = "cmd:cat " .. _G.get_config_dir() .. "/openai.key",
              },
            })
          end,
          -- OpenCode - configure default model in ~/.config/opencode/config.json
          opencode = function()
            return require("codecompanion.adapters").extend("opencode", {})
          end,
        },
        -- HTTP Adapters for traditional API access
        http = {
          opts = {
            show_presets = false,
          },
          gemini = function()
            return require("codecompanion.adapters").extend("gemini", {
              env = {
                api_key = "cmd:cat " .. _G.get_config_dir() .. "/google.key",
              },
              schema = {
                model = {
                  default = "gemini-3-pro-preview",
                },
              },
            })
          end,
          ollama = function()
            return require("codecompanion.adapters").extend("ollama", {
              env = {
                url = "https://ollama.anorebel.net",
                -- url = "http://82.208.23.25:11434",
                -- api_key = "OLLAMA_API_KEY",
              },
              --[[ headers = {
          ["Content-Type"] = "application/json",
          ["Authorization"] = "Bearer ${api_key}",
        }, ]]
              parameters = {
                sync = true,
              },
            })
          end,
        },
      },
      -- Interactions (formerly "strategies" in v17)
      interactions = {
        chat = {
          adapter = "claude_code",
          roles = {
            ---@type string|fun(adapter: CodeCompanion.Adapter): string
            llm = function(adapter)
              return adapter.formatted_name
            end,
            user = "AnoNvim",
          },
          opts = {
            -- System prompt for chat interactions
            system_prompt = [[You are a highly skilled AI programming assistant integrated into AnoNvim.
You help write, review, and debug code with precision and clarity.
When providing code, be concise and explain your reasoning.
Follow best practices and the user's coding style when apparent.]],
          },
          slash_commands = {
            ["git_files"] = {
              description = "List git files",
              ---@param chat CodeCompanion.Chat
              callback = function(chat)
                local handle = io.popen("git ls-files")
                if handle ~= nil then
                  local result = handle:read("*a")
                  handle:close()
                  chat:add_reference({ content = result }, "git", "<git_files>")
                else
                  return vim.notify("No git files available", vim.log.levels.INFO, { title = "CodeCompanion" })
                end
              end,
              opts = {
                contains_code = false,
              },
            },
          },
        },
        inline = {
          adapter = "claude_code",
        },
        cmd = {
          adapter = "opencode",
        },
      },
      -- Rules for persistent context (replaces workspaces)
      rules = {
        default = {
          description = "Common rule files for all projects",
          files = {
            ".clinerules",
            ".cursorrules",
            ".goosehints",
            ".rules",
            "CLAUDE.md",
            "CLAUDE.local.md",
            "~/.claude/CLAUDE.md",
          },
          is_preset = true,
        },
        opts = {
          chat = {
            enabled = true,
            autoload = "default",
          },
        },
      },
      -- Display settings
      display = {
        diff = {
          provider = "mini_diff",
        },
        action_palette = {
          opts = {
            show_preset_actions = true,
          },
        },
        chat = {
          floating_window = {
            border = "rounded",
          },
        },
      },
      -- Prompt Library - load from markdown files for clarity
      prompt_library = {
        -- Show preset prompts in action palette
        show_preset_prompts = true,
        -- Load custom prompts from markdown files
        markdown = {
          dirs = {
            -- AnoNvim prompts directory
            vim.fn.stdpath("config") .. "/prompts",
            -- Project-local prompts
            vim.fn.getcwd() .. "/.prompts",
          },
        },
      },
      -- Tools configuration (for HTTP adapters only - ACP adapters have their own)
      tools = {
        opts = {
          require_approval_before = true,
          require_confirmation_after = false,
        },
      },
      -- Extensions
      extensions = {
        history = {
          enabled = true,
          opts = {
            keymap = "gh",
            auto_generate_title = true,
            continue_last_chat = false,
            delete_on_clearing_chat = false,
            picker = "snacks",
            enable_logging = false,
            dir_to_save = _G.get_runtime_dir() .. "/codecompanion-history",
            auto_save = true,
            save_chat_keymap = "sc",
          },
        },
        mcphub = {
          callback = "mcphub.extensions.codecompanion",
          opts = {
            make_vars = true,
            make_slash_commands = true,
            show_result_in_chat = true,
          },
        },
        vectorcode = {
          opts = {
            add_tool = true,
          },
        },
      },
    },
    keys = {
      { "<leader>ai", "<cmd>CodeCompanion<CR>", mode = { "n", "v" }, desc = " CodeCompanion" },
      { "<leader>ac", "<cmd>CodeCompanionChat Toggle<CR>", mode = { "n", "v" }, desc = " CodeCompanion Chat" },
      { "<leader>af", "<cmd>CodeCompanionActions<CR>", mode = { "n", "v" }, desc = " CodeCompanion Actions" },
      { "<leader>ad", "<cmd>CodeCompanionCmd<CR>", mode = { "n", "v" }, desc = " CodeCompanion Command" },
      { "<leader>ah", "<cmd>CodeCompanionHistory<CR>", mode = { "n", "v" }, desc = " CodeCompanion History" },
      { "<leader>ae", "<cmd>MCPHub<CR>", mode = { "n", "v" }, desc = " MCP Hub" },
      -- Quick adapter switching
      { "<leader>aa", "<cmd>CodeCompanionChat adapter=anthropic<CR>", mode = { "n", "v" }, desc = " Chat (Anthropic)" },
      { "<leader>ag", "<cmd>CodeCompanionChat adapter=gemini<CR>", mode = { "n", "v" }, desc = " Chat (Gemini)" },
      { "<leader>ao", "<cmd>CodeCompanionChat adapter=ollama<CR>", mode = { "n", "v" }, desc = " Chat (Ollama)" },
      -- ACP agents
      {
        "<leader>aA",
        "<cmd>CodeCompanionChat adapter=claude_code<CR>",
        mode = { "n", "v" },
        desc = " Chat (Claude Code)",
      },
      {
        "<leader>aG",
        "<cmd>CodeCompanionChat adapter=gemini_cli<CR>",
        mode = { "n", "v" },
        desc = " Chat (Gemini CLI)",
      },
      { "<leader>aX", "<cmd>CodeCompanionChat adapter=codex<CR>", mode = { "n", "v" }, desc = " Chat (Codex)" },
      { "<leader>aO", "<cmd>CodeCompanionChat adapter=opencode<CR>", mode = { "n", "v" }, desc = " Chat (OpenCode)" },
    },
  },
  {
    "ravitemer/codecompanion-history.nvim",
    cmd = { "CodeCompanionHistory" },
  },
  {
    "ravitemer/mcphub.nvim",
    cmd = { "MCPHub" },
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    build = "npm install -g mcp-hub@latest",
    config = function()
      require("mcphub").setup({
        config = _G.get_config_dir() .. "/mcpservers.json",
        auto_toggle_mcp_servers = true,
        shutdown_delay = 0,
        log = {
          level = vim.log.levels.WARN,
          to_file = true,
          file_path = _G.get_state_dir() .. "/mcphub.log",
          prefix = "MCPHub",
        },
      })
    end,
  },
  {
    "Davidyz/VectorCode",
    version = "*",
    dependencies = { "nvim-lua/plenary.nvim" },
    build = "pipx upgrade vectorcode",
    opts = {
      n_query = 1,
      async_opts = {
        notify = true,
      },
    },
    cmd = { "VectorCode" },
  },
}

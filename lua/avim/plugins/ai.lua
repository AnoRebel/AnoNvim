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
        "echasnovski/mini.diff",
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
      adapters = {
        opts = {
          show_defaults = false,
          show_model_choices = true,
        },
        gemini = function()
          return require("codecompanion.adapters").extend("gemini", {
            env = {
              -- model = "gemini-2.0-flash",
              api_key = vim.fn.readfile(_G.get_config_dir() .. "/google.key")[1],
            },
            schema = {
              model = {
                default = "gemini-2.5-pro-exp-03-25",
              },
            },
          })
        end,
        groq = function()
          return require("codecompanion.adapters").extend("openai_compatible", {
            name = "groq",
            formatted_name = "Groq",
            env = {
              url = "https://api.groq.com/openai", -- "/v1"
              api_key = vim.fn.readfile(_G.get_config_dir() .. "/groq.key")[1],
            },
            schema = {
              model = {
                default = "deepseek-r1-distill-llama-70b",
              },
            },
          })
        end,
        openrouter = function()
          return require("codecompanion.adapters").extend("openai_compatible", {
            name = "openrouter",
            formatted_name = "OpenRouter",
            env = {
              url = "https://openrouter.ai/api",
              api_key = vim.fn.readfile(_G.get_config_dir() .. "/openrouter.key")[1],
            },
            schema = {
              model = {
                default = "deepseek-r1-distill-llama-70b",
              },
            },
          })
        end,
        githubmodels = function()
          return require("codecompanion.adapters").extend("githubmodels", {
            formatted_name = "Github Models",
            env = {
              api_key = vim.fn.readfile(_G.get_config_dir() .. "/github.key")[1],
            },
            schema = {
              model = {
                default = "claude-3.5-sonnet", -- "DeepSeek-R1",
              },
            },
          })
        end,
        huggingface = function()
          return require("codecompanion.adapters").extend("huggingface", {
            env = {
              api_key = vim.fn.readfile(_G.get_config_dir() .. "/huggingface.key")[1],
            },
            schema = {
              model = {
                default = "Qwen/Qwen2.5-72B-Instruct",
              },
            },
          })
        end,
      },
      strategies = {
        chat = {
          adapter = "gemini",
          roles = {
            ---@type string|fun(adapter: CodeCompanion.Adapter): string
            llm = function(adapter)
              return adapter.formatted_name
            end,
            user = "AnoNvim",
          },
          slash_commands = {
            --[[ codebase = {
              description = "run VectorCode to retrieve the project context.",
              callback = function()
                return require("vectorcode.integrations").codecompanion.chat.make_slash_command()
              end,
            }, ]]
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
          adapter = "githubmodels",
        },
        agent = { adapter = "groq" },
      },
      display = {
        diff = {
          provider = "mini_diff",
        },
      },
      extensions = {
        history = {
          enabled = true,
          opts = {
            -- Keymap to open history from chat buffer (default: gh)
            keymap = "gh",
            -- Automatically generate titles for new chats
            auto_generate_title = true,
            ---On exiting and entering neovim, loads the last chat on opening chat
            continue_last_chat = false,
            ---When chat is cleared with `gx` delete the chat from history
            delete_on_clearing_chat = false,
            -- Picker interface ("telescope" or "snacks" or "default")
            picker = "snacks",
            ---Enable detailed logging for history extension
            enable_logging = false,
            ---Directory path to save the chats
            dir_to_save = _G.get_runtime_dir() .. "/codecompanion-history",
            -- Save all chats by default
            auto_save = true,
            -- Keymap to save the current chat manually
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
      { "<leader>ai", "<cmd>CodeCompanion<CR>", mode = { "n", "v" }, desc = " CodeCompanion" },
      { "<leader>ac", "<cmd>CodeCompanionChat Toggle<CR>", mode = { "n", "v" }, desc = " CodeCompanion Chat" },
      { "<leader>af", "<cmd>CodeCompanionActions<CR>", mode = { "n", "v" }, desc = " CodeCompanion Actions" },
      { "<leader>ad", "<cmd>CodeCompanionCmd<CR>", mode = { "n", "v" }, desc = " CodeCompanion Command" },
      { "<leader>ah", "<cmd>CodeCompanionHistory<CR>", mode = { "n", "v" }, desc = " CodeCompanion History" },
      { "<leader>ae", "<cmd>MCPHub<CR>", mode = { "n", "v" }, desc = " MCP Hub" },
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
      "nvim-lua/plenary.nvim", -- Required for Job and HTTP requests
    },
    build = "npm install -g mcp-hub@latest", -- Installs required mcp-hub npm module
    config = function()
      require("mcphub").setup({
        -- Required options
        config = _G.get_config_dir() .. "/mcpservers.json",
        auto_toggle_mcp_servers = true, -- Let LLMs start and stop MCP servers automatically

        -- Optional options
        shutdown_delay = 0, -- Wait 0ms before shutting down server after last client exits
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
      n_query = 1, -- 3,
      async_opts = {
        notify = true,
      },
    },
    cmd = { "VectorCode" },
  },
}

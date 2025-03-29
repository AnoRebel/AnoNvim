-- Ensure buffer is treated as markdown by treesitter despite being codecompanion filetype
vim.treesitter.language.register("markdown", "codecompanion")

return {
  {
    "olimorris/codecompanion.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
      -- "ravitemer/mcphub.nvim",
    },
    cmd = { "CodeCompanion", "CodeCompanionCmd", "CodeCompanionChat", "CodeCompanionActions" },
    opts = {
      adapters = {
        opts = {
          show_defaults = false,
        },
        gemini = function()
          return require("codecompanion.adapters").extend("gemini", {
            env = {
              model = "gemini-2.0-flash",
              api_key = vim.fn.readfile(_G.get_config_dir() .. "/google.key")[1],
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
        githubmodels = function()
          return require("codecompanion.adapters").extend("githubmodels", {
            formatted_name = "Github Models",
            env = {
              api_key = vim.fn.readfile(_G.get_config_dir() .. "/github.key")[1],
            },
            schema = {
              model = {
                default = "DeepSeek-R1",
              },
            },
          })
        end,
        huggingface = function()
          return require("codecompanion.adapters").extend("huggingface", {
            env = {
              api_key = vim.fn.readfile(_G.get_config_dir() .. "/huggingface.key")[1],
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
          --[[ tools = {
            ["mcp"] = {
              callback = require("mcphub.extensions.codecompanion"),
              description = "Call tools and resources from the MCP Servers",
              opts = {
                -- user_approval = true,
                requires_approval = true,
              },
            },
          }, ]]
        },
        inline = {
          adapter = "github",
        },
        agent = { adapter = "groq" },
      },
      display = {
        diff = {
          provider = "mini_diff",
        },
      },
    },
    keys = {
      { "<leader>ai", "<cmd>CodeCompanion<CR>", mode = { "n", "v" }, desc = " CodeCompanion" },
      { "<leader>ac", "<cmd>CodeCompanionChat Toggle<CR>", mode = { "n", "v" }, desc = " CodeCompanion Chat" },
      { "<leader>at", "<cmd>Telescope codecompanion<CR>", mode = { "n", "v" }, desc = " CodeCompanion Palette" },
      { "<leader>af", "<cmd>CodeCompanionActions<CR>", mode = { "n", "v" }, desc = " CodeCompanion Actions" },
      { "<leader>ad", "<cmd>CodeCompanionCmd<CR>", mode = { "n", "v" }, desc = " CodeCompanion Command" },
    },
  },
  {
    "ravitemer/mcphub.nvim",
    enabled = false,
    cmd = "MCPHub",
    dependencies = {
      "nvim-lua/plenary.nvim", -- Required for Job and HTTP requests
    },
    build = "npm install -g mcp-hub@latest", -- Installs required mcp-hub npm module
    config = function()
      require("mcphub").setup({
        -- Required options
        port = 3003, -- Port for MCP Hub server
        -- config = vim.fn.expand("~/mcpservers.json"),  -- Absolute path to config file
        config = _G.get_config_dir() .. "/mcpservers.json",

        -- Optional options
        on_ready = function(hub)
          -- Called when hub is ready
        end,
        on_error = function(err)
          -- Called on errors
        end,
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
}

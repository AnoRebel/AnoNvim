-- Ensure buffer is treated as markdown by treesitter despite being codecompanion filetype
vim.treesitter.language.register("markdown", "codecompanion")

return {
  "olimorris/codecompanion.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-treesitter/nvim-treesitter",
  },
  cmd = { "CodeCompanion", "CodeCompanionChat" },
  opts = {
    adapters = {
      gemini = function()
        return require("codecompanion.adapters").extend("gemini", {
          env = {
            model = "gemini-1.5-flash",
            api_key = vim.fn.readfile(_G.get_config_dir() .. "/google.key")[1],
          },
          --[[ schema = {
              model = {
                default = "gemini-1.5-flash",
                choices = {
                  "gemini-2.0-flash",
                  "gemini-2.0-flash-001",
                  "gemini-1.5-flash-8b",
                  "gemini-2.0-flash-lite-preview-02-05",
                },
              },
            }, ]]
        })
      end,
      openai = function()
        return require("codecompanion.adapters").extend("openai_compatible", {
          env = {
            url = "https://api.groq.com/openai", -- "/v1"
            api_key = vim.fn.readfile(_G.get_config_dir() .. "/groq.key")[1],
            model = "deepseek-r1-distill-llama-70b",
          },
          --[[ schema = {
              model = {
                default = "deepseek-r1-distill-llama-70b",
                choices = {
                  "distil-whisper-large-v3-en",
                  "llama-3.3-70b-versatile",
                  "llama-3.1-8b-instant",
                  "gemma2-9b-it",
                },
              },
            }, ]]
        })
      end,
      azure_openai = function()
        return require("codecompanion.adapters").extend("azure_openai", {
          env = {
            endpoint = "https://models.inference.ai.azure.com",
            api_key = vim.fn.readfile(_G.get_config_dir() .. "/github.key")[1],
            model = "DeepSeek-R1",
          },
          --[[ schema = {
              model = {
                default = "gpt-4o",
                choices = {
                  "DeepSeek-R1",
                  "gpt-4o-mini",
                  "Llama-3.3-70B-Instruct",
                },
              },
            }, ]]
        })
      end,
    },
    strategies = {
      chat = {
        adapter = "gemini",
      },
      inline = {
        adapter = "azure_openai",
      },
      agent = { adapter = "openai" },
    },
  },
}

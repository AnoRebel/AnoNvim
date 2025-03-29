local defaults = require("avim.core.defaults")
local utilities = require("avim.utilities")

return {
  "rest-nvim/rest.nvim",
  ft = "http",
  dependencies = {
    {
      "vhyrro/luarocks.nvim",
      priority = 1000, -- Very high priority is required, luarocks.nvim should run as the first plugin in your config.
      opts = {
        rocks = defaults.rocks, -- Specify LuaRocks packages to install
        luarocks_build_args = { "--with-lua=/usr/bin/lua5.1" },
      },
    },
  },
  cmd = { "Rest" },
  config = function(_, opts)
    require("rest-nvim").setup(opts)
    -- Rest API
    utilities.map("n", "<leader>r", nil, { name = " Rest APIs" })
    utilities.map("n", "<leader>rr", "<CMD>Rest run<CR>", { desc = "Run Request Under the Cursor" })
    utilities.map("n", "<leader>rl", "<CMD>Rest run last<CR>", { desc = "Re-run Latest Request" })
  end,
  -- opts = {
  --   client = "curl",
  --   env_file = ".env",
  --   env_pattern = "\\.env$",
  --   env_edit_command = "tabedit",
  --   encode_url = true,
  --   skip_ssl_verification = false,
  --   custom_dynamic_variables = {},
  --   logs = {
  --     level = "info",
  --     save = true,
  --   },
  --   result = {
  --     split = {
  --       horizontal = false,
  --       in_place = false,
  --       stay_in_current_window_after_split = true,
  --     },
  --     behavior = {
  --       decode_url = true,
  --       show_info = {
  --         url = true,
  --         headers = true,
  --         http_info = true,
  --         curl_command = true,
  --       },
  --       statistics = {
  --         enable = true,
  --         ---@see https://curl.se/libcurl/c/curl_easy_getinfo.html
  --         stats = {
  --           { "total_time", title = "Time taken:" },
  --           { "size_download_t", title = "Download size:" },
  --         },
  --       },
  --       formatters = {
  --         json = "jq",
  --         html = function(body)
  --           if vim.fn.executable("tidy") == 0 then
  --             return body, { found = false, name = "tidy" }
  --           end
  --           local fmt_body = vim.fn
  --             .system({
  --               "tidy",
  --               "-i",
  --               "-q",
  --               "--tidy-mark",
  --               "no",
  --               "--show-body-only",
  --               "auto",
  --               "--show-errors",
  --               "0",
  --               "--show-warnings",
  --               "0",
  --               "-",
  --             }, body)
  --             :gsub("\n$", "")
  --
  --           return fmt_body, { found = true, name = "tidy" }
  --         end,
  --       },
  --     },
  --   },
  --   highlight = {
  --     enable = true,
  --     timeout = 750,
  --   },
  --   ---Example:
  --   ---
  --   ---```lua
  --   ---keybinds = {
  --   ---  {
  --   ---    "<localleader>rr", "<cmd>Rest run<cr>", "Run request under the cursor",
  --   ---  },
  --   ---  {
  --   ---    "<localleader>rl", "<cmd>Rest run last<cr>", "Re-run latest request",
  --   ---  },
  --   ---}
  --   ---
  --   ---```
  --   ---@see vim.keymap.set
  --   keybinds = {},
  -- },
}

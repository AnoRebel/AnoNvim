local M = {
  "rest-nvim/rest.nvim",
  ft = "http",
  dependencies = { "vhyrro/luarocks.nvim" },
  cmd = { "RestNvim", "RestNvimPreview", "RestNvimLast" },
  opt = {
    client = "curl",
    env_file = ".env",
    env_pattern = "\\.env$",
    env_edit_command = "tabedit",
    encode_url = true,
    skip_ssl_verification = false,
    custom_dynamic_variables = {},
    logs = {
      level = "info",
      save = true,
    },
    result = {
      split = {
        horizontal = false,
        in_place = false,
        stay_in_current_window_after_split = true,
      },
      behavior = {
        decode_url = true,
        show_info = {
          url = true,
          headers = true,
          http_info = true,
          curl_command = true,
        },
        statistics = {
          enable = true,
          ---@see https://curl.se/libcurl/c/curl_easy_getinfo.html
          stats = {
            { "total_time", title = "Time taken:" },
            { "size_download_t", title = "Download size:" },
          },
        },
        formatters = {
          json = "jq",
          html = function(body)
            if vim.fn.executable("tidy") == 0 then
              return body, { found = false, name = "tidy" }
            end
            local fmt_body = vim.fn
              .system({
                "tidy",
                "-i",
                "-q",
                "--tidy-mark",
                "no",
                "--show-body-only",
                "auto",
                "--show-errors",
                "0",
                "--show-warnings",
                "0",
                "-",
              }, body)
              :gsub("\n$", "")

            return fmt_body, { found = true, name = "tidy" }
          end,
        },
      },
    },
    highlight = {
      enable = true,
      timeout = 750,
    },
    ---Example:
    ---
    ---```lua
    ---keybinds = {
    ---  {
    ---    "<localleader>rr", "<cmd>Rest run<cr>", "Run request under the cursor",
    ---  },
    ---  {
    ---    "<localleader>rl", "<cmd>Rest run last<cr>", "Re-run latest request",
    ---  },
    ---}
    ---
    ---```
    ---@see vim.keymap.set
    keybinds = {},
  },
}

-- function M.config()
-- 	require("rest-nvim").setup({
-- 		-- Open request results in a horizontal split
-- 		result_split_horizontal = false,
-- 		-- Keep the http file buffer above|left when split horizontal|vertical
-- 		result_split_in_place = false,
-- 		-- Skip SSL verification, useful for unknown certificates
-- 		skip_ssl_verification = false,
-- 		-- Encode URL before making request
-- 		encode_url = true,
-- 		-- Highlight request on run
-- 		highlight = {
-- 			enabled = true,
-- 			timeout = 150,
-- 		},
-- 		result = {
-- 			-- toggle showing URL, HTTP info, headers at top the of result window
-- 			show_url = true,
-- 			show_http_info = true,
-- 			show_headers = true,
-- 			-- executables or functions for formatting response body [optional]
-- 			-- set them to nil if you want to disable them
-- 			formatters = {
-- 				json = "jq",
-- 				html = function(body)
-- 					return vim.fn.system({ "tidy", "-i", "-q", "-" }, body)
-- 				end,
-- 			},
-- 		},
-- 		-- Jump to request line on run
-- 		jump_to_request = false,
-- 		env_file = ".env",
-- 		custom_dynamic_variables = {},
-- 		yank_dry_run = true,
-- 	})
-- end

return M

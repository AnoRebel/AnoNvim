local M = {
  "echasnovski/mini.indentscope",
  version = false, -- wait till new 0.7.0 release to put it back on semver
  event = { "BufReadPre", "BufNewFile" },
  config = function()
    require("mini.indentscope").setup({
      draw = {
        -- Animation rule for scope's first drawing. A function which, given
        -- next and total step numbers, returns wait time (in ms). See
        -- |MiniIndentscope.gen_animation| for builtin options. To disable
        -- animation, use `require('mini.indentscope').gen_animation.none()`.
        -- cubic | quartic | exponential
        animation = require("mini.indentscope").gen_animation.quartic({
          easing = "in-out",
          duration = 100,
          unit = "total",
        }),
      },
      -- symbol = "▏",
      -- symbol = "│",
      symbol = "╎",
      options = { try_as_border = true },
    })
  end,
}

function M.init()
  vim.api.nvim_create_autocmd("FileType", {
    pattern = {
      "help",
      "alpha",
      "dashboard",
      "neo-tree",
      "NvimTree",
      "Trouble",
      "lazy",
      "mason",
      "notify",
      "toggleterm",
      "lazyterm",
    },
    callback = function()
      vim.b.miniindentscope_disable = true
    end,
  })
end

return M

return {
  {
    "nvzone/floaterm",
    dependencies = "nvzone/volt",
    opts = {
      border = true,
      size = { h = 80, w = 80 },
      -- Default sets of terminals you'd like to open
      terminals = {
        { name = "Terminal" },
        -- cmd can be function too
        -- { name = "Process", cmd = "btop" },
      },
    },
    cmd = "FloatermToggle",
  },
  {
    "nvzone/typr",
    dependencies = "nvzone/volt",
    opts = {},
    init = function()
      local ok, cmp = pcall(require, "cmp")
      if ok then
        cmp.setup.filetype("typr", {
          enabled = false,
        })
      end
    end,
    cmd = { "Typr", "TyprStats" },
  },
  {
    "nvzone/menu",
    dependencies = "nvzone/volt",
    keys = {
      {
        "<RightMouse>",
        function()
          require("menu.utils").delete_old_menus()

          vim.cmd.exec('"normal! \\<RightMouse>"')

          -- clicked buf
          local buf = vim.api.nvim_win_get_buf(vim.fn.getmousepos().winid)
          local menus = require("avim.utilities.menus")
          local options = vim.bo[buf].ft == "neo-tree" and menus.neo_tree or menus.default

          require("menu").open(options, { mouse = true, border = true })
        end,
        desc = "Open Menu",
        mode = { "n", "v" },
      },
    },
  },
  {
    "nvzone/minty",
    dependencies = "nvzone/volt",
    cmd = { "Shades", "Huefy" },
  },
  { "nvzone/timerly", dependencies = "nvzone/volt", cmd = "TimerlyToggle" },
}

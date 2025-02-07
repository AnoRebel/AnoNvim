return {
  {
    "nvzone/typr",
    dependencies = "nvzone/volt",
    opts = {},
    cmd = { "Typr", "TyprStats" },
  },
  {
    "nvzone/menu",
    enabled = false,
    dependencies = "nvzone/volt",
    opts = {},
    keys = {
      {
        "<RightMouse>",
        function()
          require("menu.utils").delete_old_menus()

          vim.cmd.exec('"normal! \\<RightMouse>"')

          -- clicked buf
          local buf = vim.api.nvim_win_get_buf(vim.fn.getmousepos().winid)
          local options = vim.bo[buf].ft == "NvimTree" and "nvimtree" or "default"

          require("menu").open(options, { mouse = true })
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

local utilities = require("avim.utilities")

-- Search and Replace
utilities.map("n", "<leader>s", nil, { name = "󰛔 Search and Replace" })

return {
  {
    "MagicDuck/grug-far.nvim",
    cmd = "GrugFar",
    opts = {
      headerMaxWidth = 80,
    },
    keys = {
      { "<leader>ss", "<cmd>lua require('grug-far').open()<CR>", desc = "Search and Replace" },
      {
        "<leader>sw",
        "<cmd>lua require('grug-far').open({ prefills = { search = vim.fn.expand('<cword>') } })<CR>",
        { desc = "Search and Replace(Current Word)" },
      },
      {
        "<leader>sv",
        "<cmd>lua require('grug-far').with_visual_selection()<CR>",
        mode = "v",
        { desc = "Search and Replace(Current Word)" },
      },
      {
        "<leader>sp",
        "viw<cmd>lua require('grug-far').open({ prefills = { paths = vim.fn.expand('%') } })<CR>",
        desc = "Search Current Directory",
      },
      {
        "<leader>sh",
        "viw<cmd>lua require('grug-far').open({ transient = true })<CR>",
        desc = "Transient Search",
      },
      {
        "<leader>sr",
        function()
          local grug = require("grug-far")
          local ext = vim.bo.buftype == "" and vim.fn.expand("%:e")
          grug.open({
            transient = true,
            prefills = {
              filesFilter = ext and ext ~= "" and "*." .. ext or nil,
            },
          })
        end,
        mode = { "n", "v" },
        desc = "Search and Replace",
      },
    },
  },
  {
    "AckslD/muren.nvim",
    config = true,
    cmd = {
      "MurenOpen",
      "MurenClose",
      "MurenToggle",
      "MurenFresh",
      "MurenUnique",
    },
    keys = {
      { "<leader>st", "<cmd>MurenToggle<CR>", desc = "[Muren] Toggle" },
      { "<leader>sf", "<cmd>MurenFresh<CR>", desc = "[Muren] Fresh Search" },
      { "<leader>su", "<cmd>MurenUnique<CR>", desc = "[Muren] Unique Search" },
    },
  },
  {
    "ggandor/flit.nvim",
    -- leap moved off GitHub and its old repo was wiped
    dependencies = {
      {
        "andyg/leap.nvim",
        url = "https://codeberg.org/andyg/leap.nvim",
        dependencies = { "tpope/vim-repeat" },
      },
    },
    keys = function()
      local ret = {}
      for _, key in ipairs({ "f", "F", "t", "T" }) do
        ret[#ret + 1] = { key, mode = { "n", "x", "o" }, desc = key }
      end
      return ret
    end,
    opts = {
      labeled_modes = "nx",
      -- flit still passes the removed `case_sensitive` to leap; false stops the warning,
      -- and `go.ignorecase` below keeps f/F/t/T case-sensitive (the old behaviour)
      opts = { case_sensitive = false },
    },
    config = function(_, opts)
      require("leap").opts.vim_opts["go.ignorecase"] = false
      require("flit").setup(opts)
    end,
  },
}

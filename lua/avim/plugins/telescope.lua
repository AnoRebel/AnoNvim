local features = require("avim.core.defaults").features
local utils = require("avim.utils")

return {
  "nvim-telescope/telescope.nvim",
  cmd = "Telescope",
  dependencies = {
    { "nvim-lua/plenary.nvim" },
    { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
    { "xiyaowong/telescope-emoji.nvim" },
  },
  config = function()
    local telescope = require("telescope")
    local actions = require("telescope.actions")
    local state = require("telescope.actions.state")
    local previewers = require("telescope.previewers")
    local sorters = require("telescope.sorters")
    local open_with_trouble = require("trouble.sources.telescope").open
    -- Use this to add more results without clearing the trouble list
    local add_to_trouble = require("trouble.sources.telescope").add
    local options = {
      defaults = {
        mappings = {
          i = { ["<c-t>"] = add_to_trouble },
          n = { ["<c-t>"] = open_with_trouble },
        },
        vimgrep_arguments = {
          "rg",
          -- "--color=never",
          "--no-heading",
          "--with-filename",
          "--line-number",
          "--column",
          "--smart-case",
          "--hidden",
          "--glob=!.git/",
        },
        pickers = {
          find_files = {
            hidden = true,
            find_command = { "fd", "--type=file", "--hidden", "--smart-case" },
            on_input_filter_cb = function(prompt)
              local find_colon = string.find(prompt, ":")
              if find_colon then
                local ret = string.sub(prompt, 1, find_colon - 1)
                vim.schedule(function()
                  local prompt_bufnr = vim.api.nvim_get_current_buf()
                  local picker = state.get_current_picker(prompt_bufnr)
                  local lnum = tonumber(prompt:sub(find_colon + 1))
                  if type(lnum) == "number" then
                    local win = picker.previewer.state.winid
                    local bufnr = picker.previewer.state.bufnr
                    local line_count = vim.api.nvim_buf_line_count(bufnr)
                    vim.api.nvim_win_set_cursor(win, { math.max(1, math.min(lnum, line_count)), 0 })
                  end
                end)
                return { prompt = ret }
              end
            end,
            attach_mappings = function()
              actions.select_default:enhance({
                post = function()
                  -- if we found something, got to line
                  local prompt = state.get_current_line()
                  local find_colon = string.find(prompt, ":")
                  if find_colon then
                    local lnum = tonumber(prompt:sub(find_colon + 1))
                    vim.api.nvim_win_set_cursor(0, { lnum, 0 })
                  end
                end,
              })
              return true
            end,
          },
          live_grep = {
            --@usage don't include the filename in the search results
            only_sort_text = true,
          },
          buffers = {
            initial_mode = "normal",
            mappings = {
              i = {
                ["<C-d>"] = actions.delete_buffer,
              },
              n = {
                ["dd"] = actions.delete_buffer,
              },
            },
          },
          planets = {
            show_pluto = true,
            show_moon = true,
          },
          git_files = {
            hidden = true,
            show_untracked = true,
          },
          colorscheme = {
            enable_preview = true,
          },
        },
        prompt_prefix = " ", -- "   ",
        selection_caret = " ", -- " ",
        entry_prefix = "  ",
        initial_mode = "insert",
        selection_strategy = "reset",
        sorting_strategy = "ascending", -- "descending",
        layout_strategy = "horizontal",
        -- layout_config = {
        --    horizontal = {
        --       prompt_position = "top",
        --       preview_width = 0.55,
        --       results_width = 0.8,
        --    },
        --    vertical = {
        --       mirror = false,
        --    },
        --    width = 0.87,
        --    height = 0.80,
        --    preview_cutoff = 120,
        -- },
        layout_config = {
          width = 0.75,
          preview_cutoff = 120,
          horizontal = {
            prompt_position = "top",
            preview_width = function(_, cols, _)
              if cols < 120 then
                return math.floor(cols * 0.5)
              end
              return math.floor(cols * 0.6)
            end,
            -- mirror = false,
          },
          vertical = { mirror = false },
        },
        file_sorter = sorters.get_fuzzy_file,
        file_ignore_patterns = { "node_modules" },
        generic_sorter = sorters.get_generic_fuzzy_sorter,
        path_display = { "smart" }, -- { shorten = 5 }, | { "truncate" },
        winblend = 0,
        border = {},
        borderchars = { "─", "│", "─", "│", "╭", "╮", "╯", "╰" },
        color_devicons = true,
        use_less = true,
        set_env = { ["COLORTERM"] = "truecolor" }, -- default = nil,
        file_previewer = previewers.vim_buffer_cat.new,
        grep_previewer = previewers.vim_buffer_vimgrep.new,
        qflist_previewer = previewers.vim_buffer_qflist.new,
        -- Developer configurations: Not meant for general override
        buffer_previewer_maker = previewers.buffer_previewer_maker,
      },
      extensions = {
        fzf = {
          fuzzy = true, -- false will only do exact matching
          override_generic_sorter = true, -- override the generic sorter
          override_file_sorter = true, -- override the file sorter
          case_mode = "smart_case", -- or "ignore_case" or "respect_case"
          -- the default case_mode is "smart_case"
        },
        media_files = {
          -- TODO: pip3 install --upgrade ueberzug && aptinstall sxiv ffmpegthumbnailer
          -- git clone https://github.com/sdushantha/fontpreview
          filetypes = { "png", "webp", "jpg", "jpeg", "webm", "mp4", "pdf" },
          find_cmd = "fd", -- | "rg" -- find command (defaults to 'fd')
        },
      },
    }
    telescope.setup(options)
    local extensions = {
      "fzf",
      "persisted",
      "emoji",
      "notify",
      "noice",
      "themes",
      "flutter",
      "refactoring",
    }
    pcall(function()
      for _, ext in ipairs(extensions) do
        telescope.load_extension(ext)
      end
    end)
    -------------------------------------------------------------------------------
    --- Keymaps
    -------------------------------------------------------------------------------
    utils.map({ "n", "v" }, "<leader>f", nil, { name = "󰥩 Finder" })
    utils.map({ "n", "v" }, "<leader>fb", "<cmd>Telescope buffers <CR>", { desc = "Buffer List" })
    utils.map(
      { "n", "v" },
      "<leader>fB",
      "<cmd>Telescope current_buffer_fuzzy_find <CR>",
      { desc = "Fuzzy Buffer List" }
    )
    utils.map({ "n", "v" }, "<leader>ff", "<cmd>Telescope find_files <CR>", { desc = "Find Files" })
    utils.map(
      { "n", "v" },
      "<leader>fa",
      "<cmd>Telescope find_files follow=true no_ignore=true hidden=true <CR>",
      { desc = "All Files" }
    )
    utils.map({ "n", "v" }, "<leader>fC", "<cmd>Telescope git_commits <CR>", { desc = "Git Commits" })
    utils.map({ "n", "v" }, "<leader>fc", "<cmd>Telescope commands <CR>", { desc = "Commands" })
    utils.map({ "n", "v" }, "<leader>fh", "<cmd>Telescope command_history<CR>", { desc = "Command History" })
    -- utils.map({ "n", "v" }, "<leader>ft", "<cmd>Telescope git_status <CR>", { desc = "Git Status" })
    -- utils.map({ "n", "v" }, "<leader>fh", "<cmd>Telescope help_tags <CR>", { desc = "Help Tags" })
    utils.map({ "n", "v" }, "<leader>fw", "<cmd>Telescope live_grep <CR>", { desc = "Live Search" })
    utils.map({ "n", "v" }, "<leader>fo", "<cmd>Telescope oldfiles <CR>", { desc = "Old Files" })
    utils.map({ "n", "v" }, "<leader>fu", "<cmd>lua require('avim.utils.theme_picker')()<CR>", { desc = "Themes" })
    utils.map({ "n", "v" }, "<leader>fk", "<cmd>Telescope keymaps <CR>", { desc = "Key Mappings" })
    utils.map({ "n", "v" }, "<leader>fm", "<cmd>Telescope man_pages <CR>", { desc = "Man Pages" })
    utils.map({ "n", "v" }, "<leader>fr", "<cmd>Telescope resume <CR>", { desc = "Resume" })
    utils.map({ "n", "v" }, "<leader>fD", "<cmd>Telescope lsp_document_symbols <CR>", { desc = "Document Symbols" })

    -- Flutter tools
    -- utils.map("n", "<leader>fd", "<cmd>Telescope flutter commands <CR>", { desc = "Flutter" })
    -- utils.map("n", "<leader>ft", "<cmd>FlutterOutlineToggle<CR>", { desc = "Flutter Toggle Outline" })
    -------------------------------------------------------------------------------
  end,
}

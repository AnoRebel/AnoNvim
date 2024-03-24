return {
  -- Enhance nvim
  { "nathom/filetype.nvim", lazy = false },
  {
    "Tastyep/structlog.nvim",
    lazy = false,
  },
  {
    "vhyrro/luarocks.nvim",
    priority = 1000, -- Very high priority is required, luarocks.nvim should run as the first plugin in your config.
    opts = {
      rocks = { "lua-curl", "nvim-nio", "mimetypes", "xml2lua" }, -- Specify LuaRocks packages to install
    },
  },
  {
    "luukvbaal/stabilize.nvim",
    lazy = false,
    config = function()
      require("stabilize").setup()
    end,
  },
  { "lambdalisue/suda.vim", cmd = { "SudaRead", "SudaWrite" } },
  { "lbrayner/vim-rzip", lazy = false },
  {
    "jbyuki/instant.nvim",
    enabled = false,
    cmd = {
      "InstantStartSingle",
      "InstantStartSession",
      "InstantJoinSingle",
      "InstantJoinSession",
      "InstantStatus",
      "InstantStop",
      "InstantFollow",
      "InstantStopFollow",
      "InstantOpenAll",
      "InstantSaveAll",
    },
  },
  {
    "chipsenkbeil/distant.nvim", -- NOTE: Requires `cargo install distant`
    cmd = { "DistantLaunch", "DistantOpen", "DistantInstall" },
    enabled = false,
    config = function()
      require("distant").setup({
        -- Applies Chip's personal settings to every machine you connect to
        --
        -- 1. Ensures that distant servers terminate with no connections
        -- 2. Provides navigation bindings for remote directories
        -- 3. Provides keybinding to jump into a remote file's parent directory
        ["*"] = require("distant.settings").chip_default(),
      })
    end,
  },
  -- DotEnv
  { "tpope/vim-dotenv" },
  -- UI
  { "MunifTanjim/nui.nvim" },
  { "nvim-lua/plenary.nvim" },
  { "nvim-lua/popup.nvim" },
  { "DanilaMihailov/beacon.nvim", lazy = false },
  { "3rd/image.nvim", opts = { backend = "kitty", integrations = { markdown = { enabled = true } } } },
  {
    "shortcuts/no-neck-pain.nvim",
    cmd = {
      "NoNeckPain",
      "NoNeckPainToggleLeftSide",
      "NoNeckPainToggleRightSide",
      "NoNeckPainResize",
      "NoNeckPainScratchPad",
      "NoNeckPainWidthUp",
      "NoNeckPainWidthDown",
    },
    opts = {
      bufferOptionsColor = {
        blend = -0.2,
      },
      buffers = {
        left = { enabled = true },
        right = { enabled = true },
        colors = {
          background = vim.g.colors_name,
          blend = -0.2,
        },
        scratchPad = {
          enabled = true,
          location = "~/Documents/obsidian/notes/",
          fileName = "scratchpad",
        },
        wo = { fillchars = "eob: " },
        bo = {
          filetype = "md",
        },
      },
      autocmds = {
        -- When `true`, reloads the plugin configuration after a colorscheme change.
        --- @type boolean
        reloadOnColorSchemeChange = true,
      },
      integrations = {
        NvimTree = {
          position = "left",
          reopen = true,
        },
        NeoTree = {
          position = "right",
          reopen = true,
        },
        undotree = {
          position = "right",
        },
        neotest = {
          -- The position of the tree.
          --- @type "right"
          position = "right",
          -- When `true`, if the tree was opened before enabling the plugin, we will reopen it.
          reopen = true,
        },
        NvimDAPUI = {
          -- The position of the tree.
          --- @type "none"
          position = "none",
          -- When `true`, if the tree was opened before enabling the plugin, we will reopen it.
          reopen = true,
        },
      },
    },
  },
  -- LSP
  {
    "folke/lsp-colors.nvim",
    event = "LspAttach",
    config = true,
  },
  {
    "kosayoda/nvim-lightbulb",
    branch = "master",
    event = "LspAttach",
    dependencies = {
      "antoinemadec/FixCursorHold.nvim",
    },
    opts = { autocmd = { enabled = true } },
  },
  -- Tests
  {
    "nvim-neotest/neotest",
    enabled = false,
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
      "antoinemadec/FixCursorHold.nvim",
      -- Adapters
      "nvim-neotest/neotest-python",
      "nvim-neotest/neotest-go",
      "sidlatau/neotest-dart",
      "marilari88/neotest-vitest",
      "haydenmeade/neotest-jest",
      "Issafalcon/neotest-dotnet",
      "jfpedroza/neotest-elixir",
      "MarkEmmons/neotest-deno",
    },
    opts = {
      adapters = {
        -- 		require("neotest-python")({
        -- 			dap = { justMyCode = false },
        -- 		}),
        -- 		require("neotest-go"),
        -- 		require("neotest-vitest"),
        -- 		require("neotest-jest"),
        -- 		require("neotest-dart"),
        -- 		require("neotest-dotnet"),
        -- 		require("neotest-elixir"),
        -- 		require("neotest-deno"),
      },
    },
  },
  -- Git
  {
    "akinsho/git-conflict.nvim",
    cmd = {
      "GitConflictChooseOurs",
      "GitConflictChooseTheirs",
      "GitConflictChooseBoth",
      "GitConflictChooseNone",
      "GitConflictNextConflict",
      "GitConflictPrevConflict",
      "GitConflictListQf",
    },
    config = true,
  },
  { "rhysd/committia.vim", lazy = false },
  {
    "rhysd/git-messenger.vim",
    lazy = true,
    event = { "BufRead" },
  },
  -- Code Helpers
  {
    "stevearc/oil.nvim",
    cmd = { "Oil" },
    opts = {
      win_options = {
        signcolumn = "number",
      },
      columns = {
        "icon",
        -- "permissions",
        "size",
        "mtime",
        -- "atime",
      },
      -- Deleted files will be removed with the trash_command (below).
      delete_to_trash = true,
      -- Skip the confirmation popup for simple operations (:help oil.skip_confirm_for_simple_edits)
      skip_confirm_for_simple_edits = false,
      view_options = {
        -- Show files and directories that start with "."
        show_hidden = false,
      },
      keymaps = {
        ["-"] = false,
        ["g."] = false,
        ["<C-l>"] = false,
        ["<C-p>"] = false,
        ["C"] = "actions.parent",
        ["K"] = "actions.preview",
        ["R"] = "actions.refresh",
        ["<C-q>"] = "actions.close",
        ["H"] = "actions.toggle_hidden",
      },
    },
    -- Optional dependencies
    dependencies = {
      "nvim-tree/nvim-web-devicons",
      {
        "SirZenith/oil-vcs-status",
        config = function()
          local status_const = require("oil-vcs-status.constant.status")
          local StatusType = status_const.StatusType
          require("oil-vcs-status").setup({
            status_symbol = {
              [StatusType.Added] = "",
              [StatusType.Copied] = "󰆏",
              [StatusType.Deleted] = "",
              [StatusType.Ignored] = "",
              [StatusType.Modified] = "",
              [StatusType.Renamed] = "",
              [StatusType.TypeChanged] = "󰉺",
              [StatusType.Unmodified] = " ",
              [StatusType.Unmerged] = "",
              [StatusType.Untracked] = "",
              [StatusType.External] = "",

              [StatusType.UpstreamAdded] = "󰈞",
              [StatusType.UpstreamCopied] = "󰈢",
              [StatusType.UpstreamDeleted] = "",
              [StatusType.UpstreamIgnored] = " ",
              [StatusType.UpstreamModified] = "󰏫",
              [StatusType.UpstreamRenamed] = "",
              [StatusType.UpstreamTypeChanged] = "󱧶",
              [StatusType.UpstreamUnmodified] = " ",
              [StatusType.UpstreamUnmerged] = "",
              [StatusType.UpstreamUntracked] = " ",
              [StatusType.UpstreamExternal] = "",
            },
          })
        end,
      },
    },
  },
  {
    "willothy/flatten.nvim",
    opts = function()
      ---@type Terminal?
      local saved_terminal

      return {
        window = {
          open = "alternate",
        },
        callbacks = {
          should_block = function(argv)
            -- Note that argv contains all the parts of the CLI command, including
            -- Neovim's path, commands, options and files.
            -- See: :help v:argv

            -- In this case, we would block if we find the `-b` flag
            -- This allows you to use `nvim -b file1` instead of
            -- `nvim --cmd 'let g:flatten_wait=1' file1`
            return vim.tbl_contains(argv, "-b")

            -- Alternatively, we can block if we find the diff-mode option
            -- return vim.tbl_contains(argv, "-d")
          end,
          pre_open = function()
            local term = require("toggleterm.terminal")
            local termid = term.get_focused_id()
            saved_terminal = term.get(termid)
          end,
          post_open = function(bufnr, winnr, ft, is_blocking)
            if is_blocking and saved_terminal then
              -- Hide the terminal while it's blocking
              saved_terminal:close()
            else
              -- If it's a normal file, just switch to its window
              vim.api.nvim_set_current_win(winnr)
            end
            -- If the file is a git commit, create one-shot autocmd to delete its buffer on write
            -- If you just want the toggleable terminal integration, ignore this bit
            if ft == "gitcommit" or ft == "gitrebase" then
              vim.api.nvim_create_autocmd("BufWritePost", {
                buffer = bufnr,
                once = true,
                callback = vim.schedule_wrap(function()
                  vim.api.nvim_buf_delete(bufnr, {})
                end),
              })
            end
          end,
          block_end = function()
            -- After blocking ends (for a git commit, etc), reopen the terminal
            vim.schedule(function()
              if saved_terminal then
                saved_terminal:open()
                saved_terminal = nil
              end
            end)
          end,
        },
      }
    end,
    lazy = false,
    priority = 1001,
  },
  {
    "otavioschwanck/arrow.nvim",
    opts = {
      show_icons = true,
      leader_key = ";", -- Recommended to be a single key
      separate_by_branch = true, -- Bookmarks will be separated by git branch
      window = {
        border = "rounded",
      },
    },
  },
  {
    "metakirby5/codi.vim",
    cmd = { "Codi", "CodiNew", "CodiSelect" },
  },
  {
    "toppair/peek.nvim",
    event = { "VeryLazy" },
    build = "deno task --quiet build:fast",
    init = function()
      vim.api.nvim_create_user_command("PeekOpen", require("peek").open, {})
      vim.api.nvim_create_user_command("PeekClose", require("peek").close, {})
      vim.api.nvim_create_user_command("Peek", function()
        local peek = require("peek")
        if peek.is_open() then
          peek.close()
        else
          peek.open()
        end
      end, {})
    end,
    config = true,
  },
  {
    "rmagatti/goto-preview",
    event = "LspAttach",
    config = true,
  },
  {
    "ggandor/leap.nvim",
    dependencies = { "tpope/vim-repeat" },
  },
  {
    "ggandor/flit.nvim",
    dependencies = { "ggandor/leap.nvim" },
    keys = function()
      local ret = {}
      for _, key in ipairs({ "f", "F", "t", "T" }) do
        ret[#ret + 1] = { key, mode = { "n", "x", "o" }, desc = key }
      end
      return ret
    end,
    opts = { labeled_modes = "nx" },
  },
  {
    "nvim-pack/nvim-spectre",
    dependencies = { "nvim-lua/plenary.nvim" },
    cmd = "Spectre",
    opts = { open_cmd = "noswapfile vnew" },
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
  },
  {
    "ThePrimeagen/refactoring.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
    },
    config = true,
  },
  {
    "barrett-ruth/import-cost.nvim",
    enabled = true, -- NOTE: Seems resource intensive
    event = "VeryLazy",
    build = "sh install.sh yarn",
    opts = {
      filetypes = {
        "javascript",
        "javascriptreact",
        "typescript",
        "typescriptreact",
        "vue",
      },
    },
  },
  {
    "kylechui/nvim-surround",
    version = "*", -- Use for stability; omit to use `main` branch for the latest features
    event = "VeryLazy",
    config = true,
  },
  { "tpope/vim-repeat", event = "VeryLazy" },
  { "tpope/vim-abolish", event = "VeryLazy" },
  {
    "mbbill/undotree",
    cmd = { "UndotreeShow", "UndotreeToggle" },
  },
  {
    "simrat39/symbols-outline.nvim",
    cmd = { "SymbolsOutline" },
    opts = { show_numbers = true, show_relative_numbers = true, auto_preview = true },
  },
  { "editorconfig/editorconfig-vim", event = "BufReadPre" },
  {
    "smoka7/multicursors.nvim",
    enabled = true,
    event = "VeryLazy",
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "smoka7/hydra.nvim",
    },
    opts = function()
      local N = require("multicursors.normal_mode")
      local I = require("multicursors.insert_mode")
      return {
        normal_keys = {
          -- to change default lhs of key mapping change the key
          [","] = {
            -- assigning nil to method exits from multi cursor mode
            method = N.clear_others,
            -- you can pass :map-arguments here
            opts = { desc = "Clear others" },
          },
        },
        insert_keys = {
          -- to change default lhs of key mapping change the key
          ["<CR>"] = {
            -- assigning nil to method exits from multi cursor mode
            method = I.Cr_method,
            -- you can pass :map-arguments here
            opts = { desc = "New line" },
          },
        },
        hint_config = {
          border = "rounded",
          position = "bottom",
          -- border = { "┏", "━", "┓", "┃", "┛", "━", "┗", "┃" },
        },
        generate_hints = {
          normal = true,
          insert = true,
          extend = true,
        },
      }
    end,
    cmd = { "MCstart", "MCvisual", "MCclear", "MCpattern", "MCvisualPattern", "MCunderCursor" },
    keys = {
      {
        mode = { "v", "n" },
        "<Leader>m",
        "<cmd>MCstart<cr>",
        desc = "Create a selection for selected text or word under the cursor",
      },
    },
  },
  -- DB
  {
    "kndndrj/nvim-dbee",
    dependencies = {
      "MunifTanjim/nui.nvim",
    },
    event = "VeryLazy",
    build = function()
      -- Install tries to automatically detect the install method
      -- If it fails, try calling it with one of these paramaters:
      --    "curl", "wget", "bitsadmin", "go"
      require("dbee").install()
    end,
    config = function()
      require("dbee").setup({
        sources = {
          require("dbee.sources").FileSource:new(_G.get_config_dir() .. "/dbee/persistence.json"),
          require("dbee.sources").EnvSource:new("DBEE_CONNECTIONS"),
        },
      })
    end,
  },
  -- Session Management
  {
    "olimorris/persisted.nvim",
    lazy = false,
    dependencies = { "nvim-telescope/telescope.nvim" },
    config = function()
      require("persisted").setup({
        save_dir = _G.SESSIONDIR,
        autoload = true,
        use_git_branch = true,
        should_autosave = function()
          -- do not autosave if the alpha dashboard is the current filetype
          if vim.bo.filetype == "alpha" then
            return false
          end
          return true
        end,
      })
    end,
    -- opts = {
    -- 	save_dir = _G.SESSIONDIR,
    -- 	autoload = true,
    -- 	use_git_branch = true,
    -- 	should_autosave = function()
    -- 		-- do not autosave if the alpha dashboard is the current filetype
    -- 		if vim.bo.filetype == "alpha" then
    -- 			return false
    -- 		end
    -- 		return true
    -- 	end,
    -- },
  },
  -- Editor Visuals
  {
    "max397574/better-escape.nvim",
    event = "BufRead",
    config = true,
  },
  {
    "windwp/nvim-autopairs",
    event = "BufRead",
    opts = {
      fast_wrap = {},
      disable_filetype = { "TelescopePrompt", "vim", "guihua", "guihua_rust", "clap_input" },
    },
  },
  {
    "numToStr/Comment.nvim",
    event = "BufRead",
    dependencies = {
      "JoosepAlviste/nvim-ts-context-commentstring",
      { "s1n7ax/nvim-comment-frame", opts = { disable_default_keymap = true } },
      { "LudoPinelli/comment-box.nvim", config = true },
    },
    config = function()
      require("Comment").setup({
        mappings = {
          basic = false,
          extra = false,
          extended = false,
        },
        pre_hook = require("ts_context_commentstring.integrations.comment_nvim").create_pre_hook(),
      })
    end,
  },
  {
    "folke/todo-comments.nvim",
    cmd = { "TodoTrouble", "TodoTelescope" },
    event = "BufReadPost",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = true,
  },
  {
    "smjonas/inc-rename.nvim",
    cmd = "IncRename",
    opts = {
      input_buffer_type = "dressing",
    },
  },
  {
    "Wansmer/treesj",
    cmd = { "TSJToggle", "TSJSplit", "TSJJoin" },
    opts = {
      use_default_keymaps = false,
    },
  },
  {
    "tversteeg/registers.nvim",
    cmd = { "Registers" },
    config = true,
  },
  {
    "kensyo/nvim-scrlbkun",
    -- "petertriho/nvim-scrollbar",
    -- dependencies = { "kevinhwang91/nvim-hlslens" },
    event = "VeryLazy",
    -- config = function()
    -- local scroll_ok, scrollbar = pcall(require, "scrollbar")
    -- scrollbar.setup()
    -- require("scrlbkun").setup({
    -- 	width = 1,
    -- })
    -- If you also want to configure `hlslens`
    -- require("scrollbar.handlers.search").setup()
    -- end,
    opts = { width = 1 },
  },
  { "RRethy/vim-illuminate", event = "BufReadPost" },
  -- Misc
  {
    "max397574/colortils.nvim",
    cmd = "Colortils",
    opts = {
      default_format = "hex", -- "rgb" || "hsl"
    },
  },
  { "szw/vim-maximizer", cmd = { "MaximizerToggle" } },
  {
    "sindrets/winshift.nvim",
    cmd = "WinShift",
    config = true,
  },
  {
    "RishabhRD/nvim-cheat.sh",
    dependencies = { "RishabhRD/popfix" },
    cmd = { "Cheat", "CheatWithoutComments", "CheatList", "CheatListWithoutComments" },
  },
  {
    "ziontee113/icon-picker.nvim",
    cmd = { "IconPickerNormal", "IconPickerInsert", "IconPickerYank" },
    opts = {
      disable_legacy_commands = true,
    },
  },
  { "eandrju/cellular-automaton.nvim", cmd = "CellularAutomaton" },
  {
    "tamton-aquib/zone.nvim",
    enabled = true,
    opts = {
      style = "vanish",
      after = 60,
    },
  },
  -- Themes
  {
    "folke/styler.nvim",
    event = "VeryLazy",
    opts = {
      themes = {
        markdown = { colorscheme = "oxocarbon" },
        gitcommit = { colorscheme = "tokyodark" },
        gitrebase = { colorscheme = "rose-pine" },
        help = { colorscheme = "catppuccin", background = "dark" },
      },
    },
  },
  {
    "catppuccin/nvim",
    priority = 999,
    lazy = false,
    name = "catppuccin",
    config = function()
      local ctpcn_ok, ctpcn = pcall(require, "catppuccin")
      if ctpcn_ok then
        ctpcn.setup({
          flavour = "mocha",
          no_italic = false,
          no_bold = false,
          -- Awesome dark variant I got from https://github.com/nullchilly/nvim/blob/nvim/lua/config/catppuccin.lua
          -- But I couldn't get the time to research how to make NvimTree Context match it so, commented out for now
          -- color_overrides = {
          -- 	mocha = {
          -- 		base = "#000000",
          -- 	},
          -- },
          dim_inactive = {
            enabled = true,
          },
          styles = {
            types = { "italic" },
            booleans = { "italic" },
          },
          term_colors = true,
          integrations = {
            alpha = true,
            beacon = true,
            cmp = true,
            fidget = true,
            gitgutter = true,
            gitsigns = true,
            illuminate = true,
            indent_blankline = { enabled = true },
            notify = true,
            mason = true,
            mini = true,
            navic = true,
            native_lsp = {
              enabled = true,
              underlines = {
                errors = { "undercurl" },
                hints = { "undercurl" },
                warnings = { "undercurl" },
                information = { "undercurl" },
              },
            },
            neotest = true,
            noice = true,
            nvimtree = true,
            semantic_tokens = true,
            telescope = true,
            treesitter = true,
            treesitter_context = true,
            ts_rainbow = true,
            symbols_outline = true,
            lsp_trouble = true,
            which_key = true,
          },
          native_lsp = {
            enabled = true,
            virtual_text = {
              errors = { "italic" },
              hints = { "italic" },
              warnings = { "italic" },
              information = { "italic" },
            },
            underlines = {
              errors = { "underline" },
              hints = { "underline" },
              warnings = { "underline" },
              information = { "underline" },
            },
          },
          highlight_overrides = {
            mocha = function(C)
              return {
                TabLineSel = { bg = C.pink },
                NvimTreeNormal = { bg = C.none },
                CmpBorder = { fg = C.surface2 },
                Pmenu = { bg = C.none },
                NormalFloat = { bg = C.none },
              }
            end,
          },
        })
      else
        vim.notify("Theme Error", vim.log.levels.WARN)
      end
    end,
  },
  {
    "tiagovla/tokyodark.nvim",
    priority = 999,
    lazy = false,
  },
  {
    "rose-pine/neovim",
    priority = 999,
    lazy = false,
    name = "rose-pine",
    config = function()
      local rp_ok, rp = pcall(require, "rose-pine")
      if rp_ok then
        rp.setup()
      else
        vim.notify("Theme Error", vim.log.levels.WARN)
      end
    end,
  },
  {
    "rebelot/kanagawa.nvim",
    priority = 999,
    lazy = false,
    config = function()
      local kngw_ok, kngw = pcall(require, "kanagawa")
      if kngw_ok then
        kngw.setup({
          compile = true,
          theme = "dragon",
          background = {
            dark = "dragon",
            light = "wave",
          },
        })
      else
        vim.notify("Theme Error", vim.log.levels.WARN)
      end
    end,
  },
  {
    "nyoom-engineering/oxocarbon.nvim",
    priority = 999,
    lazy = false,
  },
}

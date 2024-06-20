local features = require("avim.core.defaults").features

-- vim.g.instant_username = "anorebel"
return {
  {
    "jbyuki/instant.nvim",
    enabled = features.collab,
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
    enabled = features.remote,
    branch = "v0.3",
    cmd = {
      "Distant",
      "DistantMetadata",
      "DistantMkdir",
      "DistantRemove",
      "DistantRename",
      "DistantSearch",
      "DistantCancelSearch",
      "DistantCheckHealth",
      "DistantConnect",
      "DistantSystemInfo",
      "DistantSessionInfo",
      "DistantClientVersion",
      "DistantShell",
      "DistantSpawn",
      "DistantCopy",
      "DistantLaunch",
      "DistantOpen",
      "DistantInstall",
    },
    build = ":DistantInstall",
    config = function()
      require("distant"):setup({
        -- Applies Chip's personal settings to every machine you connect to
        --
        -- 1. Ensures that distant servers terminate with no connections
        -- 2. Provides navigation bindings for remote directories
        -- 3. Provides keybinding to jump into a remote file's parent directory
        ["*"] = require("distant.settings").chip_default(),
        servers = {
          ["*"] = {
            connect = {
              default = {
                port = 9157,
                username = "anorebel",
              },
              launch = {
                default = {
                  port = 9157,
                  username = "anorebel",
                },
              },
            },
          },
        },
        client = {
          log_file = _G.get_cache_dir() .. "/distant_client.log",
        },
        manager = {
          log_file = _G.get_cache_dir() .. "/distant_manager.log",
        },
        keymap = {
          dir = {
            edit = "<Return>",
            metadata = "<C-k>",
            newdir = "A",
          },
          ui = {
            main = {
              connections = {
                kill = "Q",
                toggle_info = "<C-k>",
              },
              tabs = {
                goto_connections = "gd",
                goto_system_info = "I",
              },
            },
          },
        },
      })
    end,
  },
}

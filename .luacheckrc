---@diagnostic disable
-- Luacheck configuration for AnoNvim
-- Reference: https://luacheck.readthedocs.io/en/stable/config.html

-- Define Neovim standard
stds.nvim = {
  -- Global variables
  globals = {
    -- AnoNvim globals
    "avim",                    -- AnoNvim namespace
    "USER",                    -- Current user
    "C",                       -- Configuration
    "Config",                  -- Configuration object
    "MUtils",                  -- Utility functions
    
    -- Path variables
    "WORKSPACE_PATH",          -- Current workspace
    "USER_CONFIG_PATH",        -- User config directory
    
    -- Special globals
    "TERMINAL",               -- Terminal handling
    
    -- Extended standard libraries
    vim = {
      fields = {
        "g",                  -- Global variables
        "b",                  -- Buffer variables
        "w",                  -- Window variables
        "t",                  -- Tabpage variables
        "v",                  -- Global variables
        "env",               -- Environment variables
        "opt",               -- Options
        "api",               -- Neovim API
        "fn",                -- Vim functions
        "cmd",               -- Command execution
        "loop",              -- Event loop
        "schedule",          -- Schedule callback
      }
    },
    os = {
      fields = {
        "capture",           -- Command output capture
        "execute",           -- Command execution
      }
    },
  },
  
  -- Read-only globals
  read_globals = {
    -- Lua/LuaJIT
    "jit",                   -- LuaJIT specific
    "os",                    -- Operating system
    
    -- Neovim
    "vim",                   -- Neovim API
    "avim",                  -- AnoNvim namespace
    
    -- Utility functions
    "join_paths",            -- Path joining
    "get_runtime_dir",       -- Runtime directory
    "get_config_dir",        -- Config directory
    "get_cache_dir",         -- Cache directory
    "get_avim_base_dir",     -- Base directory
  },
}

-- Lua version and standards
std = "lua51+nvim"

-- Performance settings
cache = true                -- Enable caching
max_cyclomatic_complexity = 20  -- Maximum function complexity

-- Code style
max_line_length = false     -- Disable line length warnings
max_code_line_length = 120  -- But set a soft limit
max_string_line_length = 120
max_comment_line_length = 120

-- Method handling
self = false               -- Don't report unused self arguments

-- Specific ignores
ignore = {
  "631",                   -- Line length limit
  "212/_.*",              -- Unused arguments starting with _
  "213/_.*",              -- Unused loop variables starting with _
  "542",                  -- Empty if branch
  "211/_.*",              -- Unused variable starting with _
}

-- Files to exclude
exclude_files = {
  "lua/avim/lazy/**",     -- Plugin manager files
  "tests/**",             -- Test files
  ".luacheckrc",          -- This config file
}

-- Custom file patterns
files = {
  ["lua/avim/plugins/*.lua"] = {
    enable = {"631"},      -- Enable line length checks for plugins
  },
  ["lua/avim/core/*.lua"] = {
    max_cyclomatic_complexity = 25,  -- Allow more complexity in core
  },
}

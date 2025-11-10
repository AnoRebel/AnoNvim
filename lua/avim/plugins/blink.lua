local icons = require("avim.icons")
local utilities = require("avim.utilities")

local function has_words_before()
  local line, col = (unpack or table.unpack)(vim.api.nvim_win_get_cursor(0))
  return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") == nil
end

local deps = {
  { "L3MON4D3/LuaSnip" },
  { "rafamadriz/friendly-snippets" },
  {
    "Exafunction/windsurf.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    config = function()
      require("codeium").setup({
        enable_chat = true,
        -- enable_cmp_source = false,
        virtual_text = {
          enabled = true,
          map_keys = true,
          key_bindings = {
            accept = "<M-.>",
            clear = "<C-e>",
          },
        },
        config_path = utilities.get_config_dir() .. "/codeium/config.json",
        bin_path = utilities.get_runtime_dir() .. "/codeium/bin",
      })
    end,
  },
  { "moyiz/blink-emoji.nvim" },
  { "dmitmel/cmp-cmdline-history" },
  {
    "MattiasMTS/cmp-dbee",
    dependencies = {
      { "kndndrj/nvim-dbee" },
    },
    ft = "sql",
    opts = {},
  },
  { "alexandre-abrioux/blink-cmp-npm.nvim" },
}

-- Check if in start tag for Vue filtering
local function is_in_start_tag()
  local node = utilities.get_node_at_cursor()
  if not node then
    return false
  end
  return node:type() == "start_tag"
end

-- Vue LSP entry filter for blink.cmp
--@type fun(ctx: blink.cmp.Context, items: blink.cmp.CompletionItem[]): blink.cmp.CompletionItem[]
---@param ctx blink.cmp.Context
---@param items blink.cmp.CompletionItem[]
local vue_lsp_filter = function(ctx, items)
  if vim.bo.filetype ~= "vue" then
    return items
  end

  -- Check if we're in a start tag (caching removed for simplicity)
  if not is_in_start_tag() then
    return items
  end

  local c = ctx.get_cursor()
  local cursor_line = ctx.line
  local cursor = {
    row = c[1],
    col = c[2] + 1,
    line = c[1] - 1,
  }
  -- Get cursor position and text before cursor
  local cursor_before_line = string.sub(cursor_line, 1, cursor.col - 1)

  local filtered_items = {}

  for _, item in ipairs(items) do
    local label = item.label
    -- For events
    if cursor_before_line:match("(@[%w]*)%s*$") ~= nil or cursor_before_line:sub(-1) == "@" then
      if label:match("^@") then
        table.insert(filtered_items, item)
      end
      -- For props also exclude events with `:on-` prefix
    elseif cursor_before_line:match("(:[%w]*)%s*$") ~= nil or cursor_before_line:sub(-1) == ":" then
      if label:match("^:") and not label:match("^:on%-") then
        table.insert(filtered_items, item)
      end
      -- For slot
    elseif cursor_before_line:match("(#[%w]*)%s*$") ~= nil or cursor_before_line:sub(-1) == "#" then
      if item.kind == require("blink.cmp.types").CompletionItemKind.Method then
        table.insert(filtered_items, item)
      end
    else
      table.insert(filtered_items, item)
    end
  end

  return filtered_items
end

-- Enhanced formatting function compatible with latest blink.cmp
local function format_item(ctx)
  local source_name = ctx.source_id or ctx.source_name
  -- Source mapping for formatting
  local source_mapping = {
    lsp = "[LSP]",
    path = "[PTH]",
    snippets = "[SNP]",
    buffer = "[BUF]",
    lazydev = "[LLS]",
    treesitter = "[TST]",
    cmdline = "[CMD]",
    codeium = "[CODE]",
    ["cmp-dbee"] = "[DB]",
    dbee = "[DB]",
    npm = "[NPM]",
    ["cmp-npm"] = "[NPM]",
  }

  local menu = source_mapping[source_name] or "[" .. (source_name or ""):upper() .. "]"
  local kind_icon = icons.kind_icons[ctx.kind] or ctx.kind_icon
  local maxwidth = 50

  -- Handle label truncation
  local label = ctx.label
  local truncated_label = vim.fn.strcharpart(label, 0, maxwidth)
  if truncated_label ~= label then
    -- item.label = truncated_label .. "..."
    ctx.label = truncated_label .. "..."
  end

  -- Apply tailwindcss-colorizer-cmp if available
  local formatted_item = vim.deepcopy(ctx)
  if utilities.tailwind.formatter then
    local colorized = utilities.tailwind.formatter(formatted_item)
    if colorized.hl_group then
      formatted_item = colorized
    end
  end

  -- Try nvim-web-devicons for file types
  local devicons_ok, devicons = pcall(require, "nvim-web-devicons")
  if devicons_ok then
    if ctx.source_name == "Path" then
      local _, hl_group = devicons.get_icon_color_by_filetype(vim.bo.filetype)
      if hl_group then
        formatted_item.hl_group = hl_group
      end
    end
    if ctx.kind == "File" then
      local dev_icon, dev_hl = require("nvim-web-devicons").get_icon(ctx.label)
      if dev_icon then
        formatted_item.hl_group = dev_hl
      end
    end
  end

  return {
    label = formatted_item.label or label,
    kind_icon = kind_icon,
    menu = menu,
    source = source_name,
    -- Pass through any colorizer highlight groups
    hl_group = formatted_item.hl_group,
  }
end

-- Auto-brackets function for blink.cmp (with safety checks)
---@param ctx table
local function handle_auto_brackets(ctx)
  local item = ctx.item
  if not item then
    return
  end

  local completion_item = item.completion_item or item
  local kind = completion_item.kind

  -- Check if it's a function or method (2 = Method, 3 = Function)
  if kind == 3 or kind == 2 then
    local cursor = vim.api.nvim_win_get_cursor(0)
    local line = vim.api.nvim_get_current_line()
    
    -- Safety check: ensure we're not at the end of line or next char is not already a bracket
    if cursor[2] < #line then
      local next_char = line:sub(cursor[2] + 1, cursor[2] + 1)
      if next_char == "(" or next_char == ")" then
        return
      end
    end
    
    -- Insert brackets
    local keys = vim.api.nvim_replace_termcodes("()<left>", false, false, true)
    vim.api.nvim_feedkeys(keys, "i", true)
  end
end

return {
  -- add blink.compat
  {
    "saghen/blink.compat",
    -- use v2.* for blink.cmp v1.*
    version = "2.*",
    -- lazy.nvim will automatically load the plugin when it's required by blink.cmp
    lazy = true,
    -- make sure to set opts so that lazy.nvim calls blink.compat's setup
    opts = {},
  },
  {
    "saghen/blink.cmp",
    -- use a release tag to download pre-built binaries
    version = "1.*",
    -- AND/OR build from source, requires nightly: https://rust-lang.github.io/rustup/concepts/channels.html#working-with-nightly-rust
    -- build = 'cargo build --release',
    event = { "InsertEnter", "CmdlineEnter" },
    dependencies = deps,
    opts_extend = { "sources.default", "cmdline.sources", "term.sources" },
    --- @module 'blink.cmp'
    --- @type blink.cmp.Config
    opts = {
      sources = {
        -- adding any nvim-cmp sources here will enable them
        -- with blink.compat
        -- compat = { "dbee", },
        per_filetype = {
          sql = { "dbee", "buffer" },
          -- optionally inherit from the `default` sources
          lua = { inherit_defaults = true, "lazydev" },
        },
        default = { "lsp", "path", "snippets", "buffer", "codeium", "npm", "emoji" },
        providers = {
          lazydev = {
            name = "LazyDev",
            module = "lazydev.integrations.blink",
            -- make lazydev completions top priority (see `:h blink.cmp`)
            score_offset = 100,
            max_items = 5,
          },
          lsp = {
            name = "LSP",
            module = "blink.cmp.sources.lsp",
            score_offset = 10,
            max_items = 5,
            transform_items = vue_lsp_filter,
            opts = {
              tailwind_color_icon = "󱓻",
            },
          },
          path = {
            name = "Path",
            module = "blink.cmp.sources.path",
            score_offset = 3,
            max_items = 3,
            opts = {
              show_hidden_files_by_default = true,
            },
          },
          snippets = {
            name = "Snippets",
            module = "blink.cmp.sources.snippets",
            score_offset = 5,
            max_items = 3,
            opts = {
              -- Whether to use show_condition for filtering snippets
              use_show_condition = true,
              -- Whether to show autosnippets in the completion list
              show_autosnippets = true,
            },
          },
          buffer = {
            name = "Buffer",
            module = "blink.cmp.sources.buffer",
            score_offset = -5,
            max_items = 3,
            min_keyword_length = 3,
            opts = {
              -- default to all visible buffers
              get_bufnrs = function()
                return vim
                  .iter(vim.api.nvim_list_wins())
                  :map(function(win)
                    return vim.api.nvim_win_get_buf(win)
                  end)
                  :filter(function(buf)
                    return vim.bo[buf].buftype ~= "nofile"
                  end)
                  :totable()
              end,
              -- buffers when searching with `/` or `?`
              get_search_bufnrs = function()
                return { vim.api.nvim_get_current_buf() }
              end,
            },
          },
          cmdline = {
            module = "blink.cmp.sources.cmdline",
            score_offset = 100,
            max_items = 10, -- Increased from 3 for better command suggestions
            fallbacks = { "buffer" }, -- Fallback to buffer completions if no cmdline matches
          },
          cmdline_history_cmd = {
            name = "cmdline_history",
            module = "blink.compat.source",
            max_items = 1,
            score_offset = 10,
            opts = {
              history_type = "cmd",
            },
            -- kind = "History",
          },
          cmdline_history_search = {
            name = "cmdline_history",
            module = "blink.compat.source",
            max_items = 1,
            score_offset = 10,
            opts = {
              history_type = "search",
            },
            -- kind = "History",
          },
          codeium = { name = "Codeium", module = "codeium.blink", async = true, max_items = 3 },
          ecolog = { name = "ecolog", module = "ecolog.integrations.cmp.blink_cmp" },
          npm = {
            name = "npm",
            module = "blink-cmp-npm",
            async = true,
            min_keyword_length = 3,
            -- optional - make blink-cmp-npm completions top priority (see `:h blink.cmp`)
            score_offset = 50,
            -- optional - blink-cmp-npm config
            ---@module "blink-cmp-npm"
            ---@type blink-cmp-npm.Options
            opts = {
              ignore = {},
              only_semantic_versions = false,
              only_latest_version = false,
            },
          },
          dbee = {
            -- IMPORTANT: use the same name as you would for nvim-cmp
            name = "cmp-dbee",
            module = "blink.compat.source",
            score_offset = 100,
          },
          emoji = {
            module = "blink-emoji",
            name = "Emoji",
            score_offset = 15, -- Tune by preference
            opts = {
              insert = true, -- Insert emoji (default) or complete its name
              ---@type string|table|fun():table
              trigger = function()
                return { ":" }
              end,
            },
            should_show_items = function()
              return vim.tbl_contains(
                -- Enable emoji completion only for git commits and markdown.
                -- By default, enabled for all file-types.
                { "gitcommit", "markdown" },
                vim.o.filetype
              )
            end,
          },
        },
      },
      cmdline = {
        enabled = true,
        -- use 'inherit' to inherit mappings from top level `keymap` config
        -- sources = { "buffer", "cmdline" },
        -- OR explicitly configure per cmd type
        -- This ends up being equivalent to above since the sources disable themselves automatically
        -- when not available. You may override their `enabled` functions via
        -- `sources.providers.cmdline.override.enabled = function() return your_logic end`
        sources = function()
          local type = vim.fn.getcmdtype()
          -- Search forward and backward
          if type == "/" or type == "?" then
            return { "buffer", "cmdline_history_search" }
          end
          -- Commands - enhanced ordering for better suggestions
          if type == ":" or type == "@" then
            return { "cmdline", "lazydev", "path", "cmdline_history_cmd", "buffer" }
          end
          return { "cmdline", "buffer" }
        end,
        keymap = {
          preset = "cmdline",
          -- recommended, as the default keymap will only show and select the next item
          ["<Tab>"] = { "select_next", "show", "fallback" },
          ["<S-Tab>"] = { "select_prev", "show", "fallback" },
        },
        completion = {
          list = {
            selection = {
              -- When `true`, will automatically select the first item in the completion list
              preselect = false,
              -- When `true`, inserts the completion item automatically when selecting it
              auto_insert = true,
            },
          },
          -- Whether to automatically show the window when new completion items are available
          -- Default is false for cmdline, true for cmdwin (command-line window)
          menu = {
            auto_show = function(ctx, _)
              return vim.fn.getcmdtype() == ":"
              -- return ctx.mode == "cmdwin"
            end,
          },
          -- Displays a preview of the selected item on the current line
          ghost_text = { enabled = true },
        },
      },
      term = {
        enabled = true,
        keymap = { preset = "inherit" }, -- Inherits from top level `keymap` config when not set
        sources = {},
        completion = {
          trigger = {
            show_on_blocked_trigger_characters = {},
            show_on_x_blocked_trigger_characters = nil, -- Inherits from top level `completion.trigger.show_on_blocked_trigger_characters` config when not set
          },
          -- Inherits from top level config options when not set
          list = {
            selection = {
              -- When `true`, will automatically select the first item in the completion list
              preselect = nil,
              -- When `true`, inserts the completion item automatically when selecting it
              auto_insert = nil,
            },
          },
          -- Whether to automatically show the window when new completion items are available
          menu = { auto_show = nil },
          -- Displays a preview of the selected item on the current line
          ghost_text = { enabled = nil },
        },
      },
      keymap = {
        preset = "default",
        ["<C-p>"] = { "select_prev", "fallback" },
        ["<C-n>"] = { "select_next", "fallback" },
        ["<Up>"] = { "select_prev", "fallback" },
        ["<Down>"] = { "select_next", "fallback" },
        ["<C-b>"] = {
          "scroll_documentation_up",
          function(cmp)
            local config = require("blink.cmp.config").signature
            if not config.enabled or not cmp.is_signature_visible() then
              return
            end
            local signature = require("blink.cmp.signature.window")
            vim.schedule(function()
              signature.scroll_up(4)
            end)
            return true
          end,
          "fallback",
        },
        ["<C-f>"] = {
          "scroll_documentation_down",
          function(cmp)
            local config = require("blink.cmp.config").signature
            if not config.enabled or not cmp.is_signature_visible() then
              return
            end
            local signature = require("blink.cmp.signature.window")
            vim.schedule(function()
              signature.scroll_down(4)
            end)
            return true
          end,
          "fallback",
        },
        ["<C-Space>"] = { "show", "show_documentation", "hide_documentation", "fallback" },
        ["<C-e>"] = {
          function(cmp)
            if not cmp.is_signature_visible() then
              return
            end
            cmp.hide_signature()
            return true
          end,
          "hide",
          "cancel",
          "fallback",
        },
        ["<CR>"] = {
          function()
            -- insert undo breakpoint
            utilities.run_expr("<C-g>u")
          end,
          "accept",
          "fallback",
        },
        ["<S-CR>"] = {
          "select_and_accept",
          "fallback",
        },
        ["<Tab>"] = {
          "select_next",
          "snippet_forward",
          function(cmp)
            if has_words_before() or vim.api.nvim_get_mode().mode == "c" then
              return cmp.show()
            end
          end,
          "fallback",
        },

        ["<S-Tab>"] = {
          "select_prev",
          "snippet_backward",
          function(cmp)
            if vim.api.nvim_get_mode().mode == "c" then
              return cmp.show()
            end
          end,

          "fallback",
        },
      },

      appearance = {
        -- Sets the fallback highlight groups to nvim-cmp's highlight groups
        -- Useful for when your theme doesn't support blink.cmp
        -- Will be removed in a future release
        use_nvim_cmp_as_default = true,
        nerd_font_variant = "mono",
        kind_icons = icons.kind_icons,
      },

      completion = {
        -- Screen coordinates of the command line
        list = {
          cycle = {
            from_top = true,
            from_bottom = true,
          },
          selection = {
            preselect = false,
            auto_insert = false,
          },
        },
        accept = {
          create_undo_point = true,
          resolve_timeout_ms = 5000, -- some lsps can be *that* slow, hello pyright :)
          auto_brackets = {
            enabled = true,
            default_brackets = { "(", ")" },
            override_brackets_for_filetypes = {},
            force_allow_filetypes = { "python" },
            blocked_filetypes = {},
          },
        },
        menu = {
          enabled = true,
          min_width = 15,
          max_height = 10,
          border = "rounded",
          winblend = vim.o.pumblend,
          winhighlight = "Normal:NormalFloat,FloatBorder:FloatBorder,CursorLine:PmenuSel,Search:None",
          scrollbar = true,
          direction_priority = { "s", "n" },
          auto_show = true,
          cmdline_position = function()
            if utilities.lsp.has_plugin("noice.nvim") then
              local Api = require("noice.api")
              local pos = Api.get_cmdline_position()
              local type = vim.fn.getcmdtype()

              if type == "/" or type == "?" then
                return { pos.screenpos.row - 1, pos.screenpos.col - 2 }
              end
              return { pos.screenpos.row, pos.screenpos.col - 1 }
            end

            if vim.g.ui_cmdline_pos ~= nil then
              local pos = vim.g.ui_cmdline_pos -- (1, 0)-indexed
              return { pos[1] - 1, pos[2] }
            end

            local height = (vim.o.cmdheight == 0) and 1 or vim.o.cmdheight
            return { vim.o.lines - height, 0 }
          end,
          draw = {
            treesitter = { "lsp" },
            gap = 2,
            columns = {
              { "kind_icon" },
              { "label", "label_description", gap = 1 },
              { "kind" },
              { "source" },
            },
            components = {
              kind_icon = {
                ellipsis = false,
                width = { min = 3 },
                text = function(ctx)
                  local formatted = format_item(ctx)
                  return " " .. formatted.kind_icon .. ctx.icon_gap
                end,
                highlight = function(ctx)
                  local formatted = utilities.tailwind.formatter(ctx)
                  if formatted.hl_group then
                    return formatted.hl_group or ctx.kind_hl
                  end

                  -- Fall back to default blink.cmp kind highlighting
                  return "BlinkCmpKind" .. ctx.kind
                end,
              },

              label = {
                width = { fill = true, max = 60 },
                text = function(ctx)
                  local formatted = format_item(ctx)
                  return formatted.label
                end,
                highlight = function(ctx)
                  local highlights = {}

                  -- Try tailwindcss-colorizer-cmp for additional highlighting
                  if utilities.tailwind.formatter then
                    local formatted = utilities.tailwind.formatter(ctx)
                    if formatted.hl_group then
                      table.insert(highlights, { 0, #(ctx.label or ""), group = formatted.hl_group })
                    end
                  end

                  -- Handle matched indices for fuzzy highlighting
                  if ctx.matched_indices and #ctx.matched_indices > 0 then
                    for _, idx in ipairs(ctx.matched_indices) do
                      table.insert(highlights, { idx, idx + 1, group = "BlinkCmpLabelMatch" })
                    end
                  end

                  -- Handle deprecated items
                  if ctx.deprecated then
                    table.insert(highlights, { 0, #(ctx.label or ""), group = "BlinkCmpLabelDeprecated" })
                  end

                  return highlights
                end,
              },

              label_description = {
                width = { max = 30 },
                text = function(ctx)
                  return ctx.label_description
                end,
                highlight = "BlinkCmpLabelDescription",
              },

              kind = {
                ellipsis = false,
                -- width = { fill = true },
                text = function(ctx)
                  return ctx.kind
                end,
                highlight = function(ctx)
                  return ctx.kind_hl
                end,
              },

              source = {
                -- width = { max = 30 },
                text = function(ctx)
                  local formatted = format_item(ctx)
                  return formatted.menu
                end,
                highlight = "BlinkCmpSource",
              },
            },
          },
        },
        documentation = {
          auto_show = true,
          auto_show_delay_ms = 200,
          update_delay_ms = 50,
          treesitter_highlighting = true,
          window = {
            min_width = 10,
            max_width = 60,
            max_height = 20,
            border = "rounded",
            -- winhighlight = "Normal:NormalFloat,FloatBorder:FloatBorder,CursorLine:Visual,Search:None",
            winhighlight = "Normal:NormalFloat,FloatBorder:FloatBorder,CursorLine:PmenuSel,Search:None",
            scrollbar = true,
            direction_priority = {
              menu_north = { "e", "w", "n", "s" },
              menu_south = { "e", "w", "s", "n" },
            },
          },
        },
        ghost_text = {
          enabled = false,
        },
      },

      snippets = {
        preset = "luasnip",
        expand = function(snippet, _)
          utilities.snippet.expand(snippet)
        end,
        active = function(filter)
          local luasnip = require("luasnip")
          if filter and filter.direction then
            return luasnip.jumpable(filter.direction)
          end
          return luasnip.in_snippet() or false
        end,
        jump = function(direction)
          local luasnip = require("luasnip")
          luasnip.jump(direction)
        end,
      },

      signature = {
        enabled = true,
        trigger = {
          -- buggy
          show_on_insert = false,
          blocked_trigger_characters = {},
          blocked_retrigger_characters = {},
          -- show_delay_ms = 200,
          -- hide_delay_ms = 2000,
        },
        window = {
          min_width = 1,
          max_width = 100,
          max_height = 10,
          border = "rounded",
          -- winhighlight = "Normal:NormalFloat,FloatBorder:FloatBorder",
          scrollbar = false,
          treesitter_highlighting = true,
          show_documentation = true,
          direction_priority = { "n", "s" },
        },
      },

      fuzzy = {
        frecency = { enabled  = true, },
        use_proximity = true,
        sorts = { "label", "kind", "score" },
        prebuilt_binaries = {
          download = true,
          force_version = nil,
        },
      },
    },

    config = function(_, opts)
      -- Setup blink.cmp
      require("blink.cmp").setup(opts)

      -- Autocmds for enhanced functionality
      local autocmd = vim.api.nvim_create_autocmd

      -- Disable for specific filetypes
      autocmd("FileType", {
        pattern = { "guihua", "guihua_rust" },
        callback = function()
          vim.b.completion = false
        end,
      })

      -- Clean up LuaSnip sessions
      autocmd("InsertLeave", {
        callback = function()
          if
            require("luasnip.session").current_nodes[vim.api.nvim_get_current_buf()]
            and not require("luasnip.session").jump_active
          then
            require("luasnip").unlink_current()
          end
        end,
      })



      -- Enhanced auto-brackets with nvim-autopairs integration
      autocmd("User", {
        pattern = "BlinkCmpCompletionConfirm",
        callback = function(event)
          local ctx = event.data
          if ctx and ctx.item then
            -- Handle auto brackets for specific filetypes
            if vim.tbl_contains({ "python" }, vim.bo.filetype) then
              handle_auto_brackets(ctx)
            end

            -- Integrate with nvim-autopairs
            local ok, autopairs = pcall(require, "nvim-autopairs.completion.cmp")
            local auto_pairs = require("nvim-autopairs.completion.handlers")
            if ok then
              autopairs.on_confirm_done({
                filetypes = {
                  ["*"] = {
                    ["("] = {
                      kind = {
                        require("blink.cmp.types").CompletionItemKind.Function or 3,
                        require("blink.cmp.types").CompletionItemKind.Method or 2,
                      }, -- Function, Method
                      handler = auto_pairs["*"],
                    },
                  },
                  lua = {
                    ["("] = {
                      kind = {
                        require("blink.cmp.types").CompletionItemKind.Function or 3,
                        require("blink.cmp.types").CompletionItemKind.Method or 2,
                      }, -- Function, Method
                      ---@param char string
                      ---@param item item completion
                      ---@param bufnr buffer number
                      handler = function(char, item, bufnr)
                        -- Your handler function. Inpect with print(vim.inspect{char, item, bufnr})
                      end,
                    },
                  },
                  tex = false, -- Disable for tex
                },
              })
            end
          end
        end,
      })

      -- Set up highlight groups
      -- vim.api.nvim_set_hl(0, "BlinkCmpMenu", { link = "Comment", default = true })
      -- vim.api.nvim_set_hl(0, "BlinkCmpGhostText", { link = "Comment", default = true })
    end,
  },
  {
    "L3MON4D3/LuaSnip",
    event = { "InsertEnter", "VeryLazy" },
    version = "v2.*",
    build = "make install_jsregexp",
    dependencies = { "rafamadriz/friendly-snippets" },
    keys = {
      {
        "<CR>",
        function()
          local luasnip = require("luasnip")
          if luasnip.expandable() then
            luasnip.expand()
          else
            utilities.run_expr("<CR>")
          end
        end,
        desc = "Expand Snippet",
        mode = { "i", "s" },
      },
      {
        "<Tab>",
        function()
          local luasnip = require("luasnip")
          if luasnip.locally_jumpable(1) or luasnip.jumpable(1) then
            luasnip.jump(1)
          elseif luasnip.expand_or_jumpable() then
            luasnip.expand_or_jump()
          else
            utilities.run_expr("<Tab>")
          end
        end,
        desc = "Snippet Forward",
        mode = { "i", "s" },
      },
      {
        "<S-Tab>",
        function()
          local luasnip = require("luasnip")
          if luasnip.locally_jumpable(-1) or luasnip.jumpable(-1) then
            luasnip.jump(-1)
          else
            utilities.run_expr("<S-Tab>")
          end
        end,
        desc = "Snippet Backward",
        mode = { "i", "s" },
      },
      {
        "<C-k>",
        function()
          local luasnip = require("luasnip")
          if luasnip.choice_active() then
            luasnip.change_choice(1)
            return
          end
          -- insert undo breakpoint
          utilities.run_expr("<C-g>u")

          vim.schedule(function()
            require("luasnip").expand()
          end)
        end,
        desc = "Expand Snippet Or Next Choice",
        mode = "i",
      },
      {
        "<C-S-k>",
        function()
          local luasnip = require("luasnip")
          if luasnip.choice_active() then
            luasnip.change_choice(-1)
          end
        end,
        desc = "Prev Choice",
        mode = "i",
      },
    },
    opts = {
      history = true,
      delete_check_events = "TextChanged",
      updateevents = "TextChanged,TextChangedI",
      -- Show snippets related to the language
      -- in the current cursor position
      ft_func = function()
        local filetypes = require("luasnip.extras.filetype_functions").from_pos_or_filetype()
        if vim.tbl_contains(filetypes, "markdown_inline") then
          -- HACK: fix markdown snippets not being expanded
          return { "markdown" }
        end
        return filetypes
      end,
      -- for lazy load snippets for given buffer
      load_ft_func = function(...)
        return require("luasnip.extras.filetype_functions").extend_load_ft({
          -- TODO: add injected filetypes for each filetype
          markdown = { "javascript", "json" },
        })(...)
      end,
    },
    config = function(_, opts)
      -- Setup LuaSnip
      require("luasnip").setup(opts)

      -- load snippets in nvim config folder
      -- NOTE: when using sync `load`, entries are duplicated in blink.cmp
      -- lazy_load doesn't work on nvim 0.11
      -- require("luasnip.loaders.from_vscode").load {
      require("luasnip.loaders.from_vscode").lazy_load()
      require("luasnip.loaders.from_vscode").lazy_load({
        paths = { vim.fn.stdpath("config") .. "/snippets" },
      })
    end,
  },
}

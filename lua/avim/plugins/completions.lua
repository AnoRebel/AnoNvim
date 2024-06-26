local defaults = require("avim.core.defaults")
local icons = require("avim.icons")
local utils = require("avim.utils")

CREATE_UNDO = vim.api.nvim_replace_termcodes("<c-G>u", true, true, true)
local deps = {
  { "rafamadriz/friendly-snippets" },
  { "saadparwaiz1/cmp_luasnip" },
  { "L3MON4D3/LuaSnip", build = "make install_jsregexp" },
  { "hrsh7th/cmp-nvim-lua" },
  { "hrsh7th/cmp-nvim-lsp" },
  { "hrsh7th/cmp-buffer" },
  { "hrsh7th/cmp-path" },
  { "hrsh7th/cmp-cmdline" },
  { "lukas-reineke/cmp-under-comparator" },
  { "hrsh7th/cmp-nvim-lsp-signature-help" },
  { "dmitmel/cmp-cmdline-history" },
  {
    "David-Kunz/cmp-npm",
    dependencies = { "nvim-lua/plenary.nvim" },
    ft = "json",
    config = function()
      require("cmp-npm").setup({})
    end,
  },
  { "roobert/tailwindcss-colorizer-cmp.nvim", opts = { color_square_width = 2 } },
}
local sources = {
  { name = "luasnip" },
  { name = "nvim_lsp" },
  { name = "lazydev", group_index = 0 }, -- set group index to 0 to skip loading LuaLS completions
  { name = "nvim_lsp_signature_help" },
  { name = "nvim_lua" },
  { name = "path" },
  { name = "buffer", keyword_length = 3 },
  { name = "npm", keyword_length = 3 },
}
local source_mapping = {
  luasnip = "[SNP]", -- icons.snippet .. "[SNP]",
  nvim_lsp = "[LSP]", -- icons.paragraph .. "[LSP]",
  lazydev = "[LLS]", -- icons.bomb .. "[LLS]",
  nvim_lua = "[LUA]", -- icons.bomb .. "[LUA]",
  path = "[PTH]", -- icons.folderOpen2 .. "[PTH]",
  buffer = "[BUF]", -- icons.buffer .. "[BUF]",
  treesitter = "[TST]", -- icons.tree .. "[TST]",
  zsh = "[ZSH]", -- icons.terminal .. "[ZSH]",
  npm = "[NPM]", -- icons.terminal .. "[NPM]",
}

if defaults.features.database then
  table.insert(deps, {
    "MattiasMTS/cmp-dbee",
    dependencies = {
      { "kndndrj/nvim-dbee" },
    },
    ft = "sql",
    opts = {},
  })
  source_mapping.cmp_dbee = "[DBEE]" -- icons.db .. "[DBEE]",
  table.insert(sources, { name = "cmp-dbee" })
end

if defaults.features.ai then
  table.insert(deps, {
    "tzachar/cmp-tabnine",
    build = "./install.sh",
    enabled = utils.get_os()[2] ~= "arm" and defaults.features.ai,
  })
  table.insert(deps, {
    "supermaven-inc/supermaven-nvim",
    enabled = defaults.features.ai,
    config = function()
      require("supermaven-nvim").setup({
        keymaps = {
          accept_suggestion = "<A-.>",
          clear_suggestion = "<A-c>",
          accept_word = "<A-w>",
        },
        disable_inline_completion = false, -- disables inline completion for use with cmp
        disable_keymaps = false, -- disables built in keymaps for more manual control
      })
    end,
  })
  table.insert(deps, {
    "Exafunction/codeium.nvim",
    enabled = defaults.features.ai,
    dependencies = {
      "nvim-lua/plenary.nvim",
      "hrsh7th/nvim-cmp",
    },
    config = function()
      require("codeium").setup({
        config_path = _G.get_config_dir() .. "/codeium/config.json",
        bin_path = _G.get_runtime_dir() .. "/codeium/bin",
      })
    end,
  })
  table.insert(deps, {
    "Exafunction/codeium.vim",
    enabled = defaults.features.ai,
    event = "BufEnter",
    config = function()
      -- Change '<C-g>' here to any keycode you like.
      utils.map("i", "<A-a>", function()
        -- NOTE: Hack fix for this mapping always being set to nil
        -- return vim.fn["codeium#Accept"]()
        return vim.fn.feedkeys(vim.api.nvim_replace_termcodes(vim.fn["codeium#Accept"](), true, true, true), "")
      end, { expr = true, silent = true, desc = "Codeium: Accept Suggestion" })
      utils.map("i", "<A-n>", function()
        return vim.fn["codeium#CycleCompletions"](1)
      end, { expr = true, silent = true, desc = "Codeium: Next Suggestion" })
      utils.map("i", "<A-p>", function()
        return vim.fn["codeium#CycleCompletions"](-1)
      end, { expr = true, silent = true, desc = "Codeium: Previous Suggestion" })
      utils.map("i", "<A-Space>", function()
        return vim.fn["codeium#Complete"]()
      end, { expr = true, silent = true, desc = "Codeium: Trigger Suggestions" })
      utils.map("i", "<A-Bslash>", function()
        return vim.fn["codeium#Clear"]()
      end, { expr = true, silent = true, desc = "Codeium: Clear Suggestions" })
    end,
  })
  table.insert(sources, { name = "codeium" })
  table.insert(sources, { name = "supermaven" })
  table.insert(sources, { name = "cmp_tabnine" }) -- max_item_count = 3
  source_mapping.cmp_tabnine = "[TB9]" -- icons.light .. "[TB9]",
  source_mapping.codeium = "[CODE]" -- icons.rocket .. "[CODE]",
  source_mapping.supermaven = "[SPRMVN]" -- icons.rocket .. "[SPRMVN]",
end

return {
  {
    "hrsh7th/nvim-cmp",
    -- commit = "b356f2c", -- TODO: Temporary fix
    version = false,
    event = "InsertEnter",
    dependencies = deps,
    opts = { auto_brackets = { "python" } },
    config = function(_, opts)
      local cmp = require("cmp")
      local luasnip = require("luasnip")

      vim.api.nvim_set_hl(0, "CmpGhostText", { link = "Comment", default = true })
      local parse = require("cmp.utils.snippet").parse
      require("cmp.utils.snippet").parse = function(input)
        local ok, ret = pcall(parse, input)
        if ok then
          return ret
        end
        return require("avim.utils.snippet").snippet_preview(input)
      end

      -- Utils
      local create_undo = function()
        if vim.api.nvim_get_mode().mode == "i" then
          vim.api.nvim_feedkeys(CREATE_UNDO, "n", false)
        end
      end
      local check_backspace = function()
        local col = vim.fn.col(".") - 1
        return col == 0 or vim.fn.getline("."):sub(col, col):match("%s")
      end
      local autocmd = vim.api.nvim_create_autocmd
      autocmd("FileType", {
        pattern = { "guihua", "guihua_rust" },
        command = "lua require('cmp').setup.buffer({ enabled = false })",
      })

      autocmd("InsertLeave", {
        callback = function()
          if
            require("luasnip.session").current_nodes[vim.api.nvim_get_current_buf()]
            and not require("luasnip.session").jump_active
          then
            luasnip.unlink_current()
          end
        end,
      })
      require("luasnip.config").set_config({
        history = true,
        delete_check_events = "TextChanged",
        updateevents = "TextChanged,TextChangedI",
      })
      require("luasnip.loaders.from_vscode").lazy_load()

      local options = {
        window = {
          completion = {
            winhighlight = "Normal:NormalFloat,NormalFloat:Pmenu,Pmenu:NormalFloat", -- "Normal:Pmenu,FloatBorder:Pmenu,Search:None",
            col_offset = -3,
            side_padding = 1,
            border = "shadow", -- "none",
          },
          documentation = {
            border = "shadow",
          },
        },
        snippet = {
          expand = function(args)
            -- luasnip.lsp_expand(args.body)
            return require("avim.utils.snippet").expand(args.body)
          end,
        },
        formatting = {
          fields = { "kind", "abbr", "menu" },
          format = function(entry, vim_item)
            local menu = source_mapping[entry.source.name]
            local label = vim_item.abbr
            local kind = icons.kind_icons[vim_item.kind]
            local maxwidth = 50

            if entry.source.name == "cmp_tabnine" then
              if entry.completion_item.data ~= nil and entry.completion_item.data.detail ~= nil then
                menu = menu .. "[" .. entry.completion_item.data.detail .. "]"
              end
            end

            vim_item.menu = menu
            vim_item.kind = string.format("%s", kind)
            local truncated_label = vim.fn.strcharpart(label, 0, maxwidth)
            if truncated_label ~= label then
              vim_item.abbr = truncated_label .. "..."
            else
              vim_item.abbr = string.sub(vim_item.abbr, 1, maxwidth)
            end
            vim_item = require("tailwindcss-colorizer-cmp").formatter(entry, vim_item)
            return vim_item
          end,
        },
        -- duplicates = {
        --   buffer = 1,
        --   path = 1,
        --   nvim_lsp = 1,
        --   lazydev = 1,
        --   luasnip = 1,
        --   cmp_tabnine = 1,
        --   codeium = 1,
        --   supermaven = 1,
        --   treesitter = 1,
        --   cmp_dbee = 1,
        -- },
        -- duplicates_default = 0,
        mapping = cmp.mapping.preset.insert({
          ["<C-p>"] = cmp.mapping.select_prev_item(),
          ["<C-n>"] = cmp.mapping.select_next_item(),
          ["<Down>"] = cmp.mapping(cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Select }), { "i" }),
          ["<Up>"] = cmp.mapping(cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Select }), { "i" }),
          ["<C-b>"] = cmp.mapping(cmp.mapping.scroll_docs(-2), { "i", "c" }),
          ["<C-f>"] = cmp.mapping(cmp.mapping.scroll_docs(2), { "i", "c" }),
          ["<C-Space>"] = cmp.mapping(cmp.mapping.complete(), { "i", "c" }),
          ["<C-y>"] = cmp.config.disable, -- Specify `cmp.config.disable` if you want to remove the default `<C-y>` mapping.
          ["<C-e>"] = cmp.mapping({
            i = cmp.mapping.abort(),
            c = cmp.mapping.close(),
          }),
          ["<CR>"] = cmp.mapping({
            i = function(fallback)
              if cmp.core.view:visible() or vim.fn.pumvisible() == 1 then
                create_undo()
                cmp.confirm({ behavior = cmp.ConfirmBehavior.Insert, select = true }) -- prevent overwriting brackets
              else
                fallback()
              end
            end,
            s = cmp.mapping.confirm({ behavior = cmp.ConfirmBehavior.Replace, select = true }),
            c = cmp.mapping.confirm({ behavior = cmp.ConfirmBehavior.Replace, select = true }),
          }),
          ["<S-CR>"] = cmp.mapping({
            i = function(fallback)
              if cmp.core.view:visible() or vim.fn.pumvisible() == 1 then
                create_undo()
                cmp.confirm({ behavior = cmp.ConfirmBehavior.Replace, select = false }) -- prevent overwriting brackets
              else
                fallback()
              end
            end,
            s = cmp.mapping.confirm({ behavior = cmp.ConfirmBehavior.Replace, select = true }),
            c = cmp.mapping.confirm({ behavior = cmp.ConfirmBehavior.Replace, select = true }),
          }),
          ["<Tab>"] = cmp.mapping(function(fallback)
            local has_words_before = function()
              unpack = unpack or table.unpack
              local line, col = unpack(vim.api.nvim_win_get_cursor(0))
              return col ~= 0
                and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") == nil
            end
            -- local suggestion = require('supermaven-nvim.completion_preview')
            if cmp.visible() then
              cmp.select_next_item()
            -- elseif suggestion.has_suggestion() then
            --   suggestion.on_accept_suggestion()
            elseif luasnip.expandable() then
              luasnip.expand()
            elseif luasnip.expand_or_jumpable() then
              luasnip.expand_or_jump()
            elseif has_words_before() then
              cmp.complete()
            elseif check_backspace() then
              fallback()
            else
              fallback()
            end
          end, {
            "i",
            "s",
            "c",
          }),
          ["<S-Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_prev_item()
            elseif luasnip.jumpable(-1) then
              luasnip.jump(-1)
            else
              fallback()
            end
          end, {
            "i",
            "s",
            "c",
          }),
        }),
        -- You should specify your *installed* sources.
        sources = sources,
        -- don't sort double underscore things first
        sorting = {
          comparators = {
            defaults.features.ai and require("cmp_tabnine.compare") or nil,
            cmp.config.compare.offset,
            cmp.config.compare.exact,
            cmp.config.compare.score,
            -- cmp.config.compare.scopes,
            require("cmp-under-comparator").under,
            cmp.config.compare.recently_used,
            cmp.config.compare.locality,
            cmp.config.compare.kind,
            -- cmp.config.compare.sort_text,
            cmp.config.compare.length,
            cmp.config.compare.order,
          },
        },
        confirm_opts = {
          -- behavior = cmp.ConfirmBehavior.Replace,
          behavior = cmp.ConfirmBehavior.Insert,
          select = true,
        },
        view = {
          entries = { name = "custom", selection_order = "near_cursor" }, -- "wildmenu" | "native",
        },
        experimental = {
          -- native_menu = false,
          ghost_text = {
            -- enabled = true,
            hl_group = "CmpGhostText",
          },
        },
      }

      cmp.setup(options)
      vim.api.nvim_set_hl(0, "CmpItemKindSupermaven", { fg = "#6CC644" })

      if utils.get_os()[2] ~= "arm" then
        require("cmp_tabnine.config"):setup({
          max_lines = 1000,
          max_num_results = 3,
          sort = true,
          show_prediction_strength = true,
          run_on_every_keystroke = true,
          snipper_placeholder = "..",
          ignored_file_types = {},
        })
      end

      -- Use buffer source for `/` (if you enabled `native_menu`, this won't work anymore).
      cmp.setup.cmdline("/", {
        mapping = cmp.mapping.preset.cmdline(),
        sources = {
          { name = "buffer" },
          { name = "cmdline_history" },
        },
      })

      -- Use cmdline & path source for ':' (if you enabled `native_menu`, this won't work anymore).
      cmp.setup.cmdline(":", {
        mapping = cmp.mapping.preset.cmdline(),
        sources = cmp.config.sources({
          { name = "nvim_lsp" },
          { name = "nvim_lua" },
          { name = "path" },
          { name = "cmdline_history" },
        }, {
          { name = "cmdline" },
        }),
      })

      local cmp_autopairs = require("nvim-autopairs.completion.cmp")
      local auto_pairs = require("nvim-autopairs.completion.handlers")
      cmp.event:on("menu_opened", function(event)
        require("avim.utils.snippet").add_missing_snippet_docs(event.window)
      end)
      cmp.event:on("confirm_done", function(event)
        if vim.tbl_contains(opts.auto_brackets or {}, vim.bo.filetype) then
          require("avim.utils.snippet").auto_brackets(event.entry)
        end
        cmp_autopairs.on_confirm_done({
          filetypes = {
            -- "*" is a alias to all filetypes
            ["*"] = {
              ["("] = {
                kind = {
                  cmp.lsp.CompletionItemKind.Function,
                  cmp.lsp.CompletionItemKind.Method,
                },
                handler = auto_pairs["*"],
              },
            },
            lua = {
              ["("] = {
                kind = {
                  cmp.lsp.CompletionItemKind.Function,
                  cmp.lsp.CompletionItemKind.Method,
                },
                ---@param char string
                ---@param item item completion
                ---@param bufnr buffer number
                handler = function(char, item, bufnr)
                  -- Your handler function. Inpect with print(vim.inspect{char, item, bufnr})
                end,
              },
            },
            -- Disable for tex
            tex = false,
          },
        })
      end)

      -- History
      -- I dont like it for now, until I implement it better
      -- for _, cmd_type in ipairs({ '?', '@' }) do
      --   cmp.setup.cmdline(cmd_type, {
      --     mapping = cmp.mapping.preset.cmdline(),
      --     sources = {
      --       { name = 'cmdline_history' },
      --     },
      --   })
      -- end
    end,
  },
}

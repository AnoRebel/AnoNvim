local defaults = require("avim.core.defaults")
local icons = require("avim.icons")
local utilities = require("avim.utilities")

local CREATE_UNDO = vim.api.nvim_replace_termcodes("<c-G>u", true, true, true)
local deps = {
  { "rafamadriz/friendly-snippets" },
  { "saadparwaiz1/cmp_luasnip" },
  { "L3MON4D3/LuaSnip", build = "make install_jsregexp" },
  -- { "hrsh7th/cmp-nvim-lua" },
  -- { "hrsh7th/cmp-nvim-lsp" },
  -- { "hrsh7th/cmp-buffer" },
  -- { "hrsh7th/cmp-cmdline" },
  -- { "hrsh7th/cmp-path" },
  --
  { "iguanacucumber/mag-nvim-lsp", name = "cmp-nvim-lsp", opts = {} },
  { "iguanacucumber/mag-nvim-lua", name = "cmp-nvim-lua" },
  { "iguanacucumber/mag-buffer", name = "cmp-buffer" },
  { "iguanacucumber/mag-cmdline", name = "cmp-cmdline" },
  { "https://codeberg.org/FelipeLema/cmp-async-path" }, -- better than cmp-path
  --
  { "lukas-reineke/cmp-under-comparator" },
  { "hrsh7th/cmp-nvim-lsp-signature-help" },
  { "dmitmel/cmp-cmdline-history" },
  {
    "Exafunction/codeium.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      -- "hrsh7th/nvim-cmp",
      { "iguanacucumber/magazine.nvim", name = "nvim-cmp" },
    },
    config = function()
      require("codeium").setup({
        enable_chat = true,
        enable_cmp_source = true,
        virtual_text = {
          enabled = true,
          map_keys = true,
          key_bindings = {
            -- Accept the current completion.
            accept = "<Tab>",
            -- Accept the next word.
            -- accept_word = false,
            -- Accept the next line.
            -- accept_line = false,
            -- Clear the virtual text.
            clear = "<C-e>",
            -- Cycle to the next completion.
            -- next = "<M-]>",
            -- Cycle to the previous completion.
            -- prev = "<M-[>",
          },
        },
        config_path = utilities.get_config_dir() .. "/codeium/config.json",
        bin_path = utilities.get_runtime_dir() .. "/codeium/bin",
      })
    end,
  },
  {
    "MattiasMTS/cmp-dbee",
    dependencies = {
      { "kndndrj/nvim-dbee" },
    },
    ft = "sql",
    opts = {},
  },
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
-- check if in start tag
local function is_in_start_tag()
  local ts_utils = require("nvim-treesitter.ts_utils")
  local node = ts_utils.get_node_at_cursor()
  if not node then
    return false
  end
  return node:type() == "start_tag"
end
local sources = {
  { name = "luasnip" },
  {
    name = "nvim_lsp",
    ---@param entry cmp.Entry
    ---@param ctx cmp.Context
    entry_filter = function(entry, ctx)
      -- Check if the buffer type is 'vue'
      if ctx.filetype ~= "vue" then
        return true
      end

      -- Use a buffer-local variable to cache the result of the Treesitter check
      local bufnr = ctx.bufnr
      local cached_is_in_start_tag = vim.b[bufnr]._vue_ts_cached_is_in_start_tag
      if cached_is_in_start_tag == nil then
        vim.b[bufnr]._vue_ts_cached_is_in_start_tag = is_in_start_tag()
      end
      -- If not in start tag, return true
      if vim.b[bufnr]._vue_ts_cached_is_in_start_tag == false then
        return true
      end

      local cursor_before_line = ctx.cursor_before_line
      -- For events
      if cursor_before_line:sub(-1) == "@" then
        return entry.completion_item.label:match("^@")
        -- For props also exclude events with `:on-` prefix
      elseif cursor_before_line:sub(-1) == ":" then
        return entry.completion_item.label:match("^:") and not entry.completion_item.label:match("^:on-")
      else
        return true
      end
    end,
  },
  { name = "lazydev", group_index = 0 }, -- set group index to 0 to skip loading LuaLS completions
  { name = "nvim_lsp_signature_help" },
  { name = "nvim_lua" },
  { name = "async_path" },
  -- { name = "path" },
  { name = "codeium" },
  { name = "cmp-dbee" },
  { name = "buffer", keyword_length = 3 },
  { name = "npm", keyword_length = 3 },
}
local source_mapping = {
  luasnip = "[SNP]", -- icons.snippet .. "[SNP]",
  nvim_lsp = "[LSP]", -- icons.paragraph .. "[LSP]",
  lazydev = "[LLS]", -- icons.bomb .. "[LLS]",
  nvim_lua = "[LUA]", -- icons.bomb .. "[LUA]",
  async_path = "[PTH]", -- icons.folderOpen2 .. "[PTH]",
  -- path = "[PTH]",       -- icons.folderOpen2 .. "[PTH]",
  buffer = "[BUF]", -- icons.buffer .. "[BUF]",
  treesitter = "[TST]", -- icons.tree .. "[TST]",
  zsh = "[ZSH]", -- icons.terminal .. "[ZSH]",
  npm = "[NPM]", -- icons.terminal .. "[NPM]",
  codeium = "[CODE]", -- icons.rocket .. "[CODE]",
  cmp_dbee = "[DBEE]", -- icons.db .. "[DBEE]",
}

return {
  {
    -- "hrsh7th/nvim-cmp",
    "iguanacucumber/magazine.nvim",
    name = "nvim-cmp",
    -- version = false,
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
        return require("avim.utilities.snippet").snippet_preview(input)
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

      local compare = require("cmp.config.compare")

      local options = {
        window = {
          completion = {
            winhighlight = "Normal:NormalFloat,NormalFloat:Pmenu,Pmenu:NormalFloat", -- "Normal:Pmenu,FloatBorder:Pmenu,Search:None",
            col_offset = -3,
            side_padding = 1,
            border = "rounded", -- "none",
          },
          documentation = {
            border = "rounded",
          },
        },
        snippet = {
          expand = function(args)
            -- luasnip.lsp_expand(args.body)
            return require("avim.utilities.snippet").expand(args.body)
          end,
        },
        formatting = {
          fields = { "kind", "abbr", "menu" },
          format = function(entry, vim_item)
            local menu = source_mapping[entry.source.name]
            local label = vim_item.abbr
            local kind = icons.kind_icons[vim_item.kind]
            local maxwidth = 50

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
        --   async_path = 1,
        --   nvim_lsp = 1,
        --   lazydev = 1,
        --   luasnip = 1,
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
            c = cmp.mapping.confirm({ behavior = cmp.ConfirmBehavior.Replace, select = false }),
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
            c = cmp.mapping.confirm({ behavior = cmp.ConfirmBehavior.Replace, select = false }),
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
            compare.offset,
            compare.exact,
            compare.score,
            -- compare.scopes,
            require("cmp-under-comparator").under,
            compare.recently_used,
            compare.locality,
            compare.kind,
            -- compare.sort_text,
            compare.length,
            compare.order,
          },
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
          { name = "async_path" },
          -- { name = "path" },
          { name = "cmdline_history" },
        }, {
          { name = "cmdline" },
        }),
      })

      local cmp_autopairs = require("nvim-autopairs.completion.cmp")
      local auto_pairs = require("nvim-autopairs.completion.handlers")
      cmp.event:on("menu_opened", function(event)
        require("avim.utilities.snippet").add_missing_snippet_docs(event.window)
      end)
      cmp.event:on("menu_closed", function()
        local bufnr = vim.api.nvim_get_current_buf()
        vim.b[bufnr]._vue_ts_cached_is_in_start_tag = nil
      end)
      cmp.event:on("confirm_done", function(event)
        if vim.tbl_contains(opts.auto_brackets or {}, vim.bo.filetype) then
          require("avim.utilities.snippet").auto_brackets(event.entry)
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
    end,
  },
}

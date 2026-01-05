local autocmd = vim.api.nvim_create_autocmd
local augroup = vim.api.nvim_create_augroup
local get_icon = require("avim.icons")

vim.g.neo_tree_remove_legacy_commands = true

-- Explorer Keybind Summary:
-- <C-n>     : Toggle Neo-tree (tree view)
-- <leader>e : Toggle Neo-tree (tree view)
-- -         : Open mini.files at current file (vim-style navigation)
-- _         : Open mini.files at cwd

return {
  -- mini.files: Vim-style file navigation (like oil but lighter)
  -- Keybinds: - (current file), _ (cwd)
  {
    "nvim-mini/mini.files",
    version = false,
    init = function()
      vim.api.nvim_create_autocmd("User", {
        pattern = "MiniFilesActionRename",
        callback = function(event)
          Snacks.rename.on_rename_file(event.data.from, event.data.to)
        end,
      })

      local show_dotfiles = true
      local show_preview = false

      local filter_show = function(_)
        return true
      end
      local filter_hide = function(fs_entry)
        return not vim.startswith(fs_entry.name, ".")
      end

      local toggle_dotfiles = function()
        show_dotfiles = not show_dotfiles
        local new_filter = show_dotfiles and filter_show or filter_hide
        MiniFiles.refresh({ content = { filter = new_filter } })
      end

      local toggle_preview = function()
        show_preview = not show_preview
        MiniFiles.refresh({ windows = { preview = show_preview } })
      end

      -- Open path with system default handler
      local ui_open = function()
        local entry = MiniFiles.get_fs_entry()
        if entry then
          vim.ui.open(entry.path)
        end
      end

      -- Yank full path of entry under cursor
      local yank_path = function()
        local path = (MiniFiles.get_fs_entry() or {}).path
        if path == nil then
          return vim.notify("Cursor is not on valid entry")
        end
        vim.fn.setreg(vim.v.register, path)
      end

      -- Set focused directory as current working directory
      local set_cwd = function()
        local path = (MiniFiles.get_fs_entry() or {}).path
        if path == nil then
          return vim.notify("Cursor is not on valid entry")
        end
        vim.fn.chdir(vim.fs.dirname(path))
      end

      -- GrugFar search in directory
      local grug_search = function()
        local prefills = { paths = (MiniFiles.get_fs_entry() or {}).path }
        local grug_far = require("grug-far")
        if not grug_far.has_instance("explorer") then
          grug_far.open({
            instanceName = "explorer",
            prefills = prefills,
            staticTitle = "Find and Replace from MiniFiles",
          })
        else
          grug_far.open_instance("explorer")
          grug_far.update_instance_prefills("explorer", prefills, false)
        end
      end

      -- Split mappings
      local map_split = function(buf_id, lhs, direction)
        local rhs = function()
          local cur_target = MiniFiles.get_explorer_state().target_window
          local new_target = vim.api.nvim_win_call(cur_target, function()
            vim.cmd(direction .. " split")
            return vim.api.nvim_get_current_win()
          end)
          MiniFiles.set_target_window(new_target)
        end
        local desc = "Split " .. direction
        vim.keymap.set("n", lhs, rhs, { buffer = buf_id, desc = desc })
      end

      vim.api.nvim_create_autocmd("User", {
        pattern = "MiniFilesBufferCreate",
        callback = function(args)
          local buf_id = args.data.buf_id

          -- Toggle hidden files
          vim.keymap.set("n", "g.", toggle_dotfiles, { buffer = buf_id, desc = "Toggle hidden files" })
          vim.keymap.set("n", "H", toggle_dotfiles, { buffer = buf_id, desc = "Toggle hidden files" })

          -- Splits
          map_split(buf_id, "<C-x>", "belowright horizontal")
          map_split(buf_id, "<C-v>", "belowright vertical")
          map_split(buf_id, "<C-t>", "tab")

          -- Actions
          vim.keymap.set("n", "g~", set_cwd, { buffer = buf_id, desc = "Set cwd" })
          vim.keymap.set("n", "<C-o>", ui_open, { buffer = buf_id, desc = "OS open" })
          vim.keymap.set("n", "P", toggle_preview, { buffer = buf_id, desc = "Toggle Preview" })
          vim.keymap.set("n", "gy", yank_path, { buffer = buf_id, desc = "Yank path" })
          vim.keymap.set("n", "gs", grug_search, { buffer = buf_id, desc = "Search in directory" })

          -- .NET support
          vim.keymap.set("n", "E", function()
            local entry = require("mini.files").get_fs_entry()
            if entry == nil then
              vim.notify("No entry in mini files", vim.log.levels.WARN)
              return
            end
            local target_dir = entry.path
            if entry.fs_type == "file" then
              target_dir = vim.fn.fnamemodify(entry.path, ":h")
            end
            require("easy-dotnet").create_new_item(target_dir)
          end, { buffer = buf_id, desc = "Create from dotnet template" })
        end,
      })
    end,
    opts = {
      options = {
        permanent_delete = false,
      },
      windows = {
        width_preview = 70,
      },
    },
    keys = {
      -- - opens at current file location (like oil)
      {
        "-",
        function()
          local buf_name = vim.api.nvim_buf_get_name(0)
          local path = vim.fn.filereadable(buf_name) == 1 and buf_name or vim.fn.getcwd()
          MiniFiles.open(path)
          MiniFiles.reveal_cwd()
        end,
        mode = { "n", "v" },
        desc = "MiniFiles (current file)",
      },
      -- _ opens at cwd
      { "_", "<cmd>lua MiniFiles.open()<CR>", mode = { "n", "v" }, desc = "MiniFiles (cwd)" },
    },
  },

  -- Neo-tree: Tree-style file explorer
  -- Keybinds: <C-n>, <leader>e
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons",
      "MunifTanjim/nui.nvim",
      "antosha417/nvim-lsp-file-operations",
    },
    cmd = { "Neotree" },
    keys = {
      { "<leader>e", "<cmd>Neotree toggle=true<CR>", mode = { "n", "v" }, desc = "Neo-tree Toggle" },
      { "<C-n>", "<cmd>Neotree filesystem left reveal toggle<CR>", mode = { "n", "v" }, desc = "Neo-tree Toggle" },
    },
    init = function()
      -- Lazy-load neo-tree when opening a directory
      autocmd("BufEnter", {
        desc = "Open Neo-Tree on startup with directory",
        group = augroup("neotree_start", { clear = true }),
        once = true,
        callback = function()
          if package.loaded["neo-tree"] then
            vim.api.nvim_del_augroup_by_name("neotree_start")
            return
          else
            local stats = vim.uv.fs_stat(vim.fn.argv(0))
            if stats and stats.type == "directory" then
              require("neo-tree")
              vim.api.nvim_del_augroup_by_name("neotree_start")
            end
          end
        end,
      })
    end,
    config = function(_, opts)
      local function on_move(data)
        Snacks.rename.on_rename_file(data.source, data.destination)
      end

      local events = require("neo-tree.events")
      opts.event_handlers = opts.event_handlers or {}
      vim.list_extend(opts.event_handlers, {
        { event = events.FILE_MOVED, handler = on_move },
        { event = events.FILE_RENAMED, handler = on_move },
      })
      require("neo-tree").setup(opts)
      require("lsp-file-operations").setup()
      vim.api.nvim_create_autocmd("TermClose", {
        pattern = "*lazygit",
        callback = function()
          if package.loaded["neo-tree.sources.git_status"] then
            require("neo-tree.sources.git_status").refresh()
          end
        end,
      })
    end,
    opts = function()
      return {
        auto_clean_after_session_restore = true,
        popup_border_style = "rounded",
        sources = {
          "filesystem",
          "buffers",
          "git_status",
          "document_symbols",
        },
        sort_case_insensitive = false,
        open_files_do_not_replace_types = { "terminal", "trouble", "qf" },
        source_selector = {
          winbar = true,
          statusline = false,
          content_layout = "center",
          sources = {
            { source = "filesystem", display_name = get_icon["folderM"] .. " File" },
            { source = "buffers", display_name = get_icon["fileNoLinesBg"] .. " Bufs" },
            { source = "git_status", display_name = get_icon["gitM"] .. " Git" },
            { source = "document_symbols", display_name = get_icon["treeDiagram"] .. " Symbols" },
            { source = "diagnostics", display_name = get_icon["diagnostic"] .. " Diagnostic" },
          },
        },
        default_component_configs = {
          indent = {
            with_expanders = true,
          },
          icon = {
            folder_closed = get_icon["folderM"],
            folder_open = get_icon["folderOpen"],
            folder_empty = get_icon["folderNoBg"],
            default = get_icon["fileNoBg"],
          },
          modified = { symbol = get_icon.ui["Circle"] },
          name = {
            trailing_slash = true,
            use_git_status_colors = true,
            highlight_opened_files = true,
          },
          git_status = {
            symbols = {
              added = get_icon.gitA["Add"],
              deleted = get_icon.gitA["Remove"],
              modified = get_icon.gitA["Mod"],
              renamed = get_icon.gitA["Rename"],
              untracked = get_icon.git["untracked"],
              ignored = get_icon.gitA["Ignore"],
              unstaged = get_icon.git["unstaged"],
              staged = get_icon.git["staged"],
              conflict = get_icon.gitA["Diff"],
            },
          },
          symlink_target = {
            enabled = true,
          },
        },
        window = {
          width = 35,
          position = "left",
          auto_expand_width = true,
          mappings = {
            ["<space>"] = false,
            ["<"] = "prev_source",
            [">"] = "next_source",
            ["o"] = { "toggle_node", nowait = false },
            ["<A-r>"] = "run_command",
            ["<C-x>"] = "open_split",
            ["<C-v>"] = "open_vsplit",
            ["K"] = "show_file_details",
            ["C"] = "parent_or_close",
            ["<C-t>"] = "open_tabnew",
            ["<Tab>"] = { "open_or_preview", config = { use_float = true } },
            ["<S-Tab>"] = { "toggle_preview", config = { use_float = true } },
            ["P"] = "focus_preview",
            ["R"] = "refresh",
            ["<C-o>"] = "system_open",
            ["<S-CR>"] = "open_and_clear_filter",
            ["gf"] = "picker_find",
            ["gw"] = "picker_grep",
          },
        },
        filesystem = {
          follow_current_file = { enabled = true },
          hijack_netrw_behavior = "open_current",
          use_libuv_file_watcher = true,
          components = {
            name = function(config, node, state)
              local cc = require("neo-tree.sources.common.components")
              local result = cc.name(config, node, state)
              if node:get_depth() == 1 then
                result.text = string.gsub(state.path, "(.*[/\\])(.*)", "%2")
              end
              return result
            end,
            arrow_index = function(config, node, _)
              local arrow_filenames = vim.g.arrow_filenames
              local filepath = node:get_id()
              if arrow_filenames ~= nil then
                for _, arrowname in ipairs(arrow_filenames) do
                  if arrowname == filepath then
                    return {
                      text = " 󱍻 ",
                      highlight = config.highlight or "NeoTreeDirectoryIcon",
                    }
                  else
                    return { text = "  " }
                  end
                end
              else
                return { text = "  " }
              end
            end,
          },
          filtered_items = {
            hide_gitignored = false,
            hide_by_name = {
              ".DS_Store",
              "thumbs.db",
              "node_modules",
              "\\.cache",
            },
          },
          commands = {
            ["easy"] = function(state)
              local node = state.tree:get_node()
              local path = node.type == "directory" and node.path or vim.fs.dirname(node.path)
              require("easy-dotnet").create_new_item(path, function()
                require("neo-tree.sources.manager").refresh(state.name)
              end)
            end,
          },
          window = {
            mappings = {
              ["E"] = "easy",
              ["<CR>"] = "open_drop",
              ["<C-r>"] = "grug_far_replace",
              ["H"] = "toggle_hidden",
              ["F"] = "clear_filter",
              ["s"] = "fuzzy_sorter",
              ["Y"] = "copy_selector",
              ["gy"] = "copy_selector",
              ["a"] = { "add", config = { show_path = "relative" } },
              ["A"] = { "add_directory", config = { show_path = "relative" } },
              ["d"] = false,
              ["dd"] = "trash",
              ["dv"] = "trash_visual",
              ["dD"] = "delete",
              ["D"] = "diff_files",
              -- Navigation with HJKL
              ["h"] = "close_node_or_go_parent",
              ["l"] = "open_node_or_go_child",
              ["k"] = "go_first_sibling",
              ["j"] = "go_last_sibling",
              ["S"] = "fuzzy_finder",
              ["<C-s>"] = { "show_help", nowait = false, config = { title = "Order by", prefix_key = "<C-s>" } },
              ["<C-s>c"] = { "order_by_created", nowait = false },
              ["<C-s>d"] = { "order_by_diagnostics", nowait = false },
              ["<C-s>g"] = { "order_by_git_status", nowait = false },
              ["<C-s>m"] = { "order_by_modified", nowait = false },
              ["<C-s>n"] = { "order_by_name", nowait = false },
              ["<C-s>s"] = { "order_by_size", nowait = false },
              ["<C-s>t"] = { "order_by_type", nowait = false },
              -- Disable default o-prefixed mappings
              ["oc"] = "noop",
              ["od"] = "noop",
              ["og"] = "noop",
              ["om"] = "noop",
              ["on"] = "noop",
              ["os"] = "noop",
              ["ot"] = "noop",
            },
          },
          renderers = {
            file = {
              { "indent" },
              { "icon" },
              {
                "container",
                content = {
                  { "name", zindex = 10 },
                  { "symlink_target", zindex = 10, highlight = "NeoTreeSymbolicLinkTarget" },
                  { "clipboard", zindex = 10 },
                  { "bufnr", zindex = 10 },
                  { "modified", zindex = 20, align = "right" },
                  { "diagnostics", zindex = 20, align = "right" },
                  { "git_status", zindex = 10, align = "right" },
                  { "file_size", zindex = 10, align = "right" },
                  { "type", zindex = 10, align = "right" },
                  { "last_modified", zindex = 10, align = "right" },
                  { "created", zindex = 10, align = "right" },
                },
              },
              { "arrow_index" },
            },
          },
        },
        buffers = {
          terminals_first = false,
          window = {
            position = "right",
            mappings = {
              ["<C-s>"] = { "show_help", nowait = false, config = { title = "Order by", prefix_key = "<C-s>" } },
              ["<C-s>c"] = { "order_by_created", nowait = false },
              ["<C-s>d"] = { "order_by_diagnostics", nowait = false },
              ["<C-s>g"] = { "order_by_git_status", nowait = false },
              ["<C-s>m"] = { "order_by_modified", nowait = false },
              ["<C-s>n"] = { "order_by_name", nowait = false },
              ["<C-s>s"] = { "order_by_size", nowait = false },
              ["<C-s>t"] = { "order_by_type", nowait = false },
              ["oc"] = "noop",
              ["od"] = "noop",
              ["og"] = "noop",
              ["om"] = "noop",
              ["on"] = "noop",
              ["os"] = "noop",
              ["ot"] = "noop",
            },
          },
        },
        git_status = {
          window = {
            position = "bottom",
            mappings = {
              ["<C-s>"] = { "show_help", nowait = false, config = { title = "Order by", prefix_key = "<C-s>" } },
              ["<C-s>c"] = { "order_by_created", nowait = false },
              ["<C-s>d"] = { "order_by_diagnostics", nowait = false },
              ["<C-s>g"] = { "order_by_git_status", nowait = false },
              ["<C-s>m"] = { "order_by_modified", nowait = false },
              ["<C-s>n"] = { "order_by_name", nowait = false },
              ["<C-s>s"] = { "order_by_size", nowait = false },
              ["<C-s>t"] = { "order_by_type", nowait = false },
              ["oc"] = "noop",
              ["od"] = "noop",
              ["og"] = "noop",
              ["om"] = "noop",
              ["on"] = "noop",
              ["os"] = "noop",
              ["ot"] = "noop",
            },
          },
        },
        document_symbols = {
          follow_cursor = true,
          window = {
            mappings = {
              ["K"] = "noop",
            },
          },
        },
        commands = require("avim.utilities.explorer"),
        components = {
          name = function(config, node, state)
            local cc = require("neo-tree.sources.common.components")
            local result = cc.name(config, node, state)
            if node:get_depth() == 1 then
              result.text = string.gsub(state.path, "(.*[/\\])(.*)", "%2")
            end
            return result
          end,
        },
        event_handlers = {
          {
            event = "neo_tree_buffer_enter",
            handler = function(_)
              vim.opt_local.signcolumn = "auto"
              vim.opt_local.foldcolumn = "0"
            end,
          },
          {
            event = "neo_tree_window_after_open",
            handler = function(args)
              if args.position == "left" or args.position == "right" then
                vim.cmd("wincmd =")
              end
            end,
          },
          {
            event = "neo_tree_window_after_close",
            handler = function(args)
              if args.position == "left" or args.position == "right" then
                vim.cmd("wincmd =")
              end
            end,
          },
        },
      }
    end,
  },
}

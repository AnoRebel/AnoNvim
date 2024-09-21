local autocmd = vim.api.nvim_create_autocmd
local augroup = vim.api.nvim_create_augroup
local get_icon = require("avim.icons")

vim.g.neo_tree_remove_legacy_commands = true
autocmd("BufEnter", {
    desc = "Open Neo-Tree on startup with directory",
    group = augroup("neotree_start", { clear = true }),
    callback = function()
        if package.loaded["neo-tree"] then
            vim.api.nvim_del_augroup_by_name("neotree_start")
        else
            local stats = vim.loop.fs_stat(vim.api.nvim_buf_get_name(0))
            if stats and stats.type == "directory" then
                require("neo-tree")
                vim.api.nvim_del_augroup_by_name("neotree_start")
                vim.api.nvim_exec_autocmds("BufEnter", {})
            end
        end
    end,
})

return {
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
            float = {
                border = "rounded",
            },
            preview = {
                border = "rounded",
            },
            progress = {
                border = "rounded",
            },
            ssh = {
                border = "rounded",
            },
            keymaps_help = {
                border = "rounded",
            },
            keymaps = {
                ["-"] = false,
                ["g."] = false,
                ["<C-l>"] = false,
                ["<C-p>"] = false,
                ["<C-s>"] = "actions.change_sort",
                ["<C-v>"] = { "actions.select", opts = { vertical = true }, desc = "Open the entry in a vertical split" },
                ["C"] = "actions.parent",
                ["K"] = "actions.preview",
                ["R"] = "actions.refresh",
                ["<C-q>"] = "actions.close",
                ["<leader>q"] = "actions.close",
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
        "nvim-neo-tree/neo-tree.nvim",
        branch = "v3.x",
        dependencies = {
            "nvim-lua/plenary.nvim",
            "nvim-tree/nvim-web-devicons", -- not strictly required, but recommended
            "MunifTanjim/nui.nvim",
            "antosha417/nvim-lsp-file-operations",
        },
        cmd = { "Neotree" },
        config = function(_, opts)
            require("neo-tree").setup(opts)
            require("lsp-file-operations").setup()
        end,
        opts = function()
            -- TODO move after neo-tree improves (https://github.com/nvim-neo-tree/neo-tree.nvim/issues/707)
            return {
                auto_clean_after_session_restore = true,
                -- BUG: Nui doesnt support shadow popup borders
                popup_border_style = "rounded", -- "shadow",
                sources = {
                    "filesystem",
                    "buffers",
                    "git_status",
                    "document_symbols",
                },
                sort_case_insensitive = false,                                                        -- used when sorting files and directories in the tree
                open_files_do_not_replace_types = { "terminal", "trouble", "qf", "NvimTree", "oil" }, -- when opening files, do not use windows containing these filetypes or buftypes
                source_selector = {
                    winbar = true,
                    statusline = false,
                    content_layout = "center",
                    sources = {
                        { source = "filesystem",       display_name = get_icon["folderM"] .. " File" },
                        { source = "buffers",          display_name = get_icon["fileNoLinesBg"] .. " Bufs" },
                        { source = "git_status",       display_name = get_icon["gitM"] .. " Git" },
                        { source = "document_symbols", display_name = get_icon["treeDiagram"] .. " Symbols" },
                        { source = "diagnostics",      display_name = get_icon["diagnostic"] .. " Diagnostic" },
                    },
                },
                default_component_configs = {
                    indent = {
                        with_expanders = true, -- if nil and file nesting is enabled, will enable expanders
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
                    position = "left", -- "float" | "left" | "top/bottom" | "current"
                    auto_expand_width = true,
                    mappings = {
                        ["<space>"] = false, -- disable space until we figure out which-key disabling
                        ["e"] = function()
                            vim.api.nvim_exec("Neotree focus filesystem", true)
                        end,
                        ["b"] = function()
                            vim.api.nvim_exec("Neotree focus buffers", true)
                        end,
                        ["g"] = function()
                            vim.api.nvim_exec("Neotree focus git_status", true)
                        end,
                        ["<"] = "prev_source",
                        [">"] = "next_source",
                        ["o"] = {
                            "toggle_node",
                            nowait = false, -- disable `nowait` if you have existing combos starting with this char that you want to use
                        },
                        ["<A-r>"] = "run_command",
                        ["<C-h>"] = "open_split",
                        ["<C-v>"] = "open_vsplit",
                        K = "show_file_details",
                        C = "parent_or_close",
                        -- ["S"] = "split_with_window_picker",
                        -- ["s"] = "vsplit_with_window_picker",
                        ["<C-t>"] = "open_tabnew",
                        -- ["<cr>"] = "open_drop",
                        -- ["t"] = "open_tab_drop",
                        ["<Tab>"] = { "open_or_preview", config = { use_float = true, use_image_nvim = true } },
                        ["<S-Tab>"] = { "toggle_preview", config = { use_float = true, use_image_nvim = true } },
                        ["P"] = "focus_preview",
                        ["R"] = "refresh",
                        ["<C-o>"] = "system_open",
                        ["<S-CR>"] = "open_and_clear_filter",
                        ["tf"] = "telescope_find",
                        ["tg"] = "telescope_grep",
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
                            -- local filename = node.name
                            if arrow_filenames ~= nil then
                                for index, arrowname in ipairs(arrow_filenames) do
                                    if arrowname == filepath then
                                        return {
                                            text = " 󱍻 ", -- string.format("%d ", index), -- <-- Add your favorite harpoon like arrow here
                                            highlight = config.highlight or "NeoTreeDirectoryIcon",
                                        }
                                    else
                                        return {
                                            text = "  ",
                                        }
                                    end
                                end
                            else
                                return {
                                    text = "  ",
                                }
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
                    window = {
                        mappings = {
                            ["<CR>"] = "open_drop",
                            ["<C-r>"] = "spectre_replace",
                            -- h = "parent_or_close",
                            -- l = "child_or_open",
                            H = "toggle_hidden",
                            F = "clear_filter",
                            s = "fuzzy_sorter", -- fuzzy sorting using the fzy algorithm
                            Y = "copy_selector",
                            ["-"] = "go_parent_sibling",
                            a = {
                                "add",
                                config = {
                                    show_path = "relative", -- "none"
                                },
                            },
                            ["A"] = {
                                "add_directory",            -- also accepts the optional config.show_path option like "add". this also supports BASH style brace expansion.
                                config = {
                                    show_path = "relative", -- "none"
                                },
                            },
                            d = false,
                            ["dd"] = "trash",
                            ["dv"] = "trash_visual",
                            ["dD"] = "delete",
                            D = "diff_files",
                            -- Navigation with HJKL
                            -- https://github.com/nvim-neo-tree/neo-tree.nvim/wiki/Tips#navigation-with-hjkl
                            h = "close_node_or_go_parent",
                            l = "open_node_or_go_child",
                            -- h = "prev_sibling",
                            -- l = "next_sibling",
                            k = "go_first_sibling",
                            j = "go_last_sibling",
                            S = "fuzzy_finder",
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
                    renderers = {
                        file = {
                            { "indent" },
                            { "icon" },
                            {
                                "container",
                                content = {
                                    {
                                        "name",
                                        zindex = 10,
                                    },
                                    {
                                        "symlink_target",
                                        zindex = 10,
                                        highlight = "NeoTreeSymbolicLinkTarget",
                                    },
                                    { "clipboard",     zindex = 10 },
                                    { "bufnr",         zindex = 10 },
                                    { "modified",      zindex = 20, align = "right" },
                                    { "diagnostics",   zindex = 20, align = "right" },
                                    { "git_status",    zindex = 10, align = "right" },
                                    { "file_size",     zindex = 10, align = "right" },
                                    { "type",          zindex = 10, align = "right" },
                                    { "last_modified", zindex = 10, align = "right" },
                                    { "created",       zindex = 10, align = "right" },
                                },
                            },
                            { "arrow_index" }, --> This is what actually adds the component in where you want it
                        },
                    },
                },
                buffers = {
                    terminals_first = false, -- when true, terminals will be listed before file buffers
                    window = {
                        position = "right",
                        mappings = {
                            -- ["dd"] = "buffer_delete",
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
                commands = require("avim.utils.global_commands"),
                document_symbols = {
                    follow_cursor = true,
                },
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

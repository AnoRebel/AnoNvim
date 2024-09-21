local autocmd = vim.api.nvim_create_autocmd
local augroup = vim.api.nvim_create_augroup
local defaults = require("avim.core.defaults")
local utils = require("avim.utils")

local highlight = {
    "RainbowRed",
    "RainbowYellow",
    "RainbowBlue",
    "RainbowOrange",
    "RainbowGreen",
    "RainbowViolet",
    "RainbowCyan",
}

vim.cmd([[
  hi default link BqfPreviewFloat Normal
  hi default link BqfPreviewBorder FloatBorder
  hi default link BqfPreviewTitle Title
  hi default link BqfPreviewThumb PmenuThumb
  hi default link BqfPreviewSbar PmenuSbar
  hi default link BqfPreviewCursor Cursor
  hi default link BqfPreviewCursorLine CursorLine
  hi default link BqfPreviewRange IncSearch
  hi default link BqfPreviewBufLabel BqfPreviewRange
  hi default BqfSign ctermfg=14 guifg=Cyan
]])

-- Suda
-- vim.cmd[[let g:suda#prompt = "Password:"]]
vim.g.suda_smart_edit = 1

if defaults.features.blankline then
    vim.g.rainbow_delimiters = { highlight = highlight }
    vim.api.nvim_create_autocmd("FileType", {
        pattern = {
            "help",
            "alpha",
            "dashboard",
            "neo-tree",
            "NvimTree",
            "Trouble",
            "lazy",
            "mason",
            "notify",
            "toggleterm",
            "lazyterm",
        },
        callback = function()
            vim.b.miniindentscope_disable = true
        end,
    })
end

function _G.qftf(info)
    local items
    local ret = {}
    -- The name of item in list is based on the directory of quickfix window.
    -- Change the directory for quickfix window make the name of item shorter.
    -- It's a good opportunity to change current directory in quickfixtextfunc :)
    --
    -- local alterBufnr = vim.fn.bufname('#') -- alternative buffer is the buffer before enter qf window
    -- local root = getRootByAlterBufnr(alterBufnr)
    -- vim.cmd(('noa lcd %s'):format(vim.fn.fnameescape(root)))
    --
    if info.quickfix == 1 then
        items = vim.fn.getqflist({ id = info.id, items = 0 }).items
    else
        items = vim.fn.getloclist(info.winid, { id = info.id, items = 0 }).items
    end
    local limit = 31
    local fnameFmt1, fnameFmt2 = "%-" .. limit .. "s", "…%." .. (limit - 1) .. "s"
    local validFmt = "%s │%5d:%-3d│%s %s"
    for i = info.start_idx, info.end_idx do
        local e = items[i]
        local fname = ""
        local str
        if e.valid == 1 then
            if e.bufnr > 0 then
                fname = vim.fn.bufname(e.bufnr)
                if fname == "" then
                    fname = "[No Name]"
                else
                    fname = fname:gsub("^" .. vim.env.HOME, "~")
                end
                -- char in fname may occur more than 1 width, ignore this issue in order to keep performance
                if #fname <= limit then
                    fname = fnameFmt1:format(fname)
                else
                    fname = fnameFmt2:format(fname:sub(1 - limit))
                end
            end
            local lnum = e.lnum > 99999 and -1 or e.lnum
            local col = e.col > 999 and -1 or e.col
            local qtype = e.type == "" and "" or " " .. e.type:sub(1, 1):upper()
            str = validFmt:format(fname, lnum, col, qtype, e.text)
        else
            str = e.text
        end
        table.insert(ret, str)
    end
    return ret
end

vim.o.qftf = "{info -> v:lua._G.qftf(info)}"

vim.cmd([[
  hi BqfPreviewBorder guifg=#50a14f ctermfg=71
  hi link BqfPreviewRange Search
]])

local resizin, _ = pcall(vim.api.nvim_get_autocmds, { group = "_auto_resize" })
if not resizin then
    augroup("_auto_resize", {})
end
autocmd("VimResized", {
    group = "_auto_resize",
    pattern = "*",
    command = "tabdo wincmd =",
})
-- Goto last location when opening a buffer
autocmd("BufReadPost", {
    callback = function()
        local mark = vim.api.nvim_buf_get_mark(0, '"')
        local lcount = vim.api.nvim_buf_line_count(0)
        if mark[1] > 0 and mark[1] <= lcount then
            pcall(vim.api.nvim_win_set_cursor, 0, mark)
        end
    end,
})
-- FileType Options
local ftopt, _ = pcall(vim.api.nvim_get_autocmds, { group = "_filetype_settings" })
if not ftopt then
    augroup("_filetype_settings", {})
end
-- Enable spellchecking in markdown, text and gitcommit files
autocmd("FileType", {
    group = "_filetype_settings",
    pattern = { "*.txt", "*.tex", "*.typ", "gitcommit", "gitrebase", "svg", "hgcommit", "markdown", "text" },
    callback = function()
        vim.opt_local.wrap = true
        vim.opt_local.spell = true
    end,
})
-- Fix conceallevel for json files
vim.api.nvim_create_autocmd({ "FileType" }, {
    group = augroup("json_conceal", { clear = true }),
    pattern = { "json", "jsonc", "json5" },
    callback = function()
        vim.opt_local.conceallevel = 0
    end,
})
autocmd("FileType", {
    group = "_filetype_settings",
    pattern = "qf",
    command = "set nobuflisted",
})
local auto_create, _ = pcall(vim.api.nvim_get_autocmds, { group = "auto_create_dir" })
if not auto_create then
    augroup("auto_create_dir", {})
end
autocmd({ "BufWritePre", "FileWritePre" }, {
    desc = "Create missing parent directories on write",
    callback = function(args)
        local status, result = pcall(function()
            -- this is a remote url
            if args.file:find("://") then
                return
            end
            local dir = assert(vim.fn.fnamemodify(args.file, ":h"), ("could not get dirname: %s"):format(args.file))
            -- dir already exists
            if vim.uv.fs_stat(dir) then
                return
            end
            assert(vim.fn.mkdir(dir, "p") == 1, ("could not mkdir: %s"):format(dir))
            return assert(vim.fn.fnamemodify(dir, ":p:~"), ("could not resolve full path: %s"):format(dir))
        end)
        if type(result) == "string" then
            vim.notify(result, vim.log.levels[status and "INFO" or "ERROR"], {
                title = "Create dir on write",
            })
        end
    end,
    group = "auto_create_dir",
})
-- FileType Options
local bufopt, _ = pcall(vim.api.nvim_get_autocmds, { group = "_buffer_mappings" })
if not bufopt then
    augroup("_buffer_mappings", {})
end
autocmd("FileType", {
    group = "_buffer_mappings",
    pattern = {
        "PlenaryTestPopup",
        "notify",
        "spectre_panel",
        "tsplayground",
        "neotest-output",
        "checkhealth",
        "neotest-summary",
        "neotest-output-panel",
        "qf",
        "help",
        "man",
        "floaterm",
        "lspinfo",
        "dap-float",
        "null-ls-info",
    },
    -- command = "nnoremap <silent> <buffer> q :close<CR>",
    callback = function(event)
        vim.bo[event.buf].buflisted = false
        utils.map("n", "q", "<cmd>close<cr>", { buffer = event.buf, silent = true, nowait = true })
    end,
})
local bufferlist, _ = pcall(vim.api.nvim_get_autocmds, { group = "bufferlist" })
if not bufferlist then
    augroup("bufferlist", { clear = true })
end
autocmd({ "BufAdd", "BufEnter" }, {
    desc = "Update buffers when adding new buffers",
    group = "bufferlist",
    callback = function(args)
        if not vim.t.bufs then
            vim.t.bufs = {}
        end
        local bufs = vim.t.bufs
        if not vim.tbl_contains(bufs, args.buf) then
            table.insert(bufs, args.buf)
            vim.t.bufs = bufs
        end
        vim.t.bufs = vim.tbl_filter(utils.is_valid, vim.t.bufs)
        utils.event("BufsUpdated")
    end,
})
autocmd("BufDelete", {
    desc = "Update buffers when deleting buffers",
    group = "bufferlist",
    callback = function(args)
        for _, tab in ipairs(vim.api.nvim_list_tabpages()) do
            local bufs = vim.t[tab].bufs
            if bufs then
                for i, bufnr in ipairs(bufs) do
                    if bufnr == args.buf then
                        table.remove(bufs, i)
                        vim.t[tab].bufs = bufs
                        break
                    end
                end
            end
        end
        vim.t.bufs = vim.tbl_filter(utils.is_valid, vim.t.bufs)
        utils.event("BufsUpdated")
        vim.cmd.redrawtabline()
    end,
})
local num_tog, _ = pcall(vim.api.nvim_get_autocmds, { group = "_number_toggle" })
if not num_tog then
    augroup("_number_toggle", { clear = true })
end
local fts = {
    "qf",
    "help",
    "man",
    "lspinfo",
    "mason",
    "messages",
    "chatgpt",
    "dap-float",
    "DressingSelect",
    "alpha",
    "toggleterm",
    "terminal",
    "telescope",
    "Telescope",
    "TelescopePrompt",
    "spectre_panel",
    "startuptime",
    "NvimTree",
    "Neotree",
    "NeoTree",
    "neo-tree",
    "notify",
    "nui",
    "noice",
    "prompt",
    "Prompt",
    "popup",
    "avcheatsheet",
    "code-action-menu-menu",
    "code-action-menu-diff",
    "code-action-menu-details",
    "code-action-menu-warning",
}
autocmd({ "BufEnter", "FocusGained", "InsertLeave", "CmdlineLeave", "WinEnter" }, {
    pattern = "*",
    group = "_number_toggle",
    callback = function()
        local bufnr = vim.api.nvim_get_current_buf()
        local buf_type = vim.bo[bufnr].buftype
        local buf_filetype = vim.bo[bufnr].filetype
        -- Skip if the filetype is on the list of exclusions.
        if
            vim.b.buftype == "messages"
            or vim.tbl_contains(fts, buf_filetype)
            or vim.tbl_contains(fts, buf_type)
            or vim.tbl_contains(fts, vim.api.nvim_buf_get_option(bufnr, "buftype"))
        then
            return
        end
        if vim.o.nu and vim.api.nvim_get_mode().mode ~= "i" then
            vim.opt.relativenumber = true
            vim.cmd("redraw")
            -- vim.cmd.redrawtabline()
        end
    end,
})
autocmd({ "BufLeave", "FocusLost", "InsertEnter", "CmdlineEnter", "WinLeave" }, {
    pattern = "*",
    group = "_number_toggle",
    callback = function()
        local bufnr = vim.api.nvim_get_current_buf()
        local buf_type = vim.bo[bufnr].buftype
        local buf_filetype = vim.bo[bufnr].filetype
        -- Skip if the filetype is on the list of exclusions.
        if
            vim.b.buftype == "messages"
            or vim.tbl_contains(fts, buf_filetype)
            or vim.tbl_contains(fts, buf_type)
            or vim.tbl_contains(fts, vim.api.nvim_buf_get_option(0, "buftype"))
        then
            return
        end
        if vim.o.nu ~= true and vim.api.nvim_get_mode().mode == "i" then
            vim.opt.relativenumber = false
            vim.cmd("redraw")
        end
    end,
})

-----------------------------------------------------------------------
--- Keymaps
-----------------------------------------------------------------------
local function termcodes(str)
    return vim.api.nvim_replace_termcodes(str, true, true, true)
end
utils.map(
    "n",
    "<leader>ur",
    "<Cmd>nohlsearch<Bar>diffupdate<Bar>normal! <C-L><CR>",
    { desc = "Redraw / Clear hlsearch / Diff Update" }
)
utils.map("x", "<A-k>", "<cmd>move '<-2<CR>gv-gv", { desc = "Move Selection Up" })
utils.map("x", "<A-j>", "<cmd>move '>+1<CR>gv-gv", { desc = "Move Selection Down" })
utils.map("v", "<", "<gv", { desc = "Indent Backwards" })
utils.map("v", ">", ">gv", { desc = "Indent Forward" })
utils.map("v", "p", "p<cmd>let @+=@0<CR>", { desc = "Paste" })
-- utils.map("v", "<Tab>", ">gv", { desc = "Tab Forward" })
-- utils.map("v", "<S-Tab>", "<gv", { desc = "Tab Backwards" })
utils.map({ "i", "n", "x", "s" }, "<C-s>", "<CMD>w<CR><esc>", { desc = "Save File" })
utils.map({ "i", "n", "x", "v" }, "<C-S-w>", "<cmd>wa<CR><esc>", { desc = "Save All" })
utils.map({ "i", "n", "v" }, "<Esc>", function()
    vim.cmd.nohlsearch() -- clear highlights
    vim.cmd.echo()     -- clear short-message
    vim.api.nvim_feedkeys(termcodes("<esc>"), "n", false)
end, { desc = "Clear Visuals", silent = true })
utils.map({ "n", "v" }, "<C-,>", function()
    vim.api.nvim_feedkeys(termcodes("<esc>"), "n", false)
    -- TODO: Not sure about this one
    require("trouble").close() -- close trouble
    require("notify").dismiss() -- clear notifications
    require("noice").cmd("dismiss")
    require("goto-preview").close_all_win()
    vim.cmd.nohlsearch() -- clear highlights
    vim.cmd.echo()     -- clear short-message
end, { desc = "Clear All Visuals", silent = true })
utils.map("n", "<C-/>", "<cmd>lua require('Comment.api').toggle.linewise.current()<CR>", { desc = "Comment" })
utils.map("v", "<C-/>", function()
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<ESC>", true, false, true), "nx", false)
    require("Comment.api").toggle.linewise(vim.fn.visualmode())
end, { desc = "Comment Selection" })
utils.map("x", "<C-/>", function()
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<ESC>", true, false, true), "nx", false)
    require("Comment.api").toggle.blockwise(vim.fn.visualmode())
end, { desc = "Comment Selection" })
---
utils.map(
    { "n", "x" },
    "n",
    "<Cmd>lua require('avim.utils').nN('n')<CR>",
    { desc = "Next Search Item", noremap = true, silent = true }
)
utils.map(
    { "n", "x" },
    "N",
    "<Cmd>lua require('avim.utils').nN('N')<CR>",
    { desc = "Previous Search Item", noremap = true, silent = true }
)
utils.map(
    "n",
    "*",
    "[[*<Cmd>lua require('hlslens').start()<CR>]]",
    { desc = "Start * Search", noremap = true, silent = true }
)
utils.map(
    "n",
    "#",
    "[[#<Cmd>lua require('hlslens').start()<CR>]]",
    { desc = "Start # Search", noremap = true, silent = true }
)
utils.map(
    "n",
    "g*",
    "[[g*<Cmd>lua require('hlslens').start()<CR>]]",
    { desc = "Start g* Search", noremap = true, silent = true }
)
utils.map(
    "n",
    "g#",
    "[[g#<Cmd>lua require('hlslens').start()<CR>]]",
    { desc = "Start g# Search", noremap = true, silent = true }
)
-- Movement
if not defaults.features.kitty then
    utils.map({ "n", "v" }, "<C-h>", "<C-n><C-w>h", { desc = "Move to Left Window", silent = true })
    utils.map({ "n", "v" }, "<C-j>", "<C-n><C-w>j", { desc = "Move to Bottom Window", silent = true })
    utils.map({ "n", "v" }, "<C-k>", "<C-n><C-w>k", { desc = "Move to Top Window", silent = true })
    utils.map({ "n", "v" }, "<C-l>", "<C-n><C-w>l", { desc = "Move to Right Window", silent = true })
    utils.map({ "n", "v" }, "<A-Up>", "<cmd>resize -2<CR>", { desc = "Decrease Window Height", silent = true })
    utils.map({ "n", "v" }, "<A-Down>", "<cmd>resize +2<CR>", { desc = "Increase Window Height", silent = true })
    utils.map({ "n", "v" }, "<A-Left>", "<cmd>vertical resize -2<CR>", { desc = "Decrease Window Width", silent = true })
    utils.map({ "n", "v" }, "<A-Right>", "<cmd>vertical resize +2<CR>", { desc = "Increase Window Width", silent = true })
end
-- File System
utils.map({ "n", "v" }, "<leader>e", "<cmd>Neotree toggle=true<CR>", { desc = "[Neotree] Filemanager Toggle" })
utils.map(
    { "n", "v" },
    "<C-n>",
    "<cmd>Neotree filesystem left reveal toggle<CR>",
    { desc = "[Neotree] Filemanager Toggle" }
)
utils.map({ "n", "v" }, "-", "<cmd>Oil <CR>", { desc = "[Oil] Open Folder" }) -- vim.cmd("vsplit | wincmd |")
utils.map({ "n", "v" }, "_", "<cmd>Oil --float <CR>", { desc = "[Oil] Open Floating" })
utils.map("n", "<C-q>", "<cmd>q <CR>", { desc = "Quit Editor" })
utils.map("n", "<leader>q", "<cmd>lua require('avim.utils').close_buffer()<CR>", { desc = " Close Buffer" })
utils.map("n", ">", "<cmd>><CR>", { desc = "Indent Forwards" })
utils.map("n", "<", "<cmd><<CR>", { desc = "Indent Backward" })
-- Move lines Up and Down
utils.map("n", "<A-j>", "<cmd>move .+1<CR>==", { desc = "Move Line Up" })
utils.map("n", "<A-k>", "<cmd>move .-2<CR>==", { desc = "Move Line Down" })
utils.map("n", "<A-u>", "viwU<ESC>", { desc = "Change To Uppercase", silent = true })
if defaults.features.outline then
    -- Symbol Outline
    utils.map({ "n", "i", "v" }, "<F8>", "<cmd>Outline<CR>", { desc = "Symbols Outline", silent = true })
end
---
utils.map("i", "<A-j>", "<Esc><cmd>move .+1<CR>==gi", { desc = "Move Line Down" })
utils.map("i", "<A-k>", "<Esc><cmd>move .-2<CR>==gi", { desc = "Move Line Up" })
utils.map("i", "<A-u>", "<esc>viwUi", { desc = "Uppercase", noremap = true })
utils.map("i", "<C-h>", termcodes("<C-\\><C-n><C-w>h"), { desc = "Move to Left Window", silent = true })
utils.map("i", "<C-j>", termcodes("<C-\\><C-n><C-w>j"), { desc = "Move to Bottom Window", silent = true })
utils.map("i", "<C-k>", termcodes("<C-\\><C-n><C-w>k"), { desc = "Move to Top Window", silent = true })
utils.map("i", "<C-l>", termcodes("<C-\\><C-n><C-w>l"), { desc = "Move to Right Window", silent = true })
-- utils.map("i", "kj", "<ESC>", { desc = "Escape Insert Mode" }) -- { noremap = true, silent = true }
utils.map("i", "<C-c>", "<ESC>gg<S-v>Gy`.i", { desc = "Copy All Text" })
utils.map("n", "<C-c>", "gg<S-v>G", { desc = "Select All Text", silent = true })
-- utils.map("n", "<C-c>", "ggVG", { desc = "Select All Text", silent = true })
-- utils.map("n", "<C-A>", "ggVGy`.", { desc = "Copy All Text", silent = true })
-- Package Manager
utils.map({ "n", "v" }, "<leader>p", nil, { name = "󰏖 Package Management" })
utils.map({ "n", "v" }, "<leader>pm", "<cmd>Mason<CR>", { desc = "Mason" })
utils.map({ "n", "v" }, "<leader>pl", "<cmd>Mason<CR>", { desc = "[Mason] Log" })
utils.map({ "n", "v" }, "<leader>pr", "<cmd>Mason<CR>", { desc = "[Mason] Update" })
utils.map({ "n", "v" }, "<leader>pi", "<cmd>Lazy install<CR>", { desc = "[Lazy] Install Packages" })
utils.map({ "n", "v" }, "<leader>ps", "<cmd>Lazy home<CR>", { desc = "[Lazy] Packages Status" })
utils.map({ "n", "v" }, "<leader>pS", "<cmd>Lazy sync<CR>", { desc = "[Lazy] Sync Packages" })
utils.map({ "n", "v" }, "<leader>pc", "<cmd>Lazy check<CR>", { desc = "[Lazy] Check Updates" })
utils.map({ "n", "v" }, "<leader>pu", "<cmd>Lazy update<CR>", { desc = "[Lazy] Update Packages" })
---
utils.map({ "n", "v" }, "<leader>x", nil, { name = " Trouble" })
utils.map({ "n", "v" }, "<leader>xd", "<cmd>Trouble diagnostics toggle<CR>", { desc = "Diagnostics (Trouble)" })
utils.map(
    { "n", "v" },
    "<leader>xb",
    "<cmd>Trouble diagnostics toggle filter.buf=0<CR>",
    { desc = "Buffer Diagnostics (Trouble)" }
)
utils.map({ "n", "v" }, "<leader>xf", "<cmd>Trouble lsp_definitions toggle<CR>", { desc = "LSP Definitions (Trouble)" })
utils.map(
    { "n", "v" },
    "<leader>xc",
    "<cmd>Trouble lsp_declarations toggle<CR>",
    { desc = "LSP Declarations (Trouble)" }
)
utils.map(
    { "n", "v" },
    "<leader>xi",
    "<cmd>Trouble lsp_implementations toggle<CR>",
    { desc = "LSP Implementations (Trouble)" }
)
utils.map({ "n", "v" }, "<leader>xr", "<cmd>Trouble lsp_references toggle<CR>", { desc = "LSP References (Trouble)" })
utils.map(
    { "n", "v" },
    "<leader>xt",
    "<cmd>Trouble lsp_type_definitions toggle<CR>",
    { desc = "LSP Type Definitions (Trouble)" }
)
utils.map(
    { "n", "v" },
    "<leader>xx",
    "<cmd>Trouble lsp_document_symbols toggle<CR>",
    { desc = "LSP Document Symbols (Trouble)" }
)
utils.map(
    { "n", "v" },
    "<leader>xs",
    ":Trouble symbols toggle pinned=true results.win.relative=win results.win.position=right<CR>",
    { desc = "Symbols (Trouble)" }
)
utils.map({ "n", "v" }, "<leader>xS", ":Trouble symbols toggle focus=false<CR>", { desc = "Symbols (Trouble)" })
utils.map({ "n", "v" }, "<leader>xl", ":Trouble loclist toggle<CR>", { desc = "Location List (Trouble)" })
utils.map({ "n", "v" }, "<leader>xq", ":Trouble qflist toggle<CR>", { desc = "Quickfix List (Trouble)" })
-- utils.map({ "n", "v" }, "<leader>tx", ":Trouble telescope toggle<CR>", { desc = "Telescope (Trouble)" })
-- utils.map({ "n", "v" }, "<leader>tq", ":TodoQuickFix<CR>", { desc = "Todo Quickfix" })
-- utils.map({ "n", "v" }, "<leader>td", ":TodoTelescope<CR>", { desc = "Telescope Todo" })
-- utils.map({ "n", "v" }, "<leader>ts", ":TodoTelescope keywords=TODO,FIX,FIXME<CR>", { desc = "Todo/Fix/Fixme" })
-- utils.map({ "n", "v" }, "<leader>tS", ":TodoTrouble keywords=TODO,FIX,FIXME<CR>", { desc = "Todo/Fix/Fixme (Trouble)" })
-- utils.map(
--   { "n", "v" },
--   "gR",
--   ":Trouble lsp toggle focus=false win.position=right<CR>",
--   { desc = "LSP Definitions / references / ... (Trouble)" }
-- )
-----------------------------------------------------------------------

return {
    { "nvim-lua/plenary.nvim" },
    { "editorconfig/editorconfig-vim", event = "BufReadPre" },
    { "tpope/vim-repeat",              event = "VeryLazy" },
    { "tpope/vim-abolish",             event = "VeryLazy" },
    {
        "Tastyep/structlog.nvim",
        lazy = false,
    },
    { "lambdalisue/suda.vim", cmd = { "SudaRead", "SudaWrite" } },
    { "lbrayner/vim-rzip",    lazy = false },
    { "tpope/vim-dotenv" },
    {
        "folke/which-key.nvim",
        enabled = defaults.features.which_key,
        event = "BufWinEnter",
        opts = {
            -- add operators that will trigger motion and text object completion
            -- to enable all native operators, set the preset / operators plugin above
            operators = { gc = "Comments" },
            icons = {
                breadcrumb = "»", -- symbol used in the command line area that shows your active key combo
                separator = "", -- "➜", -- symbol used between a key and it's label
                group = " ", -- "+", -- symbol prepended to a group
            },
            window = {
                border = "rounded", -- none, single, double, shadow
            },
        },
    },
    {
        "lukas-reineke/indent-blankline.nvim",
        main = "ibl",
        enabled = defaults.features.indent_alt,
        config = function()
            require("ibl").setup({
                char = "▏",
                indent = {
                    highlight = {
                        "CursorColumn",
                        "Whitespace",
                    },
                    char = "",
                },
                whitespace = {
                    highlight = {
                        "CursorColumn",
                        "Whitespace",
                    },
                    remove_blankline_trail = false,
                },
                scope = { highlight = highlight },
            })
            local hooks = require("ibl.hooks")
            -- create the highlight groups in the highlight setup hook, so they are reset
            -- every time the colorscheme changes
            hooks.register(hooks.type.HIGHLIGHT_SETUP, function()
                vim.api.nvim_set_hl(0, "RainbowRed", { fg = "#E06C75" })
                vim.api.nvim_set_hl(0, "RainbowYellow", { fg = "#E5C07B" })
                vim.api.nvim_set_hl(0, "RainbowBlue", { fg = "#61AFEF" })
                vim.api.nvim_set_hl(0, "RainbowOrange", { fg = "#D19A66" })
                vim.api.nvim_set_hl(0, "RainbowGreen", { fg = "#98C379" })
                vim.api.nvim_set_hl(0, "RainbowViolet", { fg = "#C678DD" })
                vim.api.nvim_set_hl(0, "RainbowCyan", { fg = "#56B6C2" })
            end)
            hooks.register(hooks.type.SCOPE_HIGHLIGHT, hooks.builtin.scope_highlight_from_extmark)
        end,
    },
    {
        "shellRaining/hlchunk.nvim",
        enabled = defaults.features.indent,
        event = { "BufReadPre", "BufNewFile" },
        config = function()
            require("hlchunk").setup({
                chunk = {
                    enable = false,
                },
                indent = {
                    -- enable = true,
                    chars = {
                        "│",
                        "¦",
                        "┆",
                        "┊",
                    },
                },
                line_num = {
                    -- enable = true,
                    style = "#806d9c", -- Violet
                    -- "#c21f30", -- maple red
                    use_treesitter = true,
                },
                blank = {
                    -- enable = true,
                    chars = {
                        "․",
                    },
                    style = {
                        { vim.fn.synIDattr(vim.fn.synIDtrans(vim.fn.hlID("Whitespace")), "fg", "gui"), "" },
                    },
                },
            })
        end,
    },
    {
        "echasnovski/mini.indentscope",
        enabled = defaults.features.indent_alt,
        version = false, -- wait till new 0.7.0 release to put it back on semver
        event = { "BufReadPre", "BufNewFile" },
        config = function()
            local scope = require("mini.indentscope")
            scope.setup({
                draw = {
                    -- Animation rule for scope's first drawing. A function which, given
                    -- next and total step numbers, returns wait time (in ms). See
                    -- |MiniIndentscope.gen_animation| for builtin options. To disable
                    -- animation, use `require('mini.indentscope').gen_animation.none()`.
                    -- cubic | quartic | exponential
                    animation = scope.gen_animation.quartic({
                        easing = "in-out",
                        duration = 100,
                        unit = "total",
                    }),
                },
                -- symbol = "▏",
                -- symbol = "│",
                symbol = "╎",
                options = { try_as_border = true },
            })
        end,
    },
    { "HiPhish/rainbow-delimiters.nvim", enabled = defaults.features.indent },
    {
        "numToStr/Comment.nvim",
        event = "BufRead",
        dependencies = {
            "JoosepAlviste/nvim-ts-context-commentstring",
            { "LudoPinelli/comment-box.nvim", config = true },
        },
        config = function()
            require("Comment").setup({
                mappings = {
                    basic = true,
                    extra = true,
                    extended = true,
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
        "olimorris/persisted.nvim",
        lazy = false,
        dependencies = { "nvim-telescope/telescope.nvim" },
        config = function()
            require("persisted").setup({
                save_dir = vim.fn.stdpath("state") .. "/sessions/", -- utils.join_paths(_G.get_state_dir(), "sessions"),
                autoload = false,
                autosave = true,
                use_git_branch = true,
                should_autosave = function()
                    -- do not autosave if the alpha dashboard is the current filetype
                    if vim.bo.filetype == "alpha" then
                        return false
                    end
                    return true
                end,
            })
            utils.map({ "n", "v" }, "<A-s>", "<cmd>Telescope persisted<cr>", { desc = "List Session" })
        end,
    },
    {
        "Bekaboo/dropbar.nvim",
        enabled = defaults.features.winbar,
        -- optional, but required for fuzzy finder support
        dependencies = {
            "nvim-telescope/telescope-fzf-native.nvim", -- optional dependency
            "nvim-tree/nvim-web-devicons",        -- optional dependency
        },
    },
    {
        "utilyre/barbecue.nvim",
        name = "barbecue",
        enabled = defaults.features.winbar_alt,
        version = "*",
        dependencies = {
            "SmiteshP/nvim-navic",
            "nvim-tree/nvim-web-devicons", -- optional dependency
        },
        opts = {
            create_autocmd = false, -- prevent barbecue from updating itself automatically
            attach_navic = false, -- prevent barbecue from automatically attaching nvim-navic
            ---Filetypes not to enable winbar in.
            ---
            ---@type string[]
            exclude_filetypes = { "toggleterm", "NvimTree" },
            ---Whether to display path to file.
            ---
            ---@type boolean
            show_dirname = false,

            ---Whether to display file name.
            ---
            ---@type boolean
            show_basename = false,
        },
        config = function(_, opts)
            -- Barbecue
            local barbecue_updater, _ = pcall(vim.api.nvim_get_autocmds, { group = "barbecue.updater" })
            if not barbecue_updater then
                augroup("barbecue.updater", {})
            end
            autocmd({
                "WinScrolled", -- or WinResized on NVIM-v0.9 and higher
                "WinResized",
                "BufWinEnter",
                "CursorHold",
                "InsertLeave",

                -- include this if you have set `show_modified` to `true`
                "BufModifiedSet",
            }, {
                group = "barbecue.updater",
                callback = function()
                    require("barbecue.ui").update()
                end,
            })
        end,
    },
    {
        "lewis6991/satellite.nvim",
        event = "VeryLazy",
        opts = {
            excluded_filetypes = { "neo-tree", "NvimTree" },
        },
    },
    {
        "VidocqH/lsp-lens.nvim",
        config = function()
            local SymbolKind = vim.lsp.protocol.SymbolKind
            require("lsp-lens").setup({
                enable = true,
                include_declaration = true, -- Reference include declaration
                sections = {        -- Enable / Disable specific request, formatter example looks 'Format Requests'
                    definition = true,
                    references = true,
                    implements = true,
                    git_authors = false,
                },
                target_symbol_kinds = {
                    SymbolKind.Function,
                    SymbolKind.Method,
                    SymbolKind.Interface,
                    SymbolKind.Class,
                    SymbolKind.Struct,
                },
            })
        end,
    },
    {
        "hedyhli/outline.nvim",
        enabled = defaults.features.outline,
        cmd = { "Outline", "OutlineOpen" },
        opts = { show_numbers = true, show_relative_numbers = true, auto_preview = true },
    },
    {
        "otavioschwanck/arrow.nvim",
        event = "VeryLazy",
        config = function()
            require("arrow").setup({
                show_icons = true,
                leader_key = ";",  -- Recommended to be a single key
                buffer_leader_key = ",", -- Per Buffer Mappings
                separate_by_branch = true, -- Bookmarks will be separated by git branch
                always_show_path = false,
                window = {
                    border = "rounded",
                },
                per_buffer_config = {
                    satellite = { -- defualt to nil, display arrow index in scrollbar at every update
                        enable = true,
                    },
                },
            })
            -- utils.map({ "n", "v" }, "H", '<cmd>lua require("arrow.persist").previous()<CR>', { desc = "" })
            -- utils.map({ "n", "v" }, "L", '<CMD>lua require("arrow.persist").next()<CR>', { desc = "" })
            -- utils.map({ "n", "v" }, "<C-s>", '<CMD> lua require("arrow.persist").toggle()<CR>', { desc = "" })
        end,
    },
    {
        "kevinhwang91/nvim-bqf",
        ft = { "qf" },
        command = { "BqfToggle", "BqfAutoToggle" },
        opts = {
            auto_enable = true,
            auto_resize_height = true, -- highly recommended enable
            func_map = {
                split = "h",
                vsplit = "v",
            },
            filter = {
                fzf = {
                    extra_opts = { "--bind", "ctrl-o:toggle-all", "--delimiter", "│", "--prompt", "> " },
                },
            },
        },
    },
    {
        "smoka7/multicursors.nvim",
        event = "VeryLazy",
        dependencies = {
            "nvimtools/hydra.nvim",
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
                hint = {
                    position = "bottom",
                    float_opts = {
                        border = "rounded",
                        -- border = { "┏", "━", "┓", "┃", "┛", "━", "┗", "┃" },
                    },
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
    {
        "brenton-leighton/multiple-cursors.nvim",
        enabled = false, -- defaults.features.multicursors,
        version = "*", -- Use the latest tagged version
        opts = {},   -- This causes the plugin setup function to be called
        keys = {
            {
                "<C-j>",
                "<Cmd>MultipleCursorsAddDown<CR>",
                mode = { "n", "x" },
                desc = "Add cursor and move down",
            },
            {
                "<C-k>",
                "<Cmd>MultipleCursorsAddUp<CR>",
                mode = { "n", "x" },
                desc = "Add cursor and move up",
            },

            {
                "<C-Up>",
                "<Cmd>MultipleCursorsAddUp<CR>",
                mode = { "n", "i", "x" },
                desc = "Add cursor and move up",
            },
            {
                "<C-Down>",
                "<Cmd>MultipleCursorsAddDown<CR>",
                mode = { "n", "i", "x" },
                desc = "Add cursor and move down",
            },

            {
                "<C-LeftMouse>",
                "<Cmd>MultipleCursorsMouseAddDelete<CR>",
                mode = { "n", "i" },
                desc = "Add or remove cursor",
            },

            {
                "<Leader>a",
                "<Cmd>MultipleCursorsAddMatches<CR>",
                mode = { "n", "x" },
                desc = "Add cursors to cword",
            },
            {
                "<Leader>A",
                "<Cmd>MultipleCursorsAddMatchesV<CR>",
                mode = { "n", "x" },
                desc = "Add cursors to cword in previous area",
            },

            {
                "<Leader>d",
                "<Cmd>MultipleCursorsAddJumpNextMatch<CR>",
                mode = { "n", "x" },
                desc = "Add cursor and jump to next cword",
            },
            {
                "<Leader>D",
                "<Cmd>MultipleCursorsJumpNextMatch<CR>",
                mode = { "n", "x" },
                desc = "Jump to next cword",
            },

            {
                "<Leader>l",
                "<Cmd>MultipleCursorsLock<CR>",
                mode = { "n", "x" },
                desc = "Lock virtual cursors",
            },
        },
    },
    {
        "kylechui/nvim-surround",
        version = "*", -- Use for stability; omit to use `main` branch for the latest features
        event = "VeryLazy",
        config = true,
    },
    -- Editor Visuals
    {
        "windwp/nvim-autopairs",
        event = "BufRead",
        opts = {
            fast_wrap = {},
            disable_filetype = { "TelescopePrompt", "vim", "clap_input" },
        },
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
        opts = {
            auto_load = true,
            close_on_bdelete = true,
            syntax = true,
            theme = "dark",
            update_on_change = true,
            app = "min-browser", -- vim.env.BROWSER,
            filetype = { "markdown" },
            throttle_at = 200000,
            throttle_time = "auto",
        },
        ft = "markdown",
    },
    {
        "folke/trouble.nvim",
        cmd = { "Trouble", "TroubleRefresh", "TroubleToggle", "TroubleClose" },
        opts = {
            keys = {
                j = "next",
                k = "prev",
                ["<Tab>"] = "jump",
            },
            ---@type table<string, trouble.Mode>
            modes = {
                test = {
                    mode = "diagnostics",
                    preview = {
                        type = "split",
                        relative = "win",
                        position = "right",
                        size = 0.3,
                    },
                },
                -- preview_float = {
                --   mode = "diagnostics",
                --   preview = {
                --     type = "float",
                --     relative = "editor",
                --     border = "rounded",
                --     title = "Preview",
                --     title_pos = "center",
                --     position = { 0, -2 },
                --     size = { width = 0.3, height = 0.3 },
                --     zindex = 200,
                --   },
                -- },
            },
        },
    },
}

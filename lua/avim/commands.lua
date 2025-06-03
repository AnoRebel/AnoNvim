---@class avim.commands
---@field setup fun(): nil # Setup AnoNvim commands
local M = {}

local api = vim.api
local autocmd = api.nvim_create_autocmd
local usercmd = api.nvim_create_user_command
local utilities = require("avim.utilities")

local function augroup(name, opts)
  if opts == nil then
    opts = { clear = true }
  end
  return api.nvim_create_augroup("avim_" .. name, opts)
end

---Create user commands
function M.setup()
  -- Update command
  usercmd("AnoUpdate", function(opts)
    local update = require("avim.update")
    local args = opts.fargs
    local options = {
      interactive = true,
      force = false,
      backup = true,
      branch = "main",
      show_changes = true,
    }

    -- Parse arguments
    for _, arg in ipairs(args) do
      if arg == "--no-interactive" or arg == "-n" then
        options.interactive = false
      elseif arg == "--force" or arg == "-f" then
        options.force = true
      elseif arg == "--no-backup" then
        options.backup = false
      elseif arg:match("^--branch=") then
        options.branch = arg:match("^--branch=(.*)")
      elseif arg == "--no-changes" then
        options.show_changes = false
      end
    end

    -- Execute update
    update.execute(options)
  end, {
    nargs = "*",
    desc = "Update AnoNvim",
    complete = function(arglead, cmdline, cursorpos)
      local options = {
        "--no-interactive",
        "-n",
        "--force",
        "-f",
        "--no-backup",
        "--branch=main",
        "--branch=develop",
        "--no-changes",
      }

      if arglead == "" then
        return options
      end

      return vim.tbl_filter(function(opt)
        return opt:match("^" .. vim.pesc(arglead))
      end, options)
    end,
  })

  -- Check for updates command
  usercmd("AnoCheckUpdate", function()
    local update = require("avim.update")
    local info = update.check()

    if info.has_update then
      local msg = string.format(
        "Update available!\nCurrent: %s\nLatest: %s\n\nRun :AnoUpdate to update",
        info.current_version,
        info.latest_version
      )
      utilities.notify(msg, "info")
    else
      utilities.notify("AnoNvim is up to date!", "info")
    end
  end, {
    desc = "Check for AnoNvim updates",
  })

  -- Show update history command
  usercmd("AnoUpdateHistory", function()
    local update = require("avim.update")
    local info = update.check()

    if vim.tbl_isempty(info.changes) then
      utilities.notify("No changes found", "warn")
      return
    end

    vim.ui.select(info.changes, {
      prompt = "Recent changes:",
      format_item = function(item)
        return "  " .. item
      end,
    }, function() end)
  end, {
    desc = "Show AnoNvim update history",
  })
  autocmd("User", {
    pattern = "GitConflictDetected",
    callback = function()
      vim.notify("Conflict detected in " .. vim.fn.expand("<afile>"))
    end,
  })
  autocmd("User", {
    pattern = "GitConflictResolved",
    callback = function()
      vim.notify("Conflict resolved in " .. vim.fn.expand("<afile>"))
    end,
  })
  autocmd("VimResized", {
    group = augroup("auto_resize"),
    callback = function()
      local current_tab = vim.fn.tabpagenr()
      vim.cmd("tabdo wincmd =")
      vim.cmd("tabnext " .. current_tab)
    end,
  })
  -- Goto last location when opening a buffer
  autocmd("BufReadPost", {
    callback = function(event)
      local exclude = { "gitcommit" }
      local buf = event.buf
      if vim.tbl_contains(exclude, vim.bo[buf].filetype) or vim.b[buf].avim_last_loc then
        return
      end
      vim.b[buf].avim_last_loc = true
      local mark = api.nvim_buf_get_mark(buf, '"')
      local lcount = api.nvim_buf_line_count(buf)
      if mark[1] > 0 and mark[1] <= lcount then
        pcall(api.nvim_win_set_cursor, 0, mark)
      end
    end,
  })
  -- FileType Options
  -- Enable spellchecking in markdown, text and gitcommit files
  autocmd("FileType", {
    group = augroup("filetype_settings"),
    pattern = {
      "*.txt",
      "*.tex",
      "*.typ",
      "plaintex",
      "typst",
      "gitcommit",
      "gitrebase",
      "svg",
      "hgcommit",
      "markdown",
      "text",
    },
    callback = function()
      vim.opt_local.wrap = true
      vim.opt_local.spell = true
    end,
  })
  -- Fix conceallevel for json files
  autocmd({ "FileType" }, {
    group = augroup("json_conceal"),
    pattern = { "json", "jsonc", "json5" },
    callback = function()
      vim.opt_local.conceallevel = 0
    end,
  })
  autocmd({ "BufWritePre", "FileWritePre" }, {
    group = augroup("auto_create_dir"),
    desc = "Create missing parent directories on write",
    callback = function(args)
      -- if args.match:match("^%w%w+:[\\/][\\/]") then
      --   return
      -- end
      -- local file = vim.uv.fs_realpath(args.match) or args.match
      -- vim.fn.mkdir(vim.fn.fnamemodify(file, ":p:h"), "p")
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
  })
  -- FileType Options
  autocmd("FileType", {
    group = augroup("buffer_mappings"),
    pattern = {
      "PlenaryTestPopup",
      "notify",
      "spectre_panel",
      "tsplayground",
      "neotest-output",
      "checkhealth",
      "qf",
      "help",
      "man",
      "floaterm",
      "startuptime",
      "tsplayground",
      "lspinfo",
      "gitsigns-blame",
      "grug-far",
      "null-ls-info",
    },
    -- command = "nnoremap <silent> <buffer> q :close<CR>",
    callback = function(event)
      vim.bo[event.buf].buflisted = false
      vim.schedule(function()
        utilities.map("n", "q", function()
          vim.cmd("close")
          pcall(vim.api.nvim_buf_delete, event.buf, { force = true })
        end, { desc = "Quit buffer", buffer = event.buf, silent = true, nowait = true })
      end)
    end,
  })
  -- make it easier to close man-files when opened inline
  autocmd("FileType", {
    group = augroup("man_unlisted"),
    pattern = { "man", "qf" },
    callback = function(event)
      vim.bo[event.buf].buflisted = false
    end,
  })
  autocmd({ "BufAdd", "BufEnter" }, {
    desc = "Update buffers when adding new buffers",
    group = augroup("bufferlist"),
    callback = function(args)
      if not vim.t.bufs then
        vim.t.bufs = {}
      end
      local bufs = vim.t.bufs
      if not vim.tbl_contains(bufs, args.buf) then
        table.insert(bufs, args.buf)
        vim.t.bufs = bufs
      end
      vim.t.bufs = vim.tbl_filter(utilities.is_valid, vim.t.bufs)
      utilities.event("BufsUpdated")
    end,
  })
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
    group = augroup("number_toggle"),
    callback = function()
      local bufnr = api.nvim_get_current_buf()
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
      if vim.o.nu and api.nvim_get_mode().mode ~= "i" then
        vim.opt.relativenumber = true
        vim.cmd("redraw")
        -- vim.cmd.redrawtabline()
      end
    end,
  })
  autocmd({ "BufLeave", "FocusLost", "InsertEnter", "CmdlineEnter", "WinLeave" }, {
    pattern = "*",
    group = augroup("_number_toggle"),
    callback = function()
      local bufnr = api.nvim_get_current_buf()
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
      if vim.o.nu ~= true and api.nvim_get_mode().mode == "i" then
        vim.opt.relativenumber = false
        vim.cmd("redraw")
      end
    end,
  })
  autocmd("FileType", {
    group = augroup("filetype_settings"),
    pattern = { "lua" },
    desc = "fix gf functionality inside .lua files",
    callback = function()
      ---@diagnostic disable: assign-type-mismatch
      -- credit: https://github.com/sam4llis/nvim-lua-gf
      vim.opt_local.include = [[\v<((do|load)file|require|reload)[^''"]*[''"]\zs[^''"]+]]
      vim.opt_local.includeexpr = "substitute(v:fname,'\\.','/','g')"
      vim.opt_local.suffixesadd:prepend(".lua")
      vim.opt_local.suffixesadd:prepend("init.lua")

      for _, path in pairs(api.nvim_list_runtime_paths()) do
        vim.opt_local.path:append(path .. "/lua")
      end
    end,
  })
  autocmd({ "FocusGained", "TermClose", "TermLeave" }, { command = "checktime" })
  -- Highlight yanked text
  autocmd("TextYankPost", {
    group = augroup("general_settings"),
    pattern = "*",
    desc = "Highlight text on yank",
    callback = function()
      (vim.hl or vim.highlight).on_yank({ higroup = "Search", timeout = 200 })
    end,
  })
  autocmd("WinEnter", {
    group = augroup("beacon_cursor_line"),
    pattern = "*",
    desc = "Hide cursor line on inactive windows",
    command = "setlocal cursorline",
  })
  autocmd("WinLeave", {
    group = augroup("_beacon_cursor_line"),
    pattern = "*",
    desc = "Hide cursor line on inactive windows",
    command = "setlocal nocursorline",
  })
  autocmd("LspAttach", {
    group = augroup("_tailwind_filter"),
    desc = "Filter tailwindcss completions to reduced lag",
    callback = function()
      for _, client in pairs(vim.lsp.get_clients({})) do
        if client.name == "tailwindcss" then
          client.server_capabilities.completionProvider.triggerCharacters =
            { '"', "'", "`", ".", "(", "[", "!", "/", ":" }
        end
      end
    end,
  })
  autocmd("LspDetach", {
    group = augroup("_user_lsp_config", { clear = false }),
    desc = "Kill the LS process if no buffers are attached to the client",
    callback = function(args)
      vim.lsp.buf.clear_references()

      vim.defer_fn(function()
        local client = vim.lsp.get_client_by_id(args.data.client_id)

        if client then
          local clients = vim.lsp.get_clients({ id = args.data.client_id })
          local count = 0

          if clients and #clients > 0 then
            local remaining_client = clients[1]

            if remaining_client.attached_buffers then
              for buf_id in pairs(remaining_client.attached_buffers) do
                if buf_id ~= args.buf then
                  count = count + 1
                end
              end
            end
          end
          if count == 0 then
            vim.notify("Stopping lingering Language Server", vim.log.levels.INFO, { title = "LSP" })
            client:stop()
          end
        end
      end, 200)
    end,
  })
end

return M

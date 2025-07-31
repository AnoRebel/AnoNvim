local Utils = require("avim.utilities")

---@class avim.utilities.lsp
---@field get_clients fun(opts?: lsp.Client.filter): vim.lsp.Client[]
---@field get_pkg_path fun(pkg: string, path?: string, opts?: {warn?: boolean}): string
---@field get_plugin fun(name: string): table
---@field get_plugin_path fun(name: string, path?: string): string
---@field has fun(client: vim.lsp.Client, method: string): boolean
---@field has_plugin fun(name: string): boolean
---@field is_loaded fun(name: string): boolean
---@field on_attach fun(fn: fun(client: vim.lsp.Client, buffer: number), name?: string): nil
---@field on_dynamic_capability fun(fn: fun(client: vim.lsp.Client, buffer: number), opts?: {group?: integer}): nil
---@field on_supports_method fun(method: string, fn: fun(client: vim.lsp.Client, buffer: number)): nil
---@field opts fun(name: string): table
---@field peek_or_hover fun(): nil
---@field setup fun(): nil
---@field action table
---@field binary_exists fun(bin: any): boolean
---@field disable fun(server: string, cond: fun( root_dir, config): boolean)
---@field empty_output fun(data: any): boolean
---@field execute fun(opts: LspCommand)
---@field format fun(bufnr: any)
---@field get_config fun(server: any): _.lspconfig.options
---@field is_enabled fun(server: any)
---@field move_to_file_refactor fun(client: vim.lsp.Client, buffer: any)
---@field on_rename fun(from: string, to: string, rename?: fun())
---@field quick_type fun(_: any, src: string, pkg_name: string, top_level: any)
---@field rename_file fun()
---@field _check_methods fun(client: vim.lsp.Client, buffer: any)
---@field _supports_method table<string, table<vim.lsp.Client, table<number, boolean>>>
local M = {}

---@alias lsp.Client.filter {id?: number, bufnr?: number, name?: string, method?: string, filter?:fun(client: lsp.Client):boolean}

local api = vim.api
local lsp = vim.lsp

-- use lsp formatting if it's available (and if it's good)
-- otherwise, fall back to null-ls
local preferred_formatting_clients = { "null-ls" }
local fallback_formatting_client = "eslint"

-- prevent repeated lookups
local buffer_client_ids = {}

--- Gets a path to a package in the Mason registry.
--- Prefer this to `get_package`, since the package might not always be
--- available yet and trigger errors.
---@param pkg string
---@param path? string
---@param opts? { warn?: boolean }
M.get_pkg_path = function(pkg, path, opts)
  pcall(require, "mason") -- make sure Mason is loaded. Will fail when generating docs
  local root = vim.env.MASON or Utils.join_paths(Utils.get_runtime_dir(), "mason")
  opts = opts or {}
  opts.warn = opts.warn == nil and true or opts.warn
  path = path or ""
  -- local ret = Utils.join_paths(root, "packages", pkg, path)
  local ret = root .. "/packages/" .. pkg .. "/" .. path
  if opts.warn and not vim.loop.fs_stat(ret) and not require("lazy.core.config").headless() then
    vim.notify(
      ("Mason package path not found for **%s**:\n- `%s`\nYou may need to force update the package."):format(pkg, path),
      "warn"
    )
  end
  return ret
end

M.peek_or_hover = function()
  local winid = require("ufo").peekFoldedLinesUnderCursor()
  if not winid then
    -- vim.lsp.buf.hover()
    require("hover").hover()
  end
end

---@param name string
function M.get_plugin(name)
  return require("lazy.core.config").spec.plugins[name]
end

---@param name string
---@param path string?
function M.get_plugin_path(name, path)
  local plugin = M.get_plugin(name)
  path = path and "/" .. path or ""
  return plugin and (plugin.dir .. path)
end

---@param plugin string
function M.has_plugin(plugin)
  return M.get_plugin(plugin) ~= nil
end

function M.is_loaded(name)
  local Config = require("lazy.core.config")
  return Config.plugins[name] and Config.plugins[name]._.loaded
end

---@param name string
function M.opts(name)
  local plugin = M.get_plugin(name)
  if not plugin then
    return {}
  end
  local Plugin = require("lazy.core.plugin")
  return Plugin.values(plugin, "opts", false)
end

---@param fn fun(client:vim.lsp.Client, buffer):boolean?
---@param opts? {group?: integer}
function M.on_dynamic_capability(fn, opts)
  return api.nvim_create_autocmd("User", {
    pattern = "LspDynamicCapability",
    group = opts and opts.group or nil,
    callback = function(args)
      local client = lsp.get_client_by_id(args.data.client_id)
      local buffer = args.data.buffer ---@type number
      if client then
        return fn(client, buffer)
      end
    end,
  })
end

-- This function resolves a difference between neovim nightly (version 0.11) and stable (version 0.10)
---@param client vim.lsp.Client
---@param method vim.lsp.protocol.Method
---@param bufnr? integer some lsp support methods only in specific files
---@return boolean
local function client_supports_method(client, method, bufnr)
  if vim.fn.has("nvim-0.11") == 1 then
    return client:supports_method(method, bufnr)
  else
    return client.supports_method(method, { bufnr = bufnr })
  end
end

---@param method string
---@param fn fun(client:vim.lsp.Client, buffer)
function M.on_supports_method(method, fn)
  M._supports_method[method] = M._supports_method[method] or setmetatable({}, { __mode = "k" })
  return api.nvim_create_autocmd("User", {
    pattern = "LspSupportsMethod",
    callback = function(args)
      local client = lsp.get_client_by_id(args.data.client_id)
      local buffer = args.data.buffer ---@type number
      -- if client and client_supports_method(client, method, buffer) then
      if client and method == args.data.method then
        return fn(client, buffer)
      end
    end,
  })
end

function M.rename_file()
  local buf = api.nvim_get_current_buf()
  local old = assert(require("avim.utilities.root").realpath(vim.api.nvim_buf_get_name(buf)))
  local root = assert(require("avim.utilities.root").realpath(require("avim.utilities.root").get({ normalize = true })))
  assert(old:find(root, 1, true) == 1, "File not in project root")

  local extra = old:sub(#root + 2)

  vim.ui.input({
    prompt = "New File Name: ",
    default = extra,
    completion = "file",
  }, function(new)
    if not new or new == "" or new == extra then
      return
    end
    new = Utils.norm(root .. "/" .. new)
    vim.fn.mkdir(vim.fs.dirname(new), "p")
    M.on_rename(old, new, function()
      vim.fn.rename(old, new)
      vim.cmd.edit(new)
      api.nvim_buf_delete(buf, { force = true })
      vim.fn.delete(old)
    end)
  end)
end

---@param from string
---@param to string
---@param rename? fun()
function M.on_rename(from, to, rename)
  local changes = {
    files = { {
      oldUri = vim.uri_from_fname(from),
      newUri = vim.uri_from_fname(to),
    } },
  }

  local clients = M.get_clients()
  for _, client in ipairs(clients) do
    if client.supports_method("workspace/willRenameFiles") then
      local resp = client.request_sync("workspace/willRenameFiles", changes, 1000, 0)
      if resp and resp.result ~= nil then
        lsp.util.apply_workspace_edit(resp.result, client.offset_encoding)
      end
    end
  end

  if rename then
    rename()
  end

  for _, client in ipairs(clients) do
    -- if client_supports_method(client, "workspace/didRenameFiles") then
    if client.supports_method("workspace/didRenameFiles") then
      client.notify("workspace/didRenameFiles", changes)
    end
  end
end

---@return _.lspconfig.options
function M.get_config(server)
  local configs = require("lspconfig.configs")
  return rawget(configs, server)
end

function M.is_enabled(server)
  local c = M.get_config(server)
  return c and c.enabled ~= false
end

---@param server string
---@param cond fun( root_dir, config): boolean
function M.disable(server, cond)
  local util = require("lspconfig.util")
  local def = M.get_config(server)
  ---@diagnostic disable-next-line: undefined-field
  def.document_config.on_new_config = util.add_hook_before(def.document_config.on_new_config, function(config, root_dir)
    if cond(root_dir, config) then
      config.enabled = false
    end
  end)
end

M.move_to_file_refactor = function(client, buffer)
  client.commands["_typescript.moveToFileRefactoring"] = function(command, ctx)
    ---@type string, string, lsp.Range
    local action, uri, range = unpack(command.arguments)

    local function move(newf)
      client.request("workspace/executeCommand", {
        command = command.command,
        arguments = { action, uri, range, newf },
      })
    end

    local fname = vim.uri_to_fname(uri)
    client.request("workspace/executeCommand", {
      command = "typescript.tsserverRequest",
      arguments = {
        "getMoveToRefactoringFileSuggestions",
        {
          file = fname,
          startLine = range.start.line + 1,
          startOffset = range.start.character + 1,
          endLine = range["end"].line + 1,
          endOffset = range["end"].character + 1,
        },
      },
    }, function(_, result)
      ---@type string[]
      local files = result.body.files
      table.insert(files, 1, "Enter new path...")
      vim.ui.select(files, {
        prompt = "Select move destination:",
        format_item = function(f)
          return vim.fn.fnamemodify(f, ":~:.")
        end,
      }, function(f)
        if f and f:find("^Enter new path") then
          vim.ui.input({
            prompt = "Enter move destination:",
            default = vim.fn.fnamemodify(fname, ":h") .. "/",
            completion = "file",
          }, function(newf)
            return newf and move(newf)
          end)
        elseif f then
          move(f)
        end
      end)
    end)
  end
end

---@param opts? lsp.Client.filter
M.get_clients = function(opts)
  ---@type vim.lsp.Client[]
  local ret = {}
  if lsp.get_clients then
    ret = lsp.get_clients(opts)
  else
    ---@diagnostic disable-next-line: deprecated
    ret = lsp.get_active_clients(opts)
  end
  if opts and opts.method then
    ---@param client vim.lsp.Client
    ret = vim.tbl_filter(function(client)
      -- return client_supports_method(client, opts.method, opts.bufnr)
      return client.supports_method(opts.method, { bufnr = opts.bufnr })
    end, ret)
  end
  return opts and opts.filter and vim.tbl_filter(opts.filter, ret) or ret
end

---@param on_attach fun(client:vim.lsp.Client, buffer)
---@param name? string
function M.on_attach(on_attach, name)
  return api.nvim_create_autocmd("LspAttach", {
    callback = function(args)
      local buffer = args.buf ---@type number
      local client = lsp.get_client_by_id(args.data.client_id)
      if client and (not name or client.name == name) then
        return on_attach(client, buffer)
      end
    end,
  })
end

---@type table<string, table<vim.lsp.Client, table<number, boolean>>>
M._supports_method = {}

function M.setup()
  local register_capability = lsp.handlers["client/registerCapability"]
  lsp.handlers["client/registerCapability"] = function(err, res, ctx)
    ---@diagnostic disable-next-line: no-unknown
    local ret = register_capability(err, res, ctx)
    local client = lsp.get_client_by_id(ctx.client_id)
    if client then
      for buffer in pairs(client.attached_buffers) do
        api.nvim_exec_autocmds("User", {
          pattern = "LspDynamicCapability",
          data = { client_id = client.id, buffer = buffer },
        })
      end
    end
    return ret
  end
  M.on_attach(M._check_methods)
  M.on_dynamic_capability(M._check_methods)
end

---@param client vim.lsp.Client
function M._check_methods(client, buffer)
  -- don't trigger on invalid buffers
  if not api.nvim_buf_is_valid(buffer) then
    return
  end
  -- don't trigger on non-listed buffers
  if not vim.bo[buffer].buflisted then
    return
  end
  -- don't trigger on nofile buffers
  if vim.bo[buffer].buftype == "nofile" then
    return
  end
  for method, clients in pairs(M._supports_method) do
    clients[client] = clients[client] or {}
    if not clients[client][buffer] then
      -- if client_supports_method(client, method, buffer) then
      if client.supports_method and client.supports_method(method, { bufnr = buffer }) then
        clients[client][buffer] = true
        api.nvim_exec_autocmds("User", {
          pattern = "LspSupportsMethod",
          data = { client_id = client.id, buffer = buffer, method = method },
        })
      end
    end
  end
end

---@param method string|string[]
M.has = function(buffer, method)
  if type(method) == "table" then
    for _, m in ipairs(method) do
      if M.has(buffer, m) then
        return true
      end
    end
    return false
  end
  method = method:find("/") and method or "textDocument/" .. method
  local clients = M.get_clients({ bufnr = buffer })
  for _, client in ipairs(clients) do
    -- if client_supports_method(client, method, buffer) then
    if client.supports_method(method) then
      return true
    end
  end
  return false
end

---@class LspCommand: lsp.ExecuteCommandParams
---@field open? boolean
---@field handler? lsp.Handler

---@param opts LspCommand
M.execute = function(opts)
  local params = {
    command = opts.command,
    arguments = opts.arguments,
  }
  if opts.open then
    require("trouble").open({
      mode = "lsp_command",
      params = params,
    })
  else
    return lsp.buf_request(0, "workspace/executeCommand", params, opts.handler)
  end
end

M.action = setmetatable({}, {
  __index = function(_, action)
    return function()
      lsp.buf.code_action({
        apply = true,
        context = {
          only = { action },
          diagnostics = {},
        },
      })
    end
  end,
})

function M.binary_exists(bin)
  if vim.fn.executable(bin) == 1 then
    return true
  end
  -- M.show_error(
  -- 	"No Binary",
  -- 	string.format("%s does not exist. Run `npm i -g quicktype or yarn add global quicktype`", bin)
  -- )
  vim.notify(
    string.format("%s does not exist. Run `npm i -g quicktype or yarn add global quicktype`", bin),
    vim.log.levels.WARN,
    { title = "AnoNvim" }
  )
  return false
end

function M.empty_output(data)
  if #data == 0 then
    return true
  end
  if #data == 1 and data[1] == "" then
    return true
  end

  return false
end

function M.quick_type(_, src, pkg_name, top_level)
  if not M.binary_exists("quicktype") then
    local cmd = { "npm", "install", "-g", "quicktype" }
    vim.notify("Installing quicktype ...", vim.log.levels.INFO, { title = "AnoNvim" })
    vim.fn.jobstart(cmd, {
      on_exit = function(_, code, _)
        if code == 0 then
          vim.notify("Installed quicktype", vim.log.levels.INFO, { title = "AnoNvim" })
        end
      end,
      on_stderr = function(_, data, _)
        local results = table.concat(data, "\n")
        vim.notify(results, vim.log.levels.ERROR, { title = "AnoNvim" })
      end,
    })
  end
  local prefix = "GoQuickType"
  local cur_line = vim.fn.line(".")
  local cmd = {
    "quicktype",
    "--src",
    src,
    "--lang",
    "go",
    "--src-lang",
    "json",
  }
  if pkg_name ~= nil and #pkg_name > 0 then
    table.insert(cmd, "--package")
    table.insert(cmd, pkg_name)
  else
    -- auto detect package name
    local first_line = vim.fn.getline(1)
    local matches = vim.fn.matchlist(first_line, "^package\\s\\+\\(\\S\\+\\)$")
    if matches ~= nil and #matches >= 2 then
      pkg_name = matches[2]
      table.insert(cmd, "--package")
      table.insert(cmd, pkg_name)
    end
  end
  if top_level ~= nil and #top_level > 0 then
    table.insert(cmd, "--top-level")
    table.insert(cmd, top_level)
  end
  -- add extra args
  local opt = {
    quick_type_flags = { "--just-types" },
  }
  if opt.quick_type_flags ~= nil and opt.quick_type_flags then
    for _, flag in ipairs(opt.quick_type_flags) do
      table.insert(cmd, flag)
    end
  end

  vim.fn.jobstart(cmd, {
    on_exit = function(_, code, _)
      if code == 0 then
        vim.notify("Success", vim.log.levels.INFO, { title = prefix })
      end
    end,
    on_stdout = function(_, data, _)
      if data and #data > 0 then
        for i = 1, #data do
          vim.fn.append(cur_line, data[#data + 1 - i])
        end
      end
    end,
    on_stderr = function(_, data, _)
      local results = table.concat(data, "\n")
      vim.notify(results, vim.log.levels.ERROR, { title = prefix })
    end,
  })
end

M.format = function(bufnr)
  bufnr = tonumber(bufnr) or api.nvim_get_current_buf()

  local selected_client
  if buffer_client_ids[bufnr] then
    selected_client = lsp.get_client_by_id(buffer_client_ids[bufnr])
  else
    for _, client in ipairs(M.get_clients({ buffer = bufnr })) do
      if vim.tbl_contains(preferred_formatting_clients, client.name) then
        selected_client = client
        break
      end

      if client.name == fallback_formatting_client then
        selected_client = client
      end
    end
  end

  if not selected_client then
    return
  end

  buffer_client_ids[bufnr] = selected_client.id

  local params = lsp.util.make_formatting_params()
  local res, err = selected_client.request_sync("textDocument/formatting", params, 4500, bufnr)
  if err then
    local err_msg = type(err) == "string" and err or err.message
    vim.notify("Formatting: " .. err_msg, vim.log.levels.WARN)
    return
  end

  -- if not api.nvim_buf_is_loaded(bufnr) or api.nvim_buf_get_option(bufnr, "modified") then
  --   return
  -- end

  if res and res.result then
    lsp.util.apply_text_edits(res.result, bufnr, selected_client.offset_encoding or "utf-16")
    api.nvim_buf_call(bufnr, function()
      vim.cmd("silent noautocmd update")
    end)
  end
end

return M

local nvim_lsp = require 'lspconfig'
local util = require('lspconfig/util')
local o = require('py_lsp.options')
local u = require('py_lsp.utils')

local path = util.path

local M = {}

local function get_python_path(workspace, source_strategy, venv_name)
  -- Use activated virtualenv.
  if vim.env.VIRTUAL_ENV then
      print("Using current venv")
    return path.join(vim.env.VIRTUAL_ENV, 'bin', 'python')
  end

  local patterns = {'*', '.*'}

  if venv_name ~= nil then
    patterns = { venv_name }
  end

  -- Find and use virtualenv in workspace directory.
  for _, pattern in ipairs(patterns) do

    local match = vim.fn.glob(path.join(workspace, pattern, 'pyvenv.cfg'))

    if match ~= '' and vim.tbl_contains(source_strategy, "default") then
      -- TODO: We now take the one venv found first, what to change?
      if string.find(match, "\n") then
        match = vim.gsplit(match, "\n")()
      end

      local py_path = path.join(path.dirname(match), 'bin', 'python')
      return py_path
    end

    -- If no standard venv found look for poetry
    match = vim.fn.glob(path.join(workspace, 'poetry.lock'))

    if match ~= '' and vim.tbl_contains(source_strategy, "poetry") ~= nil then
        local venv = vim.fn.trim(vim.fn.system('poetry env info -p'))
        return path.join(venv, 'bin', 'python')
    end
  end

  -- Fallback to system Python.
  return exepath('python3') or exepath('python') or 'python'
end

local function on_init(source_strategy, venv_name)
  return function(client)
      client.config.settings.python.pythonPath = get_python_path(client.config.root_dir, source_strategy, venv_name)
    end
end

local function get_client()
  local clients = vim.lsp.get_active_clients()

  if clients == nil or clients == {} then
    print("No python client attached")
    return
  end

  local current_client = nil
  for _, client in ipairs(clients) do
    if client ~= nil and client.name == "pyright" then
      current_client = client
    end
  end
  return current_client
end

M.print_venv = function()
  local client = get_client()
  if client == nil then
    print("No venv activated")
    return
  end
  print("Client pyright with venv: " .. client.config.settings.python.pythonPath)
end

M.stop_client = function()
  local client = get_client()
  vim.lsp.stop_client(client.id)
end

M.activate_venv = function (venv_name)
  local current_client = get_client()
  local cwd = vim.fn["getcwd"]()

  local match = vim.fn.glob(path.join(cwd, venv_name, 'pyvenv.cfg'))

  if match ~= "" then

    if current_client ~= nil then
      print("Stopping current running lsp server")
      vim.lsp.stop_client(current_client.id)
    end

    M.setup { venv_name = venv_name }
    -- local current_buffer = vim.get_bufnr()

    -- local current_buffer = vim.fn["bufnr"]()
    -- vim.lsp.buf_attach_client(current_buffer, get_client().id)
    print("Activated venv")
  else
    print("Cannot find venv")

  end
end

M.setup = function (opts)

  u.define_command("PyLspCurrentVenv", "print_venv")
  u.define_command("PyLspActivateVenv", "activate_venv")
  u.define_command("PyLspDeactivateVenv", "stop_client")

  -- Collect all opts from defaults and user
  opts = opts or {}
  o.set(opts)

  -- Setup server opts passed to language server
  M["server_opts"] = {
    on_init = on_init(o.get().source_strategy, opts.venv_name),
    on_attach = o.get().on_attach,
    -- TODO: Can both on_init and before_init be used?
    before_init = o.get().on_init
  }

  if o.get().auto_source then
    nvim_lsp.pyright.setup(M.server_opts)
  end
  
  o.set({ auto_source = false })
end

return M

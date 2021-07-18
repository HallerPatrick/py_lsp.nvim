
local nvim_lsp = require 'lspconfig'

local configs = require('lspconfig/configs')
local util = require('lspconfig/util')
local path = util.path

local M = {}

function dump(o)
   if type(o) == 'table' then
      local s = '{ '
      for k,v in pairs(o) do
         if type(k) ~= 'number' then k = '"'..k..'"' end
         s = s .. '['..k..'] = ' .. dump(v) .. ','
      end
      return s .. '} '
   else
      return tostring(o)
   end
end

function M.get_python_path(workspace, venv_name)
  -- Use activated virtualenv.
  if vim.env.VIRTUAL_ENV then
      print("Using current venv")
    return path.join(vim.env.VIRTUAL_ENV, 'bin', 'python')
  end

  -- Look for target venv in current directory
  if venv_name ~= nil then
    local match = vim.fn.glob(path.join(workspace, venv_name, 'pyvenv.cfg'))

    if match ~= "" then
      return path.join(path.dirname(match, 'bin', 'python'))
    end
  end

  -- Find and use virtualenv in workspace directory.
  for _, pattern in ipairs({'*', '.*'}) do

    local match = vim.fn.glob(path.join(workspace, pattern, 'pyvenv.cfg'))

    if match ~= '' then
      local pathh = path.join(path.dirname(match), 'bin', 'python')
      print("PATH: " .. pathh)
      return pathh
    end

    -- If no standard venv found look for poetry
    match = vim.fn.glob(path.join(workspace, 'poetry.lock'))
    if match ~= '' then
        local venv = vim.fn.trim(vim.fn.system('poetry env info -p'))
        return path.join(venv, 'bin', 'python')
    end
  end

  -- Fallback to system Python.
  return exepath('python3') or exepath('python') or 'python'
end


function M.server_configs(venv_name)
  return {
    on_attach = require'completion'.on_attach,
    before_init = function(_, config)
        config.settings.python.pythonPath = M.get_python_path(config.root_dir, venv_name)
    end
  }
end

local function setup_lsp() return nvim_lsp.pyright.setup(M.server_configs()) end

function M.print_venv()
  local client = M.get_client()
  if client == nil then
    print("No venv activated")
    return
  end
  print("Client pyright with venv: " .. client.config.settings.python.pythonPath)
end

function M.get_client()
  local clients = vim.lsp.get_active_clients()

  if clients == nil or clients == {} then
    print("No python client attached")
    return
  end

  for _, client in ipairs(clients) do
    if client ~= nil and client.name == "pyright" then
      return client
    end
  end
end

function M.stop_client()
  local client = M.get_client()
  vim.lsp.stop_client(client.id)
end

function M.activate_venv(venv_name)
  local current_client = M.get_client()
  local cwd = vim.fn["getcwd"]()
  local match = vim.fn.glob(path.join(cwd, venv_name, 'pyvenv.cfg'))

  if match ~= "" then

    if current_client ~= nil then
      print("Stopping current running lsp server")
      vim.lsp.stop_client(current_client.id)
    end

    nvim_lsp.pyright.setup(M.server_configs(venv_name))

    -- local current_buffer = vim.get_bufnr()
    local current_buffer = vim.fn["bufnr"]()
    vim.lsp.buf_attach_client(current_buffer, M.get_client().id)
    print("Activated venv")
  else
    print("Cannot find venv")

  end
end

function M.setup()
  setup_lsp()
end

return M

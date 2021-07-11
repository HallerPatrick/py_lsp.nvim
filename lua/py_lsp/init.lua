
local nvim_lsp = require 'lspconfig'

local configs = require('lspconfig/configs')
local util = require('lspconfig/util')
local path = util.path

local M = {
  client_id = nil
}

local current_client_id

function M.get_python_path(workspace)
  
  print(vim.lsp.lspconfig)

  -- Use activated virtualenv.
  if vim.env.VIRTUAL_ENV then
      print("Using current venv")
    return path.join(vim.env.VIRTUAL_ENV, 'bin', 'python')
  end

  -- Find and use virtualenv in workspace directory.
  for _, pattern in ipairs({'*', '.*'}) do
    local match = vim.fn.glob(path.join(workspace, pattern, 'pyvenv.cfg'))
    if match ~= '' then
      return path.join(path.dirname(match), 'bin', 'python')
    end
  end

  -- Fallback to system Python.
  return exepath('python3') or exepath('python') or 'python'
end

local server_configs = {
  on_attach = require'completion'.on_attach,
  before_init = function(_, config)
      config.settings.python.pythonPath = M.get_python_path(config.root_dir)
  end
}

local function restart_client()
end


local function setup_lsp() return nvim_lsp.pyright.setup(server_configs) end


function M.get_client()
  local clients = vim.lsp.buf_get_clients()

  if clients == nil or clients == {} then
    print("No python client attached")
    return
  end

  for _, client in ipairs(clients) do
    if client ~= nil then
      -- TODO: What to do if more than one client?  is this the right one?
      print(client.config.settings.python.pythonPath)
    end
  end
end


function M.setup()
  setup_lsp()
end

return M

local nvim_lsp = require("lspconfig")
local util = require("lspconfig/util")
local option = require("py_lsp.options")
local utils = require("py_lsp.utils")
local commands = require("py_lsp.commands")
local py = require("py_lsp.python")
local lsp = require("py_lsp.lsp")

local path = util.path
local format = string.format

local M = {}

M.runtime = {
  -- Cached full path to python venv
  current_venv = nil,
  toml_file = nil
}

---Build `on_init` function for lspconfig
---@param python_path string python path
---@return function
local function on_init(python_path)
  local ok, notify = pcall(require, "notify")
  return function(client)
    if python_path == nil then
      if option.get().plugins.notify.use and ok then
        notify.notify("Could not retrieve python path, try :PyLspReloadVenv", "error")
      else
        print("Could not retrieve python path, try :PyLspReloadVenv")
      end
      return
    end

    -- Pass to lsp
    client.config = lsp.update_client_config_python_path(client, option.get().language_server, python_path)

    -- For display
    client.config.settings.python.venv_name = utils.get_python_venv_name(python_path)

    if ok and option.get().plugins.notify.use then
      notify.notify("Using python virtual environment:\n" .. client.config.settings.python.pythonPath, "info", {
        title = " py_lsp.nvim",
        timeout = 300,
      })
    else
      vim.api.nvim_echo({ { " Using Python Virtual Environment: ", "Normal" }, { client.config.settings.python.pythonPath, "String" } }, true, {})
    end
  end
end

---Main entry to build callback funciton that is passed to lsp config
---
---@param source_strategies table Strategy used for finding venv
---@param venv_name string Name of venv
---@return function on_init callback
local function build_on_init(source_strategies, venv_name)
  local python_path = py.find_first_python_path(utils.cwd(), source_strategies, venv_name)

  M.runtime.current_venv = python_path

  -- Callback
  if option.get().on_server_ready then
    option.get().on_server_ready(M.runtime.current_venv, M.option.default_venv_name)
  end

  return on_init(python_path)
end

local function run_lsp_server(venv_name)
  local cr_loaded, config_reader = pcall(require, "py_lsp.config_reader")

  if cr_loaded then
    local toml_config, toml_file = config_reader.read_config_from_file()

    if toml_config then
      option.set(toml_config)
      M.runtime.toml_file = toml_file
    end
  end

  -- Prepare capabilities if not specified in options
  local capabilities = option.get().capabilities
  if capabilities == nil then
    capabilities = vim.lsp.protocol.make_client_capabilities()
  end

  local on_init_fn

  if venv_name then
    on_init_fn = on_init(venv_name)
  else
    on_init_fn = build_on_init(option.get().source_strategies, option.get().default_venv_name)
  end

  -- Setup server opts passed to language server
  M["server_opts"] = {
    on_init = on_init_fn,
    capabilities = capabilities,
    settings = {
      python = {},
    },
    on_attach = option.get().on_attach,
  }

  local server_opts = M.server_opts

  -- Get call command of lang server
  local cmd = require("lspconfig")[option.get().language_server]["document_config"]["default_config"]["cmd"]
  -- Check weather the lsp server is installed with `nvim-lsp-installer`
  if
      utils.has_lsp_installed_server(option.get().language_server)
      and vim.tbl_contains(lsp.allowed_clients, option.get().language_server)
  then
    -- Get specific language server configs
    local has_server, servers = require("nvim-lsp-installer/servers").get_server(option.get().language_server)
    -- Inject binary path from LspInstall setup into setup configs for lspconfig
    -- Feels a bit hacky
    if has_server then
      local root_dir = servers["root_dir"]

      if option.get().language_server == "pyright" then
        -- local bin_path = root_dir .. "/node_modules/.bin/pyright-langserver" -- .. table.concat(cmd, " ")
        local bin_path = root_dir .. "/node_modules/.bin/" .. table.concat(cmd, " ")
        server_opts["cmd"] = utils.split_string(bin_path, " ")
      else
        print("For now only pyright is properly supported when installed with the nvim-lsp-installer.")
      end
    end
  else
    -- Check in Venv for LSP
    if M.runtime.current_venv ~= nil then
      local venv_path = string.gsub(M.runtime.current_venv, "python", "")
      local lsp_path = venv_path .. table.concat(cmd)
      local ok, notify = pcall(require, "notify")
      if utils.file_exists(lsp_path) then
        if ok and option.get().plugins.notify.use then
          notify.notify("Found LSP " .. table.concat(cmd) .. " in Venv", "info")
        end
        server_opts["cmd"] = utils.split_string(lsp_path, " ")
      end
    end
  end

  if server_opts["cmd"] ~= nil then
    -- Start LSP
    nvim_lsp[option.get().language_server].setup(server_opts)
  end
end


M.print_venv = function()
  local client = lsp.get_client()
  if client == nil or client.config.settings.python == nil or client.config.settings.python.pythonPath == nil then
    print("No venv activated")
    return
  end

  print("Client " .. option.get().language_server .. " with venv: " .. client.config.settings.python.pythonPath)
end

M.reload_client = function()
  local client = lsp.get_client()
  if client then
    vim.lsp.stop_client(client.id)
  end
  run_lsp_server(M.current_venv)
end

M.activate_venv = function(cmd_tbl)
  local current_client = lsp.get_client()
  local cwd = vim.fn["getcwd"]()

  local venv_name = "venv"
  if cmd_tbl.args ~= "" then
    venv_name = cmd_tbl.args
  end

  local match = vim.fn.glob(path.join(cwd, venv_name, "pyvenv.cfg"))

  if match ~= "" then
    if current_client ~= nil then
      print("Stopping current running lsp server")
      vim.lsp.stop_client(current_client.id)
    end

    run_lsp_server(venv_name)
    print("Activated venv")
  else
    print("Cannot find venv")
  end
end

M.activate_conda_env = function(cmd_tbl)
  local current_client = lsp.get_client()

  local venv_name = "base"
  if cmd_tbl.args ~= "" then
    venv_name = cmd_tbl.args
  end

  local env_path = ""
  local base_env = vim.fn.trim(
    vim.fn.split(string.match(vim.fn.system("conda info"), "base environment : [^%s]+"), ":")[2]
  )
  local envs_loc = vim.fn.trim(
    vim.fn.split(string.match(vim.fn.system("conda info"), "envs directories : [^%s]+"), ":")[2]
  )
  if (base_env ~= "null") and venv_name == "base" then
    env_path = path.join(base_env, "bin", "python")
  elseif envs_loc ~= "null" then
    local match = vim.fn.glob(path.join(envs_loc, venv_name))
    if match ~= nil then
      env_path = path.join(match, "bin", "python")
    end
  end

  if env_path ~= "" then
    if current_client ~= nil then
      print("Stopping current running lsp server")
      vim.lsp.stop_client(current_client.id)
    end

    run_lsp_server(env_path)
    print("Activated conda env")
  else
    print("Cannot find conda env")
  end
end

M.create_venv = function(cmd_tbl)
  local python = option.get().host_python

  if not python then
    print("No python host configured")
    return
  end

  local venv_name = "venv"
  if cmd_tbl.args ~= "" then
    venv_name = cmd_tbl.args
  end

  local output = vim.fn.trim(vim.fn.system(format("%s -m virtualenv %s", python, venv_name)))
  print(output)
  run_lsp_server(venv_name)
end

M.create_popup = function(opts)
  local has_telescope, pickers = pcall(require, "py_lsp.picker")

  if has_telescope then
    pickers.popup_picker(opts, M)
  else
    print("telescope not installed")
  end
end

M.py_run = function(...)
  local args = { ... }

  -- If table is empty, then get current buffer file path
  if vim.tbl_isempty(args) then
    args = vim.api.nvim_buf_get_name(0)
  else
    args = table.concat(args, " ")
  end

  local client = lsp.get_client()

  local py_path = client.config.settings.python.pythonPath

  local has_toggleterm, runner = pcall(require, "py_lsp.run")

  if has_toggleterm then
    runner.run_toggleterm(py_path, args)
  else
    runner.run_system(py_path, args)
  end
end

--- Wrapper for callback to lsp.stop_client
M.stop_client = function()
  lsp.stop_client()
end

M.find_venvs = function(opts)
  opts = opts or {}

  local strategies = option.get().source_strategies

  local collected_venvs = py.find_all_python_paths(strategies)

  local annotated_venvs = {}

  for p, s in pairs(collected_venvs) do
    table.insert(annotated_venvs, string.format("(%s) %s", s, p))
  end

  local has_telescope, pickers = pcall(require, "py_lsp.picker")

  if has_telescope then
    pickers.find_vens_picker(opts, annotated_venvs, collected_venvs, run_lsp_server)
  else
    local ok, notify = pcall(require, "notify")
    if ok and option.get().plugins.notify.use then
      notify.notify(vim.fn.json_encode(collected_venvs), "info")
    else
      print("telescope not installed")
    end
  end
end

M.setup = function(opts)
  -- Init all commands
  for command, func in pairs(commands.commands) do
    vim.api.nvim_create_user_command(command, M[func], commands.commands_opts[command])
  end

  -- Collect all opts from defaults and user
  opts = opts or {}
  option.set(opts)

  -- Only activate venv if auto_source is true
  if option.get().auto_source then
    run_lsp_server()
  end
end

return M

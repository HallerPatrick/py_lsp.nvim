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

M.option = {
    current_venv = nil,
    venv_name = nil
}

---Build `on_init` function for lspconfig
---@param python_path string python path
---@return function
local function on_init(python_path)
    return function(client)

        if python_path == nil then print("Could not retrieve python path") end

        -- Pass to lsp
        client.config = lsp.update_client_config_python_path(client.config,
                                                             option.get().language_server,
                                                             python_path)

        -- For display
        client.config.settings.python.venv_name = utils.get_python_venv_name(python_path)

        local ok, notify = pcall(require, "notify")

        iim.pretty_print(utils.get_python_venv_name(python_path))
        if ok then
            notify.notify("Using python virtual environment:\n" ..
                              client.config.settings.python.pythonPath, "info", {
                title = "py_lsp.nvim",
                timeout = 300
            })
        end
    end

end

---Main entry to build callback funciton that is passed to lsp config
---
---@param source_strategies string Strategy used for finding venv
---@param venv_name string Name of venv
---@return function on_init callback
local function build_on_init(source_strategies, venv_name)

    local python_path = py.find_first_python_path(vim.loop.cwd(), source_strategies, venv_name)

    -- Cache to reload lsp
    M.option.current_venv = python_path
    M.option.venv_name = venv_name

    -- Callback
    if option.get().on_server_ready then
        option.get().on_server_ready(M.option.current_venv, M.option.venv_name)
    end

    return on_init(python_path)
end

local function run_lsp_server(venv_name, is_path)
    is_path = is_path or false

    -- Prepare capabilities if not specified in options
    local capabilities = option.get().capabilities
    if capabilities == nil then capabilities = vim.lsp.protocol.make_client_capabilities() end

    local on_init_fn = is_path and on_init(venv_name) or
                           build_on_init(option.get().source_strategies, venv_name)

    -- Setup server opts passed to language server
    M["server_opts"] = {
        on_init = on_init_fn,
        capabilities = capabilities,
        on_attach = option.get().on_attach
    }

    local server_opts = M.server_opts

    -- Check weather the lsp server is installed with `nvim-lsp-installer`
    if utils.has_lsp_installed_server(option.get().language_server) and
        vim.tbl_contains(lsp.allowed_clients, option.get().language_server) then

        -- Get call command of lang server
        local cmd =
            require("lspconfig")[option.get().language_server]["document_config"]["default_config"]["cmd"]

        -- Get specific language server configs
        local has_server, servers = require("nvim-lsp-installer/servers").get_server(option.get()
                                                                                         .language_server)

        -- Inject binary path from LspInstall setup into setup configs for lspconfig
        -- Feels a bit hacky
        if has_server then

            local root_dir = servers["root_dir"]

            if option.get().language_server == "pyright" then
                -- local bin_path = root_dir .. "/node_modules/.bin/pyright-langserver" -- .. table.concat(cmd, " ")
                local bin_path = root_dir .. "/node_modules/.bin/" .. table.concat(cmd, " ")
                server_opts["cmd"] = utils.split_string(bin_path, " ")
            else
                print(
                    "For now only pyright is properly supported when installed with the nvim-lsp-installer.")
            end
        end
    end

    -- Start LSP
    nvim_lsp[option.get().language_server].setup(server_opts)
end

M.print_venv = function()
    local client = lsp.get_client()
    if client == nil or client.config.settings.python.pythonPath == nil then
        print("No venv activated")
        return
    end

    print("Client pyright with venv: " .. client.config.settings.python.pythonPath)
end


M.reload_client = function()
    local client = lsp.get_client()
    vim.lsp.stop_client(client.id)
    run_lsp_server(M.current_venv)
end

M.activate_venv = function(cmd_tbl)
    local current_client = lsp.get_client()
    local cwd = vim.fn["getcwd"]()

    local venv_name = "venv"
    if cmd_tbl.args ~= "" then venv_name = cmd_tbl.args end

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
    local home = os.getenv("HOME")

    local venv_name = "base"
    if cmd_tbl.args ~= "" then venv_name = cmd_tbl.args end

    local env_path = ""
    local base_env = vim.fn.trim(vim.fn.split(string.match(vim.fn.system("conda info"),
                                                           "base environment : [^%s]+"), ":")[2])
    local envs_loc = vim.fn.trim(vim.fn.split(string.match(vim.fn.system("conda info"),
                                                           "envs directories : [^%s]+"), ":")[2])
    if (base_env ~= "null") and venv_name == "base" then
        env_path = path.join(base_env, "bin", "python")
    elseif envs_loc ~= "null" then
        local match = vim.fn.glob(path.join(envs_loc, venv_name))
        if match ~= nil then env_path = path.join(match, "bin", "python") end
    end

    if env_path ~= "" then
        if current_client ~= nil then
            print("Stopping current running lsp server")
            vim.lsp.stop_client(current_client.id)
        end

        run_lsp_server(env_path, true)
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
    if cmd_tbl.args ~= "" then venv_name = cmd_tbl.args end

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
    local args = {...}
    args = table.concat(args, " ")

    local client = lsp.get_client()

    local py_path = client.config.settings.python.pythonPath

    -- TODO: Make this work
    -- if u.is_module_available("asyncrun") then
    --     vim.cmd("AsynRun echo 'Hello World'")
    -- else
    --     print(vim.fn.system(format("%s %s", py_path, args)))
    -- end
    print(vim.fn.system(format("%s %s", py_path, args)))
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
        print("telescope not installed")
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
    if option.get().auto_source then run_lsp_server(option.get().default_venv_name) end
end

return M

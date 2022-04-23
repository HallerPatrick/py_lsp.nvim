local nvim_lsp = require("lspconfig")
local util = require("lspconfig/util")
local popup = require("py_lsp.popup")
local o = require("py_lsp.options")
local u = require("py_lsp.utils")
local c = require("py_lsp.commands")
local py = require("py_lsp.python")
local lsp = require("py_lsp.lsp")

local path = util.path
local format = string.format

local M = {}

M.o = {
    current_venv = nil,
    venv_name = nil
}

local function on_init(source_strategies, venv_name)
    return function(client)

        local python_path =
            py.find_python_path(client.config.root_dir, source_strategies, venv_name)

        -- Pass to lsp
        --
        -- TODO: Depends on lsp in use, maybe change this
        if o.get().language_server == "pyright" then
            client.config.settings.python.pythonPath = python_path
        else
            client.config.settings = {
                python = {
                    pythonPath = python_path
                }
            }
        end

        print("This is not called?")

        -- Cache to reload lsp
        M.o.current_venv = python_path

        -- For display
        client.config.settings.python.venv_name = u.get_python_venv_name(python_path)

        if u.is_module_available("notify") then

            require("notify").notify("Using python virtual environment:\n" ..
                                         client.config.settings.python.pythonPath, "info", {
                title = "py_lsp.nvim",
                timeout = 500
            })
        end
    end
end

local function run(venv_name)
    -- Prepare capabilities if not specified in options
    local capabilities = o.get().capabilities
    if capabilities == nil then capabilities = vim.lsp.protocol.make_client_capabilities() end

    -- Setup server opts passed to language server
    M["server_opts"] = {
        on_init = on_init(o.get().source_strategies, venv_name),
        capabilities = capabilities,
        on_attach = o.get().on_attach
    }

    local server_opts = M.server_opts

    -- Check weather the lsp server is installed with `nvim-lsp-installer`
    if u.has_lsp_installed_server(o.get().language_server) and
        vim.tbl_contains(lsp.allowed_clients, o.get().language_server) then

        -- Get call command of lang server
        local cmd =
            require("lspconfig")[o.get().language_server]["document_config"]["default_config"]["cmd"]

        -- Get specific language server configs
        local has_server, servers = require("nvim-lsp-installer/servers").get_server(o.get()
                                                                                         .language_server)

        -- Inject binary path from LspInstall setup into setup configs for lspconfig
        -- Feels a bit hacky
        if has_server then
            local root_dir = servers["root_dir"]

            if o.get().language_server == "pyright" then
                local bin_path = root_dir .. "/node_modules/.bin/" .. table.concat(cmd, " ")
                server_opts["cmd"] = u.split_string(bin_path, " ")
            else
                print(
                    "For now only pyright is properly supported when installed with the nvim-lsp-installer.")
            end
        end
    end

    print("but you are")
    -- Start LSP
    nvim_lsp[o.get().language_server].setup(server_opts)
end

M.get_client = function() return lsp.get_client() end

M.print_venv = function()
    local client = M.get_client()
    if client == nil or client.config.settings.python.pythonPath == nil then
        print("No venv activated")
        return
    end

    print("Client pyright with venv: " .. client.config.settings.python.pythonPath)
end

M.stop_client = function()
    local client = M.get_client()
    vim.lsp.stop_client(client.id)
end

M.reload_client = function()
    local client = M.get_client()
    vim.lsp.stop_client(client.id)
    run(M.current_venv)
end

M.activate_venv = function(venv_name)
    local current_client = M.get_client()
    local cwd = vim.fn["getcwd"]()

    local match = vim.fn.glob(path.join(cwd, venv_name, "pyvenv.cfg"))

    if match ~= "" then
        if current_client ~= nil then
            print("Stopping current running lsp server")
            vim.lsp.stop_client(current_client.id)
        end

        run(venv_name)
        print("Activated venv")
    else
        print("Cannot find venv")
    end
end

M.create_venv = function(venv_name)
    local python = o.get().host_python

    if not python then print("No python host configured") end

    venv_name = venv_name or "venv"

    local output = vim.fn.trim(vim.fn.system(format("%s -m virtualenv %s", python, venv_name)))
    print(output)
    run(venv_name)
end

M.create_popup = function()
    local lines = popup.format_lines(vim.tbl_values(c.commands_to_text))

    popup.create_popup(lines, function(row)
        local line = vim.tbl_values(c.commands_to_text)[row]
        local command = u.get_key_for_value(c.commands_to_text, line)
        M[c.commands[command]]()
    end)
end

M.py_run = function(...)
    local args = {...}
    args = table.concat(args, " ")

    local client = M.get_client()

    local py_path = client.config.settings.python.pythonPath

    -- TODO: Make this work
    -- if u.is_module_available("asyncrun") then
    --     vim.cmd("AsynRun echo 'Hello World'")
    -- else
    --     print(vim.fn.system(format("%s %s", py_path, args)))
    -- end
    print(vim.fn.system(format("%s %s", py_path, args)))
end

M.setup = function(opts)
    -- Init all commands
    for command, func in pairs(c.commands) do u.define_command(command, func) end

    -- Collect all opts from defaults and user
    opts = opts or {}
    o.set(opts)

    if o.get().auto_source then run(opts.venv_name) end
end

return M

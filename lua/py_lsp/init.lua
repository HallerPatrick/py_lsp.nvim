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
        client.config.settings.python.pythonPath = python_path
        -- local message = {
        -- 	pylsp = {
        -- 		plugins = {
        -- 			jedi = {
        -- 				environment = "venv/bin/python",
        -- 			},
        -- 		},
        -- 	},
        -- }

        -- local resp = client.notify("workspace/didChangeConfiguration", {settings = message})
        -- client.config.settings = message

        -- Cache to reload lsp
        M.o.current_venv = python_path

        -- For display
        client.config.settings.python.venv_name = u.get_python_venv_name(python_path)

        vim.notify(
            "Using python virtual environment:\n" .. client.config.settings.python.pythonPath,
            "info", {
                title = "py_lsp.nvim"
            })
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

    -- If pyright lang server is installed thrugh LspInstall, we pass "python"
    -- as the language server, because "python" is pre configured with the
    -- binary path
    if u.has_lsp_installed_server() and o.get().language_server == "pyright" then
        -- server_opts["document_config"] = nvim_lsp["python"]["document_config"]

        local configs = require("lspconfig/configs")

        -- Inject binary path from LspInstall setup into setup configs for lspconfig
        -- Feels a bit hacky
        server_opts["cmd"] = configs["python"]["document_config"]["default_config"]["cmd"]
    end

    -- print(vim.inspect(server_opts))
    -- Start LSP
    nvim_lsp[o.get().language_server].setup(server_opts)

end

M.get_client = function() return lsp.get_client(o.get().language_server) end

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

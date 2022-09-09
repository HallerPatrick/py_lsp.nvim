local nvim_lsp = require("lspconfig")
local util = require("lspconfig/util")
local popup = require("py_lsp.popup")
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

---Main callback funciton that is passed to lsp config
---
---@param source_strategies string Strategy used for finding venv
---@param venv_name string Name of venv
---@return function on_init callback
local function on_init(source_strategies, venv_name)
    return function(client)

        local python_path =
            py.find_python_path(client.config.root_dir, source_strategies, venv_name)

        -- Pass to lsp
        client.config = lsp.update_client_config_python_path(client.config, option.get().language_server,
                                                             python_path)

        -- Cache to reload lsp
        M.option.current_venv = python_path
        M.option.venv_name = venv_name

        -- For display
        client.config.settings.python.venv_name = utils.get_python_venv_name(python_path)

        -- Callback
        if option.get().on_server_ready then
            option.get().on_server_ready(M.option.current_venv, M.option.venv_name)
        end

        local ok, notify = pcall(require, "notify")

        if ok then
            notify.notify("Using python virtual environment:\n" ..
                              client.config.settings.python.pythonPath, "info", {
                title = "py_lsp.nvim",
                timeout = 500
            })
        end
    end
end

local function run_lsp_server(venv_name)
    -- Prepare capabilities if not specified in options
    local capabilities = option.get().capabilities
    if capabilities == nil then capabilities = vim.lsp.protocol.make_client_capabilities() end

    -- Setup server opts passed to language server
    M["server_opts"] = {
        on_init = on_init(option.get().source_strategies, venv_name),
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
    run_lsp_server(M.current_venv)
end

M.activate_venv = function(cmd_tbl)
    local current_client = M.get_client()
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

M.create_venv = function(cmd_tbl)

    local python = option.get().host_python
    
    if not python then print("No python host configured") return end

    local venv_name = "venv"
    if cmd_tbl.args ~= "" then venv_name = cmd_tbl.args end

    local output = vim.fn.trim(vim.fn.system(format("%s -m virtualenv %s", python, venv_name)))
    print(output)
    run_lsp_server(venv_name)
end

M.create_popup = function()
    local lines = popup.format_lines(vim.tbl_values(commands.commands_to_text))

    popup.create_popup(lines, function(row)
        local line = vim.tbl_values(commands.commands_to_text)[row]
        local command = utils.get_key_for_value(commands.commands_to_text, line)
        M[commands.commands[command]]()
    end)
end
--
-- local pickers = require "telescope.pickers"
-- local finders = require "telescope.finders"
-- local conf = require("telescope.config").values
-- local actions = require "telescope.actions"
-- local action_state = require "telescope.actions.state"

-- M.create_popup = function(opts)
--     opts = opts or {}
--
--     local func
--
--     pickers.new(opts, {
--         prompt_title = "py_lsp.nvim actions",
--         finder = finders.new_table {
--             results = vim.tbl_values(c.commands_to_text)
--         },
--         sorter = conf.generic_sorter(opts),
--         attach_mappings = function(prompt_bufnr, map)
--             actions.select_default:replace(function()
--                 actions.close(prompt_bufnr)
--                 local selection = action_state.get_selected_entry()
--                 func = vim.tbl_values(c.commands)[selection.index]
--             end)
--             return true
--         end
--     }):find()
--
--     M[func]()
-- end

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
    for command, func in pairs(commands.commands) do
        vim.api.nvim_create_user_command(command, M[func], {
            desc = commands.commands_opts[command]
        })
    end

    -- for command, func in pairs(c.commands) do u.define_command(command, func) end

    -- Collect all opts from defaults and user
    opts = opts or {}
    option.set(opts)

    -- Only activate venv if auto_source is true
    if option.get().auto_source then run_lsp_server(opts.venv_name) end
end

return M

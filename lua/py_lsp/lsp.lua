local options = require("py_lsp.options")

local M = {}

M.allowed_clients = {"pyright", "jedi-language-server", "pylsp"}

---Update the client config to include the updated python path
---
---@param client table LSP client
---@param language_server string Language server name
---@param python_path string Python path value
---@return table New config
M.update_client_config_python_path = function(client, language_server, python_path)
    local config = {}
    -- TODO: Depends on lsp in use, maybe change this
    if language_server == "pyright" then
        config = client.config
        config.settings.python.pythonPath = python_path
    elseif language_server == "pylsp" then
        local settings = {
            pylsp = {
                plugins = {}
            }
        }

        settings.pylsp.plugins = options.get().pylsp_plugins
        settings.pylsp.plugins.jedi = {
                        environment = python_path
                    }

        client.config.settings.python.pythonPath = python_path
        client.config.settings = vim.tbl_deep_extend("force", client.config.settings, settings)
        config = client.config
    else
        client.config.settings = {
            python = {
                pythonPath = python_path
            }
        }
        config = client.config
    end
    return config
end

---Return to current active client, will return last one found
---@return any
M.get_client = function()
    local clients = vim.lsp.get_active_clients()

    if clients == nil or clients == {} then
        print("No python client attached")
        return
    end

    local current_client = nil

    for _, client in ipairs(clients) do
        if client ~= nil and vim.tbl_contains(M.allowed_clients, client.name) then
            current_client = client
        end
    end
    return current_client
end

--- Stops the lsp client for current filetype (python)
--- TODO: Check if obsolete
M.stop_client = function()
    local current_buf = vim.api.nvim_get_current_buf()

    local servers_on_buffer = vim.lsp.get_active_clients {
        buffer = current_buf
    }
    for _, client in ipairs(servers_on_buffer) do
        local filetypes = client.config.filetypes
        if filetypes and vim.tbl_contains(filetypes, vim.bo[current_buf].filetype) then
            client.stop()
        end
    end
end

M.get_current_python_venv_path = function ()

  local lsp_client = M.get_client()

  local language_server = options.get().language_server

  if language_server == "pyright" then
    return lsp_client.config.settings.python.pythonPath
  end

end

return M

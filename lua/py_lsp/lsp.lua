local M = {}

M.allowed_clients = {"pyright", "jedi-language-server"}

---Update the client config to include the updated python path
---
---@param config table Config to update
---@param language_server string Language server name
---@param python_path string Python path value
---@return table New config
M.update_client_config_python_path = function(config, language_server, python_path)
    -- TODO: Depends on lsp in use, maybe change this
    if language_server == "pyright" then
        config.settings.python.pythonPath = python_path
    else
        config.settings = {
            python = {
                pythonPath = python_path
            }
        }
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


return M

local M = {}

M.allowed_clients = {"pyright", "jedi-language-server"}

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

return M

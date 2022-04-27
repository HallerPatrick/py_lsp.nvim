local M = {}

M.get_key_for_value = function(t, value)
    for k, v in pairs(t) do if v == value then return k end end
    return nil
end

M.tbl_get_keys = function(tbl)
    local keyset = {}
    for k, _ in pairs(tbl) do table.insert(keyset, k) end
    return keyset
end

-- This will probably break easily
M.get_python_venv_name = function(venv_path)
    venv_path = string.match(venv_path, "[a-zA-Z\\.0-9]+/bin/python")
    return string.gsub(venv_path, "/bin/python", "")
end

M.has_lsp_installed_server = function(server_name)
    local ok, nvim_lsp_installer = pcall(require, "nvim-lsp-installer.servers")
    if ok then
        local servers = nvim_lsp_installer.get_installed_server_names()
        if vim.tbl_contains(servers, server_name) then return true end
    end
    return false
end

M.split_string = function(s, delimiter)
    local result = {}
    for match in (s..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match)
    end
    return result;
end

return M

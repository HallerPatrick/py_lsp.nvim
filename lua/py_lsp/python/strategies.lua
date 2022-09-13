local path = require("lspconfig/util").path

local M = {}

M.default = function(workspace, venv_name)
    local patterns = {"*", ".*"}

    if venv_name ~= nil then patterns = {venv_name} end

    -- Find and use virtualenv in workspace directory.
    for _, pattern in ipairs(patterns) do
        local match = vim.fn.glob(path.join(workspace, pattern, "pyvenv.cfg"))
        if match ~= "" then
            if string.find(match, "\n") then match = vim.gsplit(match, "\n")() end

            return path.join(path.dirname(match), "bin", "python")
        end
    end

    return nil
end

M.poetry = function(workspace, _)
    -- If no standard venv found look for poetry
    local match = vim.fn.glob(path.join(workspace, "poetry.lock"))

    -- TODO: This could throw errors, should be handled
    if match ~= "" then
        local venv = vim.fn.trim(vim.fn.system("poetry env info -p"))
        return path.join(venv, "bin", "python")
    end

    return nil
end

-- M.virtualenvwrapper = function() end

-- M.pipenv = function() end

M.system = function() return vim.fn.exepath("python3") or vim.fn.exepath("python") or "python" end

M.env_path = function()

    local venv_paths = {}
    local paths = vim.env.PATH

    if paths == nil then return {} end

    for p in vim.gsplit(paths, ":") do

        local potential_python_bin = path.join(p, "python")
        local potential_python_3_bin = path.join(p, "python3")

        if vim.fn.exepath(potential_python_bin) ~= "" then
            table.insert(venv_paths, potential_python_bin)
        elseif vim.fn.exepath(potential_python_3_bin) ~= "" then
            table.insert(venv_paths, potential_python_3_bin)
        end
    end

    return venv_paths
end

return M

local search_strategies = require("py_lsp.python.strategies")

local M = {
    strategies = vim.tbl_keys(search_strategies)
}

M.strategy_provider = function(strategy)
    assert(vim.tbl_contains(M.strategies, strategy),
           string.format("Strategy '%s' is unknown", strategy))
    return search_strategies[strategy]
end

M.find_first_python_path = function(workspace, strategies, venv_name)
    for _, strategy in ipairs(strategies) do
        local strategy_fn = M.strategy_provider(strategy)

        if vim.is_callable(strategy_fn) then
            local python_path = strategy_fn(workspace, venv_name)
            if python_path ~= nil then return python_path end
        end
    end

    return nil
end

M.find_all_python_paths = function(strategies)

    local collected_venvs = {}

    for _, strategy in ipairs(strategies) do
        local strategy_fn = M.strategy_provider(strategy)

        if vim.is_callable(strategy_fn) then
            local python_path = strategy_fn()
            if python_path ~= nil then collected_venvs[strategy] = python_path end
        elseif type(strategy_fn) == "table" then
            vim.tbl_extend(collected_venvs, strategy_fn)
        end
    end

    return collected_venvs
end

return M

local search_strategies = require("py_lsp.python.strategies")

local M = {
	strategies = vim.tbl_keys(search_strategies),
}

local function strategy_provider(strategy)
	assert(vim.tbl_contains(M.strategies, strategy), string.format("Strategy '%s' is unknown", strategy))
	return search_strategies[strategy]
end

M.find_python_path = function(workspace, strategies, venv_name)
	local python_path = nil

	while python_path == nil and not vim.tbl_isempty(strategies) do
		local strategy = table.remove(strategies, 1)
		python_path = strategy_provider(strategy)(workspace, venv_name)
	end

	return python_path
end

return M

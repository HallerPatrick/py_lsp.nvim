local search_strategies = require("py_lsp.python.strategies")

local M = {
	strategies = vim.tbl_keys(search_strategies),
}

M.strategy_provider = function(strategy)
	assert(vim.tbl_contains(M.strategies, strategy), string.format("Strategy '%s' is unknown", strategy))
	return search_strategies[strategy]
end

M.find_first_python_path = function(workspace, strategies, venv_name)
	for _, strategy in ipairs(strategies) do
		local strategy_fn = M.strategy_provider(strategy)

		if vim.is_callable(strategy_fn) then
			local python_path = strategy_fn(workspace, venv_name)
			if python_path ~= nil then
				if type(python_path) == "table" then
					return python_path[1]
				end

				return python_path
			end
		end
	end

	return nil
end

---Return all found venvs, with path as key and strategy as value
---
---@param strategies table list of strategies
---@return table
M.find_all_python_paths = function(strategies)
	local collected_venvs = {}

	for _, strategy in ipairs(strategies) do
		local strategy_fn = M.strategy_provider(strategy)

		if vim.is_callable(strategy_fn) then
			local python_path = strategy_fn()

			if type(python_path) == "table" then
				for _, path in pairs(python_path) do
					collected_venvs[path] = strategy
				end
			end

			if type(python_path) == "string" then
				collected_venvs[python_path] = strategy
			end
		elseif type(strategy_fn) == "table" then
			for _, p in ipairs(strategy_fn) do
				collected_venvs[p] = strategy
			end
		end
	end

	return collected_venvs
end

return M

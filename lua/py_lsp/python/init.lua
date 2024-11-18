local path = require("lspconfig/util").path

local search_strategies = require("py_lsp.python.strategies")
local options = require("py_lsp.options")

local M = {
	strategies = vim.tbl_keys(search_strategies),
}

M.strategy_provider = function(strategy)
	assert(vim.tbl_contains(M.strategies, strategy), string.format("Strategy '%s' is unknown", strategy))
	return search_strategies[strategy]
end


---
--- Check first env vars if we already have a activate venv
--- TODO: We check probably add a option to check this first if the user
--- wants to 
---@param strategy string
---@return string
M.check_activated_env = function (strategy)
  if strategy == "default" then
    local default_venv_path = os.getenv("VIRTUAL_ENV")
    if default_venv_path ~= "" then
      return default_venv_path
    end
  elseif strategy == "conda" then
    local conda_env_path = os.getenv("CONDA_PREFIX")
    if conda_env_path ~= "" then
      return path.join(conda_env_path, "bin", "python")
    end
  end

  return nil
end

M.find_first_python_path = function(workspace, strategies, venv_name)
	for _, strategy in ipairs(strategies) do
        local activate_venv_path = M.check_activated_env(strategy)
        if activate_venv_path ~= nil and options.get().default_venv_name == nil then
          -- Check if path exists and normalize it
          local expanded_path = vim.fn.expand(activate_venv_path)
          if vim.fn.isdirectory(activate_venv_path) == 1 then
            local absolute_path = vim.fn.fnamemodify(expanded_path, ':p')
            return path.join(path.dirname(absolute_path), "bin", "python")
          end

          return activate_venv_path
        end
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

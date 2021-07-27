local defaults = {
	auto_source = true,
	language_server = "pyright",
	on_attach = require("completion").on_attach,
	source_strategy = { "default", "poetry", "system" },
	host_python = nil, -- this python should include virtualenv module
	-- before_init = function(_, config)
	--     config.settings.python.pythonPath = M.get_python_path(config.root_dir, venv_name)
	-- end
}

local options = vim.deepcopy(defaults)

local M = {}

function M.set(user_opts)
	options = vim.tbl_deep_extend("force", options, user_opts)
end

function M.get()
	return options
end

return M

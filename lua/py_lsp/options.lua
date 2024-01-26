local defaults = {
	auto_source = true,
	language_server = "pyright",
	on_attach = nil,
	capabilities = nil,
	source_strategies = { "default", "poetry", "conda", "system" },
	host_python = nil, -- this python should include the virtualenv module,
	on_server_ready = nil,
	default_venv_name = nil,
	venvs = {},
	pylsp_plugins = {},
	plugins = {
		notify = {
			use = true,
		},
		toggleterm = {
			use = true,
		},
	},
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

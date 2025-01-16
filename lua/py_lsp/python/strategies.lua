local path = require("lspconfig/util").path

function get_last_dir(path)
	return path:match("([^/]+)$")
end

local M = {}

M.default = function(workspace, venv_name)
	if workspace == nil then
		return nil
	end

	local patterns = { "*", ".*" }

	if venv_name ~= nil then
		patterns = { venv_name }
	end

	local found_venvs = {}

	-- Find and use virtualenv in workspace directory.
	for _, pattern in ipairs(patterns) do
		local match = vim.fn.glob(path.join(workspace, pattern, "pyvenv.cfg"))
		if match ~= "" then
			if string.find(match, "\n") then
				for p in vim.gsplit(match, "\n") do
					if venv_name == pattern then
						return path.join(path.dirname(p), "bin", "python")
					else
						table.insert(found_venvs, path.join(path.dirname(p), "bin", "python"))
					end
				end
			else
				table.insert(found_venvs, path.join(path.dirname(match), "bin", "python"))
			end
		end
	end

	return found_venvs
end

M.poetry = function(workspace, _)
	-- If no standard venv found look for poetry
	if workspace ~= nil then
		local match = vim.fn.glob(path.join(workspace, "poetry.lock"))

		-- TODO: This could throw errors, should be handled
		if match ~= "" then
			local venv = vim.fn.trim(vim.fn.system("poetry env info -p"))
			return path.join(venv, "bin", "python")
		end
	end

	return nil
end

M.conda = function(_, venv_name)
	-- If no standard venv found look for conda environments
	local found_envs = {}
	local json_env_list = vim.fn.systemlist("$CONDA_EXE env list --json")
	table.unpack = table.unpack or unpack -- 5.1 compatibility
	local raw_env_list = { table.unpack(json_env_list, 3, #json_env_list - 2) }
	for _, raw_env in ipairs(raw_env_list) do
		local env = string.match(raw_env, '[^%s"]+')

		if venv_name == get_last_dir(env) then
			return path.join(env, "bin", "python")
		end

		table.insert(found_envs, path.join(env, "bin", "python"))
	end

	return found_envs
end

M.hatch = function(_, venv_name)
	local venv = vim.fn.trim(vim.fn.system("hatch env find"))
	print(venv)
	local exit_code = vim.v.shell_error
	if exit_code == 0 then
		return path.join(venv, "bin", "python")
	end
	return nil
end

-- M.virtualenvwrapper = function() end

-- M.pipenv = function() end

M.system = function()
	return vim.fn.exepath("python3") or vim.fn.exepath("python")
end

M.env_path = function()
	local venv_paths = {}
	local paths = vim.env.PATH

	if paths == nil then
		return {}
	end

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

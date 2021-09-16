local format = string.format

local M = {}

M.define_command = function(name, fn)
	vim.cmd(format("command! -nargs=* %s lua require'py_lsp'.%s(<f-args>)", name, fn))
end

M.get_key_for_value = function(t, value)
	for k, v in pairs(t) do
		if v == value then
			return k
		end
	end
	return nil
end

M.tbl_get_keys = function(tbl)
	local keyset = {}
	for k, _ in pairs(tbl) do
		table.insert(keyset, k)
	end
	return keyset
end

-- This will probably break easily
M.get_python_venv_name = function(venv_path)
	venv_path = string.match(venv_path, "[a-zA-Z\\.0-9]+/bin/python")
	return string.gsub(venv_path, "/bin/python", "")
end

local is_module_available = function(name)
  if package.loaded[name] then
    return true
  else
    for _, searcher in ipairs(package.searchers or package.loaders) do
      local loader = searcher(name)
      if type(loader) == 'function' then
        package.preload[name] = loader
        return true
      end
    end
    return false
  end
end

M.has_lsp_installed_server = function()
    if is_module_available("lspinstall") then
      local servers = require'lspinstall'.installed_servers()

      if vim.tbl_contains(servers, "python") then
        return true
      end
    end
    return false
end

return M

local M = {}

-- Keep it backwards compatible with nvim < 0.10
if vim.fn.has("nvim-0.10") == 1 then
  M.uv = vim.uv
else
  M.uv = vim.loop
end

M.get_key_for_value = function(t, value)
  for k, v in pairs(t) do
    if v == value then
      return k
    end
  end
  return nil
end

-- This will probably break easily
M.get_python_venv_name = function(venv_path)
	if venv_path ~= nil then
		venv_path = string.match(venv_path, "[a-zA-Z\\.0-9_-]+/bin/python")
		return string.gsub(venv_path, "/bin/python", "")
	end
	return "/bin/python"
end

M.has_lsp_installed_server = function(server_name)
  local ok, nvim_lsp_installer = pcall(require, "nvim-lsp-installer.servers")
  if ok then
    local servers = nvim_lsp_installer.get_installed_server_names()
    if vim.tbl_contains(servers, server_name) then
      return true
    end
  end
  return false
end

M.split_string = function(s, delimiter)
  local result = {}
  for match in (s .. delimiter):gmatch("(.-)" .. delimiter) do
    table.insert(result, match)
  end
  return result
end

local function noop(...)
  return ...
end

-- convert a nested table to a flat table
M.flatten = function(t, sep, key_modifier, res)
  if type(t) ~= "table" then
    return t
  end

  if sep == nil then
    sep = "."
  end

  if res == nil then
    res = {}
  end

  if key_modifier == nil then
    key_modifier = noop
  end

  for k, v in pairs(t) do
    if type(v) == "table" then
      local v = M.flatten(v, sep, key_modifier, {})
      for k2, v2 in pairs(v) do
        res[key_modifier(k) .. sep .. key_modifier(k2)] = v2
      end
    else
      res[key_modifier(k)] = v
    end
  end
  return res
end

M.file_exists = function(fname)
  local stat = M.uv.fs_stat(fname)
  return (stat and stat.type) or false
end

M.cwd = function()
  return M.uv.cwd()
end

return M

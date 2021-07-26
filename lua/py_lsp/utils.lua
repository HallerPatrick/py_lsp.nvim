local format = string.format

local M = {}

M.define_command = function(name, fn)
    vim.cmd(format("command! -nargs=* %s lua require'py_lsp'.%s(<f-args>)", name, fn))
end

M.get_key_for_value = function(t, value)
  for k,v in pairs(t) do
    if v==value then return k end
  end
  return nil
end

return M

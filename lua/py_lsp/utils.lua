local format = string.format

local M = {}

M.define_command = function(name, fn)
    vim.cmd(format("command! -nargs=* %s lua require'py_lsp'.%s(<f-args>)", name, fn))
end

return M

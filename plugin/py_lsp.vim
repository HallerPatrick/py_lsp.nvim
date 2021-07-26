if !has('nvim-0.5')
  echoerr "Telescope.nvim requires at least nvim-0.5. Please update or uninstall"
finish
end


" F-args are not working for me in lua (commands.lua), therefore viml
command! -nargs=* PyRun lua require'py_lsp'.py_run(<f-args>)

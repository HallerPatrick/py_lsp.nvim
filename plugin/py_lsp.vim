if !has('nvim-0.5')
  echoerr "Telescope.nvim requires at least nvim-0.5. Please update or uninstall"
finish
end


" F-args are not working for me in lua (commands.lua), therefore viml
" This might help: https://www.reddit.com/r/neovim/comments/ord878/how_to_map_command_with_nargs_range_to_a_lua/
command! -nargs=* PyRun lua require'py_lsp'.py_run(<f-args>)

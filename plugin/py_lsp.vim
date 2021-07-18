
com! -nargs=* PyLspCurrentVenv lua require'py_lsp'.print_venv(<f-args>)
com! -nargs=* PyLspActivateVenv lua require'py_lsp'.activate_venv(<f-args>)
com! -nargs=* PyLspDeactivateVenv lua require'py_lsp'.stop_client(<f-args>)


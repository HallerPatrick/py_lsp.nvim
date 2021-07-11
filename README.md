# py_lsp.nvim


This plugin is created due to following [Issue](https://github.com/neovim/nvim-lspconfig/issues/500#issuecomment-877305226).
It tackles the issues about the activation and usage of python virtualenv
for the nvim lsp. 

Is serves as a starter to make virtualenv usage more easier and transparent.

This plugin currently includes a utility to automatically pass a virtualenv to
the pyright lsp server before initialization also take from the [Issue](https://github.com/neovim/nvim-lspconfig/issues/500#issuecomment-851247107). 
(Thanks [lithammer](https://github.com/lithammer) and others).

This can be done as following:


```viml
" Use your plugin manager of choice

Plug 'HallerPatrick/py_lsp.nvim'

```

```lua

-- Init pyright server completly
require'py_lsp'.setup()

-- Or just use the util to inject python path
require'lspconfig'.pyright.setup {
    before_init = function(_, config)
        config.settings.python.pythonPath = require'py_lsp'.get_python_path(config.root_dir)
    end
}

```


## Features

Get current venv used

`:PyLspCurrentVenv`


## Note

This is by no way complete and supports only standard virtualenvs with a `pyvenv.cfg` file
somewhere in the cwd.

## Potential TODOs

- [ ] Allow for non local venvs to be used
- [ ] Allow tools like poetry to be used
- [ ] Nice TUI for some more information (current activate venv etc)
- [ ] Support for statuslines to expose current venv name

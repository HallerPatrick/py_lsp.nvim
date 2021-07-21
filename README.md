# py_lsp.nvim


This plugin is created due to following [Issue](https://github.com/neovim/nvim-lspconfig/issues/500#issuecomment-877305226).
It tackles the issues about the activation and usage of python virtualenv
for the nvim lsp. 

Is serves as a starter to make virtualenv usage more easier and transparent.

This plugin currently includes a utility to automatically pass a virtualenv to
the pyright lsp server before initialization also take from the [Issue](https://github.com/neovim/nvim-lspconfig/issues/500#issuecomment-851247107). 
(Thanks [lithammer](https://github.com/lithammer) and others).


#### WARNING: This is in a early stage. The API will change!


This can be done as following:


```viml
" Use your plugin manager of choice
Plug 'HallerPatrick/py_lsp.nvim'
```

```lua
require'py_lsp'.setup()
```


## Features

Get current venv used

`:PyLspCurrentVenv`

Deactivate current venv, which means shutting down the lsp server

`:PyLspDeactiveVenv`

Activate venv, optional accepts a venv to choose from, which is in the current workspace

`:PyLspActivateVenv <venv_name>`

### Configuratio

Default:

```
Default Values:
    language_server = "pyright",
    on_attach = require'completion'.on_attach,
    source_strategy = {"default", "poetry", "system"}
```

## Note

This is by no way complete and supports only standard virtualenvs with a `pyvenv.cfg` file
somewhere in the cwd.

## TODOs

- [ ] Allow for configuration of plugin
    - [ ] Order on which to look for venv
    - [ ] Disable auto sourcing
- [ ] Allow for non local venvs to be used
- [ ] Allow tools like poetry to be used
- [ ] Nice TUI for some more information (current activate venv etc)
- [ ] Support for statuslines to expose current venv name

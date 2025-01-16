# py_lsp.nvim

## What is py_lsp?

`py_lsp.nvim` is a neovim plugin that helps with using the [lsp](https://neovim.io/doc/user/lsp.html) feature for python development.

It tackles the problem about the activation and usage of python virtual environments and conda environments
for the nvim lsp.

Includes optional support for [nvim-notify](https://github.com/rcarriga/nviqm-notify) plugins (for custom popup information) and [nvim-lsp-installer](https://github.com/williamboman/nvim-lsp-installer) for LSP detection.
Includes a detection inside the Virtual Environment for the LSP presence as last fallback (before check in the host machine).

## Installation

Using [vim-plug](https://github.com/junegunn/vim-plug):

```viml
Plug 'HallerPatrick/py_lsp.nvim'
```

Using [packer.nvim](https://github.com/wbthomason/packer.nvim):

```lua
use {
    'HallerPatrick/py_lsp.nvim',
    -- Support for versioning
    -- tag = "v0.0.1" 
}
```

## Usage

Instead of initializing the server on your own, like in [nvim-lspconfig](https://github.com/neovim/nvim-lspconfig#quickstart),
`py_lsp` is doing that for you.

Put this in your `init.lua` (or wrap in lua call for your `init.vim`)

```lua
require'py_lsp'.setup {
  -- This is optional, but allows to create virtual envs from nvim
  host_python = "/path/to/python/bin",
  default_venv_name = ".venv" -- For local venv
}
```

This minimal setup will automatically pass a python virtual environment path
to the LSP client for completion/linting.

WARNING: `py_lsp` is currently not agnostic against other python lsp servers that are starting or attaching.
Please be aware of other plugins, autostarting lsp servers.

### Features

`py_lsp` exposes several commands that help with a virtual env workflow.

| Command              | Parameter | Usage                                                                                                                     |
| -------------------- | --------- | ------------------------------------------------------------------------------------------------------------------------- |
| `:PyLspCurrentVenv`  | No        | Prints the currently used python venv                                                                                     |
| `:PyLspDeactiveVenv` | No        | Shuts down the current LSP client                                                                                         |
| `:PyLspReload`       | No        | Reload LSP client with current python venv                                                                                |
| `:PyLspActivateVenv` | venv name | Activates a virtual env with given name (default: 'venv'). This venv should lie in project root                           |
| `:PyLspActivateCondaEnv` | env name | Activates a conda env with given name (default: 'base'). Requires `conda` to be installed on the system                |
| `:PyLspCreateVenv`   | venv name | Creates a virtual env with given name (default: 'venv'). Requires `host_python` to be set and have `virtualenv` installed |
| `:PyRun`             | Optional<command>   | Run files and modules from current virtuale env. If no arguments specified, will run current buffer                                                                           |
| `:PyLspFindVenvs`       | No        | List all found Virtualenvs found by different strategies. Select and reload LSP                                           |

Most of these commands can be also run over a popup menu with `:PyLspPopup`.


#### PyRun

The `:PyRun` command uses the currently activated virtuale environment to either execute the current buffer on
or the arguments passed to pather. If `toggleterm` is an available plugin the command is executed through 
a `toggleterm` terminal.


### Configuration

The configurations are not sensible yet, and are suiting my setup. This will change.

Default:

```
Default Values:
    auto_source = true,
    language_server = "pyright",
    source_strategies = {"default", "poetry", "conda", "hatch", "system"},
    capabilities = nil,
    host_python = nil,
    on_attach = nil,
    on_server_ready = nil
    default_venv_name = nil,
    pylsp_plugins = {}, // the table with the various pylsp plugins with their parameters
    venvs = {}
```


One can also provide settings like `default_venv_name` or `source_stragie` in a `pyproject.toml` file, 
to have a per-project setting which venv to use.

```toml
[tool.py_lsp]
default_venv_name = "my_conda_venv"

# Beware, that the source_strategie is a string, not a table
source_strategie = "conda"
```

This requires a plugin for loading toml files, so include the following in your nvim config:
Lazy:

```lua
{
    "HallerPatrick/py_lsp.nvim",
    dependencies = { "dharmx/toml.nvim" },
    ...
}
```

## Other Language servers

I am using `pyright` and therefore works well with `pyright`. When using a not registered language server
like `jedi-language-server` you can register it like following:

```lua
local nvim_lsp_configs = require "lspconfig.configs"

nvim_lsp_configs["jedi_language_server"] = {
    default_config = {
        cmd = {"jedi-language-server"},

        -- Depending on your environment
        root_dir = nvim_lsp.util.root_pattern(".git", "setup.py",
                                              "pyproject.toml"),
        filetypes = {"python"}
    }
}

local capabilities = require('cmp_nvim_lsp').update_capabilities(vim.lsp
                                                                     .protocol
                                                                     .make_client_capabilities())

require("py_lsp").setup({
    language_server = "jedi_language_server",
    capabilities = capabilities
})
```

## Todo

- Support for different environment systems:
  - virtualenvwrapper
  - Pipenv
- Agnostic against other python lsp server

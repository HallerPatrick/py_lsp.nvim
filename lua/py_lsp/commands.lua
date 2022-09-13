local M = {}

-- Mapping of command to function
M.commands = {
    PyLspReloadVenv = "reload_client",
    PyLspCurrentVenv = "print_venv",
    PyLspActivateVenv = "activate_venv",
    PyLspDeactivateVenv = "stop_client",
    PyLspCreateVenv = "create_venv",
    -- PyLspPopup = "create_popup",
    -- PyLspFindVenvs = "find_venvs"
    -- PyRun = "py_run"
}

M.commands_opts = {
    PyLspReloadVenv = { desc = "Reload LSP server with current venv" },
	PyLspCurrentVenv = { desc = "Print out current path to venv" },
	PyLspActivateVenv = { desc = "Activate venv (default name: 'venv')", nargs = "?" },
	PyLspDeactivateVenv = { desc = "Stop current running LSP client" },
	PyLspCreateVenv = { desc = "Create a venv in project directory (default name: 'venv')", nargs = "?" },
 --    PyLspFindVenvs = { desc = "Find usable venvs with defined settings and in path"},
	-- PyLspPopup = {}
    -- PyRun = "Run python commands with current virtual env"
}

return M

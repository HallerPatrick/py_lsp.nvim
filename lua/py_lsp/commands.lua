local M = {}

-- Mapping of command to function
M.commands = {
    PyLspReloadVenv = "reload_client",
    PyLspCurrentVenv = "print_venv",
    PyLspActivateVenv = "activate_venv",
    PyLspDeactivateVenv = "stop_client",
    PyLspCreateVenv = "create_venv",
    PyLspPopup = "create_popup"
    -- PyRun = "py_run"
}

-- Textual description of command
M.commands_to_text = {
    PyLspReloadVenv = "Reload LSP server with current venv",
    PyLspCurrentVenv = "Print out current path to venv",
    PyLspActivateVenv = "Activate venv (default name: 'venv')",
    PyLspDeactivateVenv = "Stop current running LSP client",
    PyLspCreateVenv = "Create a venv in project directory (default name: 'venv')"
    -- PyRun = "Run python commands with current virtual env"
}

return M

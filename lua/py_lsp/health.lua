local lsp_utils = require("py_lsp.lsp")
-- local py_lsp = require("py_lsp.init")

local M = {}

-- Function that is called with :checkhealth
-- Check if the setup is correct
M.check_setup = function()
  local client = lsp_utils.get_client()

  if not client then
    vim.health.error("No client attached")
    return false
  end

  local venv_name = lsp_utils.get_current_python_venv_path()
  if venv_name then
    vim.health.ok("Virtual Environment '" .. venv_name .. "' found and activated")
  else
    vim.health.error("Path to virtual environment not detected")
  end

  -- TODO: Why does this not work?
  -- if py_lsp.runtime.toml_file then
  --   vim.health.ok("pyproject.toml found")
  -- else
  --   vim.health.error("pyproject.toml not found")
  -- end

  return true
end

M.check = function()
  vim.health.start("py_lsp.nvim Report")

  -- Check for set path and venv
  if M.check_setup() then
    vim.health.ok("Setup is correct")
  else
    vim.health.error("Setup is incorrect")
  end
end

return M

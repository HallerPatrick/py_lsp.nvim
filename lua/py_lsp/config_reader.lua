local uv = uv or vim.loop

local toml = require("toml.engine")
local toml_util = require("toml.util")

local utils = require("py_lsp.utils")

local M = {}

M.find_pyproject_toml = function()
  local project_root = uv.cwd()
  local toml_file = project_root .. "/pyproject.toml"

  if not utils.file_exists(toml_file) then
    return nil
  end

  return toml_file
end

-- Read config from pyproject.toml in project root
-- @return table, string
M.read_config_from_file = function()
  local toml_file = M.find_pyproject_toml()

  if toml_file == nil then
    return nil, nil
  end

  local data = toml_util.read(toml_file)

  local config_table = toml.decode(data)

  if config_table == nil then
    return nil, nil
  end

  -- We do not map every config one-to-one, so manually adjust the config
  local adjusted_configs = {}

  if config_table.tool then
    if config_table.tool.py_lsp then
      local py_lsp_table = config_table.tool.py_lsp

      if py_lsp_table.default_venv_name then
        adjusted_configs.default_venv_name = py_lsp_table.default_venv_name
      end
      if py_lsp_table.source_strategie then
        adjusted_configs.source_strategies = { py_lsp_table.source_strategie }
      end

      return adjusted_configs, toml_file
    end
  end

  return nil, nil
end

return M

local defaults = {
    auto_source = true,
    language_server = "pyright",
    on_attach = nil,
    capabilities = nil,
    source_strategies = {"default", "poetry", "system"},
    host_python = nil, -- this python should include the virtualenv module
}

local options = vim.deepcopy(defaults)

local M = {}

function M.set(user_opts) options = vim.tbl_deep_extend("force", options, user_opts) end

function M.get() return options end

return M

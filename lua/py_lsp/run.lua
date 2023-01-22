local format = string.format

local M = {}

local function command_preamble(py_env, args)
    -- https://stackoverflow.com/a/1718607
    local green = '\27[92m'
    local reset = '\27[0m'

    local python_text = format("'[[%s Running command: %s %s %s]]\\n'", green, py_env, args, reset)
    return format("python -c \"print(%s)\"", python_text)
end

local Terminal = nil

local toggleterm_available, toggleterm = pcall(require, "toggleterm.terminal")

if toggleterm_available then Terminal = toggleterm.Terminal end

M.toggleterm_available = toggleterm_available

M.run_toggleterm = function(py_env, args)

    local cmd_preamble = command_preamble(py_env, args)
    local terminal = Terminal:new({
        cmd = format("%s && %s %s", cmd_preamble, py_env, args),
        close_on_exit = false
    })

    terminal:toggle()
end

M.run_system = function(py_env, args)
    -- TODO: Make this work
    -- if u.is_module_available("asyncrun") then
    --     vim.cmd("AsynRun echo 'Hello World'")
    -- else
    --     print(vim.fn.system(format("%s %s", py_path, args)))
    -- end
    print(vim.fn.system(format("%s %s", py_env, args)))
end

return M


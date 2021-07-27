local nvim_lsp = require("lspconfig")
local util = require("lspconfig/util")
local popups = require("popup")
local o = require("py_lsp.options")
local u = require("py_lsp.utils")
local c = require("py_lsp.commands")

local path = util.path
local format = string.format

local M = {}

M.o = {
	current_venv = nil,
	venv_name = nil,
}

local function get_python_path(workspace, source_strategy, venv_name)
	-- Use activated virtualenv.
	if vim.env.VIRTUAL_ENV then
		print("Using current venv")
		return path.join(vim.env.VIRTUAL_ENV, "bin", "python")
	end

	local patterns = { "*", ".*" }

	if venv_name ~= nil then
		patterns = { venv_name }
	end

	-- Find and use virtualenv in workspace directory.
	for _, pattern in ipairs(patterns) do
		local match = vim.fn.glob(path.join(workspace, pattern, "pyvenv.cfg"))

		if match ~= "" and vim.tbl_contains(source_strategy, "default") then
			-- TODO: We now take the one venv found first, what to change?
			if string.find(match, "\n") then
				match = vim.gsplit(match, "\n")()
			end

			local py_path = path.join(path.dirname(match), "bin", "python")
			return py_path
		end

		-- If no standard venv found look for poetry
		match = vim.fn.glob(path.join(workspace, "poetry.lock"))

		if match ~= "" and vim.tbl_contains(source_strategy, "poetry") ~= nil then
			local venv = vim.fn.trim(vim.fn.system("poetry env info -p"))
			return path.join(venv, "bin", "python")
		end
	end

	-- Fallback to system Python.
	return exepath("python3") or exepath("python") or "python"
end

local function on_init(source_strategy, venv_name)
	return function(client)
		client.config.settings.python.pythonPath = get_python_path(client.config.root_dir, source_strategy, venv_name)
		M.o.current_venv = client.config.settings.python.pythonPath
		client.config.settings.python.venv_name = u.get_python_venv_name(M.o.current_venv)
	end
end

local function run(venv_name)
	-- Setup server opts passed to language server
	M["server_opts"] = {
		on_init = on_init(o.get().source_strategy, venv_name),
		on_attach = o.get().on_attach,
		-- TODO: Can both on_init and before_init be used?
		before_init = o.get().on_init,
	}

	nvim_lsp.pyright.setup(M.server_opts)
end

local function get_client()
	local clients = vim.lsp.get_active_clients()

	if clients == nil or clients == {} then
		print("No python client attached")
		return
	end

	local current_client = nil
	for _, client in ipairs(clients) do
		if client ~= nil and client.name == "pyright" then
			current_client = client
		end
	end
	return current_client
end

M.print_venv = function()
	local client = get_client()
	if client == nil then
		print("No venv activated")
		return
	end
	print("Client pyright with venv: " .. client.config.settings.python.pythonPath)
end

M.stop_client = function()
	local client = get_client()
	vim.lsp.stop_client(client.id)
end

M.reload_client = function()
	local client = get_client()
	vim.lsp.stop_client(client.id)
	run(M.current_venv)
end

M.activate_venv = function(venv_name)
	local current_client = get_client()
	local cwd = vim.fn["getcwd"]()

	local match = vim.fn.glob(path.join(cwd, venv_name, "pyvenv.cfg"))

	if match ~= "" then
		if current_client ~= nil then
			print("Stopping current running lsp server")
			vim.lsp.stop_client(current_client.id)
		end

		run(venv_name)
		print("Activated venv")
	else
		print("Cannot find venv")
	end
end

M.create_venv = function(venv_name)
	local python = o.get().host_python

	if not python then
		print("No python host configured")
	end

	venv_name = venv_name or "venv"

	local output = vim.fn.trim(vim.fn.system(format("%s -m virtualenv %s", python, venv_name)))
	print(output)
	run(venv_name)
end

M.create_popup = function()
	local win, buf = popup.make_popup()

	M.popup_win = win

	local lines = popup.format_lines(vim.tbl_values(c.commands_to_text))

	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

	vim.api.nvim_buf_set_keymap(
		buf,
		"n",
		"<CR>",
		":lua require('py_lsp').execute_command() <CR>",
		{ nowait = true, noremap = true, silent = true }
	)
	vim.api.nvim_win_set_option(win, "cursorline", true)
end

M.execute_command = function()
	local pos = vim.api.nvim_win_get_cursor(M.popup_win)
	local row = pos[1]
	local line = vim.tbl_values(c.commands_to_text)[row]
	local command = u.get_key_for_value(c.commands_to_text, line)
	M[c.commands[command]]()

	-- Close window and open new buffer with target file
	vim.api.nvim_win_close(M.pop_window, true)
end

M.py_run = function(...)
	local args = { ... }
	args = table.concat(args, " ")
	local client = get_client()

	local py_path = client.config.settings.python.pythonPath

	print(vim.fn.system(format("%s %s", py_path, args)))
end

M.setup = function(opts)
	-- Init all commands
	for command, func in pairs(c.commands) do
		u.define_command(command, func)
	end

	-- Collect all opts from defaults and user
	opts = opts or {}
	o.set(opts)

	if o.get().auto_source then
		run(opts.venv_name)
	end
end

return M

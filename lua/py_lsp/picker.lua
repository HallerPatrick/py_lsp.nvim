local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")

local commands = require("py_lsp.commands")

local M = {}

function M.popup_picker(opts, func_map)
	opts = opts or {}

	local func

	pickers.new(opts, {
		prompt_title = "py_lsp.nvim actions",
		finder = finders.new_table({
			results = vim.tbl_values(commands.commands_opts),
		}),
		sorter = conf.generic_sorter(opts),
		attach_mappings = function(prompt_bufnr, _)
			actions.select_default:replace(function()
				actions.close(prompt_bufnr)
				local selection = action_state.get_selected_entry()
				func = vim.tbl_values(commands.commands)[selection.index]
				func_map[func]()
			end)
			return true
		end,
	}):find()
end

function M.find_vens_picker(opts, annotated_venvs, collected_venvs, run_func)
	pickers.new(opts, {
		prompt_title = "py_lsp.nvim: Python virtual environments",
		finder = finders.new_table({
			results = annotated_venvs,
		}),
		sorter = conf.generic_sorter(opts),
		attach_mappings = function(prompt_bufnr, _)
			actions.select_default:replace(function()
				actions.close(prompt_bufnr)
				local selection = action_state.get_selected_entry()
				local selected_path = vim.tbl_keys(collected_venvs)[selection.index]
				-- We use lsp.stop_client before
				vim.lsp.stop_client()

				run_func(selected_path, true)
			end)
			return true
		end,
	}):find()
end

return M

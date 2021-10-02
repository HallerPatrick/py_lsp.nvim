local api = vim.api

local M = {}

M.make_popup_window = function()
    local buf = api.nvim_create_buf(false, true) -- create new emtpy buffer

    api.nvim_buf_set_option(buf, "bufhidden", "wipe")

    -- get dimensions
    local width = api.nvim_get_option("columns")
    local height = api.nvim_get_option("lines")

    -- calculate our floating window size
    local win_height = math.ceil(height * 0.08)
    local win_width = math.ceil(width * 0.4)

    -- and its starting position
    local row = math.ceil((height - win_height) / 2 - 1)
    local col = math.ceil((width - win_width) / 2)

    -- set some options
    local opts = {
        style = "minimal",
        relative = "editor",
        width = win_width,
        height = win_height,
        row = row,
        col = col
    }

    local border_opts = {
        style = "minimal",
        relative = "editor",
        width = win_width + 2,
        height = win_height + 2,
        row = row - 1,
        col = col - 1
    }

    local border_buf = api.nvim_create_buf(false, true)

    local border_lines = {"╔" .. string.rep("═", win_width) .. "╗"}
    local middle_line = "║" .. string.rep(" ", win_width) .. "║"
    for i = 1, win_height do table.insert(border_lines, middle_line) end
    table.insert(border_lines, "╚" .. string.rep("═", win_width) .. "╝")

    api.nvim_buf_set_lines(border_buf, 0, -1, false, border_lines)

    -- and finally create it with buffer attached
    api.nvim_open_win(border_buf, true, border_opts)
    local win = api.nvim_open_win(buf, true, opts)
    api.nvim_command('au BufWipeout <buffer> exe "silent bwipeout! "' .. border_buf)

    return win, buf
end

M.format_lines = function(lines)
    for index = 1, #lines do lines[index] = string.format(" %s. %s", index, lines[index]) end

    return lines
end

M.create_popup = function(list, callback)
    local win, buf = M.make_popup_window()

    M.popup_win = win

    local lines = M.format_lines(list)

    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.api.nvim_win_set_option(win, "cursorline", true)

    vim.api.nvim_buf_set_keymap(buf, "n", "<CR>",
                                ":lua require('py_lsp.popup').execute_command() <CR>", {
        nowait = true,
        noremap = true,
        silent = true
    })

    -- Save callback so it can be called in execute_commnad
    M.popup_callback = callback
end

M.execute_command = function()
    local pos = vim.api.nvim_win_get_cursor(M.popup_win)
    local row = pos[1]

    M.popup_callback(row)

    -- Close window
    vim.api.nvim_win_close(M.pop_window, true)
end

return M

local M = {}

M.get_client = function(lsp_server_name)
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

return M

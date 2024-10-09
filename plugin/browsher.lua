if vim.g.loaded_browsher then
	return
end
vim.g.loaded_browsher = true

vim.api.nvim_create_user_command("Browsher", function(opts)
	require("browsher").open_in_browser(opts)
end, { range = true })

if vim.g.loaded_browsher then
	return
end
vim.g.loaded_browsher = true

vim.api.nvim_create_user_command("Browsher", function(opts)
	require("browsher").open_in_browser(opts)
end, {
	range = true,
	nargs = "?",
	complete = function(arglead)
		local completions = { "branch", "tag", "commit" }
		return vim.tbl_filter(function(option)
			return option:sub(1, #arglead):lower() == arglead:lower()
		end, completions)
	end,
	desc = [[
Open current file in browser pinned to a specific branch, tag, or commit.
Usage: :Browsher [branch|tag|commit] [commit_hash]
]],
})

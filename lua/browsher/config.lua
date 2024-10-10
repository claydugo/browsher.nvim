local M = {}

local default_show_message = true
if vim.o.cmdheight == 0 then
	default_show_message = false
end

M.options = {
	default_remote = "origin",
	default_branch = nil,
	show_message = default_show_message,
	default_pin = "commit",
}

function M.setup(user_options)
	M.options = vim.tbl_extend("force", M.options, user_options or {})
end

return M

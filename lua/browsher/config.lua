local M = {}

local default_show_message = true
if vim.o.cmdheight == 0 then
	default_show_message = false
end

M.options = {
	default_remote = nil,
	default_branch = nil,
	show_message = default_show_message,
	default_pin = "commit",
	allow_line_numbers_with_uncommitted_changes = false,
}

function M.setup(user_options)
	M.options = vim.tbl_extend("force", M.options, user_options or {})
end

return M

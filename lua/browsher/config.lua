local M = {}

M.options = {
  default_branch = 'main',
}

function M.setup(user_options)
  M.options = vim.tbl_extend('force', M.options, user_options or {})
end

return M

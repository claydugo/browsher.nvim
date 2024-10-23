local M = {}

function M.check()
	local health = vim.health or require("health")
	local start = health.start or health.report_start
	local ok = health.ok or health.report_ok
	local warn = health.warn or health.report_warn
	local error = health.error or health.report_error

	start("browsher.nvim")

	local git_executable = vim.fn.executable("git")
	if git_executable ~= 1 then
		error("Git is not installed or not in PATH.")
	else
		local git_path = vim.fn.exepath("git")
		ok(string.format("Git is installed: %s", git_path))
	end
end

return M

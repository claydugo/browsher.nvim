local git = require("browsher.git")
local url_builder = require("browsher.url")
local config = require("browsher.config")

local M = {}

local function notify(message, level)
	vim.schedule(function()
		vim.notify(message, level)
	end)
end

local function notify_error(message)
	notify(message, vim.log.levels.ERROR)
end

local function get_open_command()
	if config.options.open_cmd then
		return config.options.open_cmd
	end
	if vim.fn.has("macunix") == 1 then
		return "open"
	elseif vim.fn.has("unix") == 1 then
		return "xdg-open"
	elseif vim.fn.has("win32") == 1 then
		return "start"
	else
		return nil
	end
end

local function open_url(url)
	local open_cmd = get_open_command()
	if not open_cmd then
		notify_error("Unsupported OS")
		return
	end

	vim.fn.jobstart({ open_cmd, url }, { detach = true })

	if config.options.show_message then
		notify("Opening " .. url)
	end
end

function M.open_in_browser(opts)
	local git_root, err = git.get_git_root()
	if not git_root then
		notify_error(err)
		return
	end

	local relpath, err = git.get_file_relative_path(git_root)
	if not relpath then
		notify_error(err)
		return
	end

	local remote_name = config.options.default_remote or "origin"
	local remote_url, err = git.get_remote_url(remote_name)
	if not remote_url then
		notify_error(err)
		return
	end

	local branch_or_tag, err = git.get_current_branch()
	if not branch_or_tag then
		notify_error(err)
		return
	end

	local default_branch = config.options.default_branch
	if not default_branch then
		default_branch, err = git.get_default_branch(remote_name)
		if not default_branch then
			notify_error(err)
			return
		end
	end

	if branch_or_tag == default_branch then
		local latest_tag = git.get_latest_tag()
		if latest_tag then
			branch_or_tag = latest_tag
		else
			branch_or_tag = default_branch
		end
	else
		local commit_hash, err = git.get_current_commit_hash()
		if commit_hash then
			branch_or_tag = commit_hash
		else
			notify_error(err or "Could not determine the latest commit hash")
			return
		end
	end

	local has_changes = git.has_uncommitted_changes(relpath)
	local line_info = nil

	if has_changes then
		notify("Warning: Uncommitted changes detected in this file. Line number removed from URL.", vim.log.levels.WARN)
	else
		if opts and opts.range > 0 then
			local start_line = opts.line1
			local end_line = opts.line2
			if start_line > end_line then
				start_line, end_line = end_line, start_line
			end
			line_info = { start_line = start_line, end_line = end_line }
		else
			local line_number = vim.api.nvim_win_get_cursor(0)[1]
			line_info = { line_number = line_number }
		end
	end

	local url, err = url_builder.build_url(remote_url, branch_or_tag, relpath, line_info)
	if not url then
		notify_error(err)
		return
	end

	open_url(url)
end

function M.setup(user_options)
	config.setup(user_options)
end

return M

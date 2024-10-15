local git = require("browsher.git")
local url_builder = require("browsher.url")
local config = require("browsher.config")

local M = {}

local function notify(message, level)
	vim.schedule(function()
		vim.notify(message, level)
	end)
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
		return { "explorer.exe" }
	else
		return nil
	end
end

local function open_url(url)
	local open_cmd = get_open_command()
	if not open_cmd then
		notify("Unsupported OS", vim.log.levels.ERROR)
		return
	end

	if type(open_cmd) == "table" then
		vim.fn.jobstart(vim.tbl_flatten({ open_cmd, url }), { detach = true })
	else
		vim.fn.jobstart({ open_cmd, url }, { detach = true })
	end

	if config.options.show_message then
		notify("Opening " .. url)
	end
end

function M.open_in_browser(opts)
	local args = {}
	if opts.args then
		for word in string.gmatch(opts.args, "%S+") do
			table.insert(args, word)
		end
	end

	local pin_type = args[1] or config.options.default_pin or "commit"
	local specific_commit = args[2]

	if pin_type ~= "commit" and pin_type ~= "branch" and pin_type ~= "tag" then
		notify("Invalid argument. Use 'branch', 'tag', or 'commit'.", vim.log.levels.ERROR)
		return
	end

	local git_root, root_error = git.get_git_root()
	if not git_root then
		notify(root_error, vim.log.levels.ERROR)
		return
	end

	local relpath, path_error = git.get_file_relative_path()
	if not relpath then
		notify(path_error, vim.log.levels.ERROR)
		return
	end

	local remote_name = config.options.default_remote or "origin"
	local remote_url, remote_error = git.get_remote_url(remote_name)
	if not remote_url then
		notify(remote_error, vim.log.levels.ERROR)
		return
	end

	local branch_or_tag, branch_or_tag_error = git.get_latest_tag()
	if pin_type == "tag" then
		branch_or_tag, branch_or_tag_error = git.get_latest_tag()
		if not branch_or_tag then
			notify(branch_or_tag_error or "Could not determine the latest tag", vim.log.levels.ERROR)
			return
		end
	elseif pin_type == "branch" then
		branch_or_tag, branch_or_tag_error = git.get_current_branch()
		if not branch_or_tag then
			notify(branch_or_tag_error or "Could not determine the current branch", vim.log.levels.ERROR)
			return
		end
	elseif pin_type == "commit" then
		if specific_commit then
			if not specific_commit:match("^[0-9a-fA-F]+$") then
				notify("Invalid commit hash format.", vim.log.levels.ERROR)
				return
			end
			branch_or_tag = specific_commit
		else
			branch_or_tag, branch_or_tag_error = git.get_current_commit_hash()
			if not branch_or_tag then
				notify(branch_or_tag_error or "Could not determine the latest commit hash", vim.log.levels.ERROR)
				return
			end
		end
	end

	local has_changes = git.has_uncommitted_changes(relpath)
	local line_info = nil

	if has_changes then
		notify("Warning: Uncommitted changes detected in this file. Line number removed from URL.", vim.log.levels.WARN)
	else
		if opts.range then
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
		notify(err, vim.log.levels.ERROR)
		return
	end

	open_url(url)
end

function M.setup(user_options)
	config.setup(user_options)
end

return M

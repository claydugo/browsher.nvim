local git = require("browsher.git")
local url_builder = require("browsher.url")
local config = require("browsher.config")
local utils = require("browsher.utils")

local M = {}

local function get_open_command()
	if config.options.open_cmd then
		-- Ensure it's a table
		if type(config.options.open_cmd) == "string" then
			return { config.options.open_cmd }
		else
			return config.options.open_cmd
		end
	end
	if vim.fn.has("macunix") == 1 then
		return { "open" }
	elseif vim.fn.has("unix") == 1 then
		return { "xdg-open" }
	elseif vim.fn.has("win32") == 1 then
		return { "explorer.exe" }
	else
		return nil
	end
end

local function open_url(url)
	local open_cmd = get_open_command()
	if not open_cmd then
		utils.notify("Unsupported OS", vim.log.levels.ERROR)
		return
	end

	-- Append the URL to the command
	table.insert(open_cmd, url)

	-- Start the job
	vim.fn.jobstart(open_cmd, { detach = true })

	if config.options.show_message then
		utils.notify("Opening " .. url)
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
		utils.notify("Invalid argument. Use 'branch', 'tag', or 'commit'.", vim.log.levels.ERROR)
		return
	end

	local git_root = git.get_git_root()
	if not git_root then
		return
	end

	local relpath = git.get_file_relative_path()
	if not relpath then
		return
	end

	local remote_name = config.options.default_remote or "origin"
	local remote_url = git.get_remote_url(remote_name)
	if not remote_url then
		return
	end

	local branch_or_tag
	if pin_type == "tag" then
		branch_or_tag = git.get_latest_tag()
		if not branch_or_tag then
			return
		end
	elseif pin_type == "branch" then
		branch_or_tag = git.get_current_branch()
		if not branch_or_tag then
			return
		end
	elseif pin_type == "commit" then
		if specific_commit then
			if not specific_commit:match("^[0-9a-fA-F]+$") then
				utils.notify("Invalid commit hash format.", vim.log.levels.ERROR)
				return
			end
			branch_or_tag = specific_commit
		else
			branch_or_tag = git.get_current_commit_hash()
			if not branch_or_tag then
				return
			end
		end
	end

	local has_changes = git.has_uncommitted_changes(relpath)
    local line_info = nil

    if has_changes then
        utils.notify(
            "Warning: Uncommitted changes detected in this file. Line number removed from URL.",
            vim.log.levels.WARN
        )
    else
        if opts.range > 0 then
            local start_line = opts.line1
            local end_line = opts.line2
            if start_line > end_line then
                start_line, end_line = end_line, start_line
            end
            if start_line == end_line then
                line_info = { line_number = start_line }
            else
                line_info = { start_line = start_line, end_line = end_line }
            end
        else
            local mode = vim.fn.mode()
            if mode == 'v' or mode == 'V' or mode == '\22' then
                local start_line = vim.fn.line("v")
                local end_line = vim.fn.line(".")
                if start_line > end_line then
                    start_line, end_line = end_line, start_line
                end
                if start_line == end_line then
                    line_info = { line_number = start_line }
                else
                    line_info = { start_line = start_line, end_line = end_line }
                end
            else
                local line_number = vim.api.nvim_win_get_cursor(0)[1]
                line_info = { line_number = line_number }
            end
        end
    end

	local url = url_builder.build_url(remote_url, branch_or_tag, relpath, line_info)
	if not url then
		return
	end

	open_url(url)
end

function M.setup(user_options)
	config.setup(user_options)
end

return M

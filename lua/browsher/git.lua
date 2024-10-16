local M = {}
local utils = require("browsher.utils")

-- Check if Git is available when the module is loaded
if vim.fn.executable("git") ~= 1 then
	utils.notify("Git is not installed or not in PATH. browsher.nvim will not function.", vim.log.levels.ERROR)
	return M -- Return early; the module will be empty
end

-- Run a Git command and return its output or nil
local function run_git_command(cmd, git_root)
	if git_root then
		cmd = string.format("git -C %s %s", vim.fn.shellescape(git_root), cmd)
	else
		cmd = "git " .. cmd
	end
	local output = vim.fn.systemlist(cmd .. " 2>&1")
	if vim.v.shell_error ~= 0 then
		local error_message = table.concat(output, "\n")
		utils.notify("Git command failed: " .. error_message, vim.log.levels.ERROR)
		return nil
	end
	return output
end

function M.get_git_root()
	local output = run_git_command("rev-parse --show-toplevel")
	if not output or output[1] == "" then
		utils.notify("Not inside a Git repository.", vim.log.levels.ERROR)
		return nil
	end
	return output[1]
end

function M.get_remote_url(remote_name)
	remote_name = remote_name or "origin"
	local git_root = M.get_git_root()
	if not git_root then
		return nil
	end

	local cmd = string.format("config --get remote.%s.url", remote_name)
	local output = run_git_command(cmd, git_root)
	if not output or output[1] == "" then
		utils.notify("No remote named '" .. remote_name .. "' is set.", vim.log.levels.ERROR)
		return nil
	end
	return output[1]
end

function M.get_current_branch()
	local git_root = M.get_git_root()
	if not git_root then
		return nil
	end

	local output = run_git_command("symbolic-ref --short HEAD", git_root)
	if output and output[1] ~= "" then
		return output[1]
	end

	output = run_git_command("rev-parse --short HEAD", git_root)
	if output and output[1] ~= "" then
		return output[1]
	end

	utils.notify("Could not determine the current branch or commit hash.", vim.log.levels.ERROR)
	return nil
end

function M.get_latest_tag()
	local git_root = M.get_git_root()
	if not git_root then
		return nil
	end

	local output = run_git_command("describe --tags --abbrev=0", git_root)
	if output and output[1] ~= "" then
		return output[1]
	end
	utils.notify("Could not determine the latest tag.", vim.log.levels.ERROR)
	return nil
end

function M.get_current_commit_hash()
	local git_root = M.get_git_root()
	if not git_root then
		return nil
	end

	local output = run_git_command("rev-parse HEAD", git_root)
	if output and output[1] ~= "" then
		return output[1]
	end
	utils.notify("Could not determine the latest commit hash.", vim.log.levels.ERROR)
	return nil
end

function M.get_file_relative_path()
	local git_root = M.get_git_root()
	if not git_root then
		return nil
	end

	local filepath = vim.api.nvim_buf_get_name(0)
	if filepath == "" then
		utils.notify("No file to open.", vim.log.levels.ERROR)
		return nil
	end

	filepath = vim.fn.fnamemodify(filepath, ":p")
	git_root = vim.fn.fnamemodify(git_root, ":p")

	git_root = git_root:gsub("[/\\]$", "")

	if filepath:sub(1, #git_root) ~= git_root then
		utils.notify("File is not inside the Git repository.", vim.log.levels.ERROR)
		return nil
	end

	local relpath = filepath:sub(#git_root + 2)
	relpath = relpath:gsub("\\", "/")
	return relpath
end

function M.has_uncommitted_changes(relpath)
	local git_root = M.get_git_root()
	if not git_root then
		return false
	end
	local cmd = "diff --name-only -- " .. vim.fn.shellescape(relpath)
	local output = run_git_command(cmd, git_root)
	return output and #output > 0
end

function M.get_default_branch(remote_name)
	remote_name = remote_name or "origin"
	local git_root = M.get_git_root()
	if not git_root then
		return nil
	end

	local cmd = string.format("symbolic-ref refs/remotes/%s/HEAD", remote_name)
	local output = run_git_command(cmd, git_root)
	if output and output[1] ~= "" then
		local default_branch = output[1]:match("refs/remotes/[^/]+/(.+)")
		if default_branch then
			return default_branch
		end
	end

	cmd = string.format("remote show %s", remote_name)
	output = run_git_command(cmd, git_root)
	if output then
		for _, line in ipairs(output) do
			local branch = line:match("HEAD branch: (.+)")
			if branch then
				return branch
			end
		end
	end

	utils.notify("Could not determine the default branch.", vim.log.levels.ERROR)
	return nil
end

return M

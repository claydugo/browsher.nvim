local M = {}
local config = require("browsher.config")
local utils = require("browsher.utils")

if vim.fn.executable("git") ~= 1 then
    utils.notify("Git is not installed or not in PATH. browsher.nvim will not function.", vim.log.levels.ERROR)
    return M
end

--- Run a Git command and return the output.
---
---@param cmd string The git command to run (without 'git' prefix).
---@param git_root string|nil The path to the git repository root.
---@return table|nil Output lines as a table, or nil on error.
local function run_git_command(cmd, git_root)
    if git_root then
        cmd = string.format("git -C %s %s", vim.fn.fnameescape(git_root), cmd)
    else
        cmd = "git " .. cmd
    end
    local output = vim.fn.systemlist(cmd)
    if vim.v.shell_error ~= 0 then
        local error_message = table.concat(output, "\n")
        utils.notify("Git command failed: " .. error_message, vim.log.levels.ERROR)
        return nil
    end
    for i, line in ipairs(output) do
        output[i] = line:gsub("\r$", "")
    end
    return output
end

--- Get the root directory of the git repository.
---
---@return string|nil The path to the git root, or nil if not inside a git repository.
function M.get_git_root()
    local output = run_git_command("rev-parse --show-toplevel")
    if not output or output[1] == "" then
        utils.notify("Not inside a Git repository.", vim.log.levels.ERROR)
        return nil
    end
    local git_root = output[1]:gsub("\r$", "")
    return git_root
end

--- Normalize file paths to use forward slashes.
---
---@param path string The file path to normalize.
---@return string The normalized file path.
function M.normalize_path(path)
    -- Only return the modified string, not the number of substitutions.
    return (path:gsub("\\", "/"))
end

--- Get the URL of the specified remote.
---
---@param remote_name string|nil The name of the remote (default: default remote).
---@return string|nil The remote URL, or nil on error.
function M.get_remote_url(remote_name)
    remote_name = remote_name or M.get_default_remote()
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

--- Get the default remote name (first one in the list).
---
---@return string|nil The default remote name, or nil if none found.
function M.get_default_remote()
    local git_root = M.get_git_root()
    if not git_root then
        return nil
    end
    local output = run_git_command("remote", git_root)
    if output and #output > 0 then
        return output[1]
    end
    utils.notify("No remotes found in the repository.", vim.log.levels.ERROR)
    return nil
end

--- Get the current branch name or commit hash.
---
---@return string|nil The branch name or commit hash.
---@return string|nil 'branch' or 'commit' to indicate the type.
function M.get_current_branch_or_commit()
    local git_root = M.get_git_root()
    if not git_root then
        return nil
    end

    if config.options.default_branch then
        return config.options.default_branch, "branch"
    end

    local output = run_git_command("symbolic-ref --short HEAD", git_root)
    if output and output[1] ~= "" then
        return output[1], "branch"
    end

    output = run_git_command("rev-parse --short HEAD", git_root)
    if output and output[1] ~= "" then
        return output[1], "commit"
    end

    utils.notify("Could not determine the current branch or commit hash.", vim.log.levels.ERROR)
    return nil
end

--- Get the latest tag.
---
---@return string|nil The latest tag, or nil if not found.
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

--- Get the current commit hash.
---
---@return string|nil The current commit hash, or nil if not found.
function M.get_current_commit_hash()
    local git_root = M.get_git_root()
    if not git_root then
        return nil
    end

    local abbrev_arg
    local commit_length = config.options.commit_length
    if commit_length then
        abbrev_arg = string.format("--short=%d", commit_length)
    else
        abbrev_arg = ""
    end

    local cmd = string.format("rev-parse %s HEAD", abbrev_arg)
    local output = run_git_command(cmd, git_root)
    if output and output[1] ~= "" then
        return output[1]
    end
    utils.notify("Could not determine the current commit hash.", vim.log.levels.ERROR)
    return nil
end

--- Get the file path relative to the git root.
---
---@return string|nil The relative file path, or nil if not inside the repository.
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

    local normalized_filepath = filepath:gsub("\\", "/")
    local normalized_git_root = git_root:gsub("\\", "/")

    if normalized_filepath:sub(1, #normalized_git_root) ~= normalized_git_root then
        utils.notify("File is not inside the Git repository.", vim.log.levels.ERROR)
        return nil
    end

    local relative_path = filepath:sub(#git_root + 2)
    relative_path = M.normalize_path(relative_path)
    return relative_path
end

--- Check if the file has uncommitted changes.
---
---@param relative_path string The relative file path.
---@return boolean True if there are uncommitted changes, false otherwise.
function M.has_uncommitted_changes(relative_path)
    local git_root = M.get_git_root()
    if not git_root then
        return false
    end
    local cmd = "diff --name-only -- " .. vim.fn.fnameescape(relative_path)
    local output = run_git_command(cmd, git_root)
    return (output ~= nil) and (#output > 0)
end

--- Check if the file is tracked by Git.
---
---@param relative_path string The relative file path.
---@return boolean True if the file is tracked, false otherwise.
function M.is_file_tracked(relative_path)
    local git_root = M.get_git_root()
    if not git_root then
        return false
    end
    local cmd = "ls-files --error-unmatch -- " .. vim.fn.fnameescape(relative_path)
    local output = run_git_command(cmd, git_root)
    return output ~= nil
end

--- Get the default branch of the remote repository.
---
---@param remote_name string|nil The name of the remote (default: default remote).
---@return string|nil The default branch name, or nil if not found.
function M.get_default_branch(remote_name)
    remote_name = remote_name or M.get_default_remote()
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

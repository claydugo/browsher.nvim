local M = {}
local config = require("browsher.config")
local utils = require("browsher.utils")

if vim.fn.executable("git") ~= 1 then
    utils.notify("Git is not installed or not in PATH. browsher.nvim will not function.", vim.log.levels.ERROR)
    return M
end

---@class GitResult
---@field output string[]|nil Output lines, or nil on error.
---@field exit_code number Shell exit code.

--- Run a Git command and return the result.
---
---@param cmd string The git command to run (without 'git' prefix).
---@param git_root string|nil The path to the git repository root.
---@return GitResult
local function run_git_command(cmd, git_root)
    if git_root then
        cmd = string.format("git -C %s %s", vim.fn.fnameescape(git_root), cmd)
    else
        cmd = "git " .. cmd
    end
    local output = vim.fn.systemlist(cmd)
    local exit_code = vim.v.shell_error
    if exit_code ~= 0 then
        return { output = nil, exit_code = exit_code }
    end
    for i, line in ipairs(output) do
        output[i] = line:gsub("\r$", "")
    end
    return { output = output, exit_code = 0 }
end

--- Internal cache for git root, keyed by cwd to handle directory changes.
---@type table<string, string>
local git_root_cache = {}

--- Get the root directory of the git repository.
---
---@param use_cache boolean|nil Whether to use cached value (default: false for public API safety).
---@return string|nil The path to the git root, or nil if not inside a git repository.
function M.get_git_root(use_cache)
    local cwd = vim.fn.getcwd()
    if use_cache and git_root_cache[cwd] then
        return git_root_cache[cwd]
    end
    local result = run_git_command("rev-parse --show-toplevel")
    if not result.output or result.output[1] == "" then
        return nil
    end
    local git_root = result.output[1]:gsub("\r$", "")
    git_root_cache[cwd] = git_root
    return git_root
end

--- Clear the cached git roots.
function M.clear_cache()
    git_root_cache = {}
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
---@param remote_name string|nil The name of the remote (defaults to first remote).
---@param git_root string|nil The git root (fetched if nil).
---@return string|nil The remote URL, or nil on error.
function M.get_remote_url(remote_name, git_root)
    git_root = git_root or M.get_git_root()
    if not git_root then
        return nil
    end

    remote_name = remote_name or M.get_default_remote(git_root)
    if not remote_name then
        return nil
    end

    local cmd = string.format("config --get remote.%s.url", remote_name)
    local result = run_git_command(cmd, git_root)
    if not result.output or result.output[1] == "" then
        return nil
    end
    return result.output[1]
end

--- Get the default remote name (first one in the list).
---
---@param git_root string|nil The git root (uses cached if nil).
---@return string|nil The default remote name, or nil if none found.
function M.get_default_remote(git_root)
    git_root = git_root or M.get_git_root()
    if not git_root then
        return nil
    end
    local result = run_git_command("remote", git_root)
    if result.output and #result.output > 0 then
        return result.output[1]
    end
    return nil
end

--- Check if the repository is in detached HEAD state.
---
---@param git_root string|nil The git root (uses cached if nil).
---@return boolean True if in detached HEAD state.
function M.is_detached_head(git_root)
    git_root = git_root or M.get_git_root()
    if not git_root then
        return false
    end
    local result = run_git_command("symbolic-ref -q HEAD", git_root)
    return result.exit_code ~= 0
end

--- Get the current branch name (only if on a branch, not detached HEAD).
---
---@param git_root string|nil The git root (uses cached if nil).
---@return string|nil The branch name, or nil if detached or error.
function M.get_current_branch(git_root)
    git_root = git_root or M.get_git_root()
    if not git_root then
        return nil
    end

    if config.options.default_branch then
        return config.options.default_branch
    end

    local result = run_git_command("symbolic-ref --short HEAD", git_root)
    if result.output and result.output[1] ~= "" then
        return result.output[1]
    end
    return nil
end

--- Get the current branch name or commit hash.
---
---@param git_root string|nil The git root (uses cached if nil).
---@return string|nil The branch name or commit hash.
---@return string|nil 'branch' or 'commit' to indicate the type.
function M.get_current_branch_or_commit(git_root)
    git_root = git_root or M.get_git_root()
    if not git_root then
        return nil
    end

    local branch = M.get_current_branch(git_root)
    if branch then
        return branch, "branch"
    end

    local result = run_git_command("rev-parse --short HEAD", git_root)
    if result.output and result.output[1] ~= "" then
        return result.output[1], "commit"
    end

    return nil
end

--- Get the latest tag.
---
---@param git_root string|nil The git root (uses cached if nil).
---@return string|nil The latest tag, or nil if not found.
function M.get_latest_tag(git_root)
    git_root = git_root or M.get_git_root()
    if not git_root then
        return nil
    end

    local result = run_git_command("describe --tags --abbrev=0", git_root)
    if result.output and result.output[1] ~= "" then
        return result.output[1]
    end
    return nil
end

--- Get the current commit hash.
---
---@param git_root string|nil The git root (uses cached if nil).
---@return string|nil The current commit hash, or nil if not found.
function M.get_current_commit_hash(git_root)
    git_root = git_root or M.get_git_root()
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
    local result = run_git_command(cmd, git_root)
    if result.output and result.output[1] ~= "" then
        return result.output[1]
    end
    return nil
end

--- Get the file path relative to the git root.
---
---@param git_root string|nil The git root (uses cached if nil).
---@return string|nil The relative file path, or nil if not inside the repository.
function M.get_file_relative_path(git_root)
    git_root = git_root or M.get_git_root()
    if not git_root then
        return nil
    end

    local filepath = vim.api.nvim_buf_get_name(0)
    if filepath == "" then
        return nil
    end

    filepath = vim.fn.fnamemodify(filepath, ":p")
    local expanded_root = vim.fn.fnamemodify(git_root, ":p"):gsub("[/\\]$", "")

    local normalized_filepath = filepath:gsub("\\", "/")
    local normalized_git_root = expanded_root:gsub("\\", "/")

    if normalized_filepath:sub(1, #normalized_git_root) ~= normalized_git_root then
        return nil
    end

    local relative_path = filepath:sub(#expanded_root + 2)
    return M.normalize_path(relative_path)
end

--- Check if the file has uncommitted changes.
---
---@param relative_path string The relative file path.
---@param git_root string|nil The git root (uses cached if nil).
---@return boolean True if there are uncommitted changes, false otherwise.
function M.has_uncommitted_changes(relative_path, git_root)
    git_root = git_root or M.get_git_root()
    if not git_root then
        return false
    end
    local cmd = "diff --name-only -- " .. vim.fn.fnameescape(relative_path)
    local result = run_git_command(cmd, git_root)
    return result.output ~= nil and #result.output > 0
end

--- Check if the file is tracked by Git.
---
---@param relative_path string The relative file path.
---@param git_root string|nil The git root (uses cached if nil).
---@return boolean True if the file is tracked, false otherwise.
function M.is_file_tracked(relative_path, git_root)
    git_root = git_root or M.get_git_root()
    if not git_root then
        return false
    end
    local cmd = "ls-files --error-unmatch -- " .. vim.fn.fnameescape(relative_path)
    local result = run_git_command(cmd, git_root)
    return result.output ~= nil
end

--- Get the default branch of the remote repository.
---
---@param remote_name string|nil The name of the remote.
---@param git_root string|nil The git root (uses cached if nil).
---@return string|nil The default branch name, or nil if not found.
function M.get_remote_default_branch(remote_name, git_root)
    git_root = git_root or M.get_git_root()
    if not git_root then
        return nil
    end
    remote_name = remote_name or M.get_default_remote(git_root)
    if not remote_name then
        return nil
    end

    local cmd = string.format("symbolic-ref refs/remotes/%s/HEAD", remote_name)
    local result = run_git_command(cmd, git_root)
    if result.output and result.output[1] ~= "" then
        local default_branch = result.output[1]:match("refs/remotes/[^/]+/(.+)")
        if default_branch then
            return default_branch
        end
    end

    -- Fallback: query the remote (slower, requires network)
    cmd = string.format("remote show %s", remote_name)
    result = run_git_command(cmd, git_root)
    if result.output then
        for _, line in ipairs(result.output) do
            local branch = line:match("HEAD branch: (.+)")
            if branch then
                return branch
            end
        end
    end

    return nil
end

-- Backwards compatibility alias
M.get_default_branch = M.get_remote_default_branch

return M

local M = {}
local config = require("browsher.config")

---@class GitResult
---@field output string[]|nil Output lines, or nil on error.
---@field exit_code number Shell exit code.

--- Run a Git command and return the result.
---
--- The command is passed to the OS as an argument list (no shell involved),
--- so paths containing spaces or shell metacharacters are safe on all platforms.
---
---@param args string[] The git arguments (without the 'git' prefix).
---@param git_root string|nil Directory to run git in (via -C).
---@return GitResult
local function run_git_command(args, git_root)
    local cmd = { "git" }
    if git_root then
        table.insert(cmd, "-C")
        table.insert(cmd, git_root)
    end
    vim.list_extend(cmd, args)
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

--- Quote a path as a literal git pathspec, so that characters like
--- '*' or '[' in file names are not treated as globs by git.
---
---@param path string The relative file path.
---@return string The literal pathspec.
local function literal_pathspec(path)
    return ":(literal)" .. path
end

--- Get the directory to resolve the repository from.
---
--- Prefers the current buffer's directory so that the correct repository is
--- found even when Neovim's cwd is outside it (or inside a different one).
---
---@return string The base directory.
local function get_base_dir()
    local bufname = vim.api.nvim_buf_get_name(0)
    if bufname ~= "" then
        local dir = vim.fn.fnamemodify(bufname, ":p:h")
        if vim.fn.isdirectory(dir) == 1 then
            return dir
        end
    end
    return vim.fn.getcwd()
end

--- Get the root directory of the git repository containing the current buffer
--- (or the cwd if the buffer has no file).
---
---@return string|nil The path to the git root, or nil if not inside a git repository.
function M.get_git_root()
    local result = run_git_command({ "rev-parse", "--show-toplevel" }, get_base_dir())
    if not result.output or result.output[1] == "" then
        return nil
    end
    return result.output[1]
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

    local result = run_git_command({ "config", "--get", "remote." .. remote_name .. ".url" }, git_root)
    if not result.output or result.output[1] == "" then
        return nil
    end
    return result.output[1]
end

--- List the configured remotes.
---
---@param git_root string|nil The git root (fetched if nil).
---@return string[] The remote names (empty if none or on error).
function M.list_remotes(git_root)
    git_root = git_root or M.get_git_root()
    if not git_root then
        return {}
    end
    local result = run_git_command({ "remote" }, git_root)
    return result.output or {}
end

--- Get the default remote name (first one in the list).
---
---@param git_root string|nil The git root (fetched if nil).
---@return string|nil The default remote name, or nil if none found.
function M.get_default_remote(git_root)
    local remotes = M.list_remotes(git_root)
    if #remotes > 0 then
        return remotes[1]
    end
    return nil
end

--- Check if the repository is in detached HEAD state.
---
---@param git_root string|nil The git root (fetched if nil).
---@return boolean True if in detached HEAD state.
function M.is_detached_head(git_root)
    git_root = git_root or M.get_git_root()
    if not git_root then
        return false
    end
    local result = run_git_command({ "symbolic-ref", "-q", "HEAD" }, git_root)
    return result.exit_code ~= 0
end

--- Get the current branch name (only if on a branch, not detached HEAD).
---
---@param git_root string|nil The git root (fetched if nil).
---@return string|nil The branch name, or nil if detached or error.
function M.get_current_branch(git_root)
    git_root = git_root or M.get_git_root()
    if not git_root then
        return nil
    end

    if config.options.default_branch then
        return config.options.default_branch
    end

    local result = run_git_command({ "symbolic-ref", "--short", "HEAD" }, git_root)
    if result.output and result.output[1] ~= "" then
        return result.output[1]
    end
    return nil
end

--- Get the current branch name or commit hash.
---
---@param git_root string|nil The git root (fetched if nil).
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

    local result = run_git_command({ "rev-parse", "--short", "HEAD" }, git_root)
    if result.output and result.output[1] ~= "" then
        return result.output[1], "commit"
    end

    return nil
end

--- Get the nearest tag reachable from HEAD (via `git describe`).
---
--- Note: this is the closest ancestor tag, not necessarily the most recently
--- created tag in the repository, and it may not exist on the remote.
---
---@param git_root string|nil The git root (fetched if nil).
---@return string|nil The tag, or nil if not found.
function M.get_latest_tag(git_root)
    git_root = git_root or M.get_git_root()
    if not git_root then
        return nil
    end

    local result = run_git_command({ "describe", "--tags", "--abbrev=0" }, git_root)
    if result.output and result.output[1] ~= "" then
        return result.output[1]
    end
    return nil
end

--- Get the current commit hash.
---
---@param git_root string|nil The git root (fetched if nil).
---@return string|nil The current commit hash, or nil if not found.
function M.get_current_commit_hash(git_root)
    git_root = git_root or M.get_git_root()
    if not git_root then
        return nil
    end

    local args = { "rev-parse" }
    local commit_length = config.options.commit_length
    if commit_length then
        table.insert(args, string.format("--short=%d", commit_length))
    end
    table.insert(args, "HEAD")

    local result = run_git_command(args, git_root)
    if result.output and result.output[1] ~= "" then
        return result.output[1]
    end
    return nil
end

--- Get the file path relative to the git root.
---
---@param git_root string|nil The git root (fetched if nil).
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

    -- Compare against the root with a trailing slash so that a sibling
    -- directory like /home/user/repo2 does not pass for root /home/user/repo.
    if normalized_filepath:sub(1, #normalized_git_root + 1) ~= normalized_git_root .. "/" then
        return nil
    end

    local relative_path = filepath:sub(#expanded_root + 2)
    return M.normalize_path(relative_path)
end

--- Check if the file has uncommitted (staged or unstaged) changes.
---
---@param relative_path string The relative file path.
---@param git_root string|nil The git root (fetched if nil).
---@return boolean True if there are uncommitted changes, false otherwise.
function M.has_uncommitted_changes(relative_path, git_root)
    git_root = git_root or M.get_git_root()
    if not git_root then
        return false
    end
    local result = run_git_command(
        { "status", "--porcelain", "--untracked-files=no", "--", literal_pathspec(relative_path) },
        git_root
    )
    return result.output ~= nil and #result.output > 0
end

--- Check if the file is tracked by Git.
---
---@param relative_path string The relative file path.
---@param git_root string|nil The git root (fetched if nil).
---@return boolean True if the file is tracked, false otherwise.
function M.is_file_tracked(relative_path, git_root)
    git_root = git_root or M.get_git_root()
    if not git_root then
        return false
    end
    local result = run_git_command({ "ls-files", "--error-unmatch", "--", literal_pathspec(relative_path) }, git_root)
    return result.output ~= nil
end

--- Get the default branch of the remote repository.
---
---@param remote_name string|nil The name of the remote.
---@param git_root string|nil The git root (fetched if nil).
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

    local result = run_git_command({ "symbolic-ref", "refs/remotes/" .. remote_name .. "/HEAD" }, git_root)
    if result.output and result.output[1] ~= "" then
        local default_branch = result.output[1]:match("refs/remotes/[^/]+/(.+)")
        if default_branch then
            return default_branch
        end
    end

    -- Fallback: query the remote (slower, requires network)
    result = run_git_command({ "remote", "show", remote_name }, git_root)
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

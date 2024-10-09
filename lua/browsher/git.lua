local M = {}

local uv = vim.loop
local watchers = {}

local cache = {}

local function clear_cache(git_root)
    if git_root and cache[git_root] then
        cache[git_root] = nil
    end
end

local function watch_file(path, git_root)
    local watcher = uv.new_fs_poll()
    watcher:start(path, 1000, function(err)
        if err then
            vim.schedule(function()
                vim.notify("Error watching file: " .. err, vim.log.levels.ERROR)
            end)
            return
        end
        clear_cache(git_root)
    end)
    table.insert(watchers, watcher)
end

local function setup_git_watchers(git_root)
    for _, watcher in ipairs(watchers) do
        watcher:stop()
        watcher:close()
    end
    watchers = {}

    local head_path = git_root .. "/.git/HEAD"
    watch_file(head_path, git_root)

    local refs_path = git_root .. "/.git/refs"
    watch_file(refs_path, git_root)

    local packed_refs_path = git_root .. "/.git/packed-refs"
    watch_file(packed_refs_path, git_root)

    local index_path = git_root .. "/.git/index"
    watch_file(index_path, git_root)
end

vim.api.nvim_create_autocmd("VimLeavePre", {
    callback = function()
        for _, watcher in ipairs(watchers) do
            watcher:stop()
            watcher:close()
        end
        watchers = {}
    end,
})

local function is_git_available()
    return vim.fn.executable("git") == 1
end

local function systemlist(cmd, git_root)
    if not is_git_available() then
        return nil, "Git is not installed or not in PATH."
    end
    if git_root then
        cmd = string.format("git -C %s %s", vim.fn.shellescape(git_root), cmd)
    else
        cmd = "git " .. cmd
    end
    local output = vim.fn.systemlist(cmd .. " 2>&1")
    if vim.v.shell_error ~= 0 then
        return nil, table.concat(output, "\n")
    end
    return output
end

local function get_git_root()
    local output, err = systemlist("rev-parse --show-toplevel")
    if not output or output[1] == "" then
        return nil, err or "Not inside a git repository"
    end
    return output[1]
end

function M.get_git_root()
    local git_root = get_git_root()
    if git_root then
        setup_git_watchers(git_root)
    end
    return git_root
end

function M.get_remote_url(remote_name)
    remote_name = remote_name or "origin"
    local git_root = M.get_git_root()
    if not git_root then
        return nil, "Not inside a git repository"
    end

    local cache_key = git_root .. "_remote_url_" .. remote_name
    if cache[cache_key] then
        return cache[cache_key]
    end

    local cmd = string.format("config --get remote.%s.url", remote_name)
    local output, err = systemlist(cmd, git_root)
    if not output or output[1] == "" then
        return nil, err or ("No remote " .. remote_name .. " set")
    end
    cache[cache_key] = output[1]
    return cache[cache_key]
end

function M.get_current_branch()
    local git_root = M.get_git_root()
    if not git_root then
        return nil, "Not inside a git repository"
    end

    local cache_key = git_root .. "_current_branch"
    if cache[cache_key] then
        return cache[cache_key]
    end

    local output, err = systemlist("symbolic-ref --short HEAD", git_root)
    if output and output[1] ~= "" then
        cache[cache_key] = output[1]
        return cache[cache_key]
    end

    output, err = systemlist("rev-parse --short HEAD", git_root)
    if output and output[1] ~= "" then
        cache[cache_key] = output[1]
        return cache[cache_key]
    end

    return nil, err or "Could not determine the current branch or commit hash"
end

function M.get_latest_tag()
    local git_root = M.get_git_root()
    if not git_root then
        return nil, "Not inside a git repository"
    end

    local cache_key = git_root .. "_latest_tag"
    if cache[cache_key] then
        return cache[cache_key]
    end

    local output, err = systemlist("describe --tags --abbrev=0", git_root)
    if output and output[1] ~= "" then
        cache[cache_key] = output[1]
        return cache[cache_key]
    end
    return nil, err or "Could not determine the latest tag"
end

function M.get_file_relative_path()
    local git_root = M.get_git_root()
    if not git_root then
        return nil, "Not inside a git repository"
    end

    local filepath = vim.api.nvim_buf_get_name(0)
    if filepath == "" then
        return nil, "No file to open"
    end

    filepath = vim.fn.fnamemodify(filepath, ":p")
    git_root = vim.fn.fnamemodify(git_root, ":p")

    git_root = git_root:gsub("[/\\]$", "")

    if filepath:sub(1, #git_root) ~= git_root then
        return nil, "File is not inside the git repository"
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
    local output, _ = systemlist(cmd, git_root)
    local has_changes = output and #output > 0
    return has_changes
end

function M.get_default_branch(remote_name)
    remote_name = remote_name or "origin"
    local git_root = M.get_git_root()
    if not git_root then
        return nil, "Not inside a git repository"
    end

    local cache_key = git_root .. "_default_branch_" .. remote_name
    if cache[cache_key] then
        return cache[cache_key]
    end

    local cmd = string.format("remote show %s", remote_name)
    local output, err = systemlist(cmd, git_root)
    if output then
        for _, line in ipairs(output) do
            local default_branch = line:match("HEAD branch: (.+)")
            if default_branch then
                cache[cache_key] = default_branch
                return default_branch
            end
        end
    end
    return nil, err or "Could not determine default branch"
end

function M.get_current_commit_hash()
    local git_root = M.get_git_root()
    if not git_root then
        return nil, "Not inside a git repository"
    end

    local cache_key = git_root .. "_current_commit_hash"
    if cache[cache_key] then
        return cache[cache_key]
    end

    local output, err = systemlist("rev-parse HEAD", git_root)
    if output and output[1] ~= "" then
        cache[cache_key] = output[1]
        return cache[cache_key]
    end
    return nil, err or "Could not determine the current commit hash"
end

return M

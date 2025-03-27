local M = {}
local cache = { commands = {}, timestamps = {} }
M["clear-cache"] = function(cmd)
    if cmd then
        cache.commands[cmd] = nil
        cache.timestamps[cmd] = nil
        return nil
    else
        cache.commands = {}
        cache.timestamps = {}
        return nil
    end
end
M["execute-git-command"] = function(cmd, git_root, use_cache, callback)
    return error("Platform must implement execute-git-command")
end
M["run-git-command"] = function(cmd, git_root, use_cache, callback)
    local use_cache_3f = (use_cache ~= false)
    local cache_key = (cmd .. (git_root or ""))
    local current_time = os.time()
    if
        use_cache_3f
        and cache.commands[cache_key]
        and ((current_time - cache.timestamps[cache_key]) <= (M["get-config"]("cache-ttl") or 10))
    then
        if callback then
            callback(vim.deepcopy(cache.commands[cache_key]))
        else
            vim.deepcopy(cache.commands[cache_key])
        end
    else
    end
    local full_cmd
    if git_root then
        full_cmd = string.format("git -C %s %s", M["escape-path"](git_root), cmd)
    else
        full_cmd = ("git " .. cmd)
    end
    if callback then
        local function _5_(output, err)
            if output and not err then
                if use_cache_3f then
                    cache.commands[cache_key] = vim.deepcopy(output)
                    cache.timestamps[cache_key] = os.time()
                else
                end
                return callback(output)
            else
                return nil
            end
        end
        M["execute-git-command"](full_cmd, _5_)
        return nil
    else
        local output = M["execute-git-command"](full_cmd)
        if output and (type(output) == "table") then
            if use_cache_3f then
                cache.commands[cache_key] = vim.deepcopy(output)
                cache.timestamps[cache_key] = os.time()
            else
            end
            return output
        else
            return nil
        end
    end
end
M["get-git-root"] = function()
    local output = M["run-git-command"]("rev-parse --show-toplevel")
    if output and (type(output) == "table") and (#output > 0) and (output[1] ~= "") then
        return output[1]
    else
        return nil
    end
end
M["normalize-path"] = function(path)
    return string.gsub(path, "\\", "/")
end
M["escape-path"] = function(path)
    return M["platform-escape-path"](path)
end
M["get-remote-url"] = function(remote_name)
    local remote = (remote_name or M["get-default-remote"]())
    local git_root = M["get-git-root"]()
    if git_root then
        local cmd = string.format("config --get remote.%s.url", remote)
        local output = M["run-git-command"](cmd, git_root)
        if output and (type(output) == "table") and (#output > 0) and (output[1] ~= "") then
            return output[1]
        else
            return nil
        end
    else
        return nil
    end
end
M["get-default-remote"] = function()
    local git_root = M["get-git-root"]()
    if git_root then
        local output = M["run-git-command"]("remote", git_root)
        if output and (type(output) == "table") and (#output > 0) then
            return output[1]
        else
            return nil
        end
    else
        return nil
    end
end
M["get-current-branch-or-commit"] = function()
    local git_root = M["get-git-root"]()
    if git_root then
        local output = M["run-git-command"]("symbolic-ref --short HEAD", git_root)
        if output and (type(output) == "table") and (#output > 0) and (output[1] ~= "") then
            return output[1], "branch"
        else
            local output0 = M["run-git-command"]("rev-parse --short HEAD", git_root)
            if output0 and (type(output0) == "table") and (#output0 > 0) and (output0[1] ~= "") then
                return output0[1], "commit"
            else
                return nil
            end
        end
    else
        return nil
    end
end
M["get-latest-tag"] = function()
    local git_root = M["get-git-root"]()
    if git_root then
        local output = M["run-git-command"]("describe --tags --abbrev=0", git_root)
        if output and (type(output) == "table") and (#output > 0) and (output[1] ~= "") then
            return output[1]
        else
            return nil
        end
    else
        return nil
    end
end
M["get-current-commit-hash"] = function()
    local git_root = M["get-git-root"]()
    if git_root then
        local commit_length = M["get-config"]("commit-length")
        local abbrev_arg
        if commit_length then
            abbrev_arg = string.format("--short=%d", commit_length)
        else
            abbrev_arg = ""
        end
        local cmd = string.format("rev-parse %s HEAD", abbrev_arg)
        local output = M["run-git-command"](cmd, git_root)
        if output and (type(output) == "table") and (#output > 0) and (output[1] ~= "") then
            return output[1]
        else
            return nil
        end
    else
        return nil
    end
end
M["has-uncommitted-changes"] = function(relative_path)
    local git_root = M["get-git-root"]()
    if git_root then
        local cmd = string.format("diff --name-only -- %s", M["escape-path"](relative_path))
        local output = M["run-git-command"](cmd, git_root)
        return (output and (type(output) == "table") and (#output > 0))
    else
        return nil
    end
end
M["has-line-changes"] = function(relative_path, start_line, end_line)
    local git_root = M["get-git-root"]()
    if not git_root then
    else
    end
    local cmd = string.format("diff --unified=0 -- %s", M["escape-path"](relative_path))
    local output = M["run-git-command"](cmd, git_root)
    if not output or (type(output) ~= "table") or (#output == 0) then
    else
    end
    local affected_ranges = {}
    local line_offset = 0
    for _, line in ipairs(output) do
        local hunk_match = string.match(line, "^@@ %-(%d+),(%d+) %+(%d+),(%d+) @@")
        if hunk_match then
            local old_start = tonumber(string.match(line, "^@@ %-(%d+),"))
            local old_size = tonumber(string.match(line, "^@@ %-[%d]+,(%d+)"))
            local new_start = tonumber(string.match(line, "^@@ %-[%d]+,[%d]+ %+(%d+),"))
            local new_size = tonumber(string.match(line, "^@@ %-[%d]+,[%d]+ %+[%d]+,(%d+)"))
            if old_start and old_size and new_start and new_size then
                local hunk_offset = (new_size - old_size)
                if start_line > (new_start + new_size + -1) then
                    line_offset = (line_offset + hunk_offset)
                else
                end
                if new_size > 0 then
                    table.insert(
                        affected_ranges,
                        { start = new_start, ["end"] = (new_start + new_size + -1), offset = hunk_offset }
                    )
                else
                    table.insert(affected_ranges, { start = new_start, ["end"] = new_start, offset = hunk_offset })
                end
            else
            end
        else
        end
    end
    local has_changes = false
    for _, range in ipairs(affected_ranges) do
        if not ((end_line < range.start) or (start_line > range["end"])) then
            has_changes = true
            break
        else
        end
    end
    return has_changes, line_offset
end
M["get-adjusted-line-numbers"] = function(relative_path, start_line, end_line)
    local has_changes, offset = M["has-line-changes"](relative_path, start_line, end_line)
    if offset == nil then
        return start_line, end_line, has_changes
    else
        local adjusted_start = (start_line - offset)
        local adjusted_end = (end_line - offset)
        local adjusted_start0 = math.max(1, adjusted_start)
        local adjusted_end0 = math.max(1, adjusted_end)
        return adjusted_start0, adjusted_end0, has_changes
    end
end
M["is-file-tracked"] = function(relative_path)
    local git_root = M["get-git-root"]()
    if git_root then
        local cmd = string.format("ls-files --error-unmatch -- %s", M["escape-path"](relative_path))
        local output = M["run-git-command"](cmd, git_root)
        return (output and (type(output) == "table") and (#output > 0))
    else
        return nil
    end
end
M["get-file-relative-path"] = function(file_path)
    local git_root = M["get-git-root"]()
    if git_root then
        local full_path = (file_path or M["get-current-file-path"]())
        local normalized_filepath = string.gsub(full_path, "\\", "/")
        local normalized_git_root = string.gsub(git_root, "\\", "/")
        local pattern = string.gsub(normalized_git_root, "([^%w])", "%%%1")
        if string.match(normalized_filepath, pattern) then
            return string.sub(normalized_filepath, (#normalized_git_root + 2))
        else
            return nil
        end
    else
        return nil
    end
end
M["get-current-file-path"] = function()
    return error("Platform must implement get-current-file-path")
end
M["get-config"] = function(key)
    return error("Platform must implement get-config")
end
M["platform-escape-path"] = function(path)
    return error("Platform must implement platform-escape-path")
end
M.notify = function(message, level)
    return error("Platform must implement notify")
end
return M

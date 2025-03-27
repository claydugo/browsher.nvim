local git = require("browsher.core.git")
local url_builder = require("browsher.core.url")
local M = {}
M["generate-url"] = function(opts)
    local file_path = M["get-current-file-path"]()
    local pin_type = ((opts["pin-type"] and opts["pin-type"]) or M["get-config"]("default-pin") or "commit")
    local specific_commit = (opts["specific-commit"] and opts["specific-commit"])
    if not ((pin_type == "commit") or (pin_type == "branch") or (pin_type == "tag") or (pin_type == "root")) then
        M.notify("Invalid pin type. Use 'branch', 'tag', 'commit', or 'root'.", "error")
        return nil
    else
    end
    local remote_name = (M["get-config"]("default-remote") or git["get-default-remote"]())
    if not remote_name then
        M.notify("No remote found.", "error")
        return nil
    else
    end
    local remote_url = git["get-remote-url"](remote_name)
    if not remote_url then
        M.notify("No remote URL found.", "error")
        return nil
    else
    end
    if pin_type == "root" then
        return url_builder.sanitize_remote_url(remote_url)
    else
    end
    local git_root = git["get-git-root"]()
    if not git_root then
        M.notify("Not in a Git repository.", "error")
        return nil
    else
    end
    local relative_path = git["get-file-relative-path"](file_path)
    if not relative_path then
        M.notify("Not in a Git repository.", "error")
        return nil
    else
    end
    if not git["is-file-tracked"](relative_path) then
        M.notify("File is untracked by Git.", "error")
        return nil
    else
    end
    local branch_or_tag = nil
    if pin_type == "tag" then
        branch_or_tag = git["get-latest-tag"]()
    elseif pin_type == "branch" then
        local ref_name, ref_type = git["get-current-branch-or-commit"]()
        if ref_name and (ref_type == "branch") then
            branch_or_tag = ref_name
        else
            M.notify("Cannot use 'branch' pin type in detached HEAD state.", "error")
            return nil
        end
    else
        if specific_commit then
            if string.match(specific_commit, "^[0-9a-fA-F]+$") then
                branch_or_tag = specific_commit
            else
                M.notify("Invalid commit hash format.", "error")
                return nil
            end
        else
            branch_or_tag = git["get-current-commit-hash"]()
        end
    end
    if not branch_or_tag then
        return nil
    else
    end
    local has_changes = git["has-uncommitted-changes"](relative_path)
    local line_info = nil
    local start_line = (opts["start-line"] or 1)
    local end_line = (opts["end-line"] or start_line)
    if has_changes then
        local adjusted_start, adjusted_end, lines_have_changes =
            git["get-adjusted-line-numbers"](relative_path, start_line, end_line)
        if lines_have_changes and not M["get-config"]("allow-line-numbers-with-uncommitted-changes") then
            M.notify(
                "Warning: Uncommitted changes detected in the selected lines. Line numbers removed from URL.",
                "warn"
            )
        else
            if lines_have_changes then
                M.notify(
                    "Warning: Uncommitted changes detected in the selected lines. Line numbers may not be accurate.",
                    "warn"
                )
            else
            end
            if has_changes and not lines_have_changes then
                M.notify(
                    "Note: File has uncommitted changes, but selected lines are unchanged. Line numbers included.",
                    "info"
                )
            else
            end
            if (adjusted_start ~= start_line) or (adjusted_end ~= end_line) then
                M.notify(
                    string.format(
                        "Lines adjusted from %d-%d to %d-%d to match committed version.",
                        start_line,
                        end_line,
                        adjusted_start,
                        adjusted_end
                    ),
                    "info"
                )
            else
            end
            if adjusted_start == adjusted_end then
                line_info = { ["line-number"] = adjusted_start }
            else
                line_info = { ["start-line"] = adjusted_start, ["end-line"] = adjusted_end }
            end
        end
    else
        if start_line == end_line then
            line_info = { ["line-number"] = start_line }
        else
            line_info = { ["start-line"] = start_line, ["end-line"] = end_line }
        end
    end
    return url_builder["build-url"](remote_url, branch_or_tag, relative_path, line_info)
end
M["get-current-file-path"] = function()
    return error("Platform must implement get-current-file-path")
end
M["get-config"] = function(key)
    return error("Platform must implement get-config")
end
M.notify = function(message, level)
    return error("Platform must implement notify")
end
return M

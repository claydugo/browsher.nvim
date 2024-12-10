local config = require("browsher.config")
local git = require("browsher.git")
local url_builder = require("browsher.url")
local utils = require("browsher.utils")

--- Main module for browsher.nvim.
local M = {}

--- Get the command to open URLs based on the OS or user configuration.
---
---@return table|nil The command as a list, or nil if unsupported OS.
local function get_open_command()
    if config.options.open_cmd then
        if type(config.options.open_cmd) == "string" then
            return { config.options.open_cmd }
        else
            return config.options.open_cmd
        end
    end

    if vim.fn.has("unix") == 1 then
        return { "xdg-open" }
    elseif vim.fn.has("macunix") == 1 then
        return { "open" }
    elseif vim.fn.has("win32") == 1 then
        return { "explorer.exe" }
    else
        return nil
    end
end

--- Open a URL using the system's default method or a user-specified command.
---
---@param url string The URL to open.
local function open_url(url)
    local open_cmd = get_open_command()
    if not open_cmd then
        utils.notify("Unsupported OS", vim.log.levels.ERROR)
        return
    elseif string.len(open_cmd[1]) == 1 then
        vim.fn.setreg(open_cmd[1], url)
        utils.notify("URL copied to '" .. open_cmd[1] .. "' register", vim.log.levels.INFO)
        return
    end

    table.insert(open_cmd, url)

    vim.fn.jobstart(open_cmd, { detach = true })
end

--- Open the current file in the browser.
---
---@param opts table Options passed from the user command.
function M.open_in_browser(opts)
    local args = {}
    if opts.args then
        for word in string.gmatch(opts.args, "%S+") do
            table.insert(args, word)
        end
    end

    local pin_type = args[1] or config.options.default_pin or "commit"
    local specific_commit = args[2]

    local valid_pin_types = { commit = true, branch = true, tag = true, root = true }
    if not valid_pin_types[pin_type] then
        utils.notify("Invalid argument. Use 'branch', 'tag', 'commit', or 'root'.", vim.log.levels.ERROR)
        return
    end

    local remote_name = config.options.default_remote or git.get_default_remote()
    if not remote_name then
        utils.notify("No remote found.", vim.log.levels.ERROR)
        return
    end

    local remote_url = git.get_remote_url(remote_name)
    if not remote_url then
        utils.notify("No remote URL found.", vim.log.levels.ERROR)
        return
    end

    if pin_type == "root" then
        local sanitized_url = url_builder.sanitize_remote_url(remote_url)
        open_url(sanitized_url)
        return
    end

    local git_root = git.get_git_root()
    if not git_root then
        utils.notify("Not in a Git repository.", vim.log.levels.ERROR)
        return
    end

    local relative_path = git.get_file_relative_path()
    if not relative_path then
        utils.notify("Not in a Git repository.", vim.log.levels.ERROR)
        return
    end

    if not git.is_file_tracked(relative_path) then
        utils.notify("File is untracked by Git.", vim.log.levels.ERROR)
        return
    end

    local branch_or_tag, ref_type
    if pin_type == "tag" then
        branch_or_tag = git.get_latest_tag()
        if not branch_or_tag then
            return
        end
    elseif pin_type == "branch" then
        branch_or_tag, ref_type = git.get_current_branch_or_commit()
        if not branch_or_tag or ref_type ~= "branch" then
            utils.notify("Cannot use 'branch' pin type in detached HEAD state.", vim.log.levels.ERROR)
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

    local has_changes = git.has_uncommitted_changes(relative_path)
    local line_info = nil

    if has_changes and not config.options.allow_line_numbers_with_uncommitted_changes then
        utils.notify(
            "Warning: Uncommitted changes detected in this file. Line number removed from URL.",
            vim.log.levels.WARN
        )
    else
        if has_changes then
            utils.notify(
                "Warning: Uncommitted changes detected in this file. Line numbers may not be accurate.",
                vim.log.levels.WARN
            )
        end
        local start_line, end_line

        if opts.range > 0 then
            -- Command was called with a range
            start_line = opts.line1
            end_line = opts.line2
        else
            local mode = vim.fn.mode()
            if mode == "v" or mode == "V" or mode == "\22" then
                -- Visual mode: get the visually selected lines
                start_line = vim.fn.line("v")
                end_line = vim.fn.line(".")
            else
                -- Normal mode: use the current cursor line
                start_line = vim.api.nvim_win_get_cursor(0)[1]
                end_line = start_line
            end
        end

        if start_line > end_line then
            start_line, end_line = end_line, start_line
        end

        if start_line == end_line then
            line_info = { line_number = start_line }
        else
            line_info = { start_line = start_line, end_line = end_line }
        end
    end

    local url = url_builder.build_url(remote_url, branch_or_tag, relative_path, line_info)
    if not url then
        return
    end

    open_url(url)
end

--- Setup user configuration.
---
---@param user_options table User-specified options.
function M.setup(user_options)
    config.setup(user_options)
end

return M

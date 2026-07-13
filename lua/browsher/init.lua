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

    local os_name = vim.loop.os_uname().sysname

    if os_name == "Linux" then
        return { "xdg-open" }
    elseif os_name == "Darwin" then
        return { "open" }
    elseif os_name == "Windows_NT" then
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
        local error_msg = [[
Could not determine which command used by your operating system to
open a browser from the command-line.

You must explicitly set the "open_cmd" option in your configuration
for Browsher to function.
        ]]
        utils.notify(error_msg, vim.log.levels.ERROR)
        return
    elseif string.len(open_cmd[1]) == 1 then
        vim.fn.setreg(open_cmd[1], url)
        utils.notify("URL copied to '" .. open_cmd[1] .. "' register", vim.log.levels.INFO)
        return
    end

    table.insert(open_cmd, url)

    vim.fn.jobstart(open_cmd, { detach = true })
end

--- Parse command arguments into pin type and optional commit.
---
---@param args_str string|nil The raw arguments string.
---@return string pin_type The pin type.
---@return string|nil specific_commit Optional specific commit hash.
local function parse_args(args_str)
    local args = {}
    if args_str then
        for word in string.gmatch(args_str, "%S+") do
            table.insert(args, word)
        end
    end
    local pin_type = args[1] or config.options.default_pin or "commit"
    return pin_type, args[2]
end

--- Get line information from cursor or visual selection.
---
---@param opts table Command options with range info.
---@return table|nil line_info Table with line_number or start_line/end_line.
local function get_line_info(opts)
    local start_line, end_line

    if opts.range > 0 then
        start_line = opts.line1
        end_line = opts.line2
    else
        local mode = vim.fn.mode()
        if mode == "v" or mode == "V" or mode == "\22" then
            start_line = vim.fn.line("v")
            end_line = vim.fn.line(".")
        else
            start_line = vim.api.nvim_win_get_cursor(0)[1]
            end_line = start_line
        end
    end

    if start_line > end_line then
        start_line, end_line = end_line, start_line
    end

    if start_line == end_line then
        return { line_number = start_line }
    end
    return { start_line = start_line, end_line = end_line }
end

--- Open the current file in the browser.
---
---@param opts table Options passed from the user command.
function M.open_in_browser(opts)
    local pin_type, specific_commit = parse_args(opts.args)

    local valid_pin_types = { commit = true, branch = true, tag = true, root = true }
    if not valid_pin_types[pin_type] then
        utils.notify("Invalid argument. Use 'branch', 'tag', 'commit', or 'root'.", vim.log.levels.ERROR)
        return
    end

    -- Get git root (will be cached by cwd for subsequent calls)
    local git_root = git.get_git_root()
    if not git_root then
        utils.notify("Not in a Git repository.", vim.log.levels.ERROR)
        return
    end

    local remote_name = config.options.default_remote or git.get_default_remote(git_root)
    if not remote_name then
        utils.notify("No remote found.", vim.log.levels.ERROR)
        return
    end

    local remote_url = git.get_remote_url(remote_name, git_root)
    if not remote_url then
        utils.notify("No remote URL found for '" .. remote_name .. "'.", vim.log.levels.ERROR)
        return
    end

    if pin_type == "root" then
        open_url(url_builder.sanitize_remote_url(remote_url))
        return
    end

    local relative_path = git.get_file_relative_path(git_root)
    if not relative_path then
        utils.notify("No file open or file is outside the repository.", vim.log.levels.ERROR)
        return
    end

    if not git.is_file_tracked(relative_path, git_root) then
        utils.notify("File is untracked by Git.", vim.log.levels.ERROR)
        return
    end

    local branch_or_tag
    if pin_type == "tag" then
        branch_or_tag = git.get_latest_tag(git_root)
        if not branch_or_tag then
            utils.notify("No tags found in repository.", vim.log.levels.ERROR)
            return
        end
    elseif pin_type == "branch" then
        local branch = git.get_current_branch(git_root)
        if not branch then
            if git.is_detached_head(git_root) then
                utils.notify("Cannot use 'branch' in detached HEAD state. Use 'commit' instead.", vim.log.levels.ERROR)
            else
                utils.notify("Could not determine current branch.", vim.log.levels.ERROR)
            end
            return
        end
        branch_or_tag = branch
    elseif pin_type == "commit" then
        if specific_commit then
            if not specific_commit:match("^[0-9a-fA-F]+$") then
                utils.notify("Invalid commit hash format.", vim.log.levels.ERROR)
                return
            end
            branch_or_tag = specific_commit
        else
            branch_or_tag = git.get_current_commit_hash(git_root)
            if not branch_or_tag then
                utils.notify("Could not determine current commit.", vim.log.levels.ERROR)
                return
            end
        end
    end

    local has_changes = git.has_uncommitted_changes(relative_path, git_root)
    local line_info = nil

    if has_changes and not config.options.allow_line_numbers_with_uncommitted_changes then
        utils.notify("Warning: Uncommitted changes detected. Line number removed from URL.", vim.log.levels.WARN)
    else
        if has_changes then
            utils.notify(
                "Warning: Uncommitted changes detected. Line numbers may not be accurate.",
                vim.log.levels.WARN
            )
        end
        line_info = get_line_info(opts)
    end

    local url = url_builder.build_url(remote_url, branch_or_tag, relative_path, line_info)
    if not url then
        utils.notify("Unsupported git provider.", vim.log.levels.ERROR)
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

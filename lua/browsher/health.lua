local M = {}

--- Check open command configuration.
---@param ok function
---@param warn function
---@param error_fn function
local function check_open_command(ok, warn, error_fn)
    local cfg = require("browsher.config")
    local open_cmd = cfg.options.open_cmd

    if open_cmd then
        local cmd = type(open_cmd) == "string" and open_cmd or open_cmd[1]
        if string.len(cmd) == 1 then
            ok("configured to copy URL to `" .. cmd .. "` register")
        elseif vim.fn.executable(cmd) ~= 1 then
            error_fn("{" .. cmd .. "} is not executable")
        else
            ok("{" .. cmd .. "} is executable")
        end
    else
        local os_name = (vim.uv or vim.loop).os_uname().sysname
        if os_name == "Linux" then
            if vim.fn.executable("xdg-open") == 1 then
                ok("{xdg-open} is available")
            else
                warn("{xdg-open} is not available, set `open_cmd` in configuration")
            end
        elseif os_name == "Darwin" then
            if vim.fn.executable("open") == 1 then
                ok("{open} is available")
            else
                warn("{open} is not available, set `open_cmd` in configuration")
            end
        elseif os_name == "Windows_NT" then
            ok("Windows detected, {explorer.exe} will be used")
        else
            warn("unknown OS, set `open_cmd` in configuration")
        end
    end
end

function M.check()
    local health = vim.health or require("health")
    local start = health.start or health.report_start
    local ok = health.ok or health.report_ok
    local warn = health.warn or health.report_warn
    local error_fn = health.error or health.report_error
    local info = health.info or health.report_info

    start("browsher.nvim")

    local version = require("browsher.version")
    info("{browsher.nvim} version `" .. version .. "`")

    -- Check git availability (required for plugin to work)
    if vim.fn.executable("git") ~= 1 then
        error_fn("{git} is not installed or not in PATH")
        check_open_command(ok, warn, error_fn)
        return
    end

    local git_version = vim.fn.system("git --version"):match("git version ([%d%.]+)")
    ok("{git} version `" .. (git_version or "unknown") .. "`")

    local git = require("browsher.git")
    local git_root = git.get_git_root()

    if not git_root then
        info("not inside a Git repository")
        check_open_command(ok, warn, error_fn)
        return
    end

    ok("inside Git repository `" .. git_root .. "`")

    -- Check HEAD state
    if git.is_detached_head(git_root) then
        local commit = git.get_current_commit_hash(git_root)
        info("detached HEAD at `" .. (commit or "unknown") .. "`")
        info("'branch' pin type will not work; use 'commit' instead")
    else
        local branch = git.get_current_branch(git_root)
        if branch then
            ok("on branch `" .. branch .. "`")
        end
    end

    -- Check remotes
    local remotes = git.list_remotes(git_root)
    local remote_name = remotes[1]
    if not remote_name then
        warn("no remotes configured in this repository")
        check_open_command(ok, warn, error_fn)
        return
    end

    ok("remote(s) available: `" .. table.concat(remotes, "`, `") .. "`")

    local cfg = require("browsher.config")
    local url_builder = require("browsher.url")
    local default_remote = cfg.options.default_remote or remote_name
    local remote_url = git.get_remote_url(default_remote, git_root)

    if remote_url then
        local sanitized = url_builder.sanitize_remote_url(remote_url)
        local provider_found = false
        for provider, _ in pairs(cfg.options.providers) do
            if sanitized:match(provider) then
                ok("provider matched: {" .. provider .. "}")
                provider_found = true
                break
            end
        end
        if not provider_found then
            warn("no provider configured for `" .. sanitized .. "`")
            info("add a custom provider in your config for this remote")
        end
    end

    check_open_command(ok, warn, error_fn)
end

return M

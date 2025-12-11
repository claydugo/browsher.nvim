local M = {}

function M.check()
    local health = vim.health or require("health")
    local start = health.start or health.report_start
    local ok = health.ok or health.report_ok
    local warn = health.warn or health.report_warn
    local error = health.error or health.report_error
    local info = health.info or health.report_info

    start("browsher.nvim")

    local version = require("browsher.version")
    info("{browsher.nvim} version `" .. version .. "`")

    if vim.fn.executable("git") ~= 1 then
        error("{git} is not installed or not in PATH")
    else
        local git_version = vim.fn.system("git --version"):match("git version ([%d%.]+)")
        ok("{git} version `" .. (git_version or "unknown") .. "`")
    end

    local git_root = vim.fn.systemlist("git rev-parse --show-toplevel 2>/dev/null")[1]
    if vim.v.shell_error ~= 0 or not git_root then
        info("not inside a Git repository")
    else
        ok("inside Git repository `" .. git_root .. "`")

        local remotes = vim.fn.systemlist("git remote")
        if #remotes == 0 then
            warn("no remotes configured in this repository")
        else
            ok("remote(s) available: `" .. table.concat(remotes, "`, `") .. "`")

            local config = require("browsher.config")
            local url_builder = require("browsher.url")
            local default_remote = config.options.default_remote or remotes[1]
            local remote_url = vim.fn.systemlist("git config --get remote." .. default_remote .. ".url")[1]

            if remote_url then
                local sanitized = url_builder.sanitize_remote_url(remote_url)
                local provider_found = false
                for provider, _ in pairs(config.options.providers) do
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
        end
    end

    local open_cmd = require("browsher.config").options.open_cmd
    if open_cmd then
        local cmd = type(open_cmd) == "string" and open_cmd or open_cmd[1]
        if string.len(cmd) == 1 then
            ok("configured to copy URL to `" .. cmd .. "` register")
        elseif vim.fn.executable(cmd) ~= 1 then
            error("{" .. cmd .. "} is not executable")
        else
            ok("{" .. cmd .. "} is executable")
        end
    else
        local os_name = vim.loop.os_uname().sysname
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

return M

local M = {}

function M.check()
    local health = vim.health or require("health")
    local start = health.start or health.report_start
    local ok = health.ok or health.report_ok
    local warn = health.warn or health.report_warn
    local error = health.error or health.report_error
    local info = health.info or health.report_info

    start("browsher.nvim")

    if vim.fn.executable("git") ~= 1 then
        error("Git is not installed or not in PATH.")
    else
        ok("Git is installed.")
    end

    local config = require("browsher.config")
    local open_cmd = config.options.open_cmd
    if open_cmd then
        local cmd = type(open_cmd) == "string" and open_cmd or open_cmd[1]
        if string.len(cmd) == 1 then
            info(string.format("Using register '%s' to store URLs instead of opening them.", cmd))
        elseif vim.fn.executable(cmd) ~= 1 then
            error(string.format("Configured open_cmd '%s' is not executable.", cmd))
        else
            ok(string.format("Configured open_cmd '%s' is executable.", cmd))
        end
    else
        local has_open_cmd = false
        if vim.fn.has("unix") == 1 and vim.fn.executable("xdg-open") == 1 then
            ok("xdg-open is available.")
            has_open_cmd = true
        elseif vim.fn.has("macunix") == 1 and vim.fn.executable("open") == 1 then
            ok("'open' command is available.")
            has_open_cmd = true
        elseif vim.fn.has("win32") == 1 then
            ok("Windows detected. 'explorer.exe' will be used.")
            has_open_cmd = true
        end
        if not has_open_cmd then
            warn("No suitable command found to open URLs. Set 'open_cmd' in configuration.")
        end
    end

    -- Check for async support
    if config.options.async then
        if not vim.loop or not vim.loop.spawn then
            error("Asynchronous mode enabled, but Neovim's libuv API is not available.")
        else
            ok("Asynchronous mode is enabled and supported.")
        end
    else
        info("Asynchronous mode is disabled. Enable it with 'async = true' for non-blocking operations.")
    end

    -- Check cache configuration
    if config.options.cache_ttl > 0 then
        ok(string.format("Git command caching enabled with TTL of %d seconds.", config.options.cache_ttl))
    else
        warn("Git command caching is disabled (cache_ttl is 0 or negative).")
    end

    -- Check providers
    local provider_count = 0
    for _ in pairs(config.options.providers) do
        provider_count = provider_count + 1
    end

    if provider_count > 0 then
        ok(string.format("%d URL providers configured.", provider_count))
    else
        error("No URL providers configured. The plugin will not function.")
    end
end

return M

local M = {}

function M.check()
    local health = vim.health or require("health")
    local start = health.start or health.report_start
    local ok = health.ok or health.report_ok
    local warn = health.warn or health.report_warn
    local error = health.error or health.report_error

    start("browsher.nvim")

    if vim.fn.executable("git") ~= 1 then
        error("Git is not installed or not in PATH.")
    else
        ok("Git is installed.")
    end

    local open_cmd = require("browsher.config").options.open_cmd
    if open_cmd then
        local cmd = type(open_cmd) == "string" and open_cmd or open_cmd[1]
        if vim.fn.executable(cmd) ~= 1 then
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
end

return M

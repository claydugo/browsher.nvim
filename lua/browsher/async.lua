-- Asynchronous operations for browsher.nvim
local M = {}
local utils = require("browsher.utils")

-- Run a command asynchronously and call a callback with the result
function M.run_command(cmd, callback)
    local stdout = vim.loop.new_pipe(false)
    local stderr = vim.loop.new_pipe(false)
    local handle, pid
    local output = {}
    local error_output = {}

    handle, pid = vim.loop.spawn("sh", {
        args = { "-c", cmd },
        stdio = { nil, stdout, stderr },
    }, function(code, signal)
        stdout:close()
        stderr:close()
        handle:close()

        if code ~= 0 then
            local error_message = table.concat(error_output, "\n")
            vim.schedule(function()
                if callback then
                    callback(nil, error_message)
                end
            end)
        else
            vim.schedule(function()
                if callback then
                    callback(output)
                end
            end)
        end
    end)

    if not handle then
        utils.notify("Failed to start async command: " .. cmd, vim.log.levels.ERROR)
        if callback then
            callback(nil, "Failed to start command")
        end
        return
    end

    stdout:read_start(function(err, data)
        if err then
            utils.notify("Error reading stdout: " .. err, vim.log.levels.ERROR)
        end
        if data then
            for _, line in ipairs(vim.split(data, "\n")) do
                if line ~= "" then
                    table.insert(output, line:gsub("\r$", ""))
                end
            end
        end
    end)

    stderr:read_start(function(err, data)
        if err then
            utils.notify("Error reading stderr: " .. err, vim.log.levels.ERROR)
        end
        if data then
            for _, line in ipairs(vim.split(data, "\n")) do
                if line ~= "" then
                    table.insert(error_output, line:gsub("\r$", ""))
                end
            end
        end
    end)
end

return M

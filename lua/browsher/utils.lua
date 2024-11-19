local M = {}

--- Display a notification message.
---
---@param message string The message to display.
---@param level number|nil The log level (default: INFO).
function M.notify(message, level)
    vim.schedule(function()
        vim.notify(message, level or vim.log.levels.INFO)
    end)
end

return M

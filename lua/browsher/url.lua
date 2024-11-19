local M = {}
local config = require("browsher.config")
local utils = require("browsher.utils")

--- Sanitize the remote URL to a standard HTTPS URL.
---
---@param remote_url string The remote URL to sanitize.
---@return string The sanitized remote URL.
function M.sanitize_remote_url(remote_url)
    remote_url = remote_url:gsub("%.git$", "")
    remote_url = remote_url:gsub("^git@(.-):(.*)$", "https://%1/%2")
    remote_url = remote_url:gsub("^ssh://git@(.-)/(.*)$", "https://%1/%2")
    remote_url = remote_url:gsub("git://(.-)/(.*)$", "https://%1/%2")
    remote_url = remote_url:gsub("https?://[^@]+@", "https://")
    return remote_url
end

--- URL-encode a string.
---
---@param str string The string to encode.
---@return string The URL-encoded string.
function M.url_encode(str)
    return str
        and str:gsub("([^%w_%-%./~])", function(c)
            return string.format("%%%02X", string.byte(c))
        end)
end

--- Build the URL to open in the browser.
---
---@param remote_url string The remote repository URL.
---@param branch_or_tag string The branch, tag, or commit hash.
---@param relative_path string The file path relative to the repository root.
---@param line_info table|nil Table containing line information (line_number or start_line and end_line).
---@return string|nil The constructed URL, or nil if unsupported provider.
function M.build_url(remote_url, branch_or_tag, relative_path, line_info)
    remote_url = M.sanitize_remote_url(remote_url)
    branch_or_tag = M.url_encode(branch_or_tag)
    relative_path = M.url_encode(relative_path)

    local providers = config.options.providers

    for provider, data in pairs(providers) do
        if remote_url:match(provider) then
            local url = string.format(data.url_template, remote_url, branch_or_tag, relative_path)
            if line_info then
                local line_part = ""
                if line_info.start_line and line_info.end_line then
                    local format_str = (line_info.start_line == line_info.end_line) and data.single_line_format
                        or data.multi_line_format
                    line_part = string.format(format_str, line_info.start_line, line_info.end_line)
                elseif line_info.line_number then
                    line_part = string.format(data.single_line_format, line_info.line_number)
                end
                url = url .. line_part
            end
            return url
        end
    end

    utils.notify("Unsupported remote provider: " .. remote_url, vim.log.levels.ERROR)
    return nil
end

return M

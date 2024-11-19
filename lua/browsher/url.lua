local M = {}
local utils = require("browsher.utils")

local function sanitize_remote_url(remote_url)
	remote_url = remote_url:gsub("%.git$", "")
	remote_url = remote_url:gsub("^git@(.-):(.*)$", "https://%1/%2")
	remote_url = remote_url:gsub("^ssh://git@(.-)/(.*)$", "https://%1/%2")
	remote_url = remote_url:gsub("git://(.-)/(.*)$", "https://%1/%2")
	remote_url = remote_url:gsub("https?://[^@]+@", "https://")
	return remote_url
end

function M.url_encode(str)
    return str and str:gsub("([^%w_%-%./~])", function(c)
        return string.format("%%%02X", string.byte(c))
    end)
end

function M.build_url(remote_url, branch_or_tag, relpath, line_info)
	remote_url = sanitize_remote_url(remote_url)
	branch_or_tag = M.url_encode(branch_or_tag)
	relpath = M.url_encode(relpath)

	local providers = {
		["github.com"] = {
			url_template = "%s/blob/%s/%s",
			single_line_format = "#L%d",
			multi_line_format = "#L%d-L%d",
		},
		["gitlab.com"] = {
			url_template = "%s/-/blob/%s/%s",
			single_line_format = "#L%d",
			multi_line_format = "#L%d-%d",
		},
	}

	for provider, data in pairs(providers) do
		if remote_url:match(provider) then
			local url = string.format(data.url_template, remote_url, branch_or_tag, relpath)
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

local M = {}

local function sanitize_remote_url(remote_url)
	remote_url = remote_url:gsub("%.git$", "")
	remote_url = remote_url:gsub("^git@(.-):(.*)$", "https://%1/%2")
	remote_url = remote_url:gsub("^ssh://git@(.-)/(.*)$", "https://%1/%2")
	remote_url = remote_url:gsub("git://(.-)/(.*)$", "https://%1/%2")
	remote_url = remote_url:gsub("https?://[^@]+@", "https://")
	return remote_url
end

function M.build_url(remote_url, branch_or_tag, relpath, line_info)
	remote_url = sanitize_remote_url(remote_url)

	local url
	if remote_url:match("github.com") then
		url = string.format("%s/blob/%s/%s", remote_url, branch_or_tag, relpath)
		if line_info then
			if line_info.start_line and line_info.end_line then
				url = url .. "#L" .. line_info.start_line .. "-L" .. line_info.end_line
			elseif line_info.line_number then
				url = url .. "#L" .. line_info.line_number
			end
		end
	elseif remote_url:match("gitlab.com") then
		url = string.format("%s/-/blob/%s/%s", remote_url, branch_or_tag, relpath)
		if line_info then
			if line_info.start_line and line_info.end_line then
				url = url .. "#L" .. line_info.start_line .. "-" .. line_info.end_line
			elseif line_info.line_number then
				url = url .. "#L" .. line_info.line_number
			end
		end
	else
		return nil, "Unsupported remote provider: " .. remote_url
	end

	return url
end

return M

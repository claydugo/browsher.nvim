local M = {}
M["sanitize-remote-url"] = function(remote_url)
    return string.gsub(
        string.gsub(
            string.gsub(
                string.gsub(
                    string.gsub(
                        string.gsub(
                            string.gsub(
                                string.gsub(string.gsub(remote_url, "%.git$", ""), "^git@(.-):(.*)$", "https://%1/%2"),
                                "^ssh://git@(.-)/(.*)$",
                                "https://%1/%2"
                            ),
                            "^gitea@(.-):(.*)$",
                            "https://%1/%2"
                        ),
                        "^ssh://gitea@(.-)/(.*)$",
                        "https://%1/%2"
                    ),
                    "^forgejo@(.-):(.*)$",
                    "https://%1/%2"
                ),
                "^ssh://forgejo@(.-)/(.*)$",
                "https://%1/%2"
            ),
            "git://(.-)/(.*)$",
            "https://%1/%2"
        ),
        "https?://[^@]+@",
        "https://"
    )
end
M["url-encode"] = function(str)
    if str then
        local function _1_(c)
            return string.format("%%%02X", string.byte(c))
        end
        return string.gsub(str, "([^%w_%-%./~])", _1_)
    else
        return nil
    end
end
M["build-url"] = function(remote_url, branch_or_tag, relative_path, line_info)
    local remote_url0 = M["sanitize-remote-url"](remote_url)
    local branch_or_tag0 = M["url-encode"](branch_or_tag)
    local relative_path0 = M["url-encode"](relative_path)
    local providers = M["get-providers"]()
    local found_url = nil
    for provider, data in pairs(providers) do
        if string.match(remote_url0, provider) then
            local url = string.format(data["url-template"], remote_url0, branch_or_tag0, relative_path0)
            local line_part
            if line_info then
                if line_info["start-line"] and line_info["end-line"] then
                    local format_str
                    if line_info["start-line"] == line_info["end-line"] then
                        format_str = data["single-line-format"]
                    else
                        format_str = data["multi-line-format"]
                    end
                    line_part = string.format(format_str, line_info["start-line"], line_info["end-line"])
                else
                    if line_info["line-number"] then
                        line_part = string.format(data["single-line-format"], line_info["line-number"])
                    else
                        line_part = nil
                    end
                end
            else
                line_part = nil
            end
            found_url = (url .. (line_part or ""))
            break
        else
        end
    end
    if not found_url then
        M.notify(("Unsupported remote provider: " .. remote_url0), "error")
    else
    end
    return found_url
end
M["get-providers"] = function()
    return error("Platform must implement get-providers")
end
M.notify = function(message, level)
    return error("Platform must implement notify")
end
return M

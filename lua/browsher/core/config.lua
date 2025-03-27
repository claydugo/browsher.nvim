local M = {}
local default_config = {
    ["default-remote"] = nil,
    ["default-branch"] = nil,
    ["default-pin"] = "commit",
    ["commit-length"] = nil,
    ["open-cmd"] = nil,
    ["cache-ttl"] = 10,
    providers = {
        ["github.com"] = {
            ["url-template"] = "%s/blob/%s/%s",
            ["single-line-format"] = "#L%d",
            ["multi-line-format"] = "#L%d-L%d",
        },
        ["gitlab.com"] = {
            ["url-template"] = "%s/-/blob/%s/%s",
            ["single-line-format"] = "#L%d",
            ["multi-line-format"] = "#L%d-%d",
        },
        ["bitbucket.org"] = {
            ["url-template"] = "%s/src/%s/%s",
            ["single-line-format"] = "#lines-%d",
            ["multi-line-format"] = "#lines-%d:%d",
        },
        ["dev.azure.com"] = {
            ["url-template"] = "%s?path=/%s&version=GB%s",
            ["single-line-format"] = "&line=%d&lineEnd=%d",
            ["multi-line-format"] = "&line=%d&lineEnd=%d",
        },
        ["gitea.io"] = {
            ["url-template"] = "%s/src/%s/%s",
            ["single-line-format"] = "#L%d",
            ["multi-line-format"] = "#L%d-L%d",
        },
        ["forgejo.org"] = {
            ["url-template"] = "%s/src/%s/%s",
            ["single-line-format"] = "#L%d",
            ["multi-line-format"] = "#L%d-L%d",
        },
    },
    ["allow-line-numbers-with-uncommitted-changes"] = false,
    async = false,
}
M["get-default-config"] = function()
    return M["deep-copy"](default_config)
end
M["deep-copy"] = function(tbl)
    if type(tbl) == "table" then
        local result = {}
        for k, v in pairs(tbl) do
            result[k] = M["deep-copy"](v)
        end
        return result
    else
        return tbl
    end
end
M["merge-configs"] = function(user_config)
    local result = M["deep-copy"](default_config)
    if user_config and user_config.providers then
        for provider_key, provider_data in pairs(user_config.providers) do
            result.providers[provider_key] = provider_data
        end
        user_config["providers"] = nil
    else
    end
    if user_config then
        for k, v in pairs(user_config) do
            result[k] = v
        end
    else
    end
    return result
end
return M

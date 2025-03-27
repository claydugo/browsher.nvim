local _local_1_ = require("browsher.core.config")
local merge_configs = _local_1_["merge-configs"]
local core = require("browsher.core.init")
local git = require("browsher.core.git")
local url = require("browsher.core.url")
local M = {}
local config = { options = {} }
M.init = function()
    git["execute-git-command"] = M["execute-git-command"]
    git["get-current-file-path"] = M["get-current-file-path"]
    local function _2_(key)
        return config.options[key]
    end
    git["get-config"] = _2_
    git["platform-escape-path"] = vim.fn.fnameescape
    git.notify = M.notify
    local function _3_()
        return config.options.providers
    end
    url["get-providers"] = _3_
    url.notify = M.notify
    core["get-current-file-path"] = M["get-current-file-path"]
    local function _4_(key)
        return config.options[key]
    end
    core["get-config"] = _4_
    core.notify = M.notify
    return nil
end
M["execute-git-command"] = function(cmd, callback)
    if callback then
        local function _5_(_, data, _0)
            return callback(data)
        end
        local function _6_(_, data, _0)
            if data and (#data > 0) and (data[1] ~= "") then
                M.notify(table.concat(data, "\n"), "error")
                return callback(nil, "Error executing command")
            else
                return nil
            end
        end
        return vim.fn.jobstart(cmd, { on_stdout = _5_, on_stderr = _6_, detach = true })
    else
        local output = vim.fn.systemlist(cmd)
        if vim.v.shell_error ~= 0 then
            M.notify(table.concat(output, "\n"), "error")
            return nil
        else
            return output
        end
    end
end
M["get-current-file-path"] = function()
    return vim.api.nvim_buf_get_name(0)
end
M["get-open-command"] = function()
    local open_cmd = config.options["open-cmd"]
    if open_cmd then
        if type(open_cmd) == "string" then
            return { open_cmd }
        else
            return open_cmd
        end
    else
        if vim.fn.has("unix") == 1 then
            return { "xdg-open" }
        else
            if vim.fn.has("macunix") == 1 then
                return { "open" }
            else
                if vim.fn.has("win32") == 1 then
                    return { "explorer.exe" }
                else
                    return nil
                end
            end
        end
    end
end
M["open-url"] = function(url0)
    local open_cmd = M["get-open-command"]()
    if not open_cmd then
        return M.notify("Unsupported OS", "error")
    else
        if (type(open_cmd[1]) == "string") and (#open_cmd[1] == 1) then
            vim.fn.setreg(open_cmd[1], url0)
            return M.notify(("URL copied to '" .. open_cmd[1] .. "' register"), "info")
        else
            table.insert(open_cmd, url0)
            return vim.fn.jobstart(open_cmd, { detach = true })
        end
    end
end
M.notify = function(message, level)
    local levels = { error = vim.log.levels.ERROR, warn = vim.log.levels.WARN, info = vim.log.levels.INFO }
    return vim.notify(message, ((level and levels[level]) or vim.log.levels.INFO))
end
M["setup-command"] = function()
    local function _17_(opts)
        local pin_type
        if opts.args and (opts.args ~= "") then
            local args = vim.split(opts.args, " ")
            pin_type = args[1]
        else
            pin_type = nil
        end
        local specific_commit
        if opts.args and (opts.args ~= "") then
            local args = vim.split(opts.args, " ")
            specific_commit = args[2]
        else
            specific_commit = nil
        end
        local function _21_()
            if opts.range > 0 then
                return { opts.line1, opts.line2 }
            else
                local mode = vim.fn.mode()
                if (mode == "v") or (mode == "V") or (mode == "\22") then
                    return { vim.fn.line("v"), vim.fn.line(".") }
                else
                    return { vim.api.nvim_win_get_cursor(0)[1], vim.api.nvim_win_get_cursor(0)[1] }
                end
            end
        end
        local _let_22_ = _21_()
        local start_line = _let_22_[1]
        local end_line = _let_22_[2]
        local url0 = core["generate-url"]({
            ["pin-type"] = pin_type,
            ["specific-commit"] = specific_commit,
            ["start-line"] = start_line,
            ["end-line"] = end_line,
        })
        if url0 then
            return M["open-url"](url0)
        else
            return nil
        end
    end
    vim.api.nvim_create_user_command(
        "Browsher",
        _17_,
        { range = true, nargs = "*", desc = "Open the current file in browser" }
    )
    return nil
end
M.setup = function(user_options)
    config.options = merge_configs(user_options)
    M.init()
    return M["setup-command"]()
end
return M

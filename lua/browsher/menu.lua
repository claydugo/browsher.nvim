local M = {}

--- Get menu items for browsher
---
---@return table Menu items in the format expected by nvzone/menu
function M.get_menu_items()
    -- Helper to get commit hash for HEAD~N
    local function get_commit_hash(offset)
        local cmd = offset == 0 and "git rev-parse HEAD" or string.format("git rev-parse HEAD~%d", offset)
        local handle = io.popen(cmd)
        if handle then
            local result = handle:read("*a")
            handle:close()
            return result:match("^%s*(.-)%s*$") -- trim whitespace
        end
        return nil
    end

    -- Generate commit history submenu items
    local commit_items = {}
    for i = 0, 5 do
        local label = i == 0 and "HEAD" or string.format("HEAD~%d", i)
        table.insert(commit_items, {
            name = label,
            cmd = function()
                local hash = get_commit_hash(i)
                if hash then
                    require("browsher").open_in_browser({ args = "commit " .. hash, range = 0 })
                end
            end,
        })
    end

    -- Generate copy URL commit submenu items
    local copy_commit_items = {}
    for i = 0, 5 do
        local label = i == 0 and "HEAD" or string.format("HEAD~%d", i)
        table.insert(copy_commit_items, {
            name = label,
            cmd = function()
                local config = require("browsher.config")
                local original_open_cmd = config.options.open_cmd
                local clipboard_reg = vim.fn.has("clipboard") == 1 and "+" or "*"
                config.options.open_cmd = clipboard_reg

                local hash = get_commit_hash(i)
                if hash then
                    require("browsher").open_in_browser({ args = "commit " .. hash, range = 0 })
                end

                config.options.open_cmd = original_open_cmd
            end,
        })
    end

    return {
        {
            name = "📍 Open at Commit",
            items = commit_items,
        },
        {
            name = "🌿 Open at Branch",
            cmd = function()
                require("browsher").open_in_browser({ args = "branch", range = 0 })
            end,
            rtxt = "branch",
        },
        {
            name = "🏷️ Open at Latest Tag",
            cmd = function()
                require("browsher").open_in_browser({ args = "tag", range = 0 })
            end,
            rtxt = "tag",
        },
        {
            name = "🏠 Open Repository Root",
            cmd = function()
                require("browsher").open_in_browser({ args = "root", range = 0 })
            end,
            rtxt = "root",
        },
        { name = "separator" },
        {
            name = "📋 Copy URL (Commit)",
            items = copy_commit_items,
        },
        {
            name = "📋 Copy URL (Branch)",
            cmd = function()
                local config = require("browsher.config")
                local original_open_cmd = config.options.open_cmd

                -- Temporarily set open_cmd to clipboard register
                local clipboard_reg = vim.fn.has("clipboard") == 1 and "+" or "*"
                config.options.open_cmd = clipboard_reg

                require("browsher").open_in_browser({ args = "branch", range = 0 })

                -- Restore original open_cmd
                config.options.open_cmd = original_open_cmd
            end,
            rtxt = "copy",
        },
    }
end

--- Get menu items for visual mode selection
---
---@param line1 number Start line
---@param line2 number End line
---@return table Menu items for visual selection
function M.get_visual_menu_items(line1, line2)
    -- Helper to get commit hash for HEAD~N
    local function get_commit_hash(offset)
        local cmd = offset == 0 and "git rev-parse HEAD" or string.format("git rev-parse HEAD~%d", offset)
        local handle = io.popen(cmd)
        if handle then
            local result = handle:read("*a")
            handle:close()
            return result:match("^%s*(.-)%s*$") -- trim whitespace
        end
        return nil
    end

    -- Generate commit history submenu items for visual selection
    local commit_items = {}
    for i = 0, 5 do
        local label = i == 0 and "HEAD" or string.format("HEAD~%d", i)
        table.insert(commit_items, {
            name = label,
            cmd = function()
                local hash = get_commit_hash(i)
                if hash then
                    require("browsher").open_in_browser({
                        args = "commit " .. hash,
                        range = 2,
                        line1 = line1,
                        line2 = line2,
                    })
                end
            end,
        })
    end

    -- Generate copy URL commit submenu items for visual selection
    local copy_commit_items = {}
    for i = 0, 5 do
        local label = i == 0 and "HEAD" or string.format("HEAD~%d", i)
        table.insert(copy_commit_items, {
            name = label,
            cmd = function()
                local config = require("browsher.config")
                local original_open_cmd = config.options.open_cmd
                local clipboard_reg = vim.fn.has("clipboard") == 1 and "+" or "*"
                config.options.open_cmd = clipboard_reg

                local hash = get_commit_hash(i)
                if hash then
                    require("browsher").open_in_browser({
                        args = "commit " .. hash,
                        range = 2,
                        line1 = line1,
                        line2 = line2,
                    })
                end

                config.options.open_cmd = original_open_cmd
            end,
        })
    end

    return {
        {
            name = "📍 Open Selection at Commit",
            items = commit_items,
        },
        {
            name = "🌿 Open Selection at Branch",
            cmd = function()
                require("browsher").open_in_browser({ args = "branch", range = 2, line1 = line1, line2 = line2 })
            end,
            rtxt = "branch",
        },
        {
            name = "🏷️ Open Selection at Tag",
            cmd = function()
                require("browsher").open_in_browser({ args = "tag", range = 2, line1 = line1, line2 = line2 })
            end,
            rtxt = "tag",
        },
        { name = "separator" },
        {
            name = "📋 Copy Selection URL (Commit)",
            items = copy_commit_items,
        },
        {
            name = "📋 Copy Selection URL (Branch)",
            cmd = function()
                local config = require("browsher.config")
                local original_open_cmd = config.options.open_cmd

                -- Temporarily set open_cmd to clipboard register
                local clipboard_reg = vim.fn.has("clipboard") == 1 and "+" or "*"
                config.options.open_cmd = clipboard_reg

                require("browsher").open_in_browser({ args = "branch", range = 2, line1 = line1, line2 = line2 })

                -- Restore original open_cmd
                config.options.open_cmd = original_open_cmd
            end,
            rtxt = "copy",
        },
    }
end

--- Open the browsher menu
---
---@param opts table|nil Options for the menu (e.g., { mouse = true })
function M.open(opts)
    opts = opts or {}

    local mode = vim.fn.mode()
    local menu_items

    if mode == "v" or mode == "V" or mode == "\22" then
        -- Visual mode: get selection range
        local start_line = vim.fn.line("v")
        local end_line = vim.fn.line(".")

        if start_line > end_line then
            start_line, end_line = end_line, start_line
        end

        menu_items = M.get_visual_menu_items(start_line, end_line)
    else
        -- Normal mode
        menu_items = M.get_menu_items()
    end

    require("menu").open(menu_items, opts)
end

return M

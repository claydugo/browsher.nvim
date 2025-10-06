local M = {}

--- Default configuration options.
M.options = {
    --- Default remote name (e.g., 'origin').
    default_remote = nil,
    --- Default branch name.
    default_branch = nil,
    --- Default pin type ('commit', 'branch', or 'tag').
    default_pin = "commit",
    --- Length of the commit hash to use in URLs. If nil, use full length. (40)
    commit_length = nil,
    --- Command to open URLs (e.g., 'firefox').
    open_cmd = nil,
    --- Allow line numbers with uncommitted changes.
    allow_line_numbers_with_uncommitted_changes = false,
    --- Enable right-click menu integration using nvzone/menu
    enable_menu = false,
    --- Custom keybindings for the menu (when enable_menu is true)
    menu_keybindings = {
        --- Keybinding for opening menu with keyboard
        keyboard = "<leader>bm",
        --- Enable right-click mouse support
        mouse = true,
    },
    --- Custom providers for building URLs.
    ---
    --- Each provider is a table with the following keys:
    --- - `url_template`: The URL template, where `%s` are placeholders.
    ---   The placeholders are, in order:
    ---   1. Remote URL
    ---   2. Branch or tag
    ---   3. Relative file path
    --- - `single_line_format`: Format string for a single line (e.g., `#L%d`).
    --- - `multi_line_format`: Format string for multiple lines (e.g., `#L%d-L%d`).
    ---
    --- Example:
    --- ```lua
    --- providers = {
    ---   ["mygit.com"] = {
    ---     url_template = "%s/src/%s/%s",
    ---     single_line_format = "?line=%d",
    ---     multi_line_format = "?start=%d&end=%d",
    ---   },
    --- }
    --- ```
    providers = {
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
        ["sr.ht"] = {
            url_template = "%s/tree/%s/item/%s",
            single_line_format = "#L%d",
            multi_line_format = "#L%d",
        },
    },
}

--- Setup user configuration.
---
---@param user_options table User-specified options.
function M.setup(user_options)
    user_options = user_options or {}

    if user_options.providers then
        M.options.providers = vim.tbl_deep_extend("force", M.options.providers, user_options.providers)
        user_options.providers = nil
    end

    M.options = vim.tbl_extend("force", M.options, user_options)
end

return M

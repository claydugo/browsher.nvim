if vim.g.loaded_browsher then
    return
end
vim.g.loaded_browsher = true

vim.api.nvim_create_user_command("Browsher", function(opts)
    require("browsher").open_in_browser(opts)
end, {
    range = true,
    nargs = "?",
    complete = function(arglead)
        local completions = { "branch", "tag", "commit", "root" }
        return vim.tbl_filter(function(option)
            return option:sub(1, #arglead):lower() == arglead:lower()
        end, completions)
    end,
    desc = [[
Open current file or repository in browser pinned to a specific branch, tag, commit, or root.
Usage: :Browsher [branch|tag|commit|root] [commit_hash]
]],
})

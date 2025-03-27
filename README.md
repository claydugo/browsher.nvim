# 📖 browsher.nvim

![open_in_browser](https://github.com/user-attachments/assets/06ea7885-877d-44be-83f8-43fbd0497208)

`browsher.nvim` is a highly customizable Neovim plugin that opens the current file at the specified lines or range in your default browser, pinned to a specific branch, tag, commit, or the repository root in your remote Git repository.

# ✨ Features

- **Open files in the browser**: Quickly open the current file in your remote Git repository's web interface.
- **Line and Range Support**: Supports opening specific lines or ranges, including multiline selections from visual mode.
- **Customizable providers**: Support for GitHub, GitLab, BitBucket, Azure DevOps, Gitea, Forgejo, and the ability to specify custom git web interfaces.
- **Custom open commands**: Specify custom commands to open URLs (e.g., use a specific browser).
- **Performance optimizations**: Includes caching for Git operations to improve performance.
- **Asynchronous mode**: Support for non-blocking asynchronous operations.

# 📦 Installation
Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  'claydugo/browsher.nvim',
  event = "VeryLazy",
  config = function()
    -- Specify empty to use below default options
    require('browsher').setup()
  end
}
```
> [!IMPORTANT]
> Please submit a Pull Request and add to this section if you have worked through installation instructions for other plugin managers!

# ⚙️ Configuration

You can customize `browsher.nvim` by passing options to the setup function, below are the default options.

#### Default Options
```lua
require("browsher").setup({
    --- Default remote name (e.g., 'origin').
    default_remote = nil,
    --- Default branch name.
    default_branch = nil,
    --- Default pin type ('commit', 'branch', or 'tag').
    default_pin = "commit",
    --- Length of the commit hash to use in URLs. If nil, use full length. (40)
    commit_length = nil,
    --- Allow line numbers with uncommitted changes.
    allow_line_numbers_with_uncommitted_changes = false,
    --- Command to open URLs (e.g., 'firefox').
    --- If this is a single character, it will be interpreted as a vim register
    --- instead. For example, to copy the url to your OS clipboard instead of
    --- opening it inside an application, set `open_cmd` to `+` for unix systems,
    --- or `*` if you're on Windows.
    open_cmd = nil,
    --- Cache time-to-live in seconds for git operations
    cache_ttl = 10,
    --- Enable asynchronous operations
    async = false,
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
        ["bitbucket.org"] = {
            url_template = "%s/src/%s/%s",
            single_line_format = "#lines-%d",
            multi_line_format = "#lines-%d:%d",
        },
        ["dev.azure.com"] = {
            url_template = "%s?path=/%s&version=GB%s",
            single_line_format = "&line=%d&lineEnd=%d",
            multi_line_format = "&line=%d&lineEnd=%d",
        },
        ["gitea.io"] = {
            url_template = "%s/src/%s/%s",
            single_line_format = "#L%d",
            multi_line_format = "#L%d-L%d",
        },
        ["forgejo.org"] = {
            url_template = "%s/src/%s/%s",
            single_line_format = "#L%d",
            multi_line_format = "#L%d-L%d",
        },
    },
})
```

## Key Mappings

Add the following key mappings to your Neovim configuration to quickly open files in the browser:

```lua
-- Open from the latest commit, the recommended default operation
vim.api.nvim_set_keymap('n', '<leader>b', '<cmd>Browsher commit<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('v', '<leader>b', ":'<,'>Browsher commit<CR>gv", { noremap = true, silent = true })

-- Open from the latest tag, for more human readable urls (with risk of outdated line numbers)
vim.api.nvim_set_keymap('n', '<leader>B', '<cmd>Browsher tag<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('v', '<leader>B', ":'<,'>Browsher tag<CR>gv", { noremap = true, silent = true })
```

# 🚀 Usage

Use the `:Browsher` command to open the current file in your browser:

```
:Browsher [pin_type] [commit_hash]
```

* `pin_type` (optional): Specifies how to pin the file in the URL. Can be `branch`, `tag`, or `commit`.
    If omitted, uses the default pin type from the configuration (`commit` by default).
* `commit_hash` (optional): Specific commit hash to use when `pin_type` is `commit`.

# Examples

Open current file at the latest commit:

```
:Browsher
```

Open the repository root URL:

```
:Browsher root
```

Open current file at the current branch:

```
:Browsher branch
```

Open current file at the latest tag:

```
:Browsher tag
```

Open current file at a specific commit:

```
:Browsher commit 123abc
```

Open a visual selection of lines:
```
:'<,'>Browsher commit
```

Select lines in visual mode and run:

```
:Browsher
```

# ⚠️ Notes

* **Uncommitted Changes**: If the current file has uncommitted changes, the plugin will check if the specific lines you're trying to open have uncommitted changes. Only if the selected lines themselves have changes will the line numbers be omitted (unless `allow_line_numbers_with_uncommitted_changes` is set to true). This allows you to include line numbers for parts of files that are unchanged, even if other parts of the file have uncommitted changes.

* **Line Number Adjustment**: When your file has uncommitted changes, the plugin automatically adjusts line numbers to account for additions or deletions. This ensures that the URL will point to the correct lines in the committed version on the remote repository, even if your local file has different line numbering due to your uncommitted changes.

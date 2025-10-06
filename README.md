# 📖 browsher.nvim

![open_in_browser](https://github.com/user-attachments/assets/06ea7885-877d-44be-83f8-43fbd0497208)

`browsher.nvim` is a highly customizable Neovim plugin that opens the current file at the specified lines or range in your default browser, pinned to a specific branch, tag, commit, or the repository root in your remote Git repository.

# ✨ Features

- **Open files in the browser**: Quickly open the current file in your remote Git repository's web interface.
- **Line and Range Support**: Supports opening specific lines or ranges, including multiline selections from visual mode.
- **Right-Click Menu**: Optional context menu with all browsher actions (requires [nvzone/menu](https://github.com/nvzone/menu)).
- **Customizable providers**: Support for GitHub, GitLab, Sourcehut, and the ability to specify custom git web interfaces.
- **Custom open commands**: Specify custom commands to open URLs (e.g., use a specific browser).

# 📦 Installation
Using [lazy.nvim](https://github.com/folke/lazy.nvim)

## Basic Installation

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

## Installation with Right-Click Menu

For a full-featured right-click menu interface, install [nvzone/menu](https://github.com/nvzone/menu) separately and enable the menu feature:

```lua
-- Add menu dependencies (optional)
{ "nvzone/volt", lazy = true },
{ "nvzone/menu", lazy = true },

-- Configure browsher with menu enabled
{
  'claydugo/browsher.nvim',
  event = "VeryLazy",
  config = function()
    require('browsher').setup({
      enable_menu = true,
      menu_keybindings = {
        keyboard = "<leader>bm",  -- Open menu with keyboard
        mouse = true,              -- Enable right-click menu
      },
    })
  end
}
```

> [!NOTE]
> The menu feature is completely optional. If `enable_menu = true` but the menu dependencies aren't installed, browsher will display a warning and continue working normally with the standard command interface.

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
    --- Enable right-click menu integration using nvzone/menu
    enable_menu = false,
    --- Custom keybindings for the menu (when enable_menu is true)
    menu_keybindings = {
        --- Keybinding for opening menu with keyboard
        keyboard = "<leader>bm",
        --- Enable right-click mouse support
        mouse = true,
    },
    --- Command to open URLs (e.g., 'firefox').
    --- If this is a single character, it will be interpreted as a vim register
    --- instead. For example, to copy the url to your OS clipboard instead of
    --- opening it inside an application, set `open_cmd` to `+` for unix systems,
    --- or `*` if you're on Windows.
    open_cmd = nil,
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
        ["sr.ht"] = {
            url_template = "%s/tree/%s/item/%s",
            single_line_format = "#L%d",
            multi_line_format = "#L%d",
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

## Command Line

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

## Right-Click Menu

When the menu feature is enabled, you can:

- Press `<leader>bm` (or your custom keyboard binding) to open the menu in normal or visual mode
- **Visual mode**: Select lines and right-click to open the context menu with selection-specific options

The menu provides these options:

- **📍 Open at Commit** - Submenu with HEAD, HEAD~1, HEAD~2, etc. (up to HEAD~5)
- **🌿 Open at Branch** - Open file at current branch
- **🏷️ Open at Latest Tag** - Open file at latest tag
- **🏠 Open Repository Root** - Open repository homepage
- **📋 Copy URL (Commit)** - Submenu to copy URL for specific commits
- **📋 Copy URL (Branch)** - Copy branch URL to clipboard

Navigation:
- `h` and `l` - Move between windows
- `q` - Close menu
- Press keybind or scroll and press Enter to execute

# ⚠️ Notes

* **Uncommitted Changes**: If the current file has uncommitted changes, line numbers may not correspond to what's on the remote repository. By default, line numbers are omitted when there are uncommitted changes unless `allow_line_numbers_with_uncommitted_changes` is set to true.

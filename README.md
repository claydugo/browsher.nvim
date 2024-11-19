# 📖 browsher.nvim

`browsher.nvim` is a highly customizable Neovim plugin that opens the current file at the specified lines or range in your default browser, pinned to a specific branch, tag, commit, or the repository root in your remote Git repository.

# ✨ Features

- **Open files in the browser**: Quickly open the current file in your remote Git repository's web interface.
- **Line and Range Support**: Supports opening specific lines or ranges, including multiline selections from visual mode.
- **Customizable providers**: Support for GitHub, GitLab, and custom providers.
- **Custom open commands**: Specify custom commands to open URLs (e.g., use a specific browser).

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

Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use { 'claydugo/browsher.nvim' }
```

# ⚙️ Configuration

You can customize `browsher.nvim` by passing options to the setup function, below are the default options.

## Default Options
```lua
require('browsher').setup({
	--- Default remote name (e.g., 'origin').
	default_remote = nil,
	--- Default branch name.
	default_branch = nil,
	--- Default pin type ('commit', 'branch', or 'tag').
	default_pin = "commit",
	--- Allow line numbers with uncommitted changes.
	allow_line_numbers_with_uncommitted_changes = false,
	--- Command to open URLs (e.g., 'firefox').
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
	},
  },
})
```

## Key Mappings

Add the following key mappings to your Neovim configuration to quickly open files in the browser:

```lua
-- Open from the latest commit
vim.api.nvim_set_keymap('n', '<leader>b', '<cmd>Browsher commit<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('v', '<leader>b', ":'<,'>Browsher commit<CR>gv", { noremap = true, silent = true })

-- Open from the latest tag
vim.api.nvim_set_keymap('n', '<leader>B', '<cmd>Browsher tag<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('v', '<leader>B', ":'<,'>Browsher tag<CR>gv", { noremap = true, silent = true })
```

# 🚀 Usage

Use the `:Browsher` command to open the current file in your browser:

```vim
:Browsher [pin_type] [commit_hash]
```

* `pin_type` (optional): Specifies how to pin the file in the URL. Can be `branch`, `tag`, or `commit`.
    If omitted, uses the default pin type from the configuration (`commit` by default).
* `commit_hash` (optional): Specific commit hash to use when `pin_type` is `commit`.

# Examples

Open current file at the latest commit:

```vim
:Browsher
```

Open the repository root URL:

```vim
:Browsher root
```

Open current file at the current branch:

```vim
:Browsher branch
```

Open current file at the latest tag:

```vim
:Browsher tag
```

Open current file at a specific commit:

```vim
:Browsher commit 123abc
```

Open a visual selection of lines:
```vim
:'<,'>Browsher commit
```

Select lines in visual mode and run:

```vim
:Browsher
```

# ⚠️ Notes

* **Uncommitted Changes**: If the current file has uncommitted changes, line numbers may not correspond to what's on the remote repository. By default, line numbers are omitted when there are uncommitted changes unless `allow_line_numbers_with_uncommitted_changes` is set to true.

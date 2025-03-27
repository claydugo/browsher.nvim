# Browsher - Git Repository Code Share for Neovim and VSCode

Browsher is a cross-platform tool for sharing links to code in your remote Git repository, available both as a Neovim plugin and a VSCode extension.

This repository contains the Fennel source code that powers both versions, providing a consistent experience across editors.

## Features

- **Share code links**: Generate URLs to specific lines or selections in your remote Git repository
- **Smart line adjustments**: Automatically adjusts line numbers when you have uncommitted changes
- **Multiple Git providers**: Works with GitHub, GitLab, Bitbucket, Azure DevOps, Gitea, Forgejo, and custom providers
- **Configurable behavior**: Extensive configuration options

## Project Structure

```
fennel/
  ├── browsher/
  │   ├── core/              # Shared core functionality
  │   │   ├── config.fnl     # Configuration handling
  │   │   ├── git.fnl        # Git operations
  │   │   ├── init.fnl       # Main logic
  │   │   └── url.fnl        # URL building
  │   └── platforms/         # Platform-specific adapters
  │       ├── neovim.fnl     # Neovim adapter
  │       ├── neovim-entry.fnl # Neovim entry point
  │       ├── vscode.fnl     # VSCode adapter
  │       └── vscode-extension.fnl # VSCode entry point
  └── README.md              # This file

vscode-browsher/             # VSCode extension files
  ├── extension.fnl          # Extension entry point
  ├── package.json           # Extension manifest
  └── README.md              # VSCode extension README
```

## Building and Installing

### For Neovim

1. Compile the Fennel source to Lua:
```bash
fennel --compile fennel/browsher/platforms/neovim-entry.fnl > lua/browsher/init.lua
# Compile other files as needed
```

2. Install the plugin using your favorite plugin manager, for example with lazy.nvim:
```lua
{
  'your-username/browsher.nvim',
  config = function()
    require('browsher').setup()
  end
}
```

### For VSCode

1. Navigate to the `vscode-browsher` directory
2. Install dependencies: `npm install`
3. Compile the extension: `npm run compile`
4. Package the extension: `npm run package`
5. Install the extension from the generated .vsix file

## Usage

### In Neovim

The plugin provides a `:Browsher` command that opens the current file in your browser:

```
:Browsher [pin_type] [commit_hash]
```

You can map this to a key binding:

```lua
vim.api.nvim_set_keymap('n', '<leader>b', '<cmd>Browsher<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('v', '<leader>b', ":'<,'>Browsher<CR>gv", { noremap = true, silent = true })
```

### In VSCode

Right-click on your code and select "Share Code Link" from the context menu.

## Contributing

Contributions are welcome! This project uses Fennel as the source language to allow sharing code between the two platforms.

1. Make changes to the Fennel source code
2. Compile to Lua (for Neovim) or JavaScript (for VSCode)
3. Test your changes in both environments if applicable
4. Submit a pull request

## License

MIT 
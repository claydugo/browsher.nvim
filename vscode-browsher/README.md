# Browsher - Share Code via Git Repository URLs

Browsher is a VS Code extension that allows you to quickly share links to your code in your remote Git repository. With a simple right-click, it generates a URL to the current file in your remote repository, including the selected line(s).

## Features

- **Share code links**: Right-click on your code and select "Share Code Link" to generate a URL to that specific line or selection in your remote repository
- **Smart line adjustments**: Automatically adjusts line numbers when you have uncommitted changes
- **Support for multiple Git providers**: Works with GitHub, GitLab, Bitbucket, Azure DevOps, Gitea, Forgejo, and custom providers
- **Configurable behavior**: Customize how links are generated with various options

## Usage

1. Select a line or lines of code in your editor
2. Right-click and select "Share Code Link" from the context menu
3. The link will be opened in your default browser (and can be copied from there)

## Extension Settings

This extension provides the following settings:

* `browsher.defaultRemote`: Default remote name (e.g., 'origin')
* `browsher.defaultBranch`: Default branch name
* `browsher.defaultPin`: Default pin type ('commit', 'branch', or 'tag')
* `browsher.commitLength`: Length of the commit hash to use in URLs
* `browsher.allowLineNumbersWithUncommittedChanges`: Allow line numbers with uncommitted changes
* `browsher.cacheTtl`: Cache time-to-live in seconds for git operations
* `browsher.async`: Enable asynchronous operations
* `browsher.providers`: Custom providers for building URLs

## Custom Providers

You can add custom Git providers by configuring the `browsher.providers` setting:

```json
"browsher.providers": {
  "mygit.example.com": {
    "url_template": "%s/blob/%s/%s",
    "single_line_format": "#L%d",
    "multi_line_format": "#L%d-L%d"
  }
}
```

## Requirements

- Git must be installed and available in your PATH
- Your code must be part of a Git repository with a remote

## Known Issues

- The extension requires read access to your Git configuration
- It may not work with all Git hosting providers out of the box (but can be configured)

## Release Notes

### 0.1.0

- Initial release
- Support for GitHub, GitLab, Bitbucket, Azure DevOps, Gitea, and Forgejo
- Context menu integration
- Smart line number adjustment for uncommitted changes 
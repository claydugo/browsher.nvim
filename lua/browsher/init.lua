local git = require('browsher.git')
local url_builder = require('browsher.url')
local config = require('browsher.config')

local M = {}

local function open_url(url)
  local open_cmd
  if vim.fn.has('macunix') == 1 then
    open_cmd = 'open'
  elseif vim.fn.has('unix') == 1 then
    open_cmd = 'xdg-open'
  elseif vim.fn.has('win32') == 1 then
    open_cmd = 'start'
  else
    vim.notify('Unsupported OS', vim.log.levels.ERROR)
    return
  end

  -- Open the URL in the default web browser
  vim.fn.jobstart({open_cmd, url}, {detach = true})

  -- Show the message if the option is enabled
  if config.options.show_message then
    vim.notify('Opening ' .. url)
  end
end

function M.open_in_browser()
  local git_root, err = git.get_git_root()
  if not git_root then
    vim.notify(err, vim.log.levels.ERROR)
    return
  end

  local relpath, err = git.get_file_relative_path(git_root)
  if not relpath then
    vim.notify(err, vim.log.levels.ERROR)
    return
  end

  local remote_url, err = git.get_remote_url()
  if not remote_url then
    vim.notify(err, vim.log.levels.ERROR)
    return
  end

  local branch_or_tag, err = git.get_current_branch()
  if not branch_or_tag then
    vim.notify(err, vim.log.levels.ERROR)
    return
  end

  -- Check if the current branch is the user-defined default branch
  local default_branch = config.options.default_branch
  local branch_exists = git.branch_exists(default_branch)
  if not branch_exists then
    -- Fallback to 'master' if default branch doesn't exist
    default_branch = 'master'
    branch_exists = git.branch_exists(default_branch)
    if not branch_exists then
      vim.notify('Neither default branch nor master exists', vim.log.levels.ERROR)
      return
    end
  end

  if branch_or_tag == default_branch then
    -- Try to get the latest tag
    local latest_tag, tag_err = git.get_latest_tag()
    if latest_tag then
      branch_or_tag = latest_tag
    else
      -- Proceed with default_branch but notify about the issue
      vim.notify('Latest tag not found: ' .. tag_err, vim.log.levels.WARN)
    end
  end

  -- Get the current line number if in normal mode
  local line_number = nil
  if vim.api.nvim_get_mode().mode == 'n' then
    line_number = vim.api.nvim_win_get_cursor(0)[1]
  end

  local url, err = url_builder.build_url(remote_url, branch_or_tag, relpath, line_number)
  if not url then
    vim.notify(err, vim.log.levels.ERROR)
    return
  end

  open_url(url)
end

function M.setup(user_options)
  config.setup(user_options)
end

return M

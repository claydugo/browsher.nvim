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

  vim.fn.jobstart({open_cmd, url}, {detach = true})

  if config.options.show_message then
    vim.notify('Opening ' .. url)
  end
end

function M.open_in_browser(mode)
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

  local default_branch = config.options.default_branch
  local branch_exists = git.branch_exists(default_branch)
  if not branch_exists then
    local main_exists = git.branch_exists('main')
	local master_exists = git.branch_exists('master')

	default_branch = main_exists and 'main' or master_exists and 'master' or default_branch
    if not main_exists and not master_exists then
      vim.notify('Neither default branch nor main nor master exists', vim.log.levels.ERROR)
      return
    end
  end

  if branch_or_tag == default_branch then
    local latest_tag, tag_err = git.get_latest_tag()
    if latest_tag then
      branch_or_tag = latest_tag
    else
	  branch_or_tag = default_branch
    end
  end

  local has_changes = git.has_uncommitted_changes(relpath)
  local line_info = nil

  if has_changes then
    vim.notify('Warning: Uncommitted changes detected in this file. Line number removed from url.', vim.log.levels.WARN)
  else
    if mode == 'v' or mode == 'V' or mode == '\22' then
      local start_line = vim.fn.line("'<")
      local end_line = vim.fn.line("'>")
      if start_line > end_line then
        start_line, end_line = end_line, start_line
      end
      line_info = { start_line = start_line, end_line = end_line }
    elseif mode == 'n' then
      local line_number = vim.api.nvim_win_get_cursor(0)[1]
      line_info = { line_number = line_number }
    end
  end

  local url, err = url_builder.build_url(remote_url, branch_or_tag, relpath, line_info)
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

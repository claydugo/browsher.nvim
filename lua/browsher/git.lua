local M = {}

local function systemlist(cmd)
  local output = vim.fn.systemlist(cmd)
  if vim.v.shell_error ~= 0 then
    return nil, table.concat(output, '\n')
  end
  return output
end

function M.get_git_root()
  local git_root = systemlist('git rev-parse --show-toplevel')
  if not git_root or git_root[1] == '' then
    return nil, 'Not inside a git repository'
  end
  return git_root[1]
end

function M.get_remote_url()
  local remote_url = systemlist('git config --get remote.origin.url')
  if not remote_url or remote_url[1] == '' then
    return nil, 'No remote origin set'
  end
  return remote_url[1]
end

function M.get_branches()
  local branches = systemlist('git branch --list')
  if not branches then
    return nil, 'Could not retrieve branches'
  end
  local branch_names = {}
  for _, branch in ipairs(branches) do
    local name = branch:gsub('%*?%s*(.+)', '%1')
    table.insert(branch_names, name)
  end
  return branch_names
end

function M.get_current_branch()
  local branch = systemlist('git symbolic-ref --short HEAD')
  if branch and branch[1] ~= '' then
    return branch[1]
  end
  -- Fallback to detached HEAD commit hash
  branch = systemlist('git rev-parse HEAD')
  if branch and branch[1] ~= '' then
    return branch[1]
  end
  return nil, 'Could not determine the current branch or commit hash'
end

function M.get_latest_tag()
  local tag = systemlist('git describe --tags --abbrev=0')
  if tag and tag[1] ~= '' then
    return tag[1]
  end
  return nil, 'Could not determine the latest tag'
end

function M.get_file_relative_path(git_root)
  local filepath = vim.api.nvim_buf_get_name(0)
  if filepath == '' then
    return nil, 'No file to open'
  end
  local relpath = vim.fn.fnamemodify(filepath, ':.' .. git_root)
  return relpath
end

function M.branch_exists(branch_name)
  local branches = M.get_branches()
  if not branches then return false end
  for _, name in ipairs(branches) do
    if name == branch_name then
      return true
    end
  end
  return false
end

return M

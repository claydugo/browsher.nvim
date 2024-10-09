local M = {}

local function sanitize_remote_url(remote_url)
  -- Remove .git suffix
  remote_url = remote_url:gsub('%.git$', '')

  -- Convert SSH URLs to HTTPS
  if remote_url:match('^git@') then
    remote_url = remote_url:gsub('^git@(.-):(.*)$', 'https://%1/%2')
  elseif remote_url:match('^ssh://git@') then
    remote_url = remote_url:gsub('^ssh://git@(.-)/(.*)$', 'https://%1/%2')
  end

  return remote_url
end

function M.build_url(remote_url, branch_or_tag, relpath)
  remote_url = sanitize_remote_url(remote_url)

  -- Determine the provider and construct the URL accordingly
  local url
  if remote_url:match('github.com') then
    url = string.format('%s/blob/%s/%s', remote_url, branch_or_tag, relpath)
  elseif remote_url:match('gitlab.com') then
    url = string.format('%s/-/blob/%s/%s', remote_url, branch_or_tag, relpath)
  else
    return nil, 'Unsupported remote provider: ' .. remote_url
  end

  return url
end

return M

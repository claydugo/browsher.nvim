if vim.g.loaded_browsher then
  return
end
vim.g.loaded_browsher = true

vim.api.nvim_create_user_command('Browsher', function()
  require('browsher').open_in_browser()
end, { nargs = 0 })

vim.api.nvim_set_keymap('n', '<leader>b', '<cmd>Browsher<CR>', { noremap = true, silent = true })

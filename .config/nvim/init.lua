-- disable native nvim file explorer
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- enable 24-bit RGB color in the TUI
vim.opt.termguicolors = true

-- clipboard integration
vim.opt.clipboard:append('unnamedplus')

vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.softtabstop = 4
vim.opt.expandtab = true

require('config.lazy')
